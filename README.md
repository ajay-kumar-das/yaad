# Jomado iOS

Jomado is a local-first wellness routine companion built with SwiftUI, SwiftData, AlarmKit, ActivityKit, WidgetKit, UserNotifications, and a deterministic curated-content engine.

This repository is a fresh implementation based on the canonical product specification in `JOMADO_FINAL_CANONICAL_PRODUCT_UX_TECHNICAL_SPEC.md`. The current implementation includes:

- a generic multi-routine domain model;
- SwiftData-backed routine and occurrence persistence;
- local wall-clock schedule materialization with a rolling seven-day reconciliation horizon;
- explicit completion-only reminder state transitions;
- a trust-based V1 completion-verification abstraction that can later accept HealthKit/camera verifiers;
- configurable reminder personality and intensity defaults with per-routine overrides;
- an animated in-app reminder experience with Reduce Motion support;
- a Lock Screen Live Activity and Dynamic Island presentation;
- native AlarmKit delivery for routines configured as `Alarm + Companion`, with authorization-aware local-notification fallback, duplicate-alert suppression, durable snooze/follow-up reconciliation, and App Group receipts for stop/open actions;
- actionable local notifications that are scheduled by iOS and continue when the app is not running, subject to permission/system policy;
- a bundled, validated 246-item English content pack and deterministic content selector;
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

Before device testing, register `com.ajaydas.jomado`, `com.ajaydas.jomado.liveactivity`, and `group.com.ajaydas.jomado.shared` in your Apple Developer account, then select your development team in Xcode. If those identifiers belong to a different account, change them together in `project.yml`, the app URL type, and both entitlement files.

## Key files

- `Docs/CONTENT_AND_MASCOT_CONTRACT.md` is the handoff contract for copy, graphics, mascot poses, and motion.
- `Resources/Content/Schemas/jomado-content-pack.schema.json` is the machine-readable content schema.
- `Resources/Content/en/starter-reminders.json` is the validated bundled 246-item English content pack.
- `Shared/JomadoActivityAttributes.swift` is shared by the app and Live Activity extension.
- `Jomado/Features/Reminder/ReminderExperienceView.swift` is the animated in-app reminder.
- `JomadoLiveActivity/JomadoLiveActivityWidget.swift` defines Lock Screen and Dynamic Island layouts.

## Platform behavior

Standard notification banners are system-owned and cannot host a continuously animated custom interface. Jomado therefore uses concise notification copy and actions there, short state-driven transitions in Live Activities, and richer looping animation only inside the app.

## Current verification boundary

The source and contracts can be syntax/content validated in this Linux workspace, but the app and widget targets must be compiled and exercised with Xcode 26 on macOS and on a Dynamic Island-capable device before release. The AlarmKit source path is wired into reconciliation, including authorization, fixed-alarm scheduling, cancellation, notification fallback, and duplicate suppression. It still requires Apple-SDK type-checking and physical-device verification; scheduled Live Activity lifecycle integration and deeper delivery diagnostics remain release work.
