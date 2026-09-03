# WARIS — peraturan ProGuard/R8 untuk build keluaran.

# Flutter enjin & embedding
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# sqlite3 (drift/sqlite3 — digunakan kemudian; selamat disimpan sekarang)
-keep class org.sqlite.** { *; }

# Biometrik
-keep class androidx.biometric.** { *; }
