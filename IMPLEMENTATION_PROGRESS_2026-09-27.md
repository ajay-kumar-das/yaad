# Jomado implementation progress — 2026-09-27

## Implemented in this continuation

- SwiftData persistence for routines, reminder occurrences, and content-exposure history.
- Full routine draft carries schedule window, repeat interval, weekdays, delivery mode, personality, intensity, snooze policy, and explicit completion label.
- Local wall-clock schedule planner with deterministic occurrence keys.
- Seven-day rolling notification reconciliation with a conservative 48-primary-notification budget so follow-ups retain capacity.
- Reconciliation on app bootstrap, app activation, timezone change, calendar-day change, save, enable/disable, and delete.
- Persisted notification actions for complete, remind-later, open, dismiss, and in-app skip.
- Routines screen now reads actual SwiftData records instead of sample cards.
- Add Routine now saves the configured interval/window/days instead of throwing those settings away.
- Routine-level personality and intensity selection.
- Global Reminder Settings for personality, intensity/strictness, language placeholder, emoji level, message length, and sound preference.
- Permissions screen with notification request/test, Live Activity test, and iOS Settings deep link.
- V1 trust-based completion-verification abstraction. Health-data/camera verification can be added later behind the same protocol without changing reminder completion semantics.
- Bundled English content expanded from 6 to 246 validated items. Generic coverage now exists for every personality x intensity x urgency-stage combination, while authored hydration content remains available.
- Persisted anti-repetition content exposure history is now used during scheduled content selection.
- Today now derives progress, next-up state, quick actions, and routine summaries from persisted routines/occurrences.
- Insights now derives completion rate, trend, routine progress, and streak information from persisted occurrence history. Its headline completion rate uses `completed / resolved`, excluding unresolved/open reminders from the denominator.
- Schedule planner tests added using the project's existing XCTest convention.
- Native AlarmKit source integration for `Alarm + Companion`: Info.plist usage description, permission request, fixed alarm scheduling, custom stop/open App Intents, cancellation, reconciliation, notification fallback, and duplicate ordinary-notification suppression.
- AlarmKit stop/open actions now cross the process boundary through the existing App Group as durable per-event receipts; receipts are acknowledged only after the main app has handled/persisted the state change. Stopping an alarm records acknowledgement and never completion.
- Notification open/dismiss actions now consistently route through persisted occurrence state instead of sometimes mutating only the in-memory reminder.
- Companion notification sound preference is now applied by the notification scheduler.
- Today `View Progress` now routes to Insights, and next-up selection no longer lets old unresolved history permanently mask today/future reminders.
- Snoozed follow-ups are now first-class reconciled state: follow-up date/content persist, survive app relaunch, restore through AlarmKit or notification fallback, and are removed when the routine is disabled/deleted or the snooze policy is exhausted.

## Important behavior now covered

Local notifications are registered with iOS ahead of time. Once scheduled and permission is granted, delivery does not require the Jomado process to remain open. Dismissing/stopping/opening still does not imply completion; completion remains explicit.

## Still production-critical before release

1. **AlarmKit Xcode/device validation** — scheduling and cross-process stop/open receipts are wired in source, but the AlarmKit API must still be type-checked on Xcode 26 and exercised on a physical iOS 26 device.
2. **Live Activity scheduling** — the extension exists, but future scheduled starts and delivery de-duplication with AlarmKit/notifications still need coordinator integration.
3. **Routine edit/details** — enable/disable and delete work from the routine list; editing an existing routine and richer detail/history views remain.
4. **Wire remaining global copy preferences** — personality/intensity affect selection and notification sound is wired; language, emoji level, and message length still need content-pipeline support rather than UI-only persistence.
5. **Versioned remote content refresh** — bundled local content is healthy; staged download, validation, atomic activation, rollback, and refresh policy remain to be built.
6. **Occurrence lifecycle cleanup/expiry** — add an explicit product expiry rule, old-history pruning/retention policy, delivery-health diagnostics, and capacity-stress handling.
7. **Real-device verification** — Xcode 26 compile/test, AlarmKit authorization/firing/action receipts, notification delivery while terminated, timezone/DST cases, Lock Screen/Dynamic Island behavior, accessibility, and notification-capacity stress tests are still mandatory before release.

## Validation performed in this workspace

- `python3 Scripts/validate_content.py` passes with 246 content items.
- Every Swift source and test file passes `swiftc -frontend -parse` under Swift 6.2.1.
- Full iOS type-check/build cannot be executed in this Linux workspace because SwiftUI, SwiftData, UserNotifications, ActivityKit, WidgetKit, and AlarmKit require Apple SDKs/Xcode.
