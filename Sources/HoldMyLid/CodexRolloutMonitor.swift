import Foundation

final class CodexRolloutMonitor {
    private static let discoveryBlockSize: UInt64 = 262_144

    private struct FileState {
        var offset: UInt64
        var status: AgentStatus
        var updated: Date
    }

    private var files: [String: FileState] = [:]
    private var lastDiscovery = Date.distantPast
    private var threadNames: [String: String] = [:]
    private let root: URL

    init(root: URL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".codex/sessions", isDirectory: true)) {
        self.root = root
    }

    func scan() -> [AgentSession] {
        discoverFiles()
        for path in files.keys { consume(path: path) }

        let cutoff = Date().addingTimeInterval(-48 * 60 * 60)
        return files.compactMap { path, state in
            guard state.updated >= cutoff else { return nil }
            let threadID = threadID(for: path)
            return AgentSession(
                id: threadID.map { "codex-\($0)" } ?? "codex-rollout-\(URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent)",
                agent: .codex,
                title: threadID.flatMap { threadNames[$0] } ?? "Codex task",
                status: state.status,
                lastUpdated: state.updated,
                pid: nil,
                source: "codex-rollout",
                sequence: Int64(state.updated.timeIntervalSince1970 * 1_000),
                deepLink: threadID.map { "codex://threads/\($0)" }
            )
        }
    }

    private func discoverFiles() {
        guard Date().timeIntervalSince(lastDiscovery) >= 5 else { return }
        lastDiscovery = Date()
        loadThreadNames()
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        let recent = Date().addingTimeInterval(-48 * 60 * 60)
        for case let url as URL in enumerator where url.pathExtension == "jsonl" && url.lastPathComponent.hasPrefix("rollout-") {
            guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
                  let modified = values.contentModificationDate,
                  modified >= recent else { continue }
            if files[url.path] == nil {
                let size = UInt64(values.fileSize ?? 0)
                files[url.path] = initialState(for: url, fileSize: size, modified: modified)
            }
        }
    }

    /// Reconstructs the current state of an existing rollout before switching to
    /// incremental reads. Active turns can produce megabytes of tool and context
    /// events after `task_started`, so a fixed-size tail can incorrectly classify
    /// a live task as idle.
    private func initialState(for url: URL, fileSize: UInt64, modified: Date) -> FileState {
        guard let handle = FileHandle(forReadingAtPath: url.path) else {
            return FileState(offset: 0, status: .idle, updated: modified)
        }
        defer { try? handle.close() }

        do {
            let completeEnd = try lastCompleteRecordEnd(in: handle, fileSize: fileSize)
            let status = try latestLifecycleStatus(in: handle, endingAt: completeEnd) ?? .idle
            return FileState(offset: completeEnd, status: status, updated: modified)
        } catch {
            return FileState(offset: 0, status: .idle, updated: modified)
        }
    }

    private func lastCompleteRecordEnd(in handle: FileHandle, fileSize: UInt64) throws -> UInt64 {
        var cursor = fileSize
        while cursor > 0 {
            let start = cursor > Self.discoveryBlockSize ? cursor - Self.discoveryBlockSize : 0
            try handle.seek(toOffset: start)
            let data = handle.readData(ofLength: Int(cursor - start))
            if let newline = data.lastIndex(of: 0x0A) {
                return start + UInt64(data.distance(from: data.startIndex, to: newline)) + 1
            }
            cursor = start
        }
        return 0
    }

    private func latestLifecycleStatus(in handle: FileHandle, endingAt end: UInt64) throws -> AgentStatus? {
        guard end > 0 else { return nil }
        var cursor = end
        var leadingFragment = Data()
        let decoder = JSONDecoder()

        while cursor > 0 {
            let start = cursor > Self.discoveryBlockSize ? cursor - Self.discoveryBlockSize : 0
            try handle.seek(toOffset: start)
            var combined = handle.readData(ofLength: Int(cursor - start))
            combined.append(leadingFragment)

            let pieces = combined.split(separator: 0x0A, omittingEmptySubsequences: false)
            let beginsWithDelimiter = combined.first == 0x0A
            let firstCandidate = start == 0 || beginsWithDelimiter ? 0 : 1

            if firstCandidate < pieces.count {
                for piece in pieces[firstCandidate...].reversed() where !piece.isEmpty {
                    guard let event = try? decoder.decode(RolloutEvent.self, from: Data(piece)),
                          event.type == "event_msg" else { continue }
                    switch event.payload.type {
                    case "task_started": return .working
                    case "task_complete", "turn_aborted": return .idle
                    default: continue
                    }
                }
            }

            if start > 0, !beginsWithDelimiter, let first = pieces.first {
                leadingFragment = Data(first)
            } else {
                leadingFragment.removeAll(keepingCapacity: true)
            }
            cursor = start
        }
        return nil
    }

    private func threadID(for path: String) -> String? {
        let stem = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        guard stem.count >= 36 else { return nil }
        let candidate = String(stem.suffix(36))
        return UUID(uuidString: candidate) == nil ? nil : candidate
    }

    private func loadThreadNames() {
        let index = root.deletingLastPathComponent().appendingPathComponent("session_index.jsonl")
        guard let text = try? String(contentsOf: index, encoding: .utf8) else { return }
        for line in text.split(separator: "\n") {
            guard let data = line.data(using: .utf8),
                  let item = try? JSONDecoder().decode(ThreadIndexItem.self, from: data) else { continue }
            threadNames[item.id] = item.threadName
        }
    }

    private func consume(path: String) {
        guard var state = files[path], let handle = FileHandle(forReadingAtPath: path) else { return }
        defer { try? handle.close() }
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            let fileSize = (attributes[.size] as? NSNumber)?.uint64Value ?? 0
            if state.offset > fileSize {
                state.offset = 0
                state.status = .idle
            }
            try handle.seek(toOffset: state.offset)
            let data = handle.readDataToEndOfFile()
            guard !data.isEmpty else {
                files[path] = state
                return
            }

            // Writers append rollout events in multiple writes. Only advance through
            // complete newline-terminated records so a partial event is retried.
            guard let lastNewline = data.lastIndex(of: 0x0A) else {
                files[path] = state
                return
            }
            let completeData = data.prefix(through: lastNewline)
            state.offset += UInt64(completeData.count)
            guard let text = String(data: completeData, encoding: .utf8) else {
                files[path] = state
                return
            }
            var lines = text.split(separator: "\n", omittingEmptySubsequences: true)
            if state.offset - UInt64(completeData.count) > 0, !text.hasPrefix("{") { lines = Array(lines.dropFirst()) }
            let decoder = JSONDecoder()
            for line in lines {
                guard let event = try? decoder.decode(RolloutEvent.self, from: Data(line.utf8)), event.type == "event_msg" else { continue }
                switch event.payload.type {
                case "task_started": state.status = .working
                case "task_complete", "turn_aborted": state.status = .idle
                default: continue
                }
                // Filesystem modification time is the freshness signal. Rollout
                // fixtures and imported sessions can contain timestamps from a
                // different clock or an older host date, while the file itself
                // was just written and is still a live session.
                if let eventDate = event.timestamp.flatMap(Self.parseTimestamp) {
                    state.updated = max(state.updated, eventDate)
                }
            }
            files[path] = state
        } catch {
            files[path] = state
        }
    }

    private static func parseTimestamp(_ value: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: value) { return date }
        return ISO8601DateFormatter().date(from: value)
    }
}

private struct RolloutEvent: Decodable {
    struct Payload: Decodable { let type: String }
    let timestamp: String?
    let type: String
    let payload: Payload
}

private struct ThreadIndexItem: Decodable {
    let id: String
    let threadName: String

    enum CodingKeys: String, CodingKey {
        case id
        case threadName = "thread_name"
    }
}
