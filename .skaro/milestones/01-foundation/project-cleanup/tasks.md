# Tasks: project-cleanup

## Stage 1: Filesystem Cleanup and File Migration

- [ ] Read `Vreader/VReader.entitlements` and `App/Vreader/Vreader/VReader.entitlements`, compute union of all keys → merged content ready for write
- [ ] Write merged entitlements (all 4 mandatory keys guaranteed present) → `App/Vreader/Vreader/VReader.entitlements`
- [ ] Check if `App/Vreader/Vreader/ErrorCode.swift` exists; if absent or empty, copy from `Vreader/ErrorCode.swift` → `App/Vreader/Vreader/ErrorCode.swift`
- [ ] Delete root `Vreader/` directory entirely (includes `Untitled.swift`, `StorageView.swift`, `StoragesView.swift`, `ReadingSessionView.swift`, `iCLoudSettingsStore.swift`, `Localizable.strings 00-14-05-840.strings`, `VReader.entitlements`, and all other contents) → `Vreader/` removed
- [ ] Delete root `Vreader.xcodeproj/` directory entirely → `Vreader.xcodeproj/` removed
- [ ] Verify no `Untitled.swift` remains anywhere in the project tree
- [ ] Verify no `Localizable.strings 00-14-05-840.strings` remains anywhere
- [ ] Verify exactly one definition each of `Book`, `ContentSource`, `DownloadTask`, `ErrorCode` in `App/Vreader/Vreader/`

## Stage 2: Xcode Project File Synchronization

- [ ] Parse `App/Vreader/Vreader.xcodeproj/project.pbxproj` and identify all existing file references
- [ ] Remove any stale `PBXFileReference` entries pointing to deleted files (`Untitled.swift`, `StorageView.swift`, `StoragesView.swift`, `ReadingSessionView.swift`, `iCLoudSettingsStore.swift`, any root `Vreader/` paths) → `App/Vreader/Vreader.xcodeproj/project.pbxproj`
- [ ] Remove corresponding stale `PBXBuildFile` entries for deleted files → `App/Vreader/Vreader.xcodeproj/project.pbxproj`
- [ ] Remove stale entries from `PBXGroup` and `PBXSourcesBuildPhase` sections → `App/Vreader/Vreader.xcodeproj/project.pbxproj`
- [ ] Generate valid 24-char hex UUIDs for `ErrorCode.swift` PBXFileReference and PBXBuildFile entries
- [ ] Add `PBXFileReference` entry for `ErrorCode.swift` to `project.pbxproj` → `App/Vreader/Vreader.xcodeproj/project.pbxproj`
- [ ] Add `PBXBuildFile` entry for `ErrorCode.swift` to `project.pbxproj` → `App/Vreader/Vreader.xcodeproj/project.pbxproj`
- [ ] Add `ErrorCode.swift` reference to the main group's children list in `PBXGroup` section → `App/Vreader/Vreader.xcodeproj/project.pbxproj`
- [ ] Add `ErrorCode.swift` build file UUID to the main target's `PBXSourcesBuildPhase` files list → `App/Vreader/Vreader.xcodeproj/project.pbxproj`
- [ ] Write `AI_NOTES.md` documenting: files deleted, entitlements merged, ErrorCode.swift migrated, pbxproj changes made, any deviations from spec → `AI_NOTES.md`