class DetailBarangKeluar {
  final String? id;
  final String? barangKeluarId;
  final String barangId;
  final String barangNama;
  final String? barangSatuan;
  final int barangIsi;
  final int jumlah;

  DetailBarangKeluar({
    this.id,
    this.barangKeluarId,
    required this.barangId,
    required this.barangNama,
    this.barangSatuan,
    this.barangIsi = 1,
    required this.jumlah,
  });

  factory DetailBarangKeluar.fromJson(Map<String, dynamic> json) {
    final barang = json['barang'] as Map<String, dynamic>?;

    return DetailBarangKeluar(
      id: json['id']?.toString(),
      barangKeluarId: json['barang_keluar_id']?.toString(),
      barangId: json['barang_id'].toString(),
      barangNama: json['barang_nama'] ?? barang?['nama_barang'] ?? '',
      barangSatuan: json['barang_satuan'] ?? barang?['satuan'],
      barangIsi: json['barang_isi'] ?? barang?['isi'] ?? 1,
      jumlah: json['jumlah'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barang_keluar_id': barangKeluarId,
      'barang_id': barangId,
      'barang_nama': barangNama,
      'barang_satuan': barangSatuan,
      'barang_isi': barangIsi,
      'jumlah': jumlah,
    };
  }
}
