# Jomado UI reference implementation map

The files in `ui/` are the visual source of truth for layout hierarchy, tone, spacing, color, card treatment, mascot prominence, and navigation. They are presentation mockups, not runtime assets: the phone frame, status bar, and embedded text must not be shipped as screenshots.

| Reference | Runtime screen | SwiftUI implementation |
|---|---|---|
| `01_welcome_get_started.png` | Welcome / Get Started | `OnboardingFlowView`, step 1 |
| `02_onboarding_about_you.png` | Profile questions | `OnboardingFlowView`, step 2 |
| `03_onboarding_focus_areas.png` | Routine focus selection | `OnboardingFlowView`, step 3 |
| `04_onboarding_permissions.png` | Permission readiness | `OnboardingFlowView`, step 4 |
| `05_home_dashboard.png` | Today dashboard | `TodayView` |
| `06_routines_list.png` | Routine list and filters | `RoutinesView` |
| `07_add_routine_step_1_choose_habit.png` | Add Routine selection | `AddRoutineFlowView`, page 1 |
| `08_add_routine_step_3_schedule_review.png` | Schedule and review | `AddRoutineFlowView`, page 2 |
| `09_insights_progress.png` | Progress overview | `InsightsView` |
| `10_settings.png` | Settings menu | `SettingsView` |

## Shared visual rules

- Use the cyan/blue sky palette, rounded navy typography, white elevated cards, and 18–26 pt continuous corners.
- Give Momo a prominent animated hero position while keeping copy readable and touch targets at least 44 pt.
- Recreate the landscape atmosphere with native gradients and shapes until production illustration assets arrive.
- Use semantic system controls for pickers, dates, toggles, permission prompts, and tab navigation.
- Support Dynamic Type, VoiceOver, and Reduce Motion even when the reference mockup shows a fixed layout.
- Use the supplied mockups for visual review at iPhone portrait sizes; do not duplicate their device chrome inside the app.

## Release acceptance

Each screen must be checked on a small iPhone and a Dynamic Island iPhone at default and accessibility text sizes. Production Momo and landscape artwork can replace the SwiftUI fallback without changing the layout or accessibility contract.
