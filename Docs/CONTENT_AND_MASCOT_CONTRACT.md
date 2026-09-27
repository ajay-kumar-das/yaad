# Jomado Content and Mascot Production Contract

## 1 Purpose and ownership

This document is the production handoff between product, content design, illustration, motion, localization, and iOS engineering. It defines what a designer must deliver and what the app promises to render.

The contract is versioned as `schemaVersion: 1`. A change that removes a field, changes its meaning, changes an enum, or changes a size budget requires a new schema version and an app migration. New optional fields may be added without a major migration.

Product owns behavior and safety. Content design owns copy quality. Illustration owns visual consistency. Motion owns cue timing. Engineering owns validation, selection, rendering, fallback behavior, and accessibility.

## 2 Non-negotiable product rules

Every deliverable must preserve these rules:

1. A reminder is complete only after an explicit completion action.
2. Dismiss, close, alarm stop, open, and snooze remain unresolved.
3. Momo is a general wellness companion, not only a water character.
4. Copy may be cute, firm, cheeky, or dramatic, but never insulting, shaming, coercive, sexual, or medically alarming.
5. Standard notifications are system-owned and static. Do not design a custom animated notification banner.
6. Live Activity motion is a short state-change transition, no longer than 1.5 seconds in Jomado, and then becomes static.
7. Rich looping motion is reserved for the foreground in-app reminder.
8. Every essential state has a bundled offline fallback.
9. Urgency must be conveyed by text and iconography as well as color.
10. Reduce Motion keeps expression changes but removes bounce, wobble, travel, and confetti.

## 3 Surface contract

| Surface | Purpose | Copy budget | Character treatment | Motion |
|---|---|---|---|---|
| Standard notification | Scheduled fallback and actions | Title 32, body 90 grapheme clusters | App icon only in MVP | None; system presentation only |
| Lock Screen Live Activity | Persistent glanceable status | Headline 26, body 72 | Static pose, up to 88 pt rendered | One state transition, up to 1.5 s |
| Dynamic Island expanded | Short rich status | Headline 22, body 48 | Static pose, 40–48 pt | One state transition, up to 1.2 s |
| Dynamic Island compact | Identity plus time/status | Status 10 | Face or routine glyph, 24 pt | Crossfade/scale only, up to 0.6 s |
| Dynamic Island minimal | Identity/urgency only | No sentence | Face or routine glyph, 20 pt | Crossfade only, up to 0.4 s |
| In-app reminder | Full emotional interaction | Eyebrow 24, headline 36, body 160, tip 120 | Full-body Momo, 200–280 pt | Rich loop plus one-shot reactions |
| Completion | Reward after explicit completion | Headline 32, body 120 | Proud or celebrating Momo | One-shot bounce/confetti; subdued for frequent routines |

Character counts are limits, not targets. Count user-perceived grapheme clusters. The build validator is authoritative; every line must also pass a real Dynamic Type layout check.

## 4 Momo character bible

### 4.1 Identity

Momo is a rounded blue droplet with a soft point at the top, short rounded arms and feet, navy facial features, white highlights, and warm pink cheeks. Momo should feel optimistic, slightly mischievous, and safe.

Momo remains the same character across routines. Routine context changes props and motion, not anatomy, face placement, or core colors.

### 4.2 Shape and proportion

Use a square master artboard. The standing character occupies no more than 76 percent of the artboard width and 82 percent of its height. Keep a minimum 10 percent transparent safe area on every edge so bounce, wobble, and shadows do not clip.

Relative proportions:

- body width: 100 units;
- body height excluding the top point: 105 units;
- top point: 24–30 units above the rounded body;
- eye line: 48–54 percent down the full character bounds;
- mouth center: 61–66 percent down the full character bounds;
- arm length: 26–32 percent of body width;
- foot length: 18–23 percent of body width.

Do not make Momo thinner, taller, more human, or photorealistic for a routine pack.

### 4.3 Core palette

| Role | Value |
|---|---|
| Outline and face | `#071D4A` |
| Body highlight | `#42DBFF` |
| Body midtone | `#13BDEB` |
| Body shadow | `#1597F4` |
| Deep body shadow | `#0875D8` |
| Cheeks | `#FF91AD` |
| Mouth interior | `#111827` |
| Tongue | `#FF5A76` |
| Specular highlight | `#FFFFFF` at 80–100 percent opacity |

Gradients must preserve sufficient contrast against white, sky blue, navy, yellow, orange, red, and green urgency backgrounds.

### 4.4 Canonical expressions

Every base pack must provide these expressions:

| ID | Face | Typical use |
|---|---|---|
| `idle` | open or softly closed eyes, neutral smile | Resting state |
| `hello` | happy crescent eyes, open smile | Greeting |
| `waiting` | attentive eyes, small smile | Due now |
| `hopeful` | raised brows, warm smile | Normal reminder |
| `pouty` | soft brows, tiny pout | Light overdue |
| `concerned` | wide eyes, curved brows | Medium overdue |
| `urgent` | wide eyes, firm open mouth | Red zone |
| `sleepy` | lowered lids, small yawn | Sleep routine |
| `focused` | direct eyes, neutral mouth | Strict/focused copy |
| `proud` | closed happy eyes, confident smile | Completion |
| `celebrating` | joyful eyes and open smile | Milestone |
| `cheeky` | wink or side-eye, smirk | Cheeky copy |
| `dramatic` | theatrical wide eyes and pose | Dramatic red zone |

Expressions must remain understandable at 20 pt. Fine details that disappear at compact size do not count as the only difference between expressions.

### 4.5 Routine props

Props are optional overlays and may not cover the face.

| Routine | Approved props |
|---|---|
| Hydration | water bottle, glass, splash |
| Exercise | headband, tiny dumbbell, sweat accent |
| Stretching | stretch band, motion accent |
| Eye care | rounded glasses, look-away sparkle |
| Posture | small chair/back alignment accent |
| Breathing | soft air rings, closed-eye glow |
| Meditation | small cushion, calm glow |
| Yoga | mat, calm pose accent |
| Sleep | night cap, moon/star accent |
| Custom | no prop unless mapped to an approved generic prop |

Never add medical equipment, body-measurement imagery, weapons, alcohol, sexualized clothing, or frightening emergency symbols.

## 5 Graphic deliverables and exact sizes

### 5.1 Source masters

- Illustration master: Figma vector component on a `1024 x 1024 px` square artboard.
- Motion master: Rive artboard `512 x 512` logical units, one artboard named `Momo`, one state machine named `MomoStateMachine`.
- Color space: sRGB for raster exports. Keep the vector source editable.
- Raster format: lossless PNG with transparency. Do not use JPEG or WebP in the app bundle.
- Static vector format: single-scale PDF asset with preserved vector data.
- App icon: `1024 x 1024 px` PNG, sRGB, opaque, no rounded corners, no transparency.

### 5.2 Export matrix

| Asset role | Logical slot | Required raster exports | Preferred source |
|---|---:|---:|---|
| In-app hero character | `240 x 240 pt` | `480 x 480` and `720 x 720 px` | Rive or vector PDF |
| In-app compact character | `96 x 96 pt` | `192 x 192` and `288 x 288 px` | Vector PDF |
| Lock Screen pose | max `88 x 88 pt` | `176 x 176` and `264 x 264 px` | SwiftUI vector or tightly bounded PNG |
| Dynamic Island expanded pose | max `48 x 48 pt` | `96 x 96` and `144 x 144 px` | SwiftUI vector or tightly bounded PNG |
| Dynamic Island compact glyph | `24 x 24 pt` | `48 x 48` and `72 x 72 px` | Monochrome-capable vector PDF |
| Dynamic Island minimal glyph | `20 x 20 pt` | `40 x 40` and `60 x 60 px` | Monochrome-capable vector PDF |
| Routine glyph | `32 x 32 pt` | `64 x 64` and `96 x 96 px` | Vector PDF |
| Completion confetti tile | `160 x 160 pt` | `320 x 320` and `480 x 480 px` | Vector/Rive particles |

The Live Activity extension must not ship an image whose decoded dimensions exceed the slot it is designed to render at the target scale. Oversized Live Activity images can prevent ActivityKit from starting. Keep transparent bounds tight while retaining the 10 percent motion safe area.

### 5.3 Naming

Use lowercase ASCII kebab case:

```text
momo-hopeful-wave-core.pdf
momo-pouty-waiting-core@2x.png
momo-pouty-waiting-core@3x.png
momo-sleepy-night-cap-sleep.pdf
routine-hydration-glyph.pdf
```

The canonical asset ID omits scale and extension:

```text
momo.pouty.waiting.core
```

Do not encode locale, urgency color, or personality into the illustration unless the visual truly differs. Those values normally belong in the content item and rendering code.

## 6 Motion cue contract

The content pack selects a semantic cue. Engineering owns the final curve and Reduce Motion fallback.

| Cue | Foreground behavior | Live Activity behavior | Reduce Motion |
|---|---|---|---|
| `none` | Static | Static | Static |
| `idleFloat` | 3.2 s vertical loop, 4 pt amplitude | Static | 0.2 s fade in |
| `gentleBounce` | 1.8 s soft loop, 5 percent scale | 0.45 s one-shot scale | 0.2 s fade |
| `wave` | 1.4 s arm/pose cycle, pause 2.5 s | 0.5 s one-shot pose crossfade | Pose crossfade |
| `blink` | Two blinks in 4–7 s variable loop | Static expression | Expression swap |
| `pout` | 2.4 s small settle/float | 0.4 s expression crossfade | Expression swap |
| `concernedPulse` | 1.6 s pulse, 3 percent scale | 0.6 s one-shot pulse | Color and expression swap |
| `dramaticWobble` | 0.7 s wobble repeated three times, then 2 s pause | 0.8 s one-shot wobble | Expression swap |
| `breathe` | 4.0 s scale/opacity breathing loop | Static | 0.4 s opacity change |
| `celebrate` | Three 0.35 s bounces plus optional confetti | 0.9 s one-shot scale/sparkle | 0.3 s color/expression crossfade |

In-app loops pause when the screen is not visible. Live Activity cues must settle to a static frame. Never rely on motion to communicate status.

## 7 Urgency mapping

| Stage | Default time | Color | Expression | Preferred cues |
|---|---:|---|---|---|
| `normal` | due to 2:59 late | routine accent/cyan | `hopeful` or `waiting` | `wave`, `gentleBounce` |
| `lightOverdue` | 3:00–9:59 late | yellow `#F7C948` | `pouty` or `waiting` | `pout` |
| `mediumOverdue` | 10:00–19:59 late | orange `#FF8A2B` | `concerned` | `concernedPulse` |
| `redZone` | 20:00+ late | red `#FF4D5A` | `urgent` or `dramatic` | `dramaticWobble` |
| `completed` | explicit completion | green `#34C759` | `proud` or `celebrating` | `celebrate` |

The user-selected personality may tune the expression and amplitude, but it may not hide or weaken the status label.

## 8 Content pack format

The canonical machine-readable schema is `Resources/Content/Schemas/jomado-content-pack.schema.json`.

Each file contains one pack header and an `items` array. One content item represents one semantic message across all supported surfaces so exposure history can suppress the same joke even when wording is shortened.

Required item dimensions:

- routine type;
- urgency stage;
- personality;
- intensity;
- locale;
- surface-specific copy;
- mascot direction;
- cooldown and semantic family;
- safety review metadata;
- enablement and editorial priority.

Example:

```json
{
  "id": "hydration.playful.normal.tiny-mission.001",
  "routineType": "hydration",
  "stage": "normal",
  "personality": "playful",
  "intensity": "balanced",
  "locale": "en",
  "variants": {
    "notification": {
      "title": "Water time 💧",
      "body": "Tiny sip. Big hydration energy."
    },
    "liveActivity": {
      "headline": "WATER TIME",
      "body": "A few sips moves this forward.",
      "compactStatus": "Due now"
    },
    "inApp": {
      "eyebrow": "YOUR WATER BREAK",
      "headline": "A tiny mission from Momo",
      "body": "A few comfortable sips is enough to move this reminder forward.",
      "tip": "Keep your bottle somewhere easy to reach.",
      "completionLabel": "I drank water"
    }
  },
  "mascot": {
    "character": "momo",
    "expression": "hopeful",
    "pose": "wave",
    "prop": "waterBottle",
    "animationCue": "gentleBounce",
    "accessibilityLabel": "Momo waves with a hopeful smile"
  },
  "tags": ["short", "daytime"],
  "dayparts": ["morning", "afternoon"],
  "cooldownMinutes": 10080,
  "semanticFamily": "tiny-mission",
  "priority": 10,
  "enabled": true,
  "safety": {
    "medicalClaimReviewed": true,
    "ageSafe": true,
    "reviewer": "content-team",
    "reviewedAt": "2026-09-27"
  }
}
```

## 9 Copy rules

### 9.1 Voice

- Use plain, conversational language.
- Put the requested action in the first sentence or headline.
- Keep jokes understandable without the image.
- Use `Momo` sparingly; not every message needs the name.
- Keep emoji meaningful and within the chosen emoji level.
- Do not use ALL CAPS except an occasional Dramatic headline.
- Do not imply that silence, dismissal, opening, or snooze completed the habit.
- Do not promise health outcomes or diagnose a condition.

### 9.2 Personality boundaries

| Personality | Do | Do not |
|---|---|---|
| `gentle` | warm, calm, optional language | urgency theatrics |
| `cute` | wholesome affection, soft emoji | infantilize the user |
| `playful` | light jokes, cheerful energy | obscure the requested action |
| `cheeky` | tease the situation or object | insult the user |
| `charming` | tasteful affection and praise | sexual or relationship-coded copy |
| `dramatic` | theatrical, obviously playful escalation | imply a real emergency |
| `strict` | concise, direct, respectful commands | shame, threats, punishment |
| `focused` | factual and minimal | decorative filler |

`Flirty` is not an allowed schema value in version 1.

### 9.3 Localization

Every pack has one locale. Do not mix languages in a pack. Localization rewrites the joke and emotional intent; it is not required to preserve literal wording. Fallback is regional locale, base language, then bundled English. Runtime machine translation is prohibited.

## 10 Editorial and technical acceptance gates

A pack can ship only when it passes:

- JSON schema validation;
- unique ID validation across all active packs;
- required stage coverage for every shipped routine/personality combination;
- surface length limits;
- duplicate title/body detection;
- exact ID cooldown review;
- semantic-family duplication review;
- banned phrase and medical-claim scan;
- age-safety review;
- personality consistency review;
- locale review by a fluent human;
- Dynamic Type screenshots at default and accessibility sizes;
- VoiceOver label review;
- light, dark, high-contrast, and Reduce Motion review;
- Lock Screen and Dynamic Island checks on a real device.

If a downloaded pack fails, the app keeps the previous valid pack. The bundled pack may never be deleted.

## 11 Designer delivery checklist

Deliver one folder per reviewed batch:

```text
delivery-name/
  content/
    locale-pack.json
  mascot/
    momo-core.manifest.json
    source/
    pdf/
    png/@2x/
    png/@3x/
    rive/
  review/
    copy-review.csv
    safety-signoff.md
    contact-sheet.png
```

The batch is ready for engineering only when every referenced asset ID exists, every content item validates, the reviewer and review date are populated, and the contact sheet shows all expressions at 20 pt, 48 pt, 88 pt, and 240 pt.

