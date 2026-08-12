class Supplier {
  final String id;
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
      id: json['id_supplier'].toString(),
      namaSupplier: json['nama_supplier'],
      alamat: json['alamat'],
      noTelp: json['no_telp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_supplier': id,
      'nama_supplier': namaSupplier,
      'alamat': alamat,
      'no_telp': noTelp,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Supplier && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
