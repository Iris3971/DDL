import Foundation
import FamilyControls
import Darwin

struct FocusRecord: Codable {
    var timing: SessionTiming
    let selection: FamilyActivitySelection
}

struct SessionEvent: Codable {
    let date: Date
    let source: String
    let message: String
}

struct SharedState: Codable {
    var selection = FamilyActivitySelection()
    var session: FocusRecord?
    var events: [SessionEvent] = []

    mutating func record(_ message: String, source: String) {
        events.append(SessionEvent(date: Date(), source: source, message: message))
        events = Array(events.suffix(30))
    }
}

enum SessionStorage {
    enum StorageError: LocalizedError {
        case missingGroup, lockFailed
        var errorDescription: String? {
            switch self {
            case .missingGroup: return "无法访问 App Group。请检查四个 targets 的签名与共享容器权限。"
            case .lockFailed: return "无法锁定共享 session 文件，请稍后重试或使用开发 Reset。"
            }
        }
    }

    // A real file lock serializes app/monitor operations, including their shield writes.
    // Each access opens a fresh descriptor; never cache state across processes.
    static func access<T>(write: Bool = false, recoverCorrupt: Bool = false,
                          _ operation: (inout SharedState) throws -> T) throws -> T {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: PrototypeConfiguration.appGroup
        ) else { throw StorageError.missingGroup }
        let lockURL = container.appendingPathComponent("focus.lock")
        let newLock = !FileManager.default.fileExists(atPath: lockURL.path)
        let fd = open(lockURL.path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard fd >= 0 else { throw StorageError.lockFailed }
        defer { close(fd) }
        if newLock {
            try FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: lockURL.path
            )
        }
        guard flock(fd, LOCK_EX) == 0 else { throw StorageError.lockFailed }
        defer { flock(fd, LOCK_UN) }
        let url = container.appendingPathComponent("focus-state.json")
        var state = SharedState()
        if FileManager.default.fileExists(atPath: url.path) {
            do { state = try JSONDecoder().decode(SharedState.self, from: Data(contentsOf: url)) }
            catch { if !recoverCorrupt { throw error } }
        }
        let result = try operation(&state)
        if write {
            try JSONEncoder().encode(state).write(
                to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
            )
        }
        return result
    }

    static func read() throws -> SharedState { try access { $0 } }
}
