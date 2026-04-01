## plan.md

## Stage 1: Filesystem Cleanup and File Migration

**Goal:** Execute all filesystem operations: read both entitlements files, merge them, copy `ErrorCode.swift` to canonical location, delete the root `Vreader/` directory and all its contents, delete `Untitled.swift` if it exists outside the root directory.

**Depends on:** none (pure filesystem operations)

**Inputs:**
- `Vreader/VReader.entitlements` (root, to be merged then deleted)
- `App/Vreader/Vreader/VReader.entitlements` (canonical, to be updated)
- `Vreader/ErrorCode.swift` (source for migration)
- `App/Vreader/Vreader/` (canonical directory, destination)
- Full project file tree (as listed in spec)

**Outputs:**
- `App/Vreader/Vreader/VReader.entitlements` — **modified** (merged union of both entitlements files, all 4 mandatory keys present)
- `App/Vreader/Vreader/ErrorCode.swift` — **created** (copied from `Vreader/ErrorCode.swift`)
- `Vreader/` — **deleted** entirely (including `Vreader.xcodeproj`, `Untitled.swift`, `StorageView.swift`, `StoragesView.swift`, `ReadingSessionView.swift`, `Localizable.strings 00-14-05-840.strings`, `iCLoudSettingsStore.swift`, `VReader.entitlements`, and all other contents)
- `Vreader.xcodeproj/` — **deleted** entirely (root-level xcodeproj)

**DoD:**
- [ ] `App/Vreader/Vreader/ErrorCode.swift` exists and contains the `ErrorCode` type definition
- [ ] `App/Vreader/Vreader/VReader.entitlements` contains all 4 mandatory entitlement keys: `com.apple.developer.ubiquity-kvs-identifier`, `com.apple.developer.icloud-services`, `com.apple.developer.icloud-container-identifiers`, `com.apple.security.application-groups`
- [ ] Root `Vreader/` directory does not exist
- [ ] Root `Vreader.xcodeproj/` directory does not exist
- [ ] No `Untitled.swift` anywhere in the project
- [ ] No `Localizable.strings 00-14-05-840.strings` anywhere in the project
- [ ] `find . -name "*.xcodeproj" | grep -v "^./App/"` returns empty
- [ ] Exactly one definition of each type: `Book`, `ContentSource`, `DownloadTask`, `ErrorCode` (verified by grep)

**Risks:**
- `ErrorCode.swift` in `App/` may already exist with a partial definition — must check before overwriting; root version is the one to use per spec (it's absent from `App/`)
- Entitlements merge must preserve valid plist XML structure
- `rm -rf` on wrong path could delete canonical sources — must verify paths carefully before execution

---

## Stage 2: Xcode Project File Synchronization

**Goal:** Update `App/Vreader/Vreader.xcodeproj/project.pbxproj` to add `ErrorCode.swift` to the build target's compile sources, and verify no stale file references remain pointing to deleted files. This ensures the project compiles without "missing file" errors and without duplicate type warnings.

**Depends on:** Stage 1 (ErrorCode.swift must exist on disk before being added to pbxproj)

**Inputs:**
- `App/Vreader/Vreader.xcodeproj/project.pbxproj` (to be modified)
- `App/Vreader/Vreader/ErrorCode.swift` (newly added file from Stage 1)
- List of all files currently in `App/Vreader/Vreader/` (post-cleanup filesystem state)

**Outputs:**
- `App/Vreader/Vreader.xcodeproj/project.pbxproj` — **modified**: `ErrorCode.swift` added to PBXBuildFile + PBXFileReference + PBXGroup + PBXSourcesBuildPhase; no dangling references to deleted files
- `AI_NOTES.md` — **created/updated** with cleanup summary, decisions made, and any deviations from spec

**DoD:**
- [ ] `project.pbxproj` contains a `PBXFileReference` entry for `ErrorCode.swift`
- [ ] `project.pbxproj` contains a `PBXBuildFile` entry for `ErrorCode.swift` linked to the main target's `PBXSourcesBuildPhase`
- [ ] `project.pbxproj` contains no references to `Untitled.swift`
- [ ] `project.pbxproj` contains no references to `StorageView.swift`, `StoragesView.swift`, `ReadingSessionView.swift`
- [ ] `project.pbxproj` contains no references to `iCLoudSettingsStore.swift` (root typo version)
- [ ] `project.pbxproj` contains no references to files under the deleted root `Vreader/` path
- [ ] `xcodebuild -project App/Vreader/Vreader.xcodeproj -scheme Vreader -destination 'generic/platform=iOS Simulator' build` exits 0 (or at minimum: no duplicate type errors, no missing file errors)
- [ ] `AI_NOTES.md` documents all decisions (which files were deleted, what was merged, what was added)

**Risks:**
- `pbxproj` is a fragile text format — incorrect UUID generation or malformed section edits can corrupt the project file; must use correct UUID format (24-char hex)
- The existing `pbxproj` may already reference files that don't exist on disk (pre-existing orphans) — these must be identified and removed, not just the ones from this cleanup
- If `ErrorCode.swift` was already referenced in `pbxproj` under a different group path, adding it again creates a duplicate reference

---

## Verify

```yaml
- name: No root Vreader directory
  command: test ! -d Vreader && echo "OK: root Vreader/ deleted"

- name: No root xcodeproj
  command: test ! -d Vreader.xcodeproj && echo "OK: root Vreader.xcodeproj deleted"

- name: Exactly one xcodeproj in project
  command: find . -name "*.xcodeproj" -not -path "*/\.*" | grep -v "^./App/" | wc -l | xargs -I{} test {} -eq 0 && echo "OK: only App/ xcodeproj exists"

- name: ErrorCode.swift exists in canonical location
  command: test -f App/Vreader/Vreader/ErrorCode.swift && echo "OK: ErrorCode.swift present"

- name: No Untitled.swift anywhere
  command: find . -name "Untitled.swift" -not -path "*/\.*" | wc -l | xargs -I{} test {} -eq 0 && echo "OK: no Untitled.swift"

- name: No timestamped Localizable.strings backup
  command: find . -name "Localizable.strings *" -not -path "*/\.*" | wc -l | xargs -I{} test {} -eq 0 && echo "OK: no backup Localizable.strings"

- name: No duplicate Book type definition
  command: grep -rl "^class Book\|^struct Book\|^final class Book" App/Vreader/Vreader/ | wc -l | xargs -I{} test {} -le 1 && echo "OK: Book defined once"

- name: No duplicate ContentSource type definition
  command: grep -rl "^enum ContentSource\|^struct ContentSource" App/Vreader/Vreader/ | wc -l | xargs -I{} test {} -le 1 && echo "OK: ContentSource defined once"

- name: No duplicate DownloadTask type definition
  command: grep -rl "^class DownloadTask\|^struct DownloadTask\|^final class DownloadTask" App/Vreader/Vreader/ | wc -l | xargs -I{} test {} -le 1 && echo "OK: DownloadTask defined once"

- name: No duplicate ErrorCode type definition
  command: grep -rl "^enum ErrorCode\|^struct ErrorCode" App/Vreader/Vreader/ | wc -l | xargs -I{} test {} -le 1 && echo "OK: ErrorCode defined once"

- name: Entitlements has ubiquity-kvs-identifier
  command: grep -q "ubiquity-kvs-identifier" App/Vreader/Vreader/VReader.entitlements && echo "OK: ubiquity-kvs-identifier present"

- name: Entitlements has icloud-services
  command: grep -q "icloud-services" App/Vreader/Vreader/VReader.entitlements && echo "OK: icloud-services present"

- name: Entitlements has icloud-container-identifiers
  command: grep -q "icloud-container-identifiers" App/Vreader/Vreader/VReader.entitlements && echo "OK: icloud-container-identifiers present"

- name: Entitlements has application-groups
  command: grep -q "application-groups" App/Vreader/Vreader/VReader.entitlements && echo "OK: application-groups present"

- name: pbxproj references ErrorCode.swift
  command: grep -q "ErrorCode.swift" App/Vreader/Vreader.xcodeproj/project.pbxproj && echo "OK: ErrorCode.swift in pbxproj"

- name: pbxproj has no reference to Untitled.swift
  command: grep -qv "Untitled.swift" App/Vreader/Vreader.xcodeproj/project.pbxproj && echo "OK: no Untitled.swift in pbxproj"

- name: pbxproj has no reference to StorageView.swift
  command: ! grep -q "StorageView.swift" App/Vreader/Vreader.xcodeproj/project.pbxproj && echo "OK: no StorageView.swift in pbxproj"

- name: pbxproj has no reference to iCLoudSettingsStore.swift
  command: ! grep -q "iCLoudSettingsStore.swift" App/Vreader/Vreader.xcodeproj/project.pbxproj && echo "OK: no iCLoudSettingsStore.swift in pbxproj"

- name: Xcode build succeeds
  command: xcodebuild -project App/Vreader/Vreader.xcodeproj -scheme Vreader -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```