import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/barang_model.dart';
import '../../data/models/barang_keluar_model.dart';
import '../../data/models/supplier_model.dart';
import '../../data/models/penerimaan_barang_model.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../../../core/time_service.dart';
import 'package:intl/intl.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryRepository _repository;
  final _uuid = const Uuid();

  InventoryProvider(this._repository);

  List<Supplier> _suppliers = [];
  List<Supplier> get suppliers => _suppliers;

  List<Barang> _barangs = [];
  List<Barang> get barangs => _barangs;

  List<PenerimaanBarang> _history = [];
  List<PenerimaanBarang> get history => _history;

  List<BarangKeluar> _barangKeluarHistory = [];
  List<BarangKeluar> get barangKeluarHistory => _barangKeluarHistory;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Summary Getters
  int get totalBarang => _barangs.length;
  int get totalStok => _barangs.fold(0, (total, barang) => total + barang.stok);
  int get stokKritis => _barangs.where((barang) => barang.stok <= 0).length;
  int get stokRendah =>
      _barangs
          .where(
            (barang) => barang.stok > 0 && barang.stok <= barang.stokMinimal,
          )
          .length;
  int get totalSupplier => _suppliers.length;
  int get totalPenerimaan => _history.length;

  int get penerimaanHariIni {
    final now = TimeService.instance.now();
    return _history
        .where(
          (e) =>
              e.tglTerima.year == now.year &&
              e.tglTerima.month == now.month &&
              e.tglTerima.day == now.day,
        )
        .length;
  }

  // Chart Logic
  Map<String, double> getChartData(String filter) {
    final now = TimeService.instance.now();
    Map<String, double> data = {};

    if (filter == 'Minggu') {
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final label = DateFormat('E').format(date);
        final count =
            _history
                .where(
                  (e) =>
                      e.tglTerima.year == date.year &&
                      e.tglTerima.month == date.month &&
                      e.tglTerima.day == date.day,
                )
                .length;
        data[label] = count.toDouble();
      }
    } else if (filter == 'Bulan') {
      for (int i = 3; i >= 0; i--) {
        final start = now.subtract(Duration(days: (i + 1) * 7));
        final end = now.subtract(Duration(days: i * 7));
        final label = 'W${4 - i}';
        final count =
            _history
                .where(
                  (e) =>
                      e.tglTerima.isAfter(start) &&
                      e.tglTerima.isBefore(end.add(const Duration(days: 1))),
                )
                .length;
        data[label] = count.toDouble();
      }
    } else if (filter == 'Tahun') {
      for (int i = 11; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final label = DateFormat('MMM').format(monthDate);
        final count =
            _history
                .where(
                  (e) =>
                      e.tglTerima.year == monthDate.year &&
                      e.tglTerima.month == monthDate.month,
                )
                .length;
        data[label] = count.toDouble();
      }
    }
    return data;
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadSuppliers(),
        _loadBarangs(),
        _loadHistory(),
        _loadBarangKeluarHistory(),
      ]);
    } catch (e) {
      debugPrint('InventoryProvider: Error during initialization: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadSuppliers() async {
    _suppliers = await _repository.getSuppliers();
  }

  Future<void> _loadBarangs() async {
    _barangs = await _repository.getBarangs();
  }

  Future<void> _loadHistory() async {
    _history = await _repository.getPenerimaanHistory();
  }

  Future<void> _loadBarangKeluarHistory() async {
    _barangKeluarHistory = await _repository.getBarangKeluarHistory();
  }

  Future<void> submitPenerimaan(PenerimaanBarang penerimaan) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Generate UUID sebelum submit agar idempotency berfungsi
      final receiptId = penerimaan.id ?? _uuid.v4();
      final penerimaanWithId = PenerimaanBarang(
        id: receiptId,
        noTerima: penerimaan.noTerima,
        supplierId: penerimaan.supplierId,
        supplierNama: penerimaan.supplierNama,
        tglTerima: penerimaan.tglTerima,
        fotoBonPaths: penerimaan.fotoBonPaths,
        details: penerimaan.details,
      );

      await _repository.submitPenerimaan(penerimaanWithId);

      // Update history setelah berhasil disimpan ke server
      await _loadHistory();
    } catch (e) {
      debugPrint('❌ Error saat submit penerimaan: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitBarangKeluar(BarangKeluar barangKeluar) async {
    _isLoading = true;
    notifyListeners();

    try {
      final id = barangKeluar.id ?? _uuid.v4();
      final barangKeluarWithId = BarangKeluar(
        id: id,
        noKeluar: barangKeluar.noKeluar,
        tglKeluar: barangKeluar.tglKeluar,
        keterangan: barangKeluar.keterangan,
        details: barangKeluar.details,
      );

      await _repository.submitBarangKeluar(barangKeluarWithId);

      await _loadBarangKeluarHistory();
    } catch (e) {
      debugPrint('❌ Error saat submit barang keluar: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyPenerimaan(PenerimaanBarang penerimaan, {String? catatan}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.verifyPenerimaan(penerimaan, catatan: catatan);
      debugPrint('✅ Verifikasi berhasil: ${penerimaan.noTerima}');
      await _loadHistory();
    } catch (e) {
      debugPrint('❌ Error saat verifikasi: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
