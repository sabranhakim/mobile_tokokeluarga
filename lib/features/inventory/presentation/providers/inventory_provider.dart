import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/models/barang_model.dart';
import '../../data/models/supplier_model.dart';
import '../../data/models/penerimaan_barang_model.dart';
import '../../data/repositories/inventory_repository.dart';
import 'package:intl/intl.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryRepository _repository;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  InventoryProvider(this._repository) {
    _listenToConnectivity();
  }

  void _listenToConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      ConnectivityResult result,
    ) {
      // Jika terhubung ke internet (WiFi atau Mobile Data)
      if (result != ConnectivityResult.none) {
        debugPrint('Internet terhubung ($result), mencoba sinkronisasi otomatis...');
        syncData();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

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
    final now = DateTime.now();
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
    debugPrint('InventoryProvider: Initializing...');
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadSuppliers(),
        _loadBarangs(),
        _loadHistory(),
        _updateUnsyncedCount(),
      ]);
      debugPrint('InventoryProvider: Data loaded. Suppliers: ${_suppliers.length}, Barangs: ${_barangs.length}');
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
    _history = await _repository.getPenerimaanHistoryLocal();
  }

  Future<void> _updateUnsyncedCount() async {
    _unsyncedCount = await _repository.getUnsyncedCount();
  }

  Future<void> submitPenerimaan(PenerimaanBarang penerimaan) async {
    _isLoading = true;
    notifyListeners();

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      bool isOnline = connectivityResult != ConnectivityResult.none;

      if (isOnline) {
        debugPrint('🌐 Status: ONLINE. Mencoba kirim langsung ke backend...');
        try {
          // Kirim ke server
          await _repository.syncPenerimaan(penerimaan);
          debugPrint('✅ Berhasil terkirim ke backend.');
          
          // Pastikan data juga ada di lokal dengan status SUKSES (untuk riwayat)
          await _repository.savePenerimaanLocal(penerimaan, forceSynced: true);
        } catch (e) {
          debugPrint('⚠️ Gagal kirim langsung (Server error/Timeout). Menyimpan ke lokal untuk nanti: $e');
          await _repository.savePenerimaanLocal(penerimaan, forceSynced: false);
        }
      } else {
        debugPrint('📴 Status: OFFLINE. Menyimpan ke database lokal...');
        await _repository.savePenerimaanLocal(penerimaan, forceSynced: false);
      }
    } catch (e) {
      debugPrint('❌ Error sistem saat submit: $e');
    }

    await _loadHistory();
    await _updateUnsyncedCount();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> syncData() async {
    if (_isSyncing) {
      debugPrint('🔄 Sinkronisasi sedang berjalan, mengabaikan request baru.');
      return;
    }

    // Load data terbaru untuk memastikan list unsynced akurat
    await _loadHistory();
    
    debugPrint('🔍 Memeriksa database lokal...');
    for(var item in _history) {
       debugPrint('📄 Data: ${item.noTerima}, Status Sync: ${item.isSynced}');
    }

    final unsyncedItems = _history.where((e) => e.isSynced == 0).toList();

    if (unsyncedItems.isEmpty) {
      debugPrint('✅ Tidak ada data dengan status PENDING (0) di HP.');
      return;
    }

    debugPrint('🚀 Memulai sinkronisasi ${unsyncedItems.length} data ke server...');
    _isSyncing = true;
    notifyListeners();

    int successCount = 0;
    for (var item in unsyncedItems) {
      try {
        debugPrint('📡 Mengirim data: ${item.noTerima}...');
        await _repository.syncPenerimaan(item);
        successCount++;
        debugPrint('✔️ Berhasil sinkron: ${item.noTerima}');
      } catch (e) {
        debugPrint('❌ Gagal sinkronisasi untuk ${item.noTerima}: $e');
      }
    }

    if (successCount > 0) {
      debugPrint('📊 Berhasil sinkronisasi $successCount data. Memperbarui UI...');
      await _loadHistory();
      await _updateUnsyncedCount();
    }

    _isSyncing = false;
    notifyListeners();
  }
}
