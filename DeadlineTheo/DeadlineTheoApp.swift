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
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            Form {
                Section("屏幕使用时间权限") {
                    Text(model.statusText)
                    if !model.authorized {
                        Button("授权屏幕使用时间") { Task { await model.authorize() } }
                            .disabled(model.busy).accessibilityIdentifier("authorizeButton")
                    }
                }
                Section("要限制的 App") {
                    Text("已选择 \(model.state.selection.applicationTokens.count) 个 App")
                    Button("选择 1～3 个 App") { model.preparePicker(); showPicker = true }
                        .disabled(!model.authorized || model.state.session != nil || model.busy)
                        .accessibilityIdentifier("chooseAppsButton")
                }
                Section("专注任务") {
                    TextField("任务", text: $model.task)
                        .disabled(model.state.session != nil)
                    Picker("时长", selection: $model.minutes) {
                        ForEach([15, 25, 45, 60], id: \.self) { Text("\($0) 分钟").tag($0) }
                    }.disabled(model.state.session != nil)
                    Button("开始专注") { model.start() }
                        .disabled(!model.canStart).accessibilityIdentifier("startSessionButton")
                }
                Section("当前 session") {
                    if let timing = model.state.session?.timing {
                        Text(timing.task).font(.headline)
                        Text("结束时间：\(timing.endsAt.formatted(date: .omitted, time: .shortened))")
                        Text(timing.endsAt, style: .timer).monospacedDigit()
                        Text("所选 App 已进入限制时段。")
                    } else { Text("没有正在进行的 session") }
                }
                Section("原型验证状态") {
                    Text(model.sharedReady ? "App Group：已就绪" : "App Group：未就绪")
                    if let event = model.state.events.last(where: { $0.source == "Monitor" }) {
                        Text("Monitor：\(event.message)")
                        Text(event.date.formatted(date: .omitted, time: .standard)).font(.caption)
                    } else { Text("等待 Monitor 回调") }
                    if let event = model.state.events.last { Text("最近状态：\(event.message)").font(.caption) }
                }
                #if DEBUG
                Section("仅开发测试") {
                    Button("Reset / Clear Theo 限制", role: .destructive) { model.reset() }
                        .disabled(model.busy).accessibilityIdentifier("resetButton")
                    Text("清除本原型的限制与 session。测试结束后请清理。").font(.caption)
                }
                #endif
                if let error = model.errorMessage {
                    Section("需要处理") { Text(error).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Deadline Theo")
            .sheet(isPresented: $showPicker) {
                NavigationStack {
                    VStack {
                        Text("请选择 1～3 个具体 App，不选择整类或网站。")
                            .font(.footnote).padding()
                        if let error = model.errorMessage { Text(error).foregroundStyle(.red).padding(.horizontal) }
                        FamilyActivityPicker(selection: $model.draftSelection)
                    }
                    .navigationTitle("选择 App")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("取消") { showPicker = false } }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("保存") { if model.saveSelection() { showPicker = false } }
                        }
                    }
                }
            }
            .task { model.refresh() }
            .onChange(of: scenePhase) { phase in if phase == .active { model.refresh() } }
            .onReceive(model.authorization.$authorizationStatus) { _ in model.refresh() }
            .onReceive(ticker) { _ in if scenePhase == .active { model.tick() } }
        }
    }
}
