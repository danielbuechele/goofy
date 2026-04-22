---
name: publish
description: Build, sign, notarize, and release a new version of Goofy
user_invocable: true
---

# Publish a new version of Goofy

This skill builds, signs, notarizes, and releases a new version of the Goofy macOS app.

## Prerequisites

- A "Developer ID Application" certificate must be in the keychain
- A notarytool keychain profile named `notarytool-profile` must exist. If not, the user needs to run:
  ```
  xcrun notarytool store-credentials "notarytool-profile" --apple-id "EMAIL" --team-id K5C6E7A2D6 --password "APP_SPECIFIC_PASSWORD"
  ```
- The `gh` CLI must be authenticated with GitHub

## Steps

Run each step sequentially. Stop and report errors if any step fails.

**On failure after step 1 and before step 6 (commit):** revert the version bump so the next attempt starts from a clean state. The bump only touches `goofy.xcodeproj/project.pbxproj`, so:

```bash
cd /Users/danielbuechele/goofy
git checkout -- goofy.xcodeproj/project.pbxproj
```

Do not revert after step 6 — at that point the bump is committed and tagged, and recovery is different.

### Step 1: Bump version number

```bash
cd /Users/danielbuechele/goofy
VERSION_OUTPUT=$(bash scripts/increment_build.sh)
echo "$VERSION_OUTPUT"
```

Parse the output to extract the new version. The script prints `Build NNN, version X.Y.Z`.
Extract the version (e.g. `4.0.155`) — you will need it for all subsequent steps. Store it as `NEW_VERSION`.

### Step 2: Archive the app

```bash
cd /Users/danielbuechele/goofy
xcodebuild archive \
  -project goofy.xcodeproj \
  -scheme goofy \
  -configuration Release \
  -archivePath build/Goofy.xcarchive \
  CODE_SIGN_IDENTITY="Developer ID Application" \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM=K5C6E7A2D6 \
  2>&1 | tail -30
```

Verify the output ends with `** ARCHIVE SUCCEEDED **`.

### Step 3: Export the archive

```bash
cd /Users/danielbuechele/goofy
xcodebuild -exportArchive \
  -archivePath build/Goofy.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist \
  2>&1 | tail -20
```

This produces `build/export/Goofy.app`.

### Step 4: Notarize

Create a zip for notarization submission and submit it:

```bash
cd /Users/danielbuechele/goofy
(cd build/export && zip -r -y ../Goofy-notarize.zip Goofy.app)
xcrun notarytool submit build/Goofy-notarize.zip \
  --keychain-profile "notarytool-profile" \
  --wait
```

The `--wait` flag blocks until Apple finishes processing (typically 1-5 minutes). Verify the status is `Accepted`.

### Step 5: Staple and create final zip

Staple the notarization ticket to the app, then create the release zip:

```bash
cd /Users/danielbuechele/goofy
xcrun stapler staple build/export/Goofy.app
(cd build/export && zip -r -y "../Goofy-${NEW_VERSION}.zip" Goofy.app)
```

Use `zip -r -y` (not `ditto`). Modern Xcode signing adds a sticky `com.apple.provenance` extended attribute to files in the bundle; `ditto` encodes those as `._*` AppleDouble entries, and AppUpdater's `/usr/bin/unzip` then writes them as literal `._*` files inside the installed bundle, which corrupts the code signature ("damaged" error). `zip` ignores xattrs entirely. The notarization ticket lives inside the bundle (`Contents/CodeResources`), so it survives.

**Verify before releasing:** extract the zip with `/usr/bin/unzip` to a temp dir and run `codesign --verify --deep --strict` on it. Must pass. If it reports "a sealed resource is missing or invalid", stop — the release will be broken.

### Step 6: Commit and tag

**Ask the user for confirmation before proceeding with this step.**

```bash
cd /Users/danielbuechele/goofy
git add -A
git commit -m "v${NEW_VERSION}"
git tag "${NEW_VERSION}"
git push origin main --tags
```

This commits all changes (the version bump plus any other uncommitted work). The `build/` directory is in `.gitignore` so it won't be included.

### Step 7: Create GitHub release

```bash
cd /Users/danielbuechele/goofy
gh release create "${NEW_VERSION}" \
  "build/Goofy-${NEW_VERSION}.zip" \
  --title "${NEW_VERSION}" \
  --generate-notes
```

### Step 8: Cleanup

```bash
rm -rf /Users/danielbuechele/goofy/build/
```

Report the published version and the GitHub release URL to the user.
