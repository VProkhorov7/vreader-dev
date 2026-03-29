#!/usr/bin/env python3
"""
check_refs.py — VReader validation gate.
Run before every merge. Exit 0 = pass, Exit 1 = fail.
"""

import sys
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).parent
SWIFT_DIR = ROOT / "App" / "Vreader" / "Vreader"

errors = []
warnings = []

def error(msg): errors.append(f"  ERROR: {msg}")
def warn(msg): warnings.append(f"  WARN:  {msg}")

def swift_files():
    return list(SWIFT_DIR.glob("**/*.swift"))

# ── 1. Duplicate type definitions ──────────────────────────────────────────
def check_duplicate_types():
    type_pattern = re.compile(
        r'^\s*(?:public |internal |private |fileprivate |open )*'
        r'(?:final\s+)?(?:class|struct|enum|protocol|actor)\s+(\w+)',
        re.MULTILINE
    )
    seen = {}
    for f in swift_files():
        text = f.read_text(encoding="utf-8", errors="ignore")
        for m in type_pattern.finditer(text):
            name = m.group(1)
            if name in ("Preview", "Body", "ContentView", "Coordinator", "ViewModel", "Provider"):
                continue
            if name in seen:
                error(f"Duplicate type '{name}' in {f.name} and {seen[name]}")
            else:
                seen[name] = f.name

# ── 2. Force-unwrap UTType ──────────────────────────────────────────────────
def check_uttype_force_unwrap():
    pattern = re.compile(r'UTType\([^)]+\)!')
    for f in swift_files():
        text = f.read_text(encoding="utf-8", errors="ignore")
        if pattern.search(text):
            error(f"Force-unwrap UTType in {f.name} — use optional binding")

# ── 3. Hardcoded user-facing strings ───────────────────────────────────────
def check_hardcoded_strings():
    skip_patterns = [
        re.compile(r'//.*"'),           # comments
        re.compile(r'#\w+\s*\('),       # macros
        re.compile(r'fatalError\('),
        re.compile(r'precondition\('),
        re.compile(r'assert\('),
        re.compile(r'print\('),
        re.compile(r'Logger\('),
        re.compile(r'OSLog'),
        re.compile(r'\.accessibilityLabel\('),
        re.compile(r'case\s+\w+\s*=\s*"'),  # enum raw values
        re.compile(r'NSLocalizedString'),
        re.compile(r'L10n\.'),
    ]
    ui_pattern = re.compile(r'(?:Text|Label|Button|navigationTitle|placeholder)\s*\(\s*"([^"]{3,})"')
    for f in swift_files():
        if "SampleData" in f.name or "Preview" in f.name:
            continue
        text = f.read_text(encoding="utf-8", errors="ignore")
        for m in ui_pattern.finditer(text):
            line_start = text.rfind('\n', 0, m.start()) + 1
            line = text[line_start:text.find('\n', m.start())]
            if any(p.search(line) for p in skip_patterns):
                continue
            warn(f"Possible hardcoded string in {f.name}: \"{m.group(1)[:40]}\"")

# ── 4. coverData in SwiftData models ───────────────────────────────────────
def check_cover_data():
    pattern = re.compile(r'var\s+coverData\s*:\s*Data')
    for f in swift_files():
        text = f.read_text(encoding="utf-8", errors="ignore")
        if pattern.search(text):
            error(f"coverData: Data found in {f.name} — use coverPath: String only")

# ── 5. iOS 17+ API compatibility ───────────────────────────────────────────
def check_ios_compatibility():
    deprecated = [
        ("UIApplication.shared.keyWindow", "use UIWindowScene"),
        ("UIWebView", "use WKWebView"),
        ("presentationMode", "use dismiss() environment"),
    ]
    for f in swift_files():
        text = f.read_text(encoding="utf-8", errors="ignore")
        for api, hint in deprecated:
            if api in text:
                warn(f"Deprecated API '{api}' in {f.name} — {hint}")

# ── 6. WKWebView for OAuth ──────────────────────────────────────────────────
def check_wkwebview_oauth():
    pattern = re.compile(r'WKWebView')
    oauth_files = [f for f in swift_files() if any(
        kw in f.read_text(encoding="utf-8", errors="ignore")
        for kw in ["OAuth", "oauth", "authorization_code", "redirect_uri"]
    )]
    for f in oauth_files:
        text = f.read_text(encoding="utf-8", errors="ignore")
        if pattern.search(text):
            error(f"WKWebView used for OAuth in {f.name} — use ASWebAuthenticationSession")

# ── 7. isPremium in CloudKit sync ───────────────────────────────────────────
def check_ispremium_cloudkit():
    pattern = re.compile(r'isPremium')
    for f in swift_files():
        text = f.read_text(encoding="utf-8", errors="ignore")
        if "CloudKit" in text and "CKRecord" in text and pattern.search(text):
            error(f"isPremium may be synced via CloudKit in {f.name} — forbidden by invariant")

# ── 8. Swift file structure ─────────────────────────────────────────────────
def check_swift_syntax():
    for f in swift_files():
        text = f.read_text(encoding="utf-8", errors="ignore")
        opens = text.count('{')
        closes = text.count('}')
        if opens != closes:
            error(f"Unbalanced braces in {f.name} ({opens} open, {closes} close)")

# ── 9. Entitlements check ───────────────────────────────────────────────────
def check_entitlements():
    ent = SWIFT_DIR / "VReader.entitlements"
    if not ent.exists():
        error("VReader.entitlements not found")
        return
    text = ent.read_text()
    required = [
        "ubiquity-kvs-identifier",
        "icloud-services",
        "application-groups",
    ]
    for key in required:
        if key not in text:
            error(f"Missing entitlement: {key}")

# ── Run all checks ──────────────────────────────────────────────────────────
print("🔍 VReader check_refs.py")
print(f"   Scanning {len(swift_files())} Swift files in {SWIFT_DIR}")
print()

check_duplicate_types()
check_uttype_force_unwrap()
check_cover_data()
check_ios_compatibility()
check_wkwebview_oauth()
check_ispremium_cloudkit()
check_swift_syntax()
check_entitlements()
check_hardcoded_strings()

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
    print("✅ No errors — warnings are informational")
else:
    print(f"❌ {len(errors)} error(s) found — merge blocked")

sys.exit(1 if errors else 0)
