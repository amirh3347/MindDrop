# Building & releasing MindDrop

You can ship MindDrop without installing anything locally: GitHub Actions builds,
tests and signs the APK. Local builds are optional and described at the end.

## Pipelines

| Workflow | Trigger | What it does |
|---|---|---|
| [`ci.yml`](../.github/workflows/ci.yml) | push to `main`, pull requests, manual | `flutter analyze`, `flutter test`, builds a release APK and attaches it to the run as an artifact (kept 14 days) |
| [`release.yml`](../.github/workflows/release.yml) | tag `v*` (e.g. `v1.2.0`), manual | tests, builds a signed APK named `MindDrop-v1.2.0.apk`, publishes a GitHub Release with notes from `CHANGELOG.md` and a `SHA256SUMS.txt` |

The Flutter version is pinned in both workflows (`FLUTTER_VERSION`). Bump it on purpose
and check that CI stays green.

## 1. Push the project to GitHub

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/<you>/MindDrop.git
git push -u origin main
```

Then replace `OWNER` with your GitHub username in `README.md`, `README.fa.md` and
`CHANGELOG.md` so the badges and links work:

```bash
sed -i 's#OWNER/MindDrop#<you>/MindDrop#g' README.md README.fa.md CHANGELOG.md
```

## 2. Create a signing key (one time, strongly recommended)

Android only installs an update if it is signed with the **same key** as the installed
app. Without your own key, every CI run signs with a fresh throwaway debug key, and you
would have to uninstall (losing data) before installing a newer build.

### Option A — with Java installed (any OS)

```bash
./scripts/generate-keystore.sh            # writes to ~/minddrop-signing
```

The script prints the four secret values and saves them in `~/minddrop-signing/secrets.txt`.

### Option B — no Java locally

Any machine with a JDK works (`keytool` ships with it). The command the script runs is:

```bash
keytool -genkeypair -v -keystore minddrop-release.jks -storetype PKCS12 \
  -alias minddrop -keyalg RSA -keysize 4096 -validity 10000
base64 -w0 minddrop-release.jks > keystore.base64.txt
```

### Add the secrets

GitHub → your repository → **Settings → Secrets and variables → Actions → New repository
secret**:

| Name | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | contents of `keystore.base64.txt` (one long line) |
| `ANDROID_KEYSTORE_PASSWORD` | keystore password |
| `ANDROID_KEY_ALIAS` | `minddrop` |
| `ANDROID_KEY_PASSWORD` | key password (same as keystore password for PKCS12) |

> **Back up the `.jks` file and passwords** (password manager, encrypted drive…). If you
> lose them, future versions can't be installed over the existing app. Never commit them —
> `.gitignore` already excludes `*.jks`, `*.keystore` and `key.properties`.

If the secrets are missing, builds still succeed but show a warning, and the release
notes say the APK is debug-signed.

## 3. Release a version

1. Move the items under `## [Unreleased]` in `CHANGELOG.md` into a new
   `## [1.1.0] - YYYY-MM-DD` section (that section becomes the release notes).
2. Optionally bump `version:` in `pubspec.yaml` (CI overrides it with the tag anyway).
3. Tag and push:

   ```bash
   git commit -am "Release 1.1.0"
   git tag v1.1.0
   git push origin main v1.1.0
   ```

4. Watch **Actions → Release**. When it finishes, the APK is on the **Releases** page.

Versioning: the tag gives the version name (`1.1.0`), and the workflow run number gives the
increasing Android `versionCode`. Tags with a suffix (e.g. `v1.2.0-beta.1`) are published
as pre-releases.

You can also run **Actions → Release → Run workflow** and type a version manually.

## Local development (optional)

Requirements: [Flutter](https://docs.flutter.dev/get-started/install) (stable, matching
`FLUTTER_VERSION`), Android SDK and JDK 17.

```bash
flutter pub get
flutter run                 # on a connected phone or emulator
flutter test
flutter analyze
flutter build apk --release
```

For locally signed builds, create `android/key.properties`:

```properties
storeFile=/absolute/path/to/minddrop-release.jks
storePassword=...
keyAlias=minddrop
keyPassword=...
```

`storeFile` is resolved relative to `android/app/` unless absolute.

## Troubleshooting

| Problem | Fix |
|---|---|
| "App not installed" when updating | The new APK is signed with a different key. Configure the signing secrets (step 2); after that, uninstall once and every later version will update in place. Export a backup first! |
| Release workflow fails at "Configure release signing" | One of the four secrets is missing or misspelled. |
| `keystore password was incorrect` | `ANDROID_KEYSTORE_PASSWORD` doesn't match the keystore. |
| Reminders arrive late | Some vendors (Xiaomi, Huawei, Samsung…) kill background apps aggressively. Allow MindDrop to run in the background / disable battery optimization for it. See [dontkillmyapp.com](https://dontkillmyapp.com). |
