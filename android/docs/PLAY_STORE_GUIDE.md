# SwiftBible — Google Play Store Publishing Guide

This is the **complete** end-to-end recipe for getting SwiftBible into the Google Play Store. Follow it sequentially the first time. Once it's set up, future releases are a one-liner.

---

## 1. Create a Google Play Developer account

**Cost:** US $25, one-time, for life.

1. Go to <https://play.google.com/console/signup>
2. Sign in with the Google account you want to publish under (consider a dedicated one — `swiftbible@…`).
3. Choose **"Yourself"** account type unless you have a registered business.
4. Pay the $25 fee.
5. Complete identity verification (Google will email you with required documents).
   - **Important:** as of 2024, Google requires personal developers to provide ID and a phone number. This can take a few days.
6. Once verified, you'll have access to the [Play Console](https://play.google.com/console).

---

## 2. Create the app listing in Play Console

1. Play Console → **Create app**
2. App name: `SwiftBible`
3. Default language: `English (United States) – en-US`
4. App or game: **App**
5. Free or paid: **Free**
6. Confirm declarations
7. **Create app**

You now have an app shell. Note the **package name will be `biz.am2.swiftbible`** — this is final and cannot be changed once published.

---

## 3. Generate the release keystore (one-time)

```bash
cd android
./scripts/generate_keystore.sh
```

This produces `release.keystore` and prompts for passwords.

**🔐 BACK UP THIS FILE.**
- Add it to a password manager (1Password, Bitwarden) as an attachment.
- Save a copy on an external drive or a sealed envelope.
- If you lose it, you cannot publish updates again — you'd have to publish a new app.

Then create `keystore.properties` in `android/` (NOT committed to git):

```properties
storeFile=/absolute/path/to/release.keystore
storePassword=YOUR_PASSWORD
keyAlias=swiftbible
keyPassword=YOUR_PASSWORD
```

`.gitignore` already excludes `keystore.properties` and `*.keystore` for you.

---

## 4. Build the release App Bundle

```bash
./scripts/build_release.sh
```

Outputs `app/build/outputs/bundle/release/app-release.aab`.

The first time, also generate a feature graphic:
```bash
./scripts/create_feature_graphic.sh
```

And take screenshots from a running emulator:
```bash
./scripts/take_screenshots.sh
```

---

## 5. First upload — manual via web

For your **first** release, do this manually (it's required to set up the app properly).

### 5.1 App content declarations

Play Console → **App content** in the left sidebar. Complete every section:

| Section | What to do |
|---|---|
| Privacy policy | Host `docs/PRIVACY_POLICY.md` somewhere public (GitHub Pages works) and paste the URL |
| Ads | Choose **No, my app does not contain ads** |
| App access | **All functionality is available without restrictions** |
| Content rating | Fill in IARC questionnaire — for a Bible reader, expect a Rating: **Everyone** |
| Target audience | Ages 13+ (Bible content is universal) |
| News app | **No** |
| COVID-19 contact tracing | **No** |
| Data safety | Click through and declare: **No data collected, no data shared** (this is true for SwiftBible) |
| Government apps | **No** |

### 5.2 Main store listing

Play Console → **Main store listing**. Paste from `metadata/en-US/listing/`:

| Field | Source |
|---|---|
| App name (50 chars) | `metadata/en-US/listing/title.txt` |
| Short description (80) | `metadata/en-US/listing/short-description.txt` |
| Full description (4000) | `metadata/en-US/listing/full-description.txt` |
| App icon (512×512 PNG) | export from Xcode iOS asset catalog or use `app/src/main/res/mipmap-*` |
| Feature graphic (1024×500) | `metadata/en-US/listing/feature-graphic.png` |
| Phone screenshots | At least 2; up to 8. From `metadata/en-US/screenshots/` |

**Required image specs:**
- App icon: 512×512 PNG, 32-bit, no transparency
- Feature graphic: 1024×500 JPG or 24-bit PNG (no alpha)
- Phone screenshots: 1080×1920 minimum, 16:9 or 9:16 ratio

### 5.3 Upload bundle to Internal testing

Play Console → **Testing → Internal testing → Create new release**

1. Upload `app-release.aab`
2. Release name: `1.0`
3. Release notes (paste from `metadata/en-US/release-notes/default.txt`)
4. **Save** then **Review release** then **Start rollout to Internal testing**

Add yourself as a tester:
- Internal testing → **Testers** → Create email list → add your email → Save

You'll receive an opt-in link — open it on a phone signed in with the same Google account, click the install link, and you'll see SwiftBible on the Play Store within ~10 minutes.

### 5.4 Promote to Production

When you're satisfied:

Play Console → **Production → Create new release** → upload the same .aab → set release notes → review → roll out.

Google's review for a first release typically takes **1–7 days**. Subsequent updates are usually approved in hours.

---

## 6. Subsequent releases (the easy path)

After the first release is live, future releases are scripted:

```bash
# bump versionCode in app/build.gradle.kts
# build the bundle
./scripts/build_release.sh

# upload via API to internal track
./scripts/upload_to_play.py --track internal --release-notes "Bug fixes and polish" \
  app/build/outputs/bundle/release/app-release.aab
```

To use the API:

1. Play Console → **Setup → API access**
2. Create or link a Google Cloud project
3. Create a Service Account (in Google Cloud Console)
4. In Play Console, grant the service account **Release manager** permissions
5. Download a JSON key for the service account
6. Save it as `android/service-account.json`
7. Run the script

When you're confident, switch the track to `production`:

```bash
./scripts/upload_to_play.py --track production --rollout 0.1 \
  app/build/outputs/bundle/release/app-release.aab
# 10% staged rollout. Bump rollout fraction over a few days.
```

---

## 7. CI/CD with GitHub Actions

The repo ships a working release workflow at `.github/workflows/release-android.yml`. It triggers on every push to `master` that touches `android/app/**` (or build configuration), extracts the version from `app/build.gradle.kts`, skips if a tag for that version already exists, builds a signed AAB, publishes it to the Play Store **internal** track, and tags the release as `android-v<versionName>-<versionCode>`.

### Required GitHub repo secrets

Settings → Secrets and variables → Actions → New repository secret:

| Secret | Value | How to get it |
|---|---|---|
| `RELEASE_KEYSTORE_BASE64` | Base64 of the signing keystore | `base64 -i android/release.keystore \| pbcopy` |
| `KEYSTORE_PASSWORD` | Keystore password | From local `android/keystore.properties` |
| `KEY_ALIAS` | Key alias (typically `swiftbible`) | From local `android/keystore.properties` |
| `KEY_PASSWORD` | Key password | From local `android/keystore.properties` |
| `PLAY_KEY_JSON` | Service account JSON (entire string) | Contents of local `android/play-key.json` |

The workflow asserts each secret is non-empty and validates that `PLAY_KEY_JSON` parses as JSON before doing any work, so misconfiguration fails fast.

### Promoting from internal to production

CI only deploys to internal. To promote, either:

- Run `/ship-android --production` locally (uses `promoteArtifact` — no rebuild), or
- Promote in the Play Console UI.

This intentional split keeps every master push out of public reach until you've smoke-tested it.

### Manual trigger

The workflow also supports `workflow_dispatch`, so you can re-run it for the current `master` HEAD without pushing a new commit.

---

## 8. Common gotchas

**"You uploaded an APK or Android App Bundle that was signed in debug mode."**
Your `keystore.properties` is missing or the wrong password. Verify with:
```bash
unzip -p app/build/outputs/bundle/release/app-release.aab BundleConfig.pb | head -1
keytool -printcert -jarfile app/build/outputs/bundle/release/app-release.aab
```

**"Version code 1 has already been used."**
Bump `versionCode` in `app/build.gradle.kts` (must be a unique, monotonically increasing integer for every upload).

**"App icon doesn't conform to specifications."**
512×512 PNG, **no alpha channel**, sRGB colorspace. Open in Preview → Export As → PNG, uncheck Alpha.

**"You haven't completed the Data safety section."**
That's section 5.1 in this doc. SwiftBible collects nothing, so the form is fast — but it must be submitted.

**Service account can't upload.**
The service account needs to be invited to the Play Console (Users and permissions) AND have permissions on this specific app. Both steps are required.

---

## 9. Marketing checklist (do these before you go live)

- [ ] Privacy policy live at a stable URL (GitHub Pages is free)
- [ ] App icon is 512×512 PNG with no alpha
- [ ] Feature graphic is 1024×500
- [ ] At least 2 phone screenshots, ideally 8 — show variety (light + dark, different screens)
- [ ] Short description has the search keywords you care about ("Bible KJV Apocrypha Enoch offline")
- [ ] Tested on a real device, not just the emulator
- [ ] App opens, the bottom-nav tabs work, you can read a chapter
- [ ] Contact email reachable (`mischke@proton.me` on file)

---

## 10. After you're live

| What | Where |
|---|---|
| Monitor crashes | Play Console → Quality → Crashes & ANRs |
| Read reviews | Play Console → Reviews |
| Track installs | Play Console → Statistics |
| A/B test the listing | Play Console → Store presence → Custom store listings |

Good luck. Ship something beautiful.
