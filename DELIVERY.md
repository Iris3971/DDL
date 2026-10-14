# DDL Prototype 0.1 交付说明

2026-10-14：个人 iPhone 上的核心闭环验收通过。

## 已完成的真实验证

- 付费 Developer Team 开发签名；主 App 和三个 extensions 的 provisioning profile 与有效签名均包含 Family Controls 和统一 App Group。
- `.individual` 授权成功，系统选择器选择两个 App，自定义 shield 文案正确。
- Monitor 从共享容器读取同一 session 及两个 App 的选择状态。
- 用户确认按最后一轮 15 分钟清单操作无问题：shield 按钮不会解锁，强制退出 Theo 后限制仍存在，到期先打开被限制 App 即已恢复，再重新打开 Theo。
- `IMG_9274.PNG` 显示「Monitor：到期自动清理完成」，事件时间 22:10:22，且没有正在进行的 session。这是 Monitor 到期清理的直接界面证据。
- 另一轮 25 分钟单 App session 中，其他 App 正常访问，Debug Reset 立即恢复所选 App 的访问。

证据索引见 `prototype-verification.json`；私人截图未复制进 Git。首次未强制退出的测试无法确认清理来源，保留原始记录；后续测试独立验证了 Monitor 清理。

## 工程与职责

| 路径 / target | 职责 |
| --- | --- |
| `DeadlineTheo.xcodeproj` | 四个 targets、统一签名、共享运行 scheme |
| `DeadlineTheo` | SwiftUI 主界面、授权、选择 App、启动单 session、前台 reconciliation、Debug Reset |
| `TheoActivityMonitor` | 系统区间开始 / 结束回调；到期清理 Theo 的限制 |
| `TheoShieldConfiguration` | 固定标题、文案和按钮外观 |
| `TheoShieldAction` | 按钮响应 `.close`，不解除限制 |
| `Shared` | session 时间模型、共享状态存储、文件锁、调度和专属 shield 操作 |
| `Tests` | 最小时长、结束边界、旧回调隔离及时间模型序列化检查 |

## 使用的公开 API

- FamilyControls：`AuthorizationCenter.shared.requestAuthorization(for: .individual)`、`FamilyActivityPicker`、`FamilyActivitySelection`。
- ManagedSettings：named `ManagedSettingsStore`、`shield.applications`、`clearAllSettings()`；仅操作 `theoFocus` 专属 store。
- DeviceActivity：`DeviceActivityCenter.startMonitoring` / `stopMonitoring`、`DeviceActivitySchedule`、`DeviceActivityMonitor.intervalDidStart` / `intervalDidEnd`。
- ManagedSettingsUI：`ShieldConfigurationDataSource`、`ShieldConfiguration`。
- ManagedSettings：`ShieldActionDelegate`、`ShieldActionResponse.close`。
- App Group：`FileManager.containerURL(forSecurityApplicationGroupIdentifier:)`；本地 JSON 原子写入、跨进程文件锁。

## 已配置的 capability

四个 targets 均已配置 `com.apple.developer.family-controls = true`，及统一 App Group `group.com.example.ddl.prototype01`。自动开发签名使用 Team `YOUR_TEAM_ID`。签名、profile、App ID、设备覆盖验证记录在 JSON 中；最初签名基线单独保存在 `signing-verification.json`。

## 真机安装与重复测试

当前设备已完成安装和授权，没有待完成的开发 capability 配置。

如需重新安装：

1. 在 Xcode 打开 `DeadlineTheo.xcodeproj`，选择 `DeadlineTheo` scheme。
2. 在四个 targets 的 Signing & Capabilities 中确认正式 Developer Team、Automatically manage signing、Family Controls、相同 App Group。换 Team 时需要更换唯一 Bundle IDs 和 App Group，不能直接沿用本团队注册项。
3. 连接并解锁 iPhone；按系统提示信任 Mac、开启开发者模式。选择此 iPhone 为运行设备。
4. 点击 Run，完成安装；证书、登录或设备确认弹窗由本人处理。
5. 打开 Theo，确认 App Group 已就绪；如未授权，点击授权按钮并完成系统确认。
6. 按 `TESTING.md` 完成选择 App、15 分钟 session、shield 按钮、强制退出、到期先打开被限制 App、Monitor 记录、独立 Reset 的测试。

## 已知限制

- 目前结论限于这台个人 iPhone 的已执行测试，不能保证所有系统版本或边界条件均可靠。
- 前台 reconciliation 已实现；损坏共享文件、设备重启、时区 / 系统时间变化等故障场景尚未逐一真机验证。
- 不将 DeviceActivity 当作精确到秒的后台计时器；长时间未使用设备后的行为还需补测。
- 用户保有撤销授权的权利。Reset 仅存在于 Debug。其他 Screen Time / 设备管理限制可能继续生效。
- 当前是开发签名安装；TestFlight / App Store 的 Family Controls 分发批准尚未获得或验证。开发验证不等于正式分发获批。

## 下一阶段建议

先保持当前版本，用于个人重复测试；优先补充锁屏、重启、跨日和撤销授权等边界验证，再决定下一阶段范围。当前没有进入 Prototype 0.2。
