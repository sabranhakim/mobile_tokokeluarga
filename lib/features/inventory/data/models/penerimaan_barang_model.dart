import 'detail_penerimaan_model.dart';

class PenerimaanBarang {
  final int? id; // ID di database lokal (auto-increment) atau API
  final String? noTerima;
  final int supplierId;
  final String supplierNama; // Optional, untuk mempermudah tampilan offline
  final int? userId;
  final DateTime tglTerima;
  final String? fotoBonPath; // Lokasi path foto lokal
  final int isSynced; // 0: Pending, 1: Berhasil
  final List<DetailPenerimaan> details;

  PenerimaanBarang({
    this.id,
    this.noTerima,
    required this.supplierId,
    required this.supplierNama,
    this.userId,
    required this.tglTerima,
    this.fotoBonPath,
    this.isSynced = 0,
    this.details = const [],
  });

  factory PenerimaanBarang.fromJson(Map<String, dynamic> json) {
    return PenerimaanBarang(
      id: json['id'],
      noTerima: json['no_terima'],
      supplierId: json['supplier_id'],
      supplierNama: json['supplier_nama'] ?? '',
      userId: json['user_id'],
      tglTerima: DateTime.parse(json['tgl_terima']),
      fotoBonPath: json['foto_bon'], // Jika dari API, ini adalah URL
      isSynced: json['is_synced'] ?? 1,
      details: (json['details'] as List?)
              ?.map((d) => DetailPenerimaan.fromJson(d))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'no_terima': noTerima,
      'supplier_id': supplierId,
      'supplier_nama': supplierNama,
      'user_id': userId,
      'tgl_terima': tglTerima.toIso8601String(),
      'foto_bon_path': fotoBonPath,
      'is_synced': isSynced,
    };
  }
}
