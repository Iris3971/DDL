import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import os

enum FocusSessionEngine {
    private static let logger = Logger(subsystem: "com.deadlinetheo.prototype01", category: "session")
    private static var store: ManagedSettingsStore { ManagedSettingsStore(named: PrototypeConfiguration.storeName) }

    enum SessionError: LocalizedError {
        case selection, alreadyRunning, interrupted
        var errorDescription: String? {
            switch self {
            case .selection: return "请选择 1～3 个具体 App；本原型不接受整类或网站选择。"
            case .alreadyRunning: return "已有专注 session，请等待到期或使用开发 Reset。"
            case .interrupted: return "Session 启动被中断，请重试。"
            }
        }
    }

    static func validate(_ selection: FamilyActivitySelection) throws {
        guard (1...3).contains(selection.applicationTokens.count),
              selection.categoryTokens.isEmpty, selection.webDomainTokens.isEmpty
        else { throw SessionError.selection }
    }

    static func saveSelection(_ selection: FamilyActivitySelection) throws {
        try validate(selection)
        try SessionStorage.access(write: true) { state in
            guard state.session == nil else { throw SessionError.alreadyRunning }
            state.selection = selection
        }
    }

    static func start(task: String, minutes: Int) throws {
        let timing = try SessionTiming.make(task: task, minutes: minutes)
        try SessionStorage.access(write: true) { state in
            guard state.session == nil else { throw SessionError.alreadyRunning }
            try validate(state.selection)
            state.session = FocusRecord(timing: timing, selection: state.selection)
            state.record("准备启动 session", source: "App")
        }
        let activity = DeviceActivityName(timing.activityName)
        do {
            let calendar = Calendar.current
            func components(_ date: Date) -> DateComponents {
                var parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
                parts.calendar = calendar
                parts.timeZone = calendar.timeZone
                return parts
            }
            let schedule = DeviceActivitySchedule(intervalStart: components(timing.startedAt),
                                                  intervalEnd: components(timing.endsAt), repeats: false)
            // Registration is outside the file lock: an immediate callback must not deadlock.
            try DeviceActivityCenter().startMonitoring(activity, during: schedule)
            try SessionStorage.access(write: true) { state in
                guard var record = state.session, record.timing.id == timing.id,
                      record.timing.isInWindow(at: Date()) else { throw SessionError.interrupted }
                record.timing.phase = .active
                state.session = record
                store.shield.applications = record.selection.applicationTokens
                state.record("Session 已开始，已请求屏蔽所选 App", source: "App")
            }
        } catch {
            // A failed start must never leave the user shielded without a registered end.
            do {
                try SessionStorage.access(write: true) { state in
                    guard state.session?.timing.id == timing.id else { return }
                    store.clearAllSettings()
                    state.session = nil
                    state.record("启动失败，已回滚限制", source: "App")
                }
            } catch { store.clearAllSettings() }
            DeviceActivityCenter().stopMonitoring([activity])
            throw error
        }
    }

    static func intervalStarted(_ activity: DeviceActivityName) {
        do {
            try SessionStorage.access(write: true) { state in
                guard let record = state.session, record.timing.activityName == activity.rawValue else { return }
                state.record("共享 session \(record.timing.id.uuidString.prefix(8))：\(record.selection.applicationTokens.count) 个 App", source: "Monitor")
                if record.timing.phase == .active && record.timing.isInWindow(at: Date()) {
                    store.shield.applications = record.selection.applicationTokens
                }
            }
        } catch { logger.error("intervalStarted: \(error.localizedDescription, privacy: .public)") }
    }

    static func intervalEnded(_ activity: DeviceActivityName) {
        do {
            try SessionStorage.access(write: true) { state in
                guard let record = state.session,
                      record.timing.shouldExpire(activity: activity.rawValue, now: Date()) else { return }
                store.clearAllSettings()
                state.session = nil
                state.record("到期自动清理完成", source: "Monitor")
            }
        } catch {
            // Storage errors must not trap the device behind this app's shield.
            store.clearAllSettings()
            logger.error("intervalEnded cleanup failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    static func reconcile(authorized: Bool) throws {
        var stop: DeviceActivityName?
        try SessionStorage.access(write: true) { state in
            if !authorized {
                stop = state.session.map { DeviceActivityName($0.timing.activityName) }
                store.clearAllSettings()
                state.session = nil
                state.selection = FamilyActivitySelection()
            } else if let record = state.session {
                if Date() >= record.timing.endsAt || record.timing.phase == .preparing {
                    stop = DeviceActivityName(record.timing.activityName)
                    store.clearAllSettings()
                    state.session = nil
                    state.record("前台 reconciliation 已清理到期或中断的 session", source: "App")
                } else {
                    store.shield.applications = record.selection.applicationTokens
                }
            } else {
                store.clearAllSettings()
            }
        }
        if let stop { DeviceActivityCenter().stopMonitoring([stop]) }
        // Remove orphan registrations without touching another feature's activities.
        let current = try SessionStorage.read().session?.timing.activityName
        let orphans = DeviceActivityCenter().activities.filter {
            $0.rawValue.hasPrefix(SessionTiming.activityPrefix) && $0.rawValue != current
        }
        if !orphans.isEmpty { DeviceActivityCenter().stopMonitoring(orphans) }
    }

    #if DEBUG
    static func reset() throws {
        // Clear the named store even if the group container or JSON is damaged.
        store.clearAllSettings()
        let activities = DeviceActivityCenter().activities.filter { $0.rawValue.hasPrefix(SessionTiming.activityPrefix) }
        defer { DeviceActivityCenter().stopMonitoring(activities) }
        try SessionStorage.access(write: true, recoverCorrupt: true) { state in
            store.clearAllSettings()
            state.session = nil
            state.record("开发 Reset 已清理 Theo 的限制", source: "App")
        }
    }
    #endif
}
