import Foundation

// Keep an unconfirmed authorization snapshot distinct from explicit denial.
enum SessionAuthorization: String {
    case approved, approvedWithDataAccess, notDetermined, denied, unknown

    var isApproved: Bool { self == .approved || self == .approvedWithDataAccess }

    enum CleanupReason: String { case authorizationDenied, expired, interruptedPreparing, noSession }
    enum Decision: Equatable {
        case restore, keep
        case cleanup(CleanupReason)
    }

    func decision(for timing: SessionTiming?, now: Date) -> Decision {
        if self == .denied { return .cleanup(.authorizationDenied) }
        guard let timing else { return isApproved ? .cleanup(.noSession) : .keep }
        if now >= timing.endsAt { return .cleanup(.expired) }
        // Unknown status must not erase a future session or its system restrictions.
        guard isApproved else { return .keep }
        // Preserve the existing preparing-state handling; redesign is out of scope.
        if timing.phase == .preparing { return .cleanup(.interruptedPreparing) }
        return .restore
    }
}
