# Migrating TO Best from GitHub Actions to Codemagic

This document is the setup checklist for the new `codemagic.yaml` at the repo
root. It replaces `.github/workflows/{ci,cd_tobest,cd_management}.yml`, which
have been moved to `.github/workflows-archived-github-actions/` for reference
(delete that folder once you're confident the new pipeline works).

## 1. What changed, and why

| Old (GitHub Actions) | New (Codemagic) | Why it's better |
|---|---|---|
| 2 jobs in `ci.yml` (`analyze` → `test`) | 1 job in `tobest-ci` | Codemagic workflows run on a single VM; splitting into two jobs only added a second checkout/bootstrap with no parallelism benefit. |
| Keystore as `ANDROID_KEYSTORE_BASE64` secret + manual `base64 --decode` | Keystore uploaded as a binary **Code signing identity**, referenced via `android_signing: [tobest_keystore]` | The keystore file itself never sits in a plain environment variable; Codemagic injects `CM_KEYSTORE_PATH` etc. automatically and the file isn't downloadable after upload. |
| `subosito/flutter-action@v2` + `actions/setup-java@v4` | `environment.flutter` / `environment.java` | Native to Codemagic's Flutter-aware build machines — no third-party actions to keep up to date. |
| GitHub Release via `softprops/action-gh-release@v2` | `gh release create` using the **same GitHub CLI**, now driven by Codemagic's built-in `gh` + `$CM_TAG` | Functionally identical output (still a GitHub Release with the APK attached); just runs on a different CI engine. |
| `GITHUB_RUN_NUMBER` / `GITHUB_REF_NAME` | `$BUILD_NUMBER` / `$CM_TAG` | Codemagic's built-in equivalents. |

The build logic itself (melos bootstrap → generate → build) is unchanged —
this is a CI *engine* swap, not a rebuild of your pipeline.

## 2. One-time Codemagic setup

### 2.1 Connect the repository
1. Sign in to [codemagic.io](https://codemagic.io) and install the Codemagic
   GitHub App on your account/org if you haven't already.
2. **Add application** → select this repository → when asked, confirm the
   project type as **Flutter** (Codemagic will detect `codemagic.yaml` and
   use it automatically once it's committed; ignore the Workflow Editor).
3. Because this is a monorepo, after the first scan, go to **App settings →
   Build → Project path** if you ever need to point the Flutter-detection
   logic at a specific app — but since every build step in `codemagic.yaml`
   already `cd`s into the right `apps/<name>` folder explicitly, you can
   leave this on `.` (repo root).

### 2.2 Environment variable groups
Create these under **either** Team settings → Environment variables (shared
across apps) **or** this app's Environment variables tab — group names must
match `codemagic.yaml` exactly.

**`app_secrets`** (mark each variable **Secret**)
| Variable | Value |
|---|---|
| `GAS_BASE_URL` | your Google Apps Script URL |
| `GAS_SECRET_KEY` | your GAS auth key |
| `GEMINI_API_KEY` | your Gemini API key |

**`github_credentials`** (mark **Secret**)
| Variable | Value |
|---|---|
| `GITHUB_TOKEN` | a GitHub Personal Access Token with `repo` (write) scope, used to create releases |

**`codecov_credentials`** (optional, only if you want coverage uploads — mark **Secret**)
| Variable | Value |
|---|---|
| `CODECOV_TOKEN` | token from your Codecov project settings |

### 2.3 Android keystores (replaces the old base64 secrets entirely)
Do this **twice** — once per app — under **Team settings → codemagic.yaml
settings → Code signing identities → Android keystores**:

1. Click **Choose a file**, upload `tobest.jks` (the same file you previously
   base64-encoded into `ANDROID_KEYSTORE_BASE64`).
2. Enter the keystore password, key alias and key password (the same values
   that were in `KEYSTORE_STORE_PASSWORD` / `KEYSTORE_KEY_ALIAS` /
   `KEYSTORE_KEY_PASSWORD`).
3. **Reference name:** `tobest_keystore` — must match `codemagic.yaml` exactly.
4. Click **Add keystore**.
5. Repeat for the Management app's keystore, using reference name
   `management_keystore` and the values that were in `MGMT_KEYSTORE_*`.

Codemagic cannot re-download the keystore file once uploaded — keep your own
backup copy exactly as before.

### 2.4 (Optional) Firebase App Distribution
The original setup distributed APKs only as GitHub Release assets. That still
works unchanged via the `gh release create` step. If you'd like testers to
get install notifications and a proper build history instead of hunting
through GitHub Releases:

1. Create a Firebase project, add an Android app for each binary
   (`com.tobest.app` and `com.tobest.management`), and create tester groups
   under **App Distribution → Testers & groups**.
2. Generate a Firebase service account with the **Firebase App Distribution
   Admin** role and add its JSON as a `firebase_credentials` group variable
   named `FIREBASE_SERVICE_ACCOUNT`.
3. Uncomment the `firebase:` block at the bottom of the relevant workflow in
   `codemagic.yaml`, fill in the real `app_id` values from the Firebase
   console, and add `firebase_credentials` to that workflow's `groups:` list.

### 2.5 Notification email
Replace the `team@yourdomain.com` placeholders in `codemagic.yaml` (three
occurrences) with your team's real address(es) before your first build.

## 3. How triggering works now

- **CI** (`tobest-ci`) fires on every push or pull request targeting `main`
  or `develop` — same as before.
- **TO Best release** (`tobest-android-release`) fires on pushing a tag
  matching `v*.*.*-tobest`, e.g.:
  ```bash
  git tag v1.2.0-tobest && git push origin v1.2.0-tobest
  ```
- **Management release** (`management-android-release`) fires on
  `v*.*.*-management` tags, identically.
- For tag-triggered builds to work, make sure a webhook exists: Codemagic
  sets this up automatically when you add the app, but if tag pushes aren't
  triggering builds, check **App settings → Webhooks**.

You can also start any workflow manually from the Codemagic dashboard
(useful for re-running a release without re-tagging, or for testing the
pipeline the first time).

## 4. Known gap: iOS

The archived GitHub Actions setup never built iOS either — only Android
APKs. This migration preserves that scope. If/when you want iOS builds, two
things need to happen first, independent of Codemagic:

1. **The Xcode project itself is incomplete in this codebase.** Only
   `ios/Podfile`, `ios/Runner/AppDelegate.swift` and `ios/Runner/Info.plist`
   are present for both apps — there's no `Runner.xcodeproj` or
   `Runner.xcworkspace`. Regenerate them with `flutter create .` run from
   inside each `apps/<name>` folder (this won't touch your existing Dart
   code, only scaffolds the missing native project files), then commit the
   result.
2. Once that's in place, add an `ios_signing` block (Apple Developer Program
   membership + an App Store Connect API key) and a `flutter build ipa`
   script per app, following the iOS tab in [Codemagic's Flutter quick start
   guide](https://docs.codemagic.io/yaml-quick-start/building-a-flutter-app/).
   Happy to draft those workflows once the native project files exist.

## 5. Quick sanity checklist before your first real release build

- [ ] `app_secrets`, `github_credentials` groups created with real values
- [ ] `tobest_keystore` and `management_keystore` uploaded with correct alias/passwords
- [ ] Email recipients updated in `codemagic.yaml`
- [ ] `tobest-ci` passes on a normal push to `develop`
- [ ] A test tag (e.g. `v0.0.1-tobest`) produces a signed APK and a GitHub Release
