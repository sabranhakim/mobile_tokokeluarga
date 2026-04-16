class DetailPenerimaan {
  final int? id;
  final int? penerimaanBarangId;
  final int barangId;
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
    return DetailPenerimaan(
      id: json['id'],
      penerimaanBarangId: json['penerimaan_barang_id'],
      barangId: json['barang_id'],
      barangNama: json['barang_nama'] ?? '',
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
