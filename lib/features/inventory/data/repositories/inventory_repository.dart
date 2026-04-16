import '../models/barang_model.dart';
import '../models/supplier_model.dart';
import '../models/penerimaan_barang_model.dart';

abstract class InventoryRepository {
  // Master Data
  Future<List<Supplier>> getSuppliers();
  Future<List<Barang>> getBarangs();

  // Penerimaan
  Future<void> savePenerimaanLocal(PenerimaanBarang penerimaan);
  Future<List<PenerimaanBarang>> getPenerimaanHistoryLocal();
  Future<void> syncPenerimaan(PenerimaanBarang penerimaan);
  Future<int> getUnsyncedCount();
}
