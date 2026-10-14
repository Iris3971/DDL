# DDL Prototype 0.1 — signing checkpoint passed

This is the smallest four-target project used to verify the paid team's development-signing and physical-device installation path. It is not the completed functional Prototype 0.1. The host app only displays an installation-check screen; it does not request Screen Time authorization, create sessions, or apply restrictions.

## Targets

| Target | Role in this checkpoint |
| --- | --- |
| DeadlineTheo | SwiftUI installation-check screen |
| TheoActivityMonitor | Device Activity Monitor extension entry point |
| TheoShieldConfiguration | Fixed local shield text, ready for later runtime testing |
| TheoShieldAction | Responds with `.close`; never clears restrictions |

`Shared/PrototypeConfiguration.swift` defines the dedicated `theoFocus` store name. The three extensions are embedded in the host app. Every target uses automatic development signing for the verified Developer Team and includes `com.apple.developer.family-controls = true`.

Deployment target: iOS 16. No dependencies, server, AI, analytics, accounts, or network code. App Groups and session storage are deferred until the functional 0.1 step.

## Verified on 2026-10-14

- Xcode 26.6 (17F113).
- The connected iPhone 15 Pro Max reports iOS 26.6. Pairing succeeded and Developer Mode is enabled.
- Developer Disk Image services report `contentIsCompatible: true` and `isUsable: true`.
- All four targets compile and embed successfully.
- The signed Debug build targeting the physical iPhone succeeded using automatic signing and device registration.
- Each of the four embedded development provisioning profiles contains the Family Controls entitlement, the correct team and explicit App ID, and the connected test device. Their expiration dates are 2027-10-14 UTC.
- Each of the four products' effective signed entitlements contains Family Controls, the correct team and App ID, and `get-task-allow` for development debugging.
- Each product's signature passed strict verification; the host app and all nested signatures also passed deep verification.
- The installation-check app was installed and launched successfully on the iPhone. Its running process was checked separately.

Machine-readable verification: `signing-verification.json`. Build products are local and ignored under `.build/`.

The displayed screen reads “Deadline Theo”, “Prototype 0.1 · Signing verification”, and “本次只验证安装与签名。尚未启用 App 限制。” Installation and launch do not prove Screen Time authorization, extension callbacks, or the focus-session loop work.

No app was published, no distribution entitlement request was submitted, and no restrictions were applied.

## Resolved environment issues and remaining risks

The initial Simulator download failed with MobileAsset catalog authorization error 41. Developer Disk Image mounting independently failed with CoreDevice 12040 and underlying HTTP authorization error 3501. After the user's network test and component setup, the physical-device destination and developer image became usable. A common network-path cause was suspected, but the specific service or VPN behavior was not established. Do not infer that a Simulator download is always needed to fix developer image personalization.

Development provisioning is now verified. TestFlight and App Store distribution still require separate Family Controls distribution authorization covering the host and relevant extensions. Signing may need regeneration when certificates, device registrations, or capabilities change. Keep generated profiles and private signing keys out of source control.

## Next minimal implementation

1. Configure a common App Group for session metadata and selected tokens.
2. Add individual Screen Time authorization and `FamilyActivityPicker`, enforcing a selection of 1–3 specific apps.
3. Implement one active session with a 15-minute minimum and default “IELTS Listening · 45 min”.
4. Register a one-shot DeviceActivity schedule and apply shields immediately using the dedicated named store. Roll back safely if registration fails.
5. Implement guarded, idempotent expiry cleanup in the monitor extension, foreground reconciliation, and development-only Reset/Clear. Ensure stale callbacks cannot clear a newer session.
6. Validate the fixed local shield, no-unlock action, background/force-quit behavior, and natural expiry on the physical iPhone.

This remains Prototype 0.1. No 0.2 features are included.

## Apple references

- [Configuring Family Controls](https://developer.apple.com/documentation/xcode/configuring-family-controls)
- [Requesting the Family Controls entitlement](https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement)
- [Enabling Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)

Extension point identifiers and principal-class configuration were checked against the templates bundled with this installed Xcode.
