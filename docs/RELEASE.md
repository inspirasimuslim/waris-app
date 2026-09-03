# Keluaran — WARIS

## Build APK (Fasa 5)

```bash
dart pub get
dart pub global run melos run test:all      # mesti 100% hijau SEBELUM build
cd app
flutter build apk --release                 # APK universal
flutter build apk --split-per-abi --release # per-ABI (saiz kecil)
flutter build appbundle --release           # untuk Play Store (Fasa 8)
```

Output: `app/build/app/outputs/flutter-apk/app-release.apk`

### Build pertama (2026-09-03)

- `app-release.apk` **55.2 MB** (universal — semua ABI + enjin Flutter).
- `--split-per-abi` (di bawah sasaran 40MB SPEC 5.6):
  - `app-armeabi-v7a-release.apk` **16.7 MB**
  - `app-arm64-v8a-release.apk` **19.2 MB**  ← untuk kebanyakan peranti moden
  - `app-x86_64-release.apk` **20.6 MB** (emulator)
- Ditandatangani dengan keystore ujian: `CN=WARIS Test, OU=Sakura Digital`
  (SHA-256 `9b3c1e12…`). Disahkan dengan `apksigner verify`.
- `melos run test:all` — 224 ujian lulus sebelum build.
- MaterialIcons tree-shaken 99.9%.

## Penandatanganan

- `app/waris-release.jks` + `app/android/key.properties` — **kedua-duanya dalam
  `.gitignore`**. Jangan sekali-kali commit.
- Keystore semasa ialah **KEYSTORE UJIAN** (DECISIONS D-022). Sebelum keluaran
  Play Store, jana keystore rasmi dan simpan salinannya di **dua lokasi
  berasingan** (pengurus kata laluan + storan luar talian terenkripsi).
  Kehilangan keystore = tidak boleh kemas kini app di Play Store selamanya.

## Senarai semak sebelum keluaran (SPEC 5.6)

- [ ] Ikon app pada semua ketumpatan (`flutter_launcher_icons`) — **BELUM (perlu seni ikon)**
- [ ] Skrin splash (`flutter_native_splash`) — **BELUM**
- [x] Nama app "WARIS" dalam manifest
- [x] `versionCode` = 1, `versionName` = 0.1.0
- [ ] Diuji mod keluaran pada peranti sebenar (bukan debug) — **tindakan pemilik**
- [ ] Diuji Android 6/10/14, telefon 5" + tablet — **tindakan pemilik**
- [x] Tiada `print()` dalam laluan keluaran (disemak; tiada dalam lib app)
- [ ] Saiz APK < 40MB — semak selepas build
- [ ] Ujian pasang bersih: pasang → bina keluarga → tutup → buka semula → data ada

## Kebenaran (SPEC 5.4)

`INTERNET`, `USE_BIOMETRIC`, `CAMERA`, `READ_MEDIA_IMAGES` sahaja. CAMERA &
READ_MEDIA_IMAGES diminta runtime bila foto avatar digunakan. Tiada lokasi,
kenalan, telefon, SMS, storan penuh.

## Edaran ujian (SPEC 5.7)

10–20 penguji: keluarga terdekat, 2–3 orang berpengetahuan agama, 2–3 bukan
teknikal. Borang maklum balas — soalan wajib termasuk *"Ada apa-apa yang terasa
tidak selesa atau tidak menghormati?"*
