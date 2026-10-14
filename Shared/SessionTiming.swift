import Foundation

struct SessionTiming: Codable, Equatable {
    enum Phase: String, Codable { case preparing, active }
    static let activityPrefix = "theo.focus."
    let id: UUID
    let task: String
    let startedAt: Date
    let endsAt: Date
    var phase: Phase

    var activityName: String { Self.activityPrefix + id.uuidString }

    static func make(task: String, minutes: Int, now: Date = Date()) throws -> Self {
        guard (15...180).contains(minutes) else { throw TimingError.invalidDuration }
        let start = Date(timeIntervalSince1970: floor(now.timeIntervalSince1970))
        let title = String(task.trimmingCharacters(in: .whitespacesAndNewlines).prefix(80))
        return Self(id: UUID(), task: title.isEmpty ? "IELTS Listening" : title,
                    startedAt: start, endsAt: start.addingTimeInterval(Double(minutes * 60)),
                    phase: .preparing)
    }

    func shouldExpire(activity: String, now: Date) -> Bool {
        activity == activityName && now >= endsAt
    }

    func isInWindow(at date: Date) -> Bool { startedAt <= date && date < endsAt }
    enum TimingError: Error { case invalidDuration }
}
