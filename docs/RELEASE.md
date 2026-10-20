# SmartMeal — Release Runbook

> **Status:** v1, written in P08 (2026-10-20). Android is fully covered;
> iOS steps need a Mac and are marked *pending*. Security context:
> [`SECURITY.md`](SECURITY.md).

## Contents

1. [Before every release](#1-before-every-release)
2. [Signing (Android)](#2-signing-android)
3. [Build](#3-build)
4. [Archive symbols and mapping](#4-archive-symbols-and-mapping)
5. [Upload and staged rollout](#5-upload-and-staged-rollout)
6. [Rollback](#6-rollback)
7. [iOS (pending: needs a Mac)](#7-ios-pending-needs-a-mac)
8. [Reference: what the release build enforces](#8-reference-what-the-release-build-enforces)

---

## 1. Before every release

- [ ] `main` is green in CI (quality gate, gitleaks, OSV-Scanner).
- [ ] `tool/verify.sh` passes locally on the release commit.
- [ ] Bump `version:` in `pubspec.yaml`. The format is `x.y.z+N`; `N` is
      the Android `versionCode` / iOS build number and **must increase on
      every upload**.
- [ ] The env file for the target environment exists and validates
      (`env/prod.json`; see README → "Run locally"). **Today there is only
      one Supabase project**, so a "prod" build talks to the same database
      as development (SECURITY.md §9). Create the production project
      before the first public release.
- [ ] Any database migrations in this release are **backward compatible**
      with the app version currently in users' hands. Old clients keep
      running during a staged rollout, and a rollback relies on this
      (§6).

## 2. Signing (Android)

Release builds are signed **only** with the upload key that
`android/key.properties` names. When the file, any of its keys, or the
keystore is missing, the build stops at `:app:preReleaseBuild` with:

```text
Release signing is not configured: android/key.properties not found.
Release builds never fall back to the debug key. …
```

### Create the upload keystore (once, by the owner)

```sh
keytool -genkeypair -v -storetype PKCS12 -keyalg RSA -keysize 4096 \
  -validity 10000 -alias upload \
  -keystore <OUTSIDE-THE-REPO>/smartmeal-upload.p12
```

`keytool` ships with the JDK. On this machine it is
`C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe`.

- **Store it outside the repository**, never under `smart_meal/`.
  `.gitignore` blocks `key.properties`, `*.jks` and `*.keystore`, but
  `.p12` is not on that list, which is one more reason to keep the file
  outside the repo.
- **Back it up in two places**, for example a password manager entry
  (keystore file plus passwords) and an offline encrypted drive. With Play
  App Signing a lost upload key can be reset through Play Console support,
  but that takes days and blocks releases.
- Use a strong, unique password, stored in the password manager only.

### `android/key.properties` (gitignored, never committed)

```properties
storeFile=C:/Users/<you>/secure/smartmeal-upload.p12
storePassword=<password>
keyAlias=upload
keyPassword=<password>
```

Use an absolute path with forward slashes. A relative path resolves
against `android/app/`.

### Play App Signing

Enroll on the first upload in Play Console → *Test and release* → *App
signing*, and let Google generate and hold the **app signing key**. We
keep only the **upload key**.

After enrollment, register **both** SHA-1 fingerprints with Google Cloud
for Google Sign-In (P12):

- the upload key's SHA-1, from
  `keytool -list -v -keystore <path> -alias upload`;
- the app signing key's SHA-1, from Play Console → App signing.

The debug key's SHA-1 is also needed for development builds.

## 3. Build

```sh
flutter build appbundle --release \
  --dart-define-from-file=env/prod.json \
  --obfuscate --split-debug-info=build/symbols/<version>
```

`<version>` is the `pubspec.yaml` version, e.g. `1.0.0+1`. The output is
`build/app/outputs/bundle/release/app-release.aab`.

For a device smoke test, build an APK with the same flags:
`flutter build apk --release …`. Install it with `adb install`. A
release-signed APK cannot replace an installed debug build (signature
mismatch), so uninstall the debug app first.

**Obfuscation is defense-in-depth, not a security boundary.** It makes
reverse engineering slower; it does not hide anything. Every value in the
binary, including all `env/*.json` defines, should be treated as public.
Real protection comes from the server: RLS, Edge Functions, and secrets
that never leave them (SECURITY.md §2).

**R8** (`isMinifyEnabled`, `isShrinkResources`) is on for release.
`android/app/proguard-rules.pro` holds only rules a release build or smoke
test proved necessary, each one with a comment naming the failure it
fixes. When a release build crashes with `ClassNotFoundException` /
`NoSuchMethodError` where debug works, add the narrowest `-keep` rule,
rebuild, and re-test.

### Known issue on the owner's Windows machine

In P04, `lintVital*` tasks failed with `ClassNotFoundException:
com.android.tools.lint.Main` (an environment issue). In P08 (2026-10-20)
`flutter build appbundle --release` passed without it. If it comes back,
build through Gradle and skip only those tasks:

```sh
# Git Bash, from android/; JAVA_HOME = Android Studio's JBR 21
./gradlew bundleRelease -Ptarget-platform=android-arm,android-arm64,android-x64 \
  -Pdart-obfuscation=true -Psplit-debug-info=../build/symbols/<version> \
  -Pdart-defines=<base64 defines> \
  -x lintVitalAnalyzeRelease -x lintVitalReportRelease -x lintVitalRelease
```

Prefer fixing the machine. A CI release build (future) is unaffected.

### Network on the owner's machine

Release builds download Flutter's release engine jars from
`storage.googleapis.com` once per Flutter version. On a flaky connection
Gradle times out (`Read timed out` / `No such host is known`) and Flutter
retries once. Re-run the build; the jars are cached after the first
success.

## 4. Archive symbols and mapping

Without these files, crash stack traces from the release cannot be read.
For **every** uploaded version, archive **outside git** (for example a
private cloud folder named `smartmeal-releases/<version>/`):

| File | Produced at | Used for |
|---|---|---|
| Dart symbols | `build/symbols/<version>/*.symbols` | `flutter symbolize -i <trace.txt> -d build/symbols/<version>/app.android-arm64.symbols` |
| R8 mapping | `build/app/outputs/mapping/release/mapping.txt` | Deobfuscating Java/Kotlin traces. The AAB also carries it to Play Console automatically |
| The AAB itself | `build/app/outputs/bundle/release/app-release.aab` | Reproducing exactly what shipped |

`build/` is gitignored and wiped by `flutter clean`, so archive right after
the build. Crashlytics (P19) can upload symbols automatically later.

## 5. Upload and staged rollout

1. Play Console → **Internal testing** → upload the AAB. Install it from
   the testing link and smoke-test on a real device:
   - splash;
   - sign in and sign out;
   - Google button;
   - images load;
   - app restart keeps or clears the session as expected.
2. **Closed testing** with a small group, if the change is risky.
3. **Production, staged:** 5 % → 20 % → 50 % → 100 %, at least 24 h apart.
   Before each step, check Android vitals (crash and ANR rate against the
   previous release) and the Supabase logs.
4. Keep the release notes and the archived files (§4) together.

## 6. Rollback

Play does not let you reinstall an older version on users' devices.

- **During a staged rollout:** Play Console → *Halt rollout*. Users who
  already updated keep the new version; nobody else receives it.
- **Fix forward:** rebuild a known-good commit, or the fix, with a
  **higher `versionCode`**, and roll it out (staged again).
- **Server side:** never ship a migration that the previous app version
  can't handle (§1). That is what makes halting the rollout safe.
- **Leaked or compromised key or secret:** follow SECURITY.md §7 (rotate
  first).

## 7. iOS (pending: needs a Mac)

- Add `ios/Runner/PrivacyInfo.xcprivacy` (created in P08) to the
  **Runner target** in Xcode (*Target Membership*), then confirm it
  appears in the built `.app`.
- `flutter build ipa --release --dart-define-from-file=env/prod.json
  --obfuscate --split-debug-info=build/symbols/<version>`, archive the
  symbols (§4), upload with Xcode Organizer or Transporter, then TestFlight,
  then App Store with **phased release** (Apple's 7-day ramp; can be
  paused).
- Signing uses Xcode automatic signing under the OJ Tech team. Certificates
  and profiles never go into git.
- ATS: `Info.plist` has no `NSAppTransportSecurity` exceptions (checked in
  P08). Keep it that way.

## 8. Reference: what the release build enforces

| Control | Where | Verified in P08 |
|---|---|---|
| No debug-key fallback; clear failure without signing | `android/app/build.gradle.kts` | Build with no `key.properties` → fails at `preReleaseBuild` |
| R8 code and resource shrinking | `android/app/build.gradle.kts`, `proguard-rules.pro` | Release AAB builds |
| No backup or device transfer | `AndroidManifest.xml` (`allowBackup=false`, `fullBackupContent`, `dataExtractionRules`), `res/xml/*_rules.xml` | Merged release manifest |
| No cleartext; system CAs only (user CAs in debug only) | `AndroidManifest.xml`, `res/xml/network_security_config.xml` | Merged release manifest |
| Only the launcher activity exported; not debuggable | Merged manifest | Merged release manifest: `MainActivity` is the only exported activity. The exported receivers/services added by plugins are each guarded by a permission (`c2dm.permission.SEND` for FCM, the Google sign-in `REVOCATION_NOTIFICATION`, `DUMP` for `ProfileInstallReceiver`). Re-check this list whenever a plugin is added |
| Dart obfuscation + split debug info | Build command (§3) | Release AAB builds |
| No logging in release | `AppLogger` (`kDebugMode` guard) | `log()` returns immediately in release. 4 of 5 log messages are compiled out of `libapp.so`; the background-message one survives as an inert constant (no PII) |
| iOS privacy manifest; no ATS exceptions | `ios/Runner/PrivacyInfo.xcprivacy`, `Info.plist` | File created; Xcode target membership pending |
