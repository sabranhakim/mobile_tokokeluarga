import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/models/barang_model.dart';
import '../../data/models/supplier_model.dart';
import '../../data/models/penerimaan_barang_model.dart';
import '../../data/repositories/inventory_repository.dart';
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

  int _unsyncedCount = 0;
  int get unsyncedCount => _unsyncedCount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  // Summary Getters
  int get totalBarang => _barangs.length;
  int get totalSupplier => _suppliers.length;
  int get totalPenerimaan => _history.length;
  
  int get penerimaanHariIni {
    final now = DateTime.now();
    return _history.where((e) => 
      e.tglTerima.year == now.year && 
      e.tglTerima.month == now.month && 
      e.tglTerima.day == now.day
    ).length;
  }

  // Chart Logic
  Map<String, double> getChartData(String filter) {
    final now = DateTime.now();
    Map<String, double> data = {};

    if (filter == 'Minggu') {
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final label = DateFormat('E').format(date);
        final count = _history.where((e) => 
          e.tglTerima.year == date.year && 
          e.tglTerima.month == date.month && 
          e.tglTerima.day == date.day
        ).length;
        data[label] = count.toDouble();
      }
    } else if (filter == 'Bulan') {
      for (int i = 3; i >= 0; i--) {
        final start = now.subtract(Duration(days: (i + 1) * 7));
        final end = now.subtract(Duration(days: i * 7));
        final label = 'W\${4-i}';
        final count = _history.where((e) => 
          e.tglTerima.isAfter(start) && e.tglTerima.isBefore(end.add(const Duration(days: 1)))
        ).length;
        data[label] = count.toDouble();
      }
    } else if (filter == 'Tahun') {
      for (int i = 11; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final label = DateFormat('MMM').format(monthDate);
        final count = _history.where((e) => 
          e.tglTerima.year == monthDate.year && 
          e.tglTerima.month == monthDate.month
        ).length;
        data[label] = count.toDouble();
      }
    }
    return data;
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      _loadSuppliers(),
      _loadBarangs(),
      _loadHistory(),
      _updateUnsyncedCount(),
    ]);

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
    _history = await _repository.getPenerimaanHistoryLocal();
  }

  Future<void> _updateUnsyncedCount() async {
    _unsyncedCount = await _repository.getUnsyncedCount();
  }

  Future<void> saveOffline(PenerimaanBarang penerimaan) async {
    await _repository.savePenerimaanLocal(penerimaan);
    await _loadHistory();
    await _updateUnsyncedCount();
    notifyListeners();
  }

  Future<void> syncData() async {
    if (_isSyncing) return;

    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
       // Optional: Notify UI about no connection
       return;
    }

    final unsyncedItems = _history.where((e) => e.isSynced == 0).toList();
    if (unsyncedItems.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    int successCount = 0;
    for (var item in unsyncedItems) {
      try {
        await _repository.syncPenerimaan(item);
        successCount++;
      } catch (e) {
        print('Failed to sync item \${item.noTerima}: \$e');
      }
    }

    if (successCount > 0) {
      await _loadHistory();
      await _updateUnsyncedCount();
    }

    _isSyncing = false;
    notifyListeners();
  }
}
