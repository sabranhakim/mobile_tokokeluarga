import '../models/barang_model.dart';
import '../models/barang_keluar_model.dart';
import '../models/supplier_model.dart';
import '../models/penerimaan_barang_model.dart';

abstract class InventoryRepository {
  // Master Data
  Future<List<Supplier>> getSuppliers();
  Future<List<Barang>> getBarangs();

  // Penerimaan
  Future<List<PenerimaanBarang>> getPenerimaanHistory();
  Future<void> submitPenerimaan(PenerimaanBarang penerimaan);

  // Verifikasi
  Future<void> verifyPenerimaan(PenerimaanBarang penerimaan, {String? catatan});

  // Barang Keluar
  Future<List<BarangKeluar>> getBarangKeluarHistory();
  Future<void> submitBarangKeluar(BarangKeluar barangKeluar);
}
