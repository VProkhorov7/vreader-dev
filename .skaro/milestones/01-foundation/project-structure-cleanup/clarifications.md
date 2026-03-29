# Clarifications: project-structure-cleanup

## Question 1
Which files are canonical — Core/ or App/Vreader/Vreader/?
**Answer:** Compare by modification date, take newer version. All canonical files go to App/Vreader/Vreader/.

**Answer:**
Compare by modification date, take newer version. All canonical files go to App/Vreader/Vreader/.

## Question 2
Preserve git history when moving files?
**Answer:** Yes, use git mv to preserve history.

**Answer:**
Yes, use git mv to preserve history.

## Question 3
Reorganize files into Models/, Services/, UI/ subfolders?
**Answer:** No. Only delete Core/ and Untitled.swift. Layer reorganization deferred.

**Answer:**
No. Only delete Core/ and Untitled.swift. Layer reorganization deferred.

## Question 4
Entitlement values?
**Answer:** $(TeamIdentifierPrefix)com.vreader.app for KVS, iCloud.com.vreader.app for container.

**Answer:**
$(TeamIdentifierPrefix)com.vreader.app for KVS, iCloud.com.vreader.app for container.

## Question 5
What to do with AppState.swift and iCLoudSettingsStore.swift?
**Answer:** Rename iCLoudSettingsStore.swift to iCloudSettingsStore.swift. Add TODO comment to AppState.swift about ADR-009 refactoring.

**Answer:**
Rename iCLoudSettingsStore.swift to iCloudSettingsStore.swift. Add TODO comment to AppState.swift about ADR-009 refactoring.
