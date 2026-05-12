class Barang {
  final String id;
  final String kodeBarang;
  final String namaBarang;
  final String satuan;
  final int stok;
  final int? hargaBeli;

  Barang({
    required this.id,
    required this.kodeBarang,
    required this.namaBarang,
    required this.satuan,
    required this.stok,
    this.hargaBeli,
  });

  factory Barang.fromJson(Map<String, dynamic> json) {
    return Barang(
      id: json['id'].toString(),
      kodeBarang: json['kode_barang'],
      namaBarang: json['nama_barang'],
      satuan: json['satuan'],
      stok: json['stok'] ?? 0,
      hargaBeli: json['harga_beli'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kode_barang': kodeBarang,
      'nama_barang': namaBarang,
      'satuan': satuan,
      'stok': stok,
      'harga_beli': hargaBeli,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Barang && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
