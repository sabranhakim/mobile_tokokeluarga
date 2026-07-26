import 'detail_barang_keluar_model.dart';

class BarangKeluar {
  final String? id;
  final String? noKeluar;
  final int? userId;
  final DateTime tglKeluar;
  final String? keterangan;
  final int isSynced;
  final List<DetailBarangKeluar> details;

  BarangKeluar({
    this.id,
    this.noKeluar,
    this.userId,
    required this.tglKeluar,
    this.keterangan,
    this.isSynced = 0,
    this.details = const [],
  });

  factory BarangKeluar.fromJson(Map<String, dynamic> json) {
    final details = json['details'] ?? json['detail_barang_keluars'] as List?;

    return BarangKeluar(
      id: json['id']?.toString(),
      noKeluar: json['no_keluar'],
      userId: json['user_id'],
      tglKeluar: DateTime.parse(json['tgl_keluar']),
      keterangan: json['keterangan'],
      isSynced: json['is_synced'] ?? 1,
      details: details?.map((d) => DetailBarangKeluar.fromJson(d)).toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'no_keluar': noKeluar,
      'user_id': userId,
      'tgl_keluar': tglKeluar.toIso8601String(),
      'keterangan': keterangan,
      'is_synced': isSynced,
    };
  }
}
