import AppKit
import Foundation

enum ActivityRuleKind: String, CaseIterable, Identifiable, Codable {
    case downloading, rendering, compiling, exporting, backingUp, selectedApps

    var id: String { rawValue }
    var title: String {
        switch self {
        case .downloading: "Downloading"
        case .rendering: "Rendering"
        case .compiling: "Compiling"
        case .exporting: "Exporting"
        case .backingUp: "Backing up"
        case .selectedApps: "Selected applications"
        }
    }
    var symbol: String {
        switch self {
        case .downloading: "arrow.down.circle"
        case .rendering: "sparkles.rectangle.stack"
        case .compiling: "hammer"
        case .exporting: "square.and.arrow.up"
        case .backingUp: "externaldrive.badge.timemachine"
        case .selectedApps: "app.badge"
        }
    }
    fileprivate var processHints: [String] {
        switch self {
        case .downloading: ["curl", "wget", "aria2c", "transmission", "qbittorrent"]
        case .rendering: ["blender", "cinema 4d", "after effects", "compressor", "ffmpeg"]
        case .compiling: ["swiftc", "clang", "xcodebuild", "make", "ninja", "cargo", "gradle"]
        case .exporting: ["compressor", "media encoder", "handbrake", "ffmpeg"]
        case .backingUp: ["backupd", "restic", "borg", "rclone", "arq"]
        case .selectedApps: []
        }
    }
}

struct ActivityRule: Identifiable, Codable, Equatable {
    var id: ActivityRuleKind { kind }
    var kind: ActivityRuleKind
    var isEnabled: Bool = false
    var selectedApplicationPaths: [String] = []

    static var defaults: [ActivityRule] { ActivityRuleKind.allCases.map { ActivityRule(kind: $0) } }
}

struct ActivityMatch: Identifiable, Equatable {
    var id: String { "\(kind.rawValue)-\(processName)" }
    var kind: ActivityRuleKind
    var processName: String
    var reason: String { kind == .selectedApps ? processName : kind.title }
}

final class ActivityRuleMonitor {
    private let snapshotProvider: () -> ActivityProcessSnapshot

    init(snapshotProvider: @escaping () -> ActivityProcessSnapshot = ActivityRuleMonitor.systemSnapshot) {
        self.snapshotProvider = snapshotProvider
    }

    func scan(rules: [ActivityRule]) -> [ActivityMatch] {
        let enabled = rules.filter(\.isEnabled)
        guard !enabled.isEmpty else { return [] }
        let snapshot = snapshotProvider()
        var matches: [ActivityMatch] = []
        for rule in enabled {
            if rule.kind == .selectedApps {
                for path in rule.selectedApplicationPaths {
                    let name = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
                    if snapshot.runningApplicationPaths.contains(where: { $0.caseInsensitiveCompare(path) == .orderedSame }) {
                        matches.append(ActivityMatch(kind: rule.kind, processName: name))
                    }
                }
            } else if let process = snapshot.executableNames.first(where: { name in
                rule.kind.processHints.contains { name.caseInsensitiveCompare($0) == .orderedSame }
            }) {
                matches.append(ActivityMatch(kind: rule.kind, processName: process))
            }
        }
        return Array(Dictionary(grouping: matches, by: \.id).values.compactMap(\.first))
    }

    fileprivate static func systemSnapshot() -> ActivityProcessSnapshot {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-axo", "comm="]
        process.standardOutput = pipe
        process.standardError = Pipe()
        do { try process.run() } catch { return ActivityProcessSnapshot(executableNames: [], runningApplicationPaths: []) }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0, let text = String(data: data, encoding: .utf8) else { return ActivityProcessSnapshot(executableNames: [], runningApplicationPaths: []) }
        let names = text.split(separator: "\n").map { URL(fileURLWithPath: String($0).trimmingCharacters(in: .whitespaces)).lastPathComponent }
        let apps = NSWorkspace.shared.runningApplications.compactMap { $0.bundleURL?.path }
        return ActivityProcessSnapshot(executableNames: names, runningApplicationPaths: apps)
    }
}

struct ActivityProcessSnapshot {
    var executableNames: [String]
    var runningApplicationPaths: [String]
}
