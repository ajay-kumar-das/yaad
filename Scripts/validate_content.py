"""Validate bundled Jomado content without third-party dependencies."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CONTENT_ROOT = ROOT / "Resources" / "Content"

ROUTINES = {
    "hydration",
    "exercise",
    "stretching",
    "eyeCare",
    "posture",
    "breathing",
    "meditation",
    "yoga",
    "sleep",
    "custom",
    "generic",
}
STAGES = {"normal", "lightOverdue", "mediumOverdue", "redZone", "completed"}
PERSONALITIES = {
    "gentle",
    "cute",
    "playful",
    "cheeky",
    "charming",
    "dramatic",
    "strict",
    "focused",
}
INTENSITIES = {"soft", "balanced", "firm"}
EXPRESSIONS = {
    "idle",
    "hello",
    "waiting",
    "hopeful",
    "pouty",
    "concerned",
    "urgent",
    "sleepy",
    "focused",
    "proud",
    "celebrating",
    "cheeky",
    "dramatic",
}
ANIMATION_CUES = {
    "none",
    "idleFloat",
    "gentleBounce",
    "wave",
    "blink",
    "pout",
    "concernedPulse",
    "dramaticWobble",
    "breathe",
    "celebrate",
}
DAYPARTS = {"any", "morning", "afternoon", "evening", "night"}

TEXT_LIMITS = {
    ("variants", "notification", "title"): 32,
    ("variants", "notification", "body"): 90,
    ("variants", "liveActivity", "headline"): 26,
    ("variants", "liveActivity", "body"): 72,
    ("variants", "liveActivity", "compactStatus"): 10,
    ("variants", "inApp", "eyebrow"): 24,
    ("variants", "inApp", "headline"): 36,
    ("variants", "inApp", "body"): 160,
    ("variants", "inApp", "completionLabel"): 32,
    ("mascot", "accessibilityLabel"): 80,
}

BANNED_PATTERNS = {
    "medical emergency": re.compile(r"\b(medical emergency|heart attack|you will die)\b", re.I),
    "shaming": re.compile(r"\b(lazy|pathetic|failure|disgusting)\b", re.I),
    "coercion": re.compile(r"\b(prove you care|or else|you must love)\b", re.I),
}


def nested_value(item: dict, path: tuple[str, ...]):
    value = item
    for key in path:
        if not isinstance(value, dict) or key not in value:
            raise KeyError(".".join(path))
        value = value[key]
    return value


def validate_pack(path: Path) -> tuple[list[str], int]:
    errors: list[str] = []
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"{path}: invalid JSON: {error}"], 0

    if data.get("schemaVersion") != 1:
        errors.append(f"{path}: schemaVersion must be 1")

    pack = data.get("pack")
    items = data.get("items")
    if not isinstance(pack, dict):
        return errors + [f"{path}: pack must be an object"], 0
    if not isinstance(items, list) or not items:
        return errors + [f"{path}: items must be a non-empty array"], 0

    locale = pack.get("locale")
    seen_ids: set[str] = set()
    coverage: dict[tuple[str, str, str], set[str]] = {}

    for index, item in enumerate(items):
        prefix = f"{path}: item[{index}]"
        if not isinstance(item, dict):
            errors.append(f"{prefix} must be an object")
            continue

        item_id = item.get("id")
        if not isinstance(item_id, str) or not re.fullmatch(r"[a-z0-9]+(?:[.-][a-z0-9]+)*", item_id):
            errors.append(f"{prefix}: invalid id")
            item_id = f"item[{index}]"
        elif item_id in seen_ids:
            errors.append(f"{prefix}: duplicate id {item_id}")
        seen_ids.add(item_id)

        routine = item.get("routineType")
        stage = item.get("stage")
        personality = item.get("personality")
        intensity = item.get("intensity")
        if routine not in ROUTINES:
            errors.append(f"{item_id}: invalid routineType {routine!r}")
        if stage not in STAGES:
            errors.append(f"{item_id}: invalid stage {stage!r}")
        if personality not in PERSONALITIES:
            errors.append(f"{item_id}: invalid personality {personality!r}")
        if intensity not in INTENSITIES:
            errors.append(f"{item_id}: invalid intensity {intensity!r}")
        if item.get("locale") != locale:
            errors.append(f"{item_id}: locale must match pack locale {locale!r}")

        if routine in ROUTINES and personality in PERSONALITIES and intensity in INTENSITIES and stage in STAGES:
            coverage.setdefault((routine, personality, intensity), set()).add(stage)

        for field_path, limit in TEXT_LIMITS.items():
            try:
                text = nested_value(item, field_path)
            except KeyError:
                errors.append(f"{item_id}: missing {'.'.join(field_path)}")
                continue
            if not isinstance(text, str) or not text.strip():
                errors.append(f"{item_id}: {'.'.join(field_path)} must be non-empty text")
                continue
            if len(text) > limit:
                errors.append(
                    f"{item_id}: {'.'.join(field_path)} has {len(text)} characters; limit is {limit}"
                )
            for label, pattern in BANNED_PATTERNS.items():
                if pattern.search(text):
                    errors.append(f"{item_id}: {'.'.join(field_path)} triggered {label} scan")

        tip = item.get("variants", {}).get("inApp", {}).get("tip")
        if tip is not None and (not isinstance(tip, str) or len(tip) > 120):
            errors.append(f"{item_id}: variants.inApp.tip must be at most 120 characters")

        mascot = item.get("mascot", {})
        if mascot.get("character") != "momo":
            errors.append(f"{item_id}: mascot.character must be momo")
        if mascot.get("expression") not in EXPRESSIONS:
            errors.append(f"{item_id}: invalid mascot expression")
        if mascot.get("animationCue") not in ANIMATION_CUES:
            errors.append(f"{item_id}: invalid animation cue")

        dayparts = item.get("dayparts")
        if not isinstance(dayparts, list) or not dayparts or any(daypart not in DAYPARTS for daypart in dayparts):
            errors.append(f"{item_id}: invalid dayparts")

        cooldown = item.get("cooldownMinutes")
        if not isinstance(cooldown, int) or not 0 <= cooldown <= 43_200:
            errors.append(f"{item_id}: cooldownMinutes must be 0...43200")

        safety = item.get("safety", {})
        if safety.get("medicalClaimReviewed") is not True or safety.get("ageSafe") is not True:
            errors.append(f"{item_id}: required safety review is missing")
        if not safety.get("reviewer") or not safety.get("reviewedAt"):
            errors.append(f"{item_id}: reviewer and reviewedAt are required")

    for key, stages in coverage.items():
        missing = STAGES - stages
        if missing:
            errors.append(
                f"{path}: {key[0]}/{key[1]}/{key[2]} is missing stages: {', '.join(sorted(missing))}"
            )

    return errors, len(items)


def main() -> int:
    pack_paths = sorted(
        path
        for path in CONTENT_ROOT.rglob("*.json")
        if "Schemas" not in path.parts
    )
    if not pack_paths:
        print("No content packs found.", file=sys.stderr)
        return 1

    all_errors: list[str] = []
    total_items = 0
    for path in pack_paths:
        errors, count = validate_pack(path)
        all_errors.extend(errors)
        total_items += count

    if all_errors:
        for error in all_errors:
            print(f"ERROR: {error}", file=sys.stderr)
        print(f"Content validation failed with {len(all_errors)} error(s).", file=sys.stderr)
        return 1

    print(f"Content validation passed: {len(pack_paths)} pack(s), {total_items} item(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

