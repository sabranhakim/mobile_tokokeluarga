class BarangStok {
  final String id;
  final String barangId;
  final String? batchNumber;
  final int stok;
  final DateTime? tglKadaluarsa;
  final DateTime tglMasuk;
  final int hargaBeli;

  BarangStok({
    required this.id,
    required this.barangId,
    this.batchNumber,
    required this.stok,
    this.tglKadaluarsa,
    required this.tglMasuk,
    required this.hargaBeli,
  });

  factory BarangStok.fromJson(Map<String, dynamic> json) {
    return BarangStok(
      id: json['id'].toString(),
      barangId: json['barang_id'].toString(),
      batchNumber: json['batch_number'],
      stok: json['stok'] ?? 0,
      tglKadaluarsa: json['tgl_kadaluarsa'] != null
          ? DateTime.tryParse(json['tgl_kadaluarsa'])
          : null,
      tglMasuk: DateTime.parse(json['tgl_masuk']),
      hargaBeli: json['harga_beli'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barang_id': barangId,
      'batch_number': batchNumber,
      'stok': stok,
      'tgl_kadaluarsa': tglKadaluarsa?.toIso8601String(),
      'tgl_masuk': tglMasuk.toIso8601String(),
      'harga_beli': hargaBeli,
    };
  }
}

class Barang {
  final String id;
  final String kodeBarang;
  final String namaBarang;
  final String satuan;
  final int isi;
  final int stok;
  final int stokMinimal;
  final int? hargaBeli;
  final List<BarangStok> barangStoks;

  Barang({
    required this.id,
    required this.kodeBarang,
    required this.namaBarang,
    required this.satuan,
    this.isi = 1,
    required this.stok,
    this.stokMinimal = 10,
    this.hargaBeli,
    this.barangStoks = const [],
  });

  factory Barang.fromJson(Map<String, dynamic> json) {
    final stoks = (json['barang_stoks'] as List?)
            ?.map((e) => BarangStok.fromJson(e))
            .toList() ??
        [];

    return Barang(
      id: json['id'].toString(),
      kodeBarang: json['kode_barang'],
      namaBarang: json['nama_barang'],
      satuan: json['satuan'],
      isi: json['isi'] ?? 1,
      stok: json['stok'] ?? 0,
      stokMinimal: json['stok_minimal'] ?? 10,
      hargaBeli: json['harga_beli'],
      barangStoks: stoks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kode_barang': kodeBarang,
      'nama_barang': namaBarang,
      'satuan': satuan,
      'isi': isi,
      'stok': stok,
      'stok_minimal': stokMinimal,
      'harga_beli': hargaBeli,
      'barang_stoks': barangStoks.map((e) => e.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Barang && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
