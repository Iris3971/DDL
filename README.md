# DDL Prototype 0.1

Native SwiftUI focus-session prototype. **Prototype 0.1's core loop passed acceptance on the owner's personal iPhone on 2026-10-14.** Individual authorization, app selection, custom shield, shield-button behavior, persistence after host force-quit, Monitor expiry cleanup before reopening the host, unaffected unselected apps, and Debug Reset were verified through owner reports and device screenshots. This is one-device prototype acceptance, not a general reliability or distribution certification.

**2026-10-15 regression update:** the owner reproduced premature session cancellation when reopening the host before expiry. The minimal authorization/restoration fix builds, passes decision checks, and is installed on the personal iPhone. The owner now confirms the pre-expiry force-quit/reopen regression passes: the active session/end time and shield remain. Extended Monitor expiry and Developer Reset rechecks have not yet been reported for this build. The 2026-10-14 results below remain historical evidence and do not certify this fix.

See [交付说明](DELIVERY.md), [repeatable device checklist](TESTING.md), and [verification evidence](prototype-verification.json).

## Git signing milestone

- Commit: `a9f9a89` — **Prototype 0.1 signing + physical device installation verified**
- Annotated tag: `prototype-0.1-signing-verified`
- `signing-verification.json` is the evidence for that earlier installation-check build. It does not assert that the later functional session loop has passed.
- Current functional-build evidence is in `prototype-verification.json`.
- Core-loop milestone: annotated tag `prototype-0.1-core-loop-verified`, with commit message **Prototype 0.1 core loop verified on physical iPhone**. Milestones are local; no remote push.

## Current verification status

| Check | Status |
| --- | --- |
| Signing milestone commit and tag | Saved locally; no remote push |
| Four-target physical-device Debug build | Passed |
| Family Controls in all profiles and effective signatures | Passed |
| Common App Group in all profiles and effective signatures | Passed |
| Team, explicit App IDs, and test-device coverage | Passed |
| Strict signatures, including embedded extensions | Passed |
| Minimum duration, aligned dates, expiry boundary, stale activity rejection, Codable timing round-trip | Passed |
| Functional build installed and launched; process running | Passed |
| Host App Group read/write at runtime | Owner confirmed the app displays App Group ready |
| Monitor extension reads shared session | Passed: device screenshot shows a Monitor-written session event and two apps |
| Individual authorization | Owner confirmed authorization successful |
| Two-app selection and exact custom shield | Passed: owner report and device screenshots |
| Natural expiry restoration | Passed by owner report, including access before reopening the force-quit host |
| Force-quit persistence and Monitor expiry cleanup | Passed by owner report and IMG_9274.PNG: Monitor completion at 22:10:22 |
| Shield button preserves restrictions | Passed: owner confirms following the final test steps without issues |
| Unselected apps remain accessible | Passed by owner report during a separate single-app session |
| Debug Reset recovery | Passed by owner report: separate 25-minute session shielded the selected app, Reset immediately restored access |

First session evidence: `IMG_9268.PNG`–`IMG_9271.PNG` shows the exact shield, two selected apps, and shared-state access. `IMG_9272.PNG` did not establish that session's cleanup source. A subsequent 15-minute test followed the force-quit procedure: the owner confirms the selected app remained shielded after termination and became accessible at expiry before Theo reopened. `IMG_9274.PNG` then shows **Monitor: 到期自动清理完成**, timestamp **22:10:22**, no active session, and App Group ready. This resolves the Monitor acceptance requirement for the subsequent test without attributing the earlier cleanup. A separate 25-minute session verified immediate Reset and access to unselected apps. Image binaries are not copied into Git; `prototype-verification.json` separates screenshot observations from owner reports.

The connected device reports iPhone 15 Pro Max / iOS 26.6. The Mac uses Xcode 26.6 (17F113). Developer Disk Image services are compatible and usable. Earlier component and developer-image network authorization failures disappeared after the user's network/component checks; the exact network cause was not established.

## Screen 1 UI polish — 2026-10-15

In this prototype build, Screen 1 uses English display copy, including its picker wrapper and Developer-only area. Existing stored diagnostics are rendered in English by a view-only adapter; their original data is unchanged. This is not a permanent English-only product decision. Future product versions will support localization based on system language; this task adds no localization framework or global language override. Apple-owned system UI and user-entered task text are not translated.

Commitment Setup now follows task → duration → distracting apps → one blue **Start commitment** action, using the existing native Form controls and bindings. Short commitment copy replaces the developer-panel emphasis. Unneeded authorization diagnostics, App Group / Monitor status, and the Debug-only Reset are under a collapsed **Prototype / Developer-only** disclosure at the bottom. When authorization is needed, the existing authorization button remains visible beside app selection. Current session details still appear while active; the idle placeholder is omitted. Error feedback remains visible near the primary action.

Signed iOS Debug and simulator builds passed. Simulator inspection checked text layout, disabled primary action, and expansion of the developer diagnostics/Reset area. The unsigned simulator run reports App Group unavailable, so it does not verify authorization or restriction behavior.

The UI-polish edit changed presentation only; the subsequent bug fix described below intentionally changes authorization handling in reconciliation. The ViewModel, shared session engine/storage/timing, all extensions, entitlements, and lifecycle callbacks remain unchanged. Earlier core-loop evidence remains historical evidence for the validated implementation; the polished UI still requires an owner-run iPhone regression using TESTING.md. No formal override, Screen 2, Screen 3, or 0.2 work is included.

## Relaunch restoration fix — 2026-10-15 (pre-expiry reopen verified)

Authorization is no longer reduced to a cleanup Boolean. A small `SessionAuthorization` decision helper distinguishes approved, explicitly denied, not-determined, and unknown snapshots. The publisher callback passes its emitted status directly. Reconciliation reads persisted state under the existing lock and returns that state for UI restoration.

- Future active session + unconfirmed authorization: **keep** session/selection/shield/schedule; restore the session UI.
- Future active session + approved authorization: **restore** the session and existing selected-app shield, without re-registering its schedule.
- Actual expiry: **cleanup / expired**, including when authorization is unconfirmed.
- Explicit denial: **cleanup / authorizationDenied**.
- Approved + successfully read empty state: existing **cleanup / noSession** behavior retained.
- Approved + preparing record: existing **cleanup / interruptedPreparing** behavior retained. Preparing redesign is **Future Work**, not part of this fix.
- A state-read failure logs the error and does not itself request cleanup; failed operations are distinguished from successful decisions.

Each reconciliation writes a bounded local diagnostic event and an OS log with trigger source, authorization snapshot, persisted-session presence/ID, end time, whether it is still in the future, phase, decision, and reason. OS logs additionally record completed/failed outcome. The existing Developer-only area displays the latest event without a UI change. Unconfirmed authorization also skips orphan-schedule cleanup.

Decision checks (including actual Combine willSet delivery) passed; this does not prove device behavior:

```sh
swiftc -module-cache-path .build/check-cache Shared/SessionTiming.swift Shared/SessionAuthorization.swift Tests/SessionRestorationChecks.swift -o .build/session-restoration-check
.build/session-restoration-check
```

The Screen 1 visual layout, duration rules, session storage format, Custom Shield, Monitor callbacks, start flow, and explicit Developer Reset remain unchanged. The project only links the new helper into the host and Monitor targets. The owner-confirmed pre-expiry reopen result is recorded in `prototype-verification.json`; remaining expiry/Reset rechecks are listed in TESTING.md. Local milestone tag: `prototype-0.1-relaunch-verified`. Xcode also upgraded the shared scheme format and normalized the debugger launcher identifier when the project was first opened; the Debug run configuration and build target are preserved.

## Four targets and shared code

- **DeadlineTheo:** explicit `.individual` authorization button, system `FamilyActivityPicker`, task/duration controls, session status, foreground reconciliation, Debug-only Reset/Clear.
- **TheoActivityMonitor:** receives system interval callbacks, reads the shared session, and clears Theo's named store at expiry.
- **TheoShieldConfiguration:** local fixed shield: “Deadline Theo”, “给我学。”, “You asked me to stop you.”
- **TheoShieldAction:** returns `.close` for shield button actions; never unlocks apps.
- **Shared:** `SessionTiming`, `SessionStorage`, `SessionAuthorization`, `FocusSessionEngine`, and `PrototypeConfiguration`.

All four targets use Family Controls and `group.com.example.ddl.prototype01`. Only the host and monitor need session-file access. The shield appearance/action extensions use fixed local behavior.

One named `ManagedSettingsStore`, `theoFocus`, owns all prototype restrictions. The App Group JSON stores the user's opaque selection tokens, one session, and at most 30 local diagnostic events. A POSIX file lock serializes cross-process state and shield operations; writes are atomic and accessible after first device unlock. Each session has its own UUID-based activity name. Stale callbacks cannot end a different session during normal operation. Monitor expiry and explicit Reset retain their existing recovery behavior; a relaunch state-read failure reports an error without treating it as authorization denial or requesting cleanup.

## App icon

The host uses the supplied blue handwritten DDL design, adapted to full-bleed square artwork without mockup corners or outer shadow. The opaque 1024×1024 PNG is in `DeadlineTheo/Assets.xcassets/AppIcon.appiconset`; see `ICON.md` for the image-edit prompt. The shield extension keeps its existing appearance.

## Functional scope

- Default: **IELTS Listening · 45 min**. Duration choices: 15, 25, 45, 60 minutes.
- Selection must contain 1–3 specific app tokens, with no whole-category or website selection.
- Only one active/preparing session. Selection is frozen while it runs.
- Start persists a preparing record, registers a one-shot schedule, activates the record, and requests shields immediately. Errors roll back the start.
- Monitor expiry and foreground reconciliation remove only Theo's own store settings. An interrupted preparing state is cleared when the app returns to the foreground.
- Debug Reset clears the dedicated store even if shared-state reading fails, then attempts to reset the record and stop Theo's activities. It is excluded from Release builds.
- Revoked authorization clears saved selection; invalidated tokens must be selected again after authorization is restored.

## Device test

Follow [TESTING.md](TESTING.md). Stop at system permission prompts and let the device owner act. Never mark the full loop verified merely from compilation, signatures, or a successful installation.

To rerun the pure timing checks locally:

```sh
swiftc -module-cache-path .build/check-cache Shared/SessionTiming.swift Tests/SessionTimingChecks.swift -o .build/session-timing-check
.build/session-timing-check
```

## Limits

DeviceActivity callbacks depend on device use; this is not a precise-to-the-second background alarm. For expiry acceptance, use the phone after the scheduled end and verify that the selected app becomes accessible without reopening Theo. A foreground cleanup event alone does not prove the Monitor cleaned up while the host was terminated.

The user retains the ability to revoke authorization. Other Screen Time or device-management restrictions may still apply after Theo clears its own store. TestFlight and App Store distribution require separate Family Controls distribution approval covering the host and relevant extensions.

No AI, chat, accounts, cloud, analytics, task-completion detection, complex override, or 0.2 features are implemented. No app was published and no distribution entitlement request was submitted.

## Apple references

- [Configuring Family Controls](https://developer.apple.com/documentation/xcode/configuring-family-controls)
- [Configuring app groups](https://developer.apple.com/documentation/xcode/configuring-app-groups)
- [FamilyActivitySelection and revoked tokens](https://developer.apple.com/documentation/familycontrols/familyactivityselection)
- [DeviceActivity interval end semantics](https://developer.apple.com/documentation/deviceactivity/deviceactivitymonitor/intervaldidend(for:))

Extension identifiers and principal classes match this installed Xcode's official templates.
