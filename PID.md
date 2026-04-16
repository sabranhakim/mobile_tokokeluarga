Mantap! Karena Backend Laravel kita sudah siap dengan **Service Layer** dan **Cloudinary**, sekarang kita fokus membangun "si ujung tombak" yaitu aplikasi **Flutter**.

Sesuai permintaanmu, aplikasi ini akan memiliki 3 halaman utama dengan fitur **Offline-First** (menggunakan SQLite) agar tetap bisa bekerja di gudang yang minim sinyal. Berikut adalah **PID (Project Implementation Document)** untuk tahap Mobile.

---

## **PID: Pengembangan Mobile App Staf Gudang (Flutter)**

### **1. Informasi Proyek**
* **Nama Aplikasi:** GrosirKue Mobile (Staf Gudang)
* **Teknologi Utama:** Flutter (Dart), SQLite (sqflite), Provider/Bloc (State Management), Dio (API Client).
* **Target Device:** Android (Minimum SDK 21 / Android 5.0).

---

### **2. Arsitektur Data & Flow**
Aplikasi ini akan menggunakan pola **Repository Pattern** untuk menangani transisi data dari Lokal ke API.

* **Offline Mode:** Data input disimpan ke SQLite + Foto disimpan di folder `App Documents`.
* **Sync Mode:** Aplikasi mendeteksi internet -> Kirim data JSON & File Multipart (Foto) ke API Laravel -> Update status di SQLite menjadi `is_synced = 1`.

---

### **3. Struktur Halaman (Sitemaps)**

| Halaman | Deskripsi Fitur | Elemen UI Utama |
| :--- | :--- | :--- |
| **Dashboard** | Ringkasan stok & status sinkronisasi. | Card total barang, status koneksi, tombol "Sync Now". |
| **Input Barang** | Form utama penerimaan barang dari supplier. | Dropdown Supplier, Input Barang (dynamic list), Camera Picker (Foto Bon). |
| **History** | Daftar transaksi yang sudah diinput. | List item dengan indikator warna (Tersinkron/Belum Tersinkron). |

---

### **4. Tech Stack & Dependencies**
Tambahkan ini di `pubspec.yaml` kamu:
```yaml
dependencies:
  dio: ^5.4.0              # Untuk request API ke Laravel
  sqflite: ^2.3.0          # Database lokal untuk mode offline
  path_provider: ^2.1.2    # Mengatur lokasi penyimpanan foto
  image_picker: ^1.0.7     # Mengambil foto bon via Kamera
  connectivity_plus: ^5.0.2 # Mendeteksi status internet
  intl: ^0.19.0            # Formatter tanggal & mata uang
```

---

### **5. Roadmap Implementasi (Langkah Kerja)**

#### **Tahap 1: Database Helper (SQLite)**
Membuat skema tabel lokal yang mirip dengan database Laravel agar sinkronisasi mudah.
* Tabel `suppliers` (Cache dari API)
* Tabel `barangs` (Cache dari API)
* Tabel `penerimaan_offline` (Menyimpan input saat offline)

#### **Tahap 2: UI Development**
1.  **Dashboard:** Menampilkan jumlah antrian data yang belum tersinkron.
2.  **Input Form:** Menggunakan `Form` widget. Fitur terpenting adalah fungsi **Camera Capture** untuk foto bon.
3.  **History:** Menggunakan `ListView.builder` dengan *pull-to-refresh*.

#### **Tahap 3: Logic Sinkronisasi (The "Bridge")**
Membuat fungsi `uploadData()` yang mengirimkan file foto ke API Laravel kita yang sudah terintegrasi dengan Cloudinary.

---

### **6. Struktur Folder yang Disarankan**
```text
lib/
├── core/               # Error handling, API client, theme, constant
├── features/           # Dibagi per Fitur (Standard Modular)
│   ├── inventory/      # Fitur Inventoris
│   │   ├── data/       # Models, Repositories (API & SQLite)
│   │   ├── domain/     # Entities, Use Cases (Logika Bisnis)
│   │   └── presentation/ # Widgets, BLoC/Provider
│   └── auth/           # Fitur Login
└── main.dart
```

---

### **Poin Plus untuk TA kamu:**
Saat sidang, kamu bisa mendemokan fitur **"Reliability"**:
1. Matikan WiFi/Data di HP.
2. Input data barang masuk + Foto bon.
3. Tunjukkan data masuk ke **History** dengan status "Pending/Belum Sinkron".
4. Nyalakan WiFi.
5. Tekan tombol **Sync** -> Data terkirim ke Laravel -> Foto muncul di Cloudinary -> Status di HP berubah jadi "Berhasil".

**Langkah Selanjutnya:**
Apakah kamu ingin saya buatkan **Script SQLite Helper** awal untuk menyimpan data `penerimaan` secara offline ini?