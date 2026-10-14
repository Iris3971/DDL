# Prototype 0.1 physical-device acceptance

Use the installed Debug build on the owner's personal iPhone. **Core-loop acceptance passed on 2026-10-14.** The owner confirmed the force-quit procedure without issues; `IMG_9274.PNG` shows Monitor expiry cleanup at 22:10:22 and no active session. Earlier tests verified authorization, selection, exact custom shield, shared state, access to unselected apps, and immediate Debug Reset. These steps remain the repeatable acceptance procedure; evidence is recorded in `prototype-verification.json`.

## First manual checkpoint: shared container and authorization

1. Unlock the iPhone and open **Deadline Theo**.
2. Under **原型验证状态**, confirm **App Group：已就绪**. If it says **未就绪** or shows an error, stop and report the exact text.
3. Tap **授权屏幕使用时间**. Approve the system request and complete authentication on the phone.
4. Confirm that the status changes to **已授权**. Stop and report this result before starting a session.

## App selection and initial shield

1. Tap **选择 1～3 个 App**.
2. Expand a category and select one specific entertainment test app. Do not select an entire category or a website. Save.
3. Confirm the selected count is 1.
4. Keep the task **IELTS Listening**. Use **15 分钟** for the first natural-expiry test; 45 minutes remains the normal default.
5. Tap **开始专注**. Record the displayed end time and check that a session is shown.
6. Open the selected entertainment app. Expect the custom shield text **Deadline Theo / 给我学。 / You asked me to stop you.**
7. Tap the shield button. The current app should close and the restriction must remain on reopening it.
8. Verify an unrelated, unselected app remains accessible.

## Shared Monitor access and host termination

1. Before terminating Theo, its diagnostic section should eventually show a **Monitor** event with a session identifier and selected-app count. This event is written by the separate extension through the shared container. If it is not visible yet, a foreground refresh reloads shared state; it must not be fabricated from host state.
2. Leave Theo in the background and verify the chosen app remains shielded.
3. Force-quit Theo from the app switcher and verify it remains shielded.
4. Keep Theo closed until the recorded end. After that time, use the phone and open the selected app **before reopening Theo**. Expect access to be restored.
5. Reopen Theo. Expect no active session and a Monitor event **到期自动清理完成**. If only a foreground reconciliation event appears, background Monitor expiry has not yet been proved.

## Development Reset

1. Start a separate test session and confirm a shield appears.
2. In Theo, tap **Reset / Clear Theo 限制** under **仅开发测试**.
3. Confirm no active session remains and the selected app is accessible.
4. Verify unselected apps are unaffected. Reset clears only Theo's dedicated settings store.

## Acceptance evidence

Report the selected-app count, whether the exact shield appeared, whether its button kept the restriction, whether the force-quit check passed, the scheduled end time, the Monitor's cleanup event, and Reset behavior. App names, opaque tokens, passwords, and device identifiers are unnecessary in reports.

Do not claim Prototype 0.1 complete until natural expiry with the host terminated and the Debug Reset have both been checked. Revoke Screen Time access in iPhone Settings if a development bug prevents recovery through Reset.
