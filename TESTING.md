# Prototype 0.1 physical-device acceptance

Use the installed Debug build on the owner's personal iPhone. **Core-loop acceptance passed on 2026-10-14.** The owner confirmed the force-quit procedure without issues; `IMG_9274.PNG` shows Monitor expiry cleanup at 22:10:22 and no active session. Earlier tests verified authorization, selection, exact custom shield, shared state, access to unselected apps, and immediate Debug Reset. These steps remain the repeatable acceptance procedure; evidence is recorded in `prototype-verification.json`.

## Relaunch regression — pre-expiry reopen passed on 2026-10-15

The owner reports the pre-expiry force-quit/reopen test passed on the installed fix: active session/end time and shield remain. Monitor expiry and Developer Reset rechecks have not yet been reported for this build. The procedure below remains repeatable.

The current Debug fix was installed on the owner’s iPhone on 2026-10-15 using official devicectl. For a later repeat, build/install the current Debug project through Xcode Run before testing; the earlier English UI-only build does not contain this fix. No permission prompt may be approved by automation. Confirm no earlier test session is active before beginning.

1. Authorize if needed, select one test app, choose **15 min**, and tap **Start commitment**. Record the displayed end time and confirm its shield appears. Do not change device time or authorization during this test.
2. After about one minute, force-quit Theo. Open the selected app and confirm it is still shielded.
3. After another one or two minutes, while clearly before the recorded end, reopen Theo. **Do not tap Allow Screen Time access, Start commitment, or Reset to make restoration happen.** The current commitment must appear with the original task and end time. No new session should be created.
4. Expand **Prototype / Developer-only** and capture **Latest status**. Expect `persistedSessionFound=true`, the same session ID across reopen attempts, `endInFuture=true`, `phase=active`, and `decision=keep` / `reason=authorizationUnconfirmed` or `decision=restore` / `reason=activeFutureSession`. Authorization may be `notDetermined` during restoration; that alone is not a failure. There must be no pre-expiry cleanup for that reason.
5. Immediately open the selected app again and confirm the shield remains. Confirm an unselected app still opens.
6. Repeat force-quit → reopen once more before expiry, checking the same end time/session ID and continued shield. Record whether every attempt passes.
7. Force-quit Theo again and leave it closed until expiry. **Open the selected app before reopening Theo.** Expect access restored, then reopen Theo and confirm the Monitor event **Automatic cleanup completed at expiry** and no active commitment. This is required to verify the original schedule was preserved.
8. Start a separate test session and use Developer Reset. Confirm immediate access restoration and no current commitment; restarting Theo must not resurrect that reset session.
9. If any step fails, stop and report elapsed time, original end time, current-commitment screen, Latest status, and Monitor status. Do not mask a failure by starting a replacement session.

Also repeat the original reproduction as a fresh session. A passing build or decision test is not a passing phone regression. Explicit-denial behavior is covered by the decision check; actual Settings revocation can be checked separately by the owner after the core regression, with reauthorization/reselection afterward. No automatic revoke or new override flow is introduced.

## First manual checkpoint: shared container and authorization

1. Unlock the iPhone and open **Deadline Theo**.
2. Expand **Prototype / Developer-only → Prototype diagnostics and testing** at the bottom of the page and confirm **App Group: Ready**. If it says **Not ready** or shows an error, stop and report the exact text.
3. Tap **Allow Screen Time access**. Approve the system request and complete authentication on the phone.
4. Confirm that the status changes to **Authorized**. Stop and report this result before starting a session.

## App selection and initial shield

1. Tap **Choose distracting apps** in the third setup section.
2. Expand a category and select one specific entertainment test app. Do not select an entire category or a website. Save.
3. Confirm the selected count is 1.
4. Keep the task **IELTS Listening**. Use **15 min** for the first natural-expiry test; 45 minutes remains the normal default.
5. Tap **Start commitment**. Record the displayed end time and check that a session is shown.
6. Open the selected entertainment app. Expect the custom shield text **Deadline Theo / 给我学。 / You asked me to stop you.**
7. Tap the shield button. The current app should close and the restriction must remain on reopening it.
8. Verify an unrelated, unselected app remains accessible.

## Shared Monitor access and host termination

1. Before terminating Theo, expand its **Prototype / Developer-only** area; it should eventually show a **Monitor** event with a session identifier and selected-app count. This event is written by the separate extension through the shared container. If it is not visible yet, a foreground refresh reloads shared state; it must not be fabricated from host state.
2. Leave Theo in the background and verify the chosen app remains shielded.
3. Force-quit Theo from the app switcher and verify it remains shielded.
4. Keep Theo closed until the recorded end. After that time, use the phone and open the selected app **before reopening Theo**. Expect access to be restored.
5. Reopen Theo. Expect no active session and a Monitor event **Automatic cleanup completed at expiry**. If only a foreground reconciliation event appears, background Monitor expiry has not yet been proved.

## Development Reset

1. Start a separate test session and confirm a shield appears.
2. In Theo, expand **Prototype / Developer-only**, then tap **Reset / Clear Theo restrictions**, marked **Developer-only**.
3. Confirm no active session remains and the selected app is accessible.
4. Verify unselected apps are unaffected. Reset clears only Theo's dedicated settings store.

## Acceptance evidence

Report the selected-app count, whether the exact shield appeared, whether its button kept the restriction, whether the force-quit check passed, the scheduled end time, the Monitor's cleanup event, and Reset behavior. App names, opaque tokens, passwords, and device identifiers are unnecessary in reports.

Do not claim Prototype 0.1 complete until natural expiry with the host terminated and the Debug Reset have both been checked. Revoke Screen Time access in iPhone Settings if a development bug prevents recovery through Reset.
