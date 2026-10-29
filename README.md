# Peopleo SSEPD — rebuilt (Flutter)

A clean-room rebuild of the employee attendance app, wired to the **live backend
exactly as the original** (`https://ssepdats-backend.ino-o.com/api/v1`, endpoints
untouched). The proprietary KBY-AI face SDK is replaced with an **open-source
on-device face module**:

- **Google ML Kit** — face detection + a lightweight liveness check (blink / head-pose).
- **TFLite MobileFaceNet** — 112×112 embedding; matching by cosine similarity.

Matching stays on the device, just like the original; only the punch result and
selfie are posted to `/employee-punch`.

## What's included
```
lib/config/api_config.dart     base URL + match threshold
lib/core/api_endpoints.dart    all ~50 live endpoints, verbatim
lib/services/                  dio client, auth/attendance/leave/expense/profile
lib/services/face/             ML Kit detector, TFLite recognizer, local template store
lib/screens/                   login, dashboard, register-face, punch in/out, leave, expense, profile
```

## Run it
This repo carries the Dart source and Android manifest/permissions. Generate the
platform folders once, then run:

```bash
# 1. add the face model
#    put a MobileFaceNet model at: assets/models/mobilefacenet.tflite

# 2. generate android/ios platform scaffolding around this source
flutter create .

# 3. deps + run on a device (camera + GPS need real hardware)
flutter pub get
flutter run
```

`flutter create .` keeps existing `lib/`, `pubspec.yaml` and the custom
`AndroidManifest.xml` permissions.

## Face model
Drop `mobilefacenet.tflite` (112×112 input, 128/192-d output) into
`assets/models/`. Without it the app still runs: detection + liveness work and
recognition reports "model not loaded". See `assets/models/README.txt`.

## Notes / limits
- First use: **Register Face** once (stores a local embedding), then Punch In/Out verifies against it.
- Response field names (`token`, `status`, `message`, `data`) are read defensively; adjust
  the small parsers in `services/*` if your backend wording differs.
- Endpoints are reproduced verbatim and must not be renamed.
- Dynamic/runtime fields (exact request bodies) were reconstructed from the original
  binary's strings; tweak payload keys in the services if the server expects different ones.

## Getting an installable APK

This source was prepared in an ARM64 Linux environment, which cannot run the
Android/Flutter build toolchain (the Flutter SDK and Android `aapt2` are x86-64
only), so the `.apk` has to be compiled elsewhere. Two easy ways:

### Option A — GitHub (no local setup)
1. Create a new GitHub repo and push this project to it.
2. The included workflow `.github/workflows/build-apk.yml` runs automatically.
3. Open the run under the **Actions** tab, download the **peopleo-clone-apk**
   artifact, and install `app-debug.apk` on your phone (enable "install unknown apps").

### Option B — local machine (with Flutter installed)
```bash
flutter create --org com.oasystspl --project-name peopleo_clone .
flutter pub get
flutter build apk --debug
# APK: build/app/outputs/flutter-apk/app-debug.apk
```
