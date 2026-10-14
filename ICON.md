# App icon

Based on the owner's supplied DDL icon on 2026-10-14. Edited with the built-in imagegen tool, then resized with macOS `sips` to the required 1024×1024 pixels. The PNG is opaque; iOS supplies the corner mask. Only the host AppIcon asset is changed, not Shield Configuration.

Final asset: `DeadlineTheo/Assets.xcassets/AppIcon.appiconset/AppIcon.png`.

Edit prompt:

Use case: precise-object-edit. Asset type: production iOS App Store app icon, square 1024x1024 opaque PNG. Input image 1 is the edit target. Convert this supplied icon mockup to the flat full-bleed artwork used INSIDE an iOS app icon. Preserve the exact blue handwritten DDL lettering and its sweeping underline, stroke shapes, slope, relative spacing and blue color as faithfully as possible. Remove ONLY the outer mockup framing: no pre-rounded tile, no tile edge, no external drop shadow, no external white margin. Extend the inner soft white / barely blue background all the way to all four square edges. The DDL and underline should be centered together with a safe 12% margin; roughly 76% width. Keep the airy minimal look. The full image must be a square with square corners and opaque background; the OS will mask the corners. No new elements, no added words, no extra icons, no border, no watermark. Text verbatim: DDL.

Validation on 2026-10-14: opaque 1024×1024 PNG, project plist validation, signed iOS Debug build, compiled Assets.car, and generated CFBundlePrimaryIcon = AppIcon all passed. The first device installation attempt failed with CoreDeviceError 4000 / connection reset by peer. After the owner reconnected the iPhone, the official devicectl installation succeeded at 22:37 on 2026-10-14. Home-screen appearance remains for the owner to inspect.
