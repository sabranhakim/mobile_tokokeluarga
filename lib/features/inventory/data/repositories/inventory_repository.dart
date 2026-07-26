import '../models/barang_model.dart';
import '../models/barang_keluar_model.dart';
import '../models/supplier_model.dart';
import '../models/penerimaan_barang_model.dart';

abstract class InventoryRepository {
  // Master Data
  Future<List<Supplier>> getSuppliers();
  Future<List<Barang>> getBarangs();

  // Penerimaan
  Future<void> savePenerimaanLocal(PenerimaanBarang penerimaan, {bool forceSynced = false});
  Future<List<PenerimaanBarang>> getPenerimaanHistoryLocal();
  Future<void> syncPenerimaan(PenerimaanBarang penerimaan);
  Future<int> getUnsyncedCount();

  // Verifikasi
  Future<void> verifyPenerimaanLocal(String id, {String? catatan});
  Future<void> verifyPenerimaan(PenerimaanBarang penerimaan, {String? catatan});

  // Barang Keluar
  Future<void> saveBarangKeluarLocal(BarangKeluar barangKeluar, {bool forceSynced = false});
  Future<List<BarangKeluar>> getBarangKeluarHistoryLocal();
  Future<void> syncBarangKeluar(BarangKeluar barangKeluar);
  Future<int> getUnsyncedBarangKeluarCount();
}
