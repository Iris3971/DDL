import SwiftUI
import FamilyControls
import Combine

@main
struct DeadlineTheoApp: App {
    var body: some Scene {
        WindowGroup { FocusView() }
    }
}

struct FocusView: View {
    @StateObject private var model = FocusViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showPicker = false
    @State private var showPrototypeTools = false
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Make a commitment now.")
                            .font(.headline)
                        Text("Theo will help you hold it when distraction shows up.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("A promise you make to yourself.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))

                Section {
                    TextField("e.g. IELTS Listening", text: $model.task)
                        .disabled(model.state.session != nil)
                        .accessibilityLabel("Choose a task you want to complete.")
                } header: {
                    setupHeading("What are you committing to?", translation: "Choose a task you want to complete.")
                }

                Section {
                    Picker("Duration", selection: $model.minutes) {
                        ForEach([15, 25, 45, 60], id: \.self) { Text("\($0) min").tag($0) }
                    }
                    .disabled(model.state.session != nil)
                } header: {
                    setupHeading("For how long?", translation: "Set the duration of your commitment.")
                }

                Section {
                    if !model.authorized {
                        Text("Allow Screen Time access so Theo can shield the apps you choose.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Allow Screen Time access") { Task { await model.authorize() } }
                            .disabled(model.busy).accessibilityIdentifier("authorizeButton")
                    }
                    Button {
                        model.preparePicker()
                        showPicker = true
                    } label: {
                        HStack {
                            Text("Choose distracting apps")
                            Spacer()
                            Text("\(model.state.selection.applicationTokens.count) selected")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(!model.authorized || model.state.session != nil || model.busy)
                    .accessibilityIdentifier("chooseAppsButton")
                } header: {
                    setupHeading("What should Theo keep you away from?", translation: "Choose the apps that distract you.")
                } footer: {
                    Text("Choose 1–3 individual apps.")
                }

                if let error = model.errorMessage {
                    Section("Needs attention") { Text(caseStudyCopy(error)).foregroundStyle(.red) }
                }

                Section {
                    Button { model.start() } label: {
                        Text("Start commitment")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .disabled(!model.canStart)
                        .accessibilityLabel("Start commitment")
                        .accessibilityIdentifier("startSessionButton")
                    VStack(spacing: 4) {
                        Text("Theo will hold this boundary for the time you chose.")
                        Text("Your choice. Your commitment.")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))

                if let timing = model.state.session?.timing {
                    Section("Current commitment") {
                        Text(timing.task).font(.headline)
                        Text("Ends at: \(timing.endsAt.formatted(.dateTime.hour().minute().locale(Locale(identifier: "en"))))")
                        Text(timing.endsAt, style: .timer).monospacedDigit()
                        Text("Your selected apps are shielded for this commitment.")
                    }
                }

                Section {
                    DisclosureGroup(isExpanded: $showPrototypeTools) {
                        Text("Authorization: \(caseStudyCopy(model.statusText))")
                        Text(model.sharedReady ? "App Group: Ready" : "App Group: Not ready")
                        if let event = model.state.events.last(where: { $0.source == "Monitor" }) {
                            Text("Monitor: \(caseStudyCopy(event.message))")
                            Text(event.date.formatted(.dateTime.hour().minute().second().locale(Locale(identifier: "en"))))
                        } else { Text("Waiting for a Monitor callback") }
                        if let event = model.state.events.last { Text("Latest status: \(caseStudyCopy(event.message))") }
                        #if DEBUG
                        Button("Reset / Clear Theo restrictions", role: .destructive) { model.reset() }
                            .disabled(model.busy).accessibilityIdentifier("resetButton")
                        Text("Developer-only. Clear this prototype’s restrictions and session.")
                        #endif
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Prototype / Developer-only")
                            Text("Prototype diagnostics and testing")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                    .font(.footnote)
                }
            }
            .navigationTitle("Deadline Theo")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPicker) {
                NavigationStack {
                    VStack {
                        Text("Choose 1–3 individual apps, not entire categories or websites.")
                            .font(.footnote).padding()
                        if let error = model.errorMessage { Text(caseStudyCopy(error)).foregroundStyle(.red).padding(.horizontal) }
                        FamilyActivityPicker(selection: $model.draftSelection)
                    }
                    .navigationTitle("Choose apps")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showPicker = false } }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") { if model.saveSelection() { showPicker = false } }
                        }
                    }
                }
            }
            .task { model.refresh(source: "launch") }
            .onChange(of: scenePhase) { phase in if phase == .active { model.refresh(source: "foreground") } }
            .onReceive(model.authorization.$authorizationStatus) { status in
                model.refresh(updatedAuthorization: status, source: "authorization publisher")
            }
            .onReceive(ticker) { _ in if scenePhase == .active { model.tick() } }
        }
    }

    // Display-only copy for the HCI case study; do not rewrite stored diagnostics.
    private func caseStudyCopy(_ message: String) -> String {
        switch message {
        case "已授权": return "Authorized"
        case "未授权／已撤销": return "Denied / Revoked"
        case "尚未授权": return "Not yet authorized"
        case "未知状态": return "Unknown status"
        case "请选择 1～3 个具体 App；本原型不接受整类或网站选择。":
            return "Choose 1–3 individual apps, not entire categories or websites."
        case "已有专注 session，请等待到期或使用开发 Reset。":
            return "A commitment is already active. Wait until it ends or use Developer Reset."
        case "Session 启动被中断，请重试。":
            return "The commitment could not start. Please try again."
        case "无法访问 App Group。请检查四个 targets 的签名与共享容器权限。":
            return "App Group unavailable. Check signing and shared-container access for all four targets."
        case "无法锁定共享 session 文件，请稍后重试或使用开发 Reset。":
            return "Unable to lock the shared session file. Try again or use Developer Reset."
        case "准备启动 session": return "Preparing to start the session"
        case "Session 已开始，已请求屏蔽所选 App": return "Session started; shielding requested for selected apps"
        case "启动失败，已回滚限制": return "Start failed; restrictions rolled back"
        case "到期自动清理完成": return "Automatic cleanup completed at expiry"
        case "前台 reconciliation 已清理到期或中断的 session":
            return "Foreground reconciliation cleared an expired or interrupted session"
        case "开发 Reset 已清理 Theo 的限制": return "Developer Reset cleared Theo’s restrictions"
        default:
            let resetPrefix = "Theo 的限制已请求清除，但共享状态读取失败："
            if message.hasPrefix(resetPrefix) {
                return "Theo’s restrictions were requested to be cleared, but shared-state reading failed: " +
                    caseStudyCopy(String(message.dropFirst(resetPrefix.count)))
            }
            if message.hasPrefix("共享 session ") {
                return message.replacingOccurrences(of: "共享 session ", with: "Shared session ")
                    .replacingOccurrences(of: "：", with: ": ")
                    .replacingOccurrences(of: " 个 App", with: " app(s)")
            }
            return message
        }
    }

    private func setupHeading(_ title: String, translation: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline).foregroundStyle(Color.primary)
            Text(translation).font(.subheadline).foregroundStyle(Color.secondary)
        }
        .textCase(nil)
        .padding(.bottom, 4)
    }
}
