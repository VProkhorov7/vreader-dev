#!/usr/bin/env python3
"""
check_refs.py — VReader validation gate.
Run before every merge. Exit 0 = pass, Exit 1 = fail.

Usage:
    python3 check_refs.py [scan_dir]

    scan_dir defaults to App/Vreader/Vreader relative to this script's
    parent directory (i.e. the project root).
"""

import sys
import re
from pathlib import Path

ROOT = Path(__file__).parent.parent

def resolve_scan_dir(argv: list[str]) -> Path:
    if len(argv) > 1:
        candidate = Path(argv[1])
        if candidate.is_absolute():
            return candidate
        return ROOT / candidate
    return ROOT / "App" / "Vreader" / "Vreader"

SWIFT_DIR = resolve_scan_dir(sys.argv)

EN_STRINGS = SWIFT_DIR / "en.lproj" / "Localizable.strings"
RU_STRINGS = SWIFT_DIR / "ru.lproj" / "Localizable.strings"
L10N_SWIFT = SWIFT_DIR / "L10n.swift"

errors: list[str] = []
warnings: list[str] = []

def error(msg: str) -> None:
    errors.append(f"  ERROR: {msg}")

def warn(msg: str) -> None:
    warnings.append(f"  WARN:  {msg}")

def swift_files() -> list[Path]:
    return list(SWIFT_DIR.glob("**/*.swift"))

def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore")


# ── L10n namespace → dot-prefix mapping ────────────────────────────────────
L10N_NAMESPACE_MAP: dict[str, str] = {
    "Library":    "library",
    "Reader":     "reader",
    "Settings":   "settings",
    "Cloud":      "cloud",
    "AI":         "ai",
    "Premium":    "premium",
    "Common":     "common",
    "Errors":     "errors",
    "Onboarding": "onboarding",
}

_L10N_REF_RE = re.compile(
    r'\bL10n\.([A-Z][A-Za-z]*)\.([a-z][A-Za-z0-9]*)'
)


def camel_to_dot(namespace: str, key: str) -> str | None:
    prefix = L10N_NAMESPACE_MAP.get(namespace)
    if prefix is None:
        return None
    return f"{prefix}.{key}"


def load_strings_keys(path: Path) -> set[str]:
    if not path.exists():
        return set()
    text = read_text(path)
    return set(re.findall(r'^"([^"]+)"\s*=', text, re.MULTILINE))


def load_l10n_defined_keys(path: Path) -> set[str]:
    if not path.exists():
        return set()
    text = read_text(path)
    return set(re.findall(r'NSLocalizedString\("([^"]+)"', text))


# ── Check 1: Unresolved L10n.* key references ──────────────────────────────
def check_l10n_key_references(en_keys: set[str], ru_keys: set[str]) -> None:
    unresolved: dict[str, list[str]] = {}

    for f in swift_files():
        if f.name == "L10n.swift":
            continue
        text = read_text(f)
        for m in _L10N_REF_RE.finditer(text):
            namespace = m.group(1)
            key_name = m.group(2)
            dot_key = camel_to_dot(namespace, key_name)
            if dot_key is None:
                warn(
                    f"Unknown L10n namespace '{namespace}' referenced in "
                    f"{f.name} — add to L10N_NAMESPACE_MAP if intentional"
                )
                continue
            missing_in: list[str] = []
            if dot_key not in en_keys:
                missing_in.append("en.lproj/Localizable.strings")
            if dot_key not in ru_keys:
                missing_in.append("ru.lproj/Localizable.strings")
            if missing_in:
                tag = f"{f.name}: L10n.{namespace}.{key_name} → \"{dot_key}\""
                unresolved.setdefault(tag, []).extend(missing_in)

    for tag, locations in sorted(unresolved.items()):
        unique_locations = sorted(set(locations))
        error(f"Unresolved L10n key — {tag} missing in: {', '.join(unique_locations)}")


# ── Check 2: L10n.swift keys present in both .strings files ────────────────
def check_l10n_swift_keys_in_strings(en_keys: set[str], ru_keys: set[str]) -> None:
    if not L10N_SWIFT.exists():
        warn("L10n.swift not found — skipping L10n key completeness check")
        return

    declared = load_l10n_defined_keys(L10N_SWIFT)

    for key in sorted(declared):
        if key not in en_keys:
            error(f"L10n.swift declares \"{key}\" but it is missing from en.lproj/Localizable.strings")
        if key not in ru_keys:
            error(f"L10n.swift declares \"{key}\" but it is missing from ru.lproj/Localizable.strings")


# ── Check 3: EN and RU key parity ──────────────────────────────────────────
def check_strings_parity(en_keys: set[str], ru_keys: set[str]) -> None:
    for key in sorted(en_keys - ru_keys):
        error(f"Key \"{key}\" present in en.lproj but missing from ru.lproj/Localizable.strings")
    for key in sorted(ru_keys - en_keys):
        error(f"Key \"{key}\" present in ru.lproj but missing from en.lproj/Localizable.strings")


# ── Check 4: Hardcoded UI strings (non-blocking warnings) ──────────────────
_SKIP_LINE_PATTERNS: list[re.Pattern[str]] = [
    re.compile(r'^\s*//'),
    re.compile(r'NSLocalizedString'),
    re.compile(r'\bL10n\.'),
    re.compile(r'fatalError\('),
    re.compile(r'precondition\('),
    re.compile(r'assert\('),
    re.compile(r'\bprint\('),
    re.compile(r'\bLogger\b'),
    re.compile(r'OSLog'),
    re.compile(r'\.accessibilityLabel\('),
    re.compile(r'\.accessibilityHint\('),
    re.compile(r'\.accessibilityValue\('),
    re.compile(r'case\s+\w+\s*=\s*"'),
    re.compile(r'#\w+\s*\('),
    re.compile(r'identifier\s*=\s*"'),
    re.compile(r'bundleIdentifier'),
    re.compile(r'providerID\s*=\s*"'),
    re.compile(r'kSecAttr'),
    re.compile(r'CKRecord\.RecordType'),
    re.compile(r'\.userInfo\['),
    re.compile(r'Notification\.Name\('),
    re.compile(r'UTType\('),
    re.compile(r'\.scheme\s*==\s*"'),
    re.compile(r'URL\(string:\s*"'),
    re.compile(r'URLComponents'),
    re.compile(r'com\.apple\.'),
    re.compile(r'com\.vreader\.'),
    re.compile(r'vreader://'),
    re.compile(r'#if\s+DEBUG'),
    re.compile(r'#Preview'),
]

_SKIP_FILE_PATTERNS: list[str] = [
    "SampleData",
    "Preview",
    "L10n.swift",
    "check_refs.py",
]

_HARDCODED_UI_RE = re.compile(
    r'(?:'
    r'(?<!\w)Text\s*\(\s*"([^"]{2,})"'
    r'|\.navigationTitle\s*\(\s*"([^"]{2,})"'
    r'|\.placeholder\s*\(\s*"([^"]{2,})"'
    r'|Label\s*\(\s*"([^"]{2,})"'
    r'|Button\s*\(\s*"([^"]{2,})"'
    r'|\.help\s*\(\s*"([^"]{2,})"'
    r'|EmptyView\s*\(\s*"([^"]{2,})"'
    r')'
)

def check_hardcoded_strings() -> None:
    for f in swift_files():
        if any(skip in f.name for skip in _SKIP_FILE_PATTERNS):
            continue
        text = read_text(f)
        lines = text.splitlines()
        for line_no, line in enumerate(lines, start=1):
            if any(p.search(line) for p in _SKIP_LINE_PATTERNS):
                continue
            m = _HARDCODED_UI_RE.search(line)
            if m:
                literal = next(g for g in m.groups() if g is not None)
                warn(
                    f"Possible hardcoded UI string in {f.name}:{line_no} "
                    f"— \"{literal[:50]}\" — use L10n.*"
                )


# ── Check 5: Duplicate type definitions ────────────────────────────────────
_TYPE_DEF_RE = re.compile(
    r'^\s*(?:(?:public|internal|private|fileprivate|open)\s+)*'
    r'(?:final\s+)?(?:class|struct|enum|protocol|actor)\s+(\w+)',
    re.MULTILINE,
)
_ALLOWED_DUPLICATES: frozenset[str] = frozenset({
    "Preview", "Body", "ContentView", "Coordinator", "ViewModel", "Provider",
})

def check_duplicate_types() -> None:
    seen: dict[str, str] = {}
    for f in swift_files():
        text = read_text(f)
        for m in _TYPE_DEF_RE.finditer(text):
            name = m.group(1)
            if name in _ALLOWED_DUPLICATES:
                continue
            if name in seen:
                error(f"Duplicate type '{name}' in {f.name} and {seen[name]}")
            else:
                seen[name] = f.name


# ── Check 6: Force-unwrap UTType ────────────────────────────────────────────
def check_uttype_force_unwrap() -> None:
    pattern = re.compile(r'UTType\([^)]+\)!')
    for f in swift_files():
        if pattern.search(read_text(f)):
            error(f"Force-unwrap UTType in {f.name} — use optional binding")


# ── Check 7: coverData in SwiftData models ──────────────────────────────────
def check_cover_data() -> None:
    pattern = re.compile(r'var\s+coverData\s*:\s*Data')
    for f in swift_files():
        if pattern.search(read_text(f)):
            error(f"coverData: Data found in {f.name} — use coverPath: String only")


# ── Check 8: WKWebView for OAuth ────────────────────────────────────────────
def check_wkwebview_oauth() -> None:
    oauth_keywords = {"OAuth", "oauth", "authorization_code", "redirect_uri"}
    wk_pattern = re.compile(r'WKWebView')
    for f in swift_files():
        text = read_text(f)
        if any(kw in text for kw in oauth_keywords) and wk_pattern.search(text):
            error(f"WKWebView used for OAuth in {f.name} — use ASWebAuthenticationSession")


# ── Check 9: isPremium in CloudKit sync ─────────────────────────────────────
def check_ispremium_cloudkit() -> None:
    pattern = re.compile(r'isPremium')
    for f in swift_files():
        text = read_text(f)
        if "CloudKit" in text and "CKRecord" in text and pattern.search(text):
            error(
                f"isPremium may be synced via CloudKit in {f.name} "
                f"— forbidden by invariant"
            )


# ── Check 10: Unbalanced braces ─────────────────────────────────────────────
def check_swift_syntax() -> None:
    for f in swift_files():
        text = read_text(f)
        opens = text.count('{')
        closes = text.count('}')
        if opens != closes:
            error(f"Unbalanced braces in {f.name} ({opens} open, {closes} close)")


# ── Check 11: iOS deprecated API ────────────────────────────────────────────
_DEPRECATED_APIS: list[tuple[str, str]] = [
    ("UIApplication.shared.keyWindow", "use UIWindowScene"),
    ("UIWebView", "use WKWebView"),
    ("presentationMode", "use dismiss() environment"),
]

def check_ios_compatibility() -> None:
    for f in swift_files():
        text = read_text(f)
        for api, hint in _DEPRECATED_APIS:
            if api in text:
                warn(f"Deprecated API '{api}' in {f.name} — {hint}")


# ── Check 12: Entitlements ───────────────────────────────────────────────────
def check_entitlements() -> None:
    ent = SWIFT_DIR / "VReader.entitlements"
    if not ent.exists():
        error("VReader.entitlements not found")
        return
    text = read_text(ent)
    required = [
        "ubiquity-kvs-identifier",
        "icloud-services",
        "application-groups",
    ]
    for key in required:
        if key not in text:
            error(f"Missing entitlement: {key}")


# ── Check 13: dot-notation keys in .strings files ───────────────────────────
def check_dot_notation_keys(en_keys: set[str], ru_keys: set[str]) -> None:
    flat_re = re.compile(r'^[a-z]+_[a-z_]+$')
    for key in sorted(en_keys | ru_keys):
        if flat_re.match(key):
            error(
                f"Flat snake_case key \"{key}\" found in .strings files "
                f"— must use dot-notation (e.g. library.title)"
            )


# ── Main ─────────────────────────────────────────────────────────────────────
def main() -> int:
    print("🔍 VReader check_refs.py")
    all_swift = swift_files()
    print(f"   Scanning {len(all_swift)} Swift files in {SWIFT_DIR}")

    if not EN_STRINGS.exists():
        error(f"en.lproj/Localizable.strings not found at {EN_STRINGS}")
    if not RU_STRINGS.exists():
        error(f"ru.lproj/Localizable.strings not found at {RU_STRINGS}")

    en_keys = load_strings_keys(EN_STRINGS)
    ru_keys = load_strings_keys(RU_STRINGS)

    print(f"   EN keys: {len(en_keys)}  |  RU keys: {len(ru_keys)}")
    print()

    check_strings_parity(en_keys, ru_keys)
    check_dot_notation_keys(en_keys, ru_keys)
    check_l10n_swift_keys_in_strings(en_keys, ru_keys)
    check_l10n_key_references(en_keys, ru_keys)
    check_hardcoded_strings()
    check_duplicate_types()
    check_uttype_force_unwrap()
    check_cover_data()
    check_ios_compatibility()
    check_wkwebview_oauth()
    check_ispremium_cloudkit()
    check_swift_syntax()
    check_entitlements()

    if errors:
        print("❌ ERRORS (must fix before merge):")
        for e in errors:
            print(e)
        print()

    if warnings:
        print("⚠️  WARNINGS (review recommended):")
        for w in warnings:
            print(w)
        print()

    if not errors and not warnings:
        print("✅ All checks passed")
    elif not errors:
        print("✅ No errors — warnings are informational only")
    else:
        print(f"❌ {len(errors)} error(s) found — merge blocked")

    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())