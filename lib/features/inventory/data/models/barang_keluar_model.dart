import 'detail_barang_keluar_model.dart';

class BarangKeluar {
  final String? id;
  final String? noKeluar;
  final int? userId;
  final DateTime tglKeluar;
  final String? jenisKeluar;
  final String? keterangan;
  final List<DetailBarangKeluar> details;

  BarangKeluar({
    this.id,
    this.noKeluar,
    this.userId,
    required this.tglKeluar,
    this.jenisKeluar = 'penjualan',
    this.keterangan,
    this.details = const [],
  });

  factory BarangKeluar.fromJson(Map<String, dynamic> json) {
    final details = (json['details'] ?? json['detail_barang_keluars']) as List?;

    return BarangKeluar(
      id: json['id_barang_keluar']?.toString(),
      noKeluar: json['no_keluar'],
      userId: json['user_id'],
      tglKeluar: DateTime.parse(json['tgl_keluar']),
      jenisKeluar: json['jenis_keluar'] ?? 'penjualan',
      keterangan: json['keterangan'],
      details: details?.map((d) => DetailBarangKeluar.fromJson(d)).toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_barang_keluar': id,
      'no_keluar': noKeluar,
      'user_id': userId,
      'tgl_keluar': tglKeluar.toIso8601String(),
      'jenis_keluar': jenisKeluar ?? 'penjualan',
      'keterangan': keterangan,
    };
  }
}
