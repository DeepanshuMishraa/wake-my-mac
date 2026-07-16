import Foundation

// AppState serializes access on its dedicated utility queue. The monitor owns
// incremental rollout state, so callers must not scan it concurrently.
final class AgentMonitor: @unchecked Sendable {
    private let hooksDirectory: URL
    private let codexMonitor = CodexRolloutMonitor()

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        hooksDirectory = base.appendingPathComponent("Hold My Lid/Sessions", isDirectory: true)
        try? FileManager.default.createDirectory(at: hooksDirectory, withIntermediateDirectories: true)
    }

    func scan() -> [AgentRow] {
        let installedAgents = AgentKind.allCases.filter { $0.isMenuVisible && $0.isInstalled }
        let processRows = ProcessListing.read()
        let livePIDs = Set(processRows.map(\.pid))
        let hooked = readHookSessions(livePIDs: livePIDs, processRows: processRows)
            .filter { installedAgents.contains($0.agent) }
        let codexSessions = installedAgents.contains(.codex) ? codexMonitor.scan() : []
        let processBacked = readProcessSessions(
            for: installedAgents,
            existingIDs: Set(hooked.map(\.id)),
            processRows: processRows
        )
        let sessions = hooked + codexSessions + processBacked

        return installedAgents.map { kind in
            AgentRow(agent: kind, sessions: sessions.filter { $0.agent == kind }.sorted { $0.title < $1.title })
        }
    }

    private func readHookSessions(livePIDs: Set<Int>, processRows: [ProcessRow]) -> [AgentSession] {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: hooksDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let now = Date()

        return urls.compactMap { url in
            guard url.pathExtension == "json", let data = try? Data(contentsOf: url) else { return nil }
            guard var session = try? decoder.decode(AgentSession.self, from: data), session.status != .absent else { return nil }
            if let pid = session.pid, !livePIDs.contains(pid) {
                return nil
            }
            let hasMatchingProcess = processRows.contains { session.agent.matchesProcess($0) }
            if SessionLiveness.shouldTreatAsIdle(session, hasMatchingProcess: hasMatchingProcess, now: now) {
                session.status = .idle
            }
            return session
        }
    }

    private func readProcessSessions(
        for installedAgents: [AgentKind],
        existingIDs: Set<String>,
        processRows: [ProcessRow]
    ) -> [AgentSession] {
        var sessions: [AgentSession] = []

        for kind in installedAgents {
            let matches = processRows.filter { row in
                kind.matchesProcess(row)
            }

            for match in matches.prefix(3) {
                let id = "\(kind.rawValue)-pid-\(match.pid)"
                guard !existingIDs.contains(id) else { continue }
                sessions.append(AgentSession(
                    id: id,
                    agent: kind,
                    title: match.command.lastPathComponentFallback,
                    status: .idle,
                    lastUpdated: Date(),
                    pid: match.pid,
                    source: "process",
                    sequence: nil,
                    deepLink: nil
                ))
            }
        }

        return sessions
    }
}

enum SessionLiveness {
    static func shouldTreatAsIdle(_ session: AgentSession, hasMatchingProcess: Bool, now: Date) -> Bool {
        guard session.pid == nil, session.status == .working || session.status == .blocked else { return false }
        let age = now.timeIntervalSince(session.lastUpdated)
        if session.source == "hook" { return age > 120 }
        if session.source.hasSuffix("-adapter") { return age > 10 && !hasMatchingProcess }
        return false
    }
}

private struct ProcessRow {
    var pid: Int
    var command: String
    var arguments: String
}

private extension AgentKind {
    func matchesProcess(_ row: ProcessRow) -> Bool {
        guard !shouldIgnoreProcess(arguments: row.arguments) else { return false }
        let commandName = URL(fileURLWithPath: row.command).lastPathComponent
        let exactMatch = exactProcessNames.contains { commandName.caseInsensitiveCompare($0) == .orderedSame }
        let hintedMatch = processHints.contains { hint in
            row.command.localizedCaseInsensitiveContains(hint) || row.arguments.localizedCaseInsensitiveContains(hint)
        }
        return exactMatch || hintedMatch
    }
}

private enum ProcessListing {
    static func read() -> [ProcessRow] {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-axo", "pid=,comm=,args="]
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return []
        }

        // Drain stdout while `ps` is still running. Waiting for termination first
        // can deadlock when the process list exceeds the pipe buffer: `ps` blocks
        // waiting for a reader while the app's main thread blocks waiting for `ps`.
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard let output = String(data: data, encoding: .utf8) else { return [] }

        return output.split(separator: "\n").compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard let firstSpace = trimmed.firstIndex(where: { $0 == " " }) else { return nil }
            let pidText = String(trimmed[..<firstSpace])
            guard let pid = Int(pidText) else { return nil }
            let rest = trimmed[firstSpace...].trimmingCharacters(in: .whitespaces)
            let pieces = rest.split(separator: " ", maxSplits: 1).map(String.init)
            guard let command = pieces.first else { return nil }
            let args = pieces.count > 1 ? pieces[1] : command
            return ProcessRow(pid: pid, command: command, arguments: args)
        }
    }
}

private extension String {
    var lastPathComponentFallback: String {
        URL(fileURLWithPath: self).lastPathComponent.isEmpty ? self : URL(fileURLWithPath: self).lastPathComponent
    }
}
