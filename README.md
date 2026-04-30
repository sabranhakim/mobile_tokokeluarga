# Toko Keluarga - Mobile Application

Aplikasi mobile untuk staf lapangan Toko Keluarga untuk memudahkan proses penerimaan barang dan manajemen stok secara real-time.

## Fitur Utama

- **Penerimaan Barang**: Input barang masuk langsung dari gudang.
- **Kamera & Scan**: Ambil foto nota/bon fisik sebagai bukti penerimaan.
- **Mode Offline**: Tetap bisa input data meskipun tanpa koneksi internet (menggunakan SQLite).
- **Sinkronisasi Otomatis**: Data akan terkirim ke server backend secara otomatis saat koneksi tersedia.
- **Dashboard Ringkas**: Lihat statistik stok dan aktivitas terbaru.

## Tech Stack

- **Framework**: Flutter (Dart)
- **API Client**: Dio
- **Local Database**: SQFlite (SQLite)
- **State Management**: Provider
- **Secure Storage**: Flutter Secure Storage (untuk token autentikasi)
- **Image Handling**: Camera & Image Picker

## Persyaratan Sistem

- Flutter SDK (^3.7.2)
- Android Studio / VS Code (dengan Flutter extension)
- Perangkat Android/iOS atau Emulator

## Cara Instalasi

1.  **Clone Repository**
    ```bash
    git clone [repository-url]
    cd mobile_tokokeluarga
    ```

2.  **Instal Dependensi**
    ```bash
    flutter pub get
    ```

3.  **Jalankan Aplikasi**
    ```bash
    flutter run
    ```

## Pengujian
```bash
flutter test
```

## Lisensi

Sistem ini dikembangkan untuk keperluan internal Toko Keluarga.
