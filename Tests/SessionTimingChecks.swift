import Foundation

@main
enum SessionTimingChecks {
    static func main() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000.75)
        let first = try SessionTiming.make(task: "IELTS Listening", minutes: 15, now: now)
        let second = try SessionTiming.make(task: "Other", minutes: 45, now: now)
        precondition(first.endsAt.timeIntervalSince(first.startedAt) == 900)
        precondition(first.startedAt.timeIntervalSince1970.rounded(.down) == first.startedAt.timeIntervalSince1970)
        precondition(!first.shouldExpire(activity: first.activityName, now: first.endsAt.addingTimeInterval(-1)))
        precondition(first.shouldExpire(activity: first.activityName, now: first.endsAt))
        precondition(!second.shouldExpire(activity: first.activityName, now: second.endsAt.addingTimeInterval(1)))
        precondition(first.isInWindow(at: first.startedAt))
        precondition(!first.isInWindow(at: first.endsAt))
        do {
            _ = try SessionTiming.make(task: "Too short", minutes: 14, now: now)
            fatalError("A sub-15-minute session was accepted")
        } catch SessionTiming.TimingError.invalidDuration {}
        let encoded = try JSONEncoder().encode(first)
        let decoded = try JSONDecoder().decode(SessionTiming.self, from: encoded)
        precondition(decoded == first)
        print("PASS: minimum duration, aligned schedule, expiry boundary, stale callback rejection, Codable round-trip")
    }
}
