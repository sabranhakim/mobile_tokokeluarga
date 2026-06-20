class DetailPenerimaan {
  final String? id;
  final String? penerimaanBarangId;
  final String barangId;
  final String barangNama; // Optional, mempermudah tampilan offline
  final int jumlah;

  DetailPenerimaan({
    this.id,
    this.penerimaanBarangId,
    required this.barangId,
    required this.barangNama,
    required this.jumlah,
  });

  factory DetailPenerimaan.fromJson(Map<String, dynamic> json) {
    final barang = json['barang'] as Map<String, dynamic>?;

    return DetailPenerimaan(
      id: json['id']?.toString(),
      penerimaanBarangId: json['penerimaan_barang_id']?.toString(),
      barangId: json['barang_id'].toString(),
      barangNama: json['barang_nama'] ?? barang?['nama_barang'] ?? '',
      jumlah: json['jumlah'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'penerimaan_barang_id': penerimaanBarangId,
      'barang_id': barangId,
      'barang_nama': barangNama,
      'jumlah': jumlah,
    };
  }
}
