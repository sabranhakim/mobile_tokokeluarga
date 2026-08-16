import 'package:flutter/material.dart';
import '../../data/models/barang_model.dart';
import '../../data/models/barang_keluar_model.dart';
import '../../data/models/supplier_model.dart';
import '../../data/models/penerimaan_barang_model.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../../../core/time_service.dart';
import 'package:intl/intl.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryRepository _repository;

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
  int get totalBarangKeluar => _barangKeluarHistory.length;

  int get penerimaanHariIni {
    final now = TimeService.instance.now();
    return _countToday(_history, (item) => item.tglTerima, now);
  }

  int get penerimaanBulanIni {
    final now = TimeService.instance.now();
    return _countByMonth(_history, (item) => item.tglTerima, now);
  }

  int get barangKeluarHariIni {
    final now = TimeService.instance.now();
    return _countToday(_barangKeluarHistory, (item) => item.tglKeluar, now);
  }

  int get barangKeluarBulanIni {
    final now = TimeService.instance.now();
    return _countByMonth(_barangKeluarHistory, (item) => item.tglKeluar, now);
  }

  // Chart Logic
  Map<String, double> getChartData(String filter) {
    return _buildChartData(_history, filter, (item) => item.tglTerima);
  }

  Map<String, double> getBarangKeluarChartData(String filter) {
    return _buildChartData(
      _barangKeluarHistory,
      filter,
      (item) => item.tglKeluar,
    );
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
      await _repository.submitPenerimaan(penerimaan);

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
      await _repository.submitBarangKeluar(barangKeluar);

      await _loadBarangKeluarHistory();
    } catch (e) {
      debugPrint('❌ Error saat submit barang keluar: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyPenerimaan(
    PenerimaanBarang penerimaan, {
    String? catatan,
  }) async {
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

  int _countToday<T>(
    List<T> items,
    DateTime Function(T item) getDate,
    DateTime now,
  ) {
    return items.where((item) {
      final date = getDate(item);
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  int _countByMonth<T>(
    List<T> items,
    DateTime Function(T item) getDate,
    DateTime now,
  ) {
    return items.where((item) {
      final date = getDate(item);
      return date.year == now.year && date.month == now.month;
    }).length;
  }

  Map<String, double> _buildChartData<T>(
    List<T> items,
    String filter,
    DateTime Function(T item) getDate,
  ) {
    final now = TimeService.instance.now();
    final Map<String, double> data = {};

    if (filter == 'Minggu') {
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final label = DateFormat('E').format(date);
        final count =
            items.where((item) {
              final itemDate = getDate(item);
              return itemDate.year == date.year &&
                  itemDate.month == date.month &&
                  itemDate.day == date.day;
            }).length;
        data[label] = count.toDouble();
      }
    } else if (filter == 'Bulan') {
      for (int i = 3; i >= 0; i--) {
        final start = now.subtract(Duration(days: (i + 1) * 7));
        final end = now.subtract(Duration(days: i * 7));
        final label = 'W${4 - i}';
        final count =
            items.where((item) {
              final itemDate = getDate(item);
              return itemDate.isAfter(start) &&
                  itemDate.isBefore(end.add(const Duration(days: 1)));
            }).length;
        data[label] = count.toDouble();
      }
    }

    return data;
  }
}
