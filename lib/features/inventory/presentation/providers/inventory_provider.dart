import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/barang_model.dart';
import '../../data/models/supplier_model.dart';
import '../../data/models/penerimaan_barang_model.dart';
import '../../data/repositories/inventory_repository.dart';
import 'package:intl/intl.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryRepository _repository;
  final _uuid = const Uuid();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  InventoryProvider(this._repository) {
    _listenToConnectivity();
  }

  void _listenToConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final online = results.isNotEmpty && !results.contains(ConnectivityResult.none);
      if (online != _isOnline) {
        _isOnline = online;
        notifyListeners();
      }
      if (online) {
        debugPrint(
          '🌐 Internet terdeteksi ($results). Mencoba sinkronisasi data pending...',
        );
        syncData();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  bool _isOnline = true;
  bool get isOnline => _isOnline;

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
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadSuppliers(),
        _loadBarangs(),
        _loadHistory(),
        _updateUnsyncedCount(),
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
    _history = await _repository.getPenerimaanHistoryLocal();
  }

  Future<void> _updateUnsyncedCount() async {
    _unsyncedCount = await _repository.getUnsyncedCount();
  }

  Future<void> submitPenerimaan(PenerimaanBarang penerimaan) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Generate UUID sebelum simpan & sync agar idempotency berfungsi
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

      // 1. SELALU simpan ke lokal dulu (Offline-First)
      debugPrint('💾 Menyimpan data ke database lokal (Status: PENDING)...');
      await _repository.savePenerimaanLocal(penerimaanWithId, forceSynced: false);

      // Update UI history agar data langsung muncul di daftar
      await _loadHistory();
      await _updateUnsyncedCount();
      _isLoading = false;
      notifyListeners();

      // 2. Coba kirim ke backend di background (Tanpa cek koneksi eksplisit)
      debugPrint('🛰️ Mencoba sinkronisasi background...');
      _backgroundSyncItem(penerimaanWithId);
    } catch (e) {
      debugPrint('❌ Error sistem saat simpan lokal: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi internal untuk mencoba sync satu item tanpa mengganggu alur UI utama
  Future<void> _backgroundSyncItem(PenerimaanBarang penerimaan) async {
    try {
      // Repository syncPenerimaan sudah memiliki timeout internal di Dio (ApiClient)
      await _repository.syncPenerimaan(penerimaan);
      debugPrint('✅ Background Sync Berhasil: ${penerimaan.noTerima}');

      // Update data lokal jika berhasil
      await _loadHistory();
      await _updateUnsyncedCount();
      notifyListeners();
    } catch (e) {
      debugPrint(
        'ℹ️ Background Sync Tertunda (Offline/Server Error): ${penerimaan.noTerima}',
      );
      // Tidak perlu throw, data sudah aman di lokal dengan status 0
    }
  }

  Future<void> syncData() async {
    if (_isSyncing) return;

    await _loadHistory();
    final unsyncedItems = _history.where((e) => e.isSynced == 0).toList();

    if (unsyncedItems.isEmpty) {
      debugPrint('✅ Tidak ada data pending.');
      return;
    }

    debugPrint(
      '🚀 Sinkronisasi masal dimulai (${unsyncedItems.length} data)...',
    );
    _isSyncing = true;
    notifyListeners();

    int successCount = 0;
    for (var item in unsyncedItems) {
      try {
        await _repository.syncPenerimaan(item);
        successCount++;
        debugPrint('✔️ Berhasil: ${item.noTerima}');
      } catch (e) {
        debugPrint('❌ Gagal: ${item.noTerima}. Akan dicoba lagi nanti.');
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
