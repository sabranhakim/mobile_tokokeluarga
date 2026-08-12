import 'dart:convert';
import 'detail_penerimaan_model.dart';

class PenerimaanBarang {
  final String? id; // id_penerimaan_barang (integer dari server)
  final String? noTerima;
  final String supplierId;
  final String supplierNama; // Optional, untuk mempermudah tampilan offline
  final int? userId;
  final DateTime tglTerima;
  final List<String> fotoBonPaths; // Lokasi path foto (mendukung multi-foto)
  final String statusVerifikasi; // 'pending' atau 'verified'
  final String? catatanVerifikasi;
  final DateTime? verifiedAt;
  final List<DetailPenerimaan> details;

  PenerimaanBarang({
    this.id,
    this.noTerima,
    required this.supplierId,
    required this.supplierNama,
    this.userId,
    required this.tglTerima,
    this.fotoBonPaths = const [],
    this.statusVerifikasi = 'pending',
    this.catatanVerifikasi,
    this.verifiedAt,
    this.details = const [],
  });

  factory PenerimaanBarang.fromJson(Map<String, dynamic> json) {
    final supplier = json['supplier'] as Map<String, dynamic>?;
    final details = (json['details'] ?? json['detail_penerimaans']) as List?;

    List<String> parsePaths(dynamic value) {
      if (value is List) return value.cast<String>();
      if (value is String) {
        if (value.startsWith('[')) {
          return (jsonDecode(value) as List).cast<String>();
        }
        return value.isNotEmpty ? [value] : [];
      }
      return [];
    }

    return PenerimaanBarang(
      id: json['id_penerimaan_barang']?.toString(),
      noTerima: json['no_terima'],
      supplierId: json['supplier_id'].toString(),
      supplierNama: json['supplier_nama'] ?? supplier?['nama_supplier'] ?? '',
      userId: json['user_id'],
      tglTerima: DateTime.parse(json['tgl_terima']),
      fotoBonPaths: parsePaths(json['foto_bon_path'] ?? json['foto_bon']),
      statusVerifikasi: json['status_verifikasi'] ?? 'pending',
      catatanVerifikasi: json['catatan_verifikasi'],
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'])
          : null,
      details: details?.map((d) => DetailPenerimaan.fromJson(d)).toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_penerimaan_barang': id,
      'no_terima': noTerima,
      'supplier_id': supplierId,
      'supplier_nama': supplierNama,
      'user_id': userId,
      'tgl_terima': tglTerima.toIso8601String(),
      'foto_bon_path': jsonEncode(fotoBonPaths),
      'status_verifikasi': statusVerifikasi,
      'catatan_verifikasi': catatanVerifikasi,
      'verified_at': verifiedAt?.toIso8601String(),
    };
  }

  /// Mengembalikan path foto pertama (untuk backward compatibility)
  String? get fotoBonPath => fotoBonPaths.isNotEmpty ? fotoBonPaths.first : null;
}
