class Supplier {
  final int id;
  final String namaSupplier;
  final String? alamat;
  final String? noTelp;

  Supplier({
    required this.id,
    required this.namaSupplier,
    this.alamat,
    this.noTelp,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'],
      namaSupplier: json['nama_supplier'],
      alamat: json['alamat'],
      noTelp: json['no_telp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_supplier': namaSupplier,
      'alamat': alamat,
      'no_telp': noTelp,
    };
  }
}
