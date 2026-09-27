# Jomado iOS

Jomado is a local-first wellness routine companion built with SwiftUI, ActivityKit, WidgetKit, UserNotifications, and a deterministic curated-content engine.

This repository is a fresh implementation based on the canonical product specification in `JOMADO_FINAL_CANONICAL_PRODUCT_UX_TECHNICAL_SPEC.md`. The first vertical slice includes:

- a generic multi-routine domain model;
- explicit completion-only reminder state transitions;
- an animated in-app reminder experience with Reduce Motion support;
- a Lock Screen Live Activity and Dynamic Island presentation;
- actionable local notifications;
- a bundled, validated content pack and deterministic content selector;
- a production-facing content and mascot asset contract for designers.

## Open the project

The Xcode project is generated from `project.yml` so target membership stays reproducible.

Requirements:

- macOS with Xcode 26 or newer;
- XcodeGen 2.42 or newer;
- an Apple development team for device signing.

From the repository root on macOS:

```sh
xcodegen generate
open Jomado.xcodeproj
```

Validate the designer-owned content before generating the project:

```sh
python3 Scripts/validate_content.py
```

Before device testing, replace the placeholder bundle identifiers and App Group in `project.yml` and both entitlement files with identifiers registered to your Apple Developer account.

## Key files

- `Docs/CONTENT_AND_MASCOT_CONTRACT.md` is the handoff contract for copy, graphics, mascot poses, and motion.
- `Resources/Content/Schemas/jomado-content-pack.schema.json` is the machine-readable content schema.
- `Resources/Content/en/starter-reminders.json` is a small bootstrap pack used by the current slice.
- `Shared/JomadoActivityAttributes.swift` is shared by the app and Live Activity extension.
- `Jomado/Features/Reminder/ReminderExperienceView.swift` is the animated in-app reminder.
- `JomadoLiveActivity/JomadoLiveActivityWidget.swift` defines Lock Screen and Dynamic Island layouts.

## Platform behavior

Standard notification banners are system-owned and cannot host a continuously animated custom interface. Jomado therefore uses concise notification copy and actions there, short state-driven transitions in Live Activities, and richer looping animation only inside the app.

## Current verification boundary

The source and contracts can be validated in this Windows workspace, but the app and widget targets must be compiled and exercised with Xcode 26 on macOS and on a Dynamic Island-capable device before release.
