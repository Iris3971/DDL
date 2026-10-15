import Foundation
import Combine

@main
enum SessionRestorationChecks {
    final class AuthorizationPublisher {
        @Published var value = SessionAuthorization.notDetermined
    }

    static func main() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var timing = try SessionTiming.make(task: "IELTS Listening", minutes: 15, now: now)
        timing.phase = .active
        let persisted = try JSONEncoder().encode(timing)
        let restored = try JSONDecoder().decode(SessionTiming.self, from: persisted)

        // A relaunch reads the same session ID/end time before authorization is confirmed.
        precondition(restored == timing)
        for status in [SessionAuthorization.notDetermined, .unknown] {
            precondition(status.decision(for: restored, now: now) == .keep)
            precondition(status.decision(for: nil, now: now) == .keep)
            precondition(status.decision(for: restored, now: restored.endsAt) == .cleanup(.expired))
        }
        for status in [SessionAuthorization.approved, .approvedWithDataAccess] {
            precondition(status.decision(for: restored, now: now) == .restore)
            precondition(status.decision(for: restored, now: restored.endsAt.addingTimeInterval(-1)) == .restore)
            precondition(status.decision(for: restored, now: restored.endsAt) == .cleanup(.expired))
            precondition(status.decision(for: nil, now: now) == .cleanup(.noSession))
        }
        precondition(SessionAuthorization.denied.decision(for: restored, now: now) == .cleanup(.authorizationDenied))

        // Preserve existing handling for an interrupted preparing record when authorized.
        var preparing = restored
        preparing.phase = .preparing
        precondition(SessionAuthorization.approved.decision(for: preparing, now: now) == .cleanup(.interruptedPreparing))
        precondition(SessionAuthorization.notDetermined.decision(for: preparing, now: now) == .keep)

        // Exercise real Combine willSet delivery: use the emitted value, not property readback.
        let publisher = AuthorizationPublisher()
        var decisions: [SessionAuthorization.Decision] = []
        var readbackAtApproval: SessionAuthorization?
        let subscription = publisher.$value.sink { newValue in
            if newValue == .approved { readbackAtApproval = publisher.value }
            decisions.append(newValue.decision(for: restored, now: now))
        }
        publisher.value = .approved
        precondition(readbackAtApproval == .notDetermined)
        precondition(decisions == [.keep, .restore])
        publisher.value = .denied
        precondition(decisions.last == .cleanup(.authorizationDenied))
        withExtendedLifetime(subscription) {}
        print("PASS: persisted future session, unconfirmed authorization, emitted-value delivery, explicit denial, real expiry, unchanged preparing policy")
        print("These checks cover decision logic, not physical-device Screen Time behavior.")
    }
}
