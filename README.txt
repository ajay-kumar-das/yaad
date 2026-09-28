Jomado rich-notification/onboarding/Live Activity integration
Base main: 0840832a4025c290ac367b75bc9ecce4b59c9de1

From the repository root:

powershell -ExecutionPolicy Bypass -File "<extracted-folder>\apply-jomado-rich-notification-onboarding-live.ps1"

Then review:
git diff --check
git diff --stat
git status --short

Commit:
git add .
git commit -m "Add task-aware rich notifications and fix onboarding layout"
git push

What changes:
- resets onboarding scroll position on every step
- uses 2-column gender layout and non-hyphenating focus cards
- sends routineType + mascotID in every local notification
- attaches the correct routine-compatible mascot PNG
- adds a Notification Content Extension for task-aware expanded notifications
- guarantees a neutral RGB Jomado app icon for the compact notification source icon
- starts near-due Live Activities immediately (<=5 min) and keeps scheduled future starts
- keeps notification mascot and Live Activity mascot consistent
