import SwiftUI
import FamilyControls

@MainActor
final class FocusViewModel: ObservableObject {
    let authorization = AuthorizationCenter.shared
    @Published var authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    @Published var task = "IELTS Listening"
    @Published var minutes = 45
    @Published var draftSelection = FamilyActivitySelection()
    @Published var state = SharedState()
    @Published var sharedReady = false
    @Published var busy = false
    @Published var errorMessage: String?

    var authorized: Bool {
        if authorizationStatus == .approved { return true }
        if #available(iOS 26.4, *) { return authorizationStatus == .approvedWithDataAccess }
        return false
    }
    var canStart: Bool {
        authorized && sharedReady && !busy && state.session == nil &&
        (try? FocusSessionEngine.validate(state.selection)) != nil
    }

    var statusText: String {
        if authorized { return "已授权" }
        switch authorizationStatus {
        case .denied: return "未授权／已撤销"
        case .notDetermined: return "尚未授权"
        default: return "未知状态"
        }
    }

    func refresh() {
        authorizationStatus = authorization.authorizationStatus
        do {
            try FocusSessionEngine.reconcile(authorized: authorized)
            state = try SessionStorage.read()
            sharedReady = true
        } catch {
            sharedReady = false
            errorMessage = error.localizedDescription
        }
    }

    func authorize() async {
        busy = true
        errorMessage = nil
        defer { busy = false }
        do { try await authorization.requestAuthorization(for: .individual) }
        catch { errorMessage = error.localizedDescription }
        refresh()
    }

    func preparePicker() {
        errorMessage = nil
        draftSelection = state.selection
    }

    func saveSelection() -> Bool {
        do {
            guard authorized else { return false }
            try FocusSessionEngine.saveSelection(draftSelection)
            state = try SessionStorage.read()
            errorMessage = nil
            return true
        } catch { errorMessage = error.localizedDescription; return false }
    }

    func start() {
        guard canStart else { return }
        busy = true
        errorMessage = nil
        defer { busy = false }
        do {
            try FocusSessionEngine.start(task: task, minutes: minutes)
            state = try SessionStorage.read()
        } catch { errorMessage = error.localizedDescription; refresh() }
    }

    func tick() {
        if let record = state.session, Date() >= record.timing.endsAt { refresh() }
    }

    #if DEBUG
    func reset() {
        errorMessage = nil
        do { try FocusSessionEngine.reset(); state = try SessionStorage.read(); sharedReady = true }
        catch { errorMessage = "Theo 的限制已请求清除，但共享状态读取失败：\(error.localizedDescription)" }
    }
    #endif
}
