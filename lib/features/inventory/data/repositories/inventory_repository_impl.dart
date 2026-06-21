import 'dart:developer' as developer;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/api_client.dart';
import '../../../../core/database_helper.dart';
import '../models/barang_model.dart';
import '../models/detail_penerimaan_model.dart';
import '../models/penerimaan_barang_model.dart';
import '../models/supplier_model.dart';
import 'inventory_repository.dart';
import 'package:intl/intl.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final ApiClient _apiClient = ApiClient.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final _uuid = const Uuid();

  @override
  Future<List<Supplier>> getSuppliers() async {
    try {
      final response = await _apiClient.dio.get('/suppliers');
      final List data = response.data['data'];
      final suppliers = data.map((e) => Supplier.fromJson(e)).toList();

      final db = await _dbHelper.database;
      await db.delete('suppliers');
      for (var s in suppliers) {
        await db.insert('suppliers', s.toJson());
      }
      return suppliers;
    } catch (e) {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('suppliers');
      return maps.map((e) => Supplier.fromJson(e)).toList();
    }
  }

  @override
  Future<List<Barang>> getBarangs() async {
    try {
      final response = await _apiClient.dio.get('/barangs');
      final List data = response.data['data'];
      final barangs = data.map((e) => Barang.fromJson(e)).toList();

      final db = await _dbHelper.database;
      await db.delete('barangs');
      for (var b in barangs) {
        await db.insert('barangs', b.toJson());
      }
      return barangs;
    } catch (e) {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('barangs');
      return maps.map((e) => Barang.fromJson(e)).toList();
    }
  }

  @override
  Future<void> savePenerimaanLocal(PenerimaanBarang penerimaan, {bool forceSynced = false}) async {
    final db = await _dbHelper.database;

    String receiptId = penerimaan.id ?? _uuid.v4();
    String noTerima = penerimaan.noTerima ?? 'TRX-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}';

    Map<String, dynamic> data = penerimaan.toMap();
    data['id'] = receiptId;
    data['no_terima'] = noTerima;
    
    // Jika forceSynced true, set status ke 1 (Sukses)
    if (forceSynced) {
      data['is_synced'] = 1;
    }

    await db.transaction((txn) async {
      // Use conflictAlgorithm to replace in case it already exists somehow
      await txn.insert('penerimaan_barang', data, conflictAlgorithm: ConflictAlgorithm.replace);
      
      // Delete old details if replacing
      await txn.delete('detail_penerimaan', where: 'penerimaan_barang_id = ?', whereArgs: [receiptId]);
      
      for (var detail in penerimaan.details) {
        String detailId = detail.id ?? _uuid.v4();
        await txn.insert('detail_penerimaan', {
          ...detail.toMap(),
          'id': detailId,
          'penerimaan_barang_id': receiptId,
        });
      }
    });
  }

  @override
  Future<List<PenerimaanBarang>> getPenerimaanHistoryLocal() async {
    List<PenerimaanBarang> apiHistory = [];

    // 1. Ambil data dari API
    try {
      final response = await _apiClient.dio.get('/penerimaan-barang');
      if (response.statusCode == 200) {
        final List data = response.data['data'];
        apiHistory = data.map((e) => PenerimaanBarang.fromJson(e)).toList();
        developer.log('Fetched ${apiHistory.length} items from API', name: 'InventoryRepository');
      }
    } catch (e) {
      developer.log('Fetch History API Error: $e', name: 'InventoryRepository');
    }

    // 2. Ambil data dari Database Lokal yang BELUM sinkron
    final db = await _dbHelper.database;
    List<PenerimaanBarang> localUnsynced = [];
    try {
      final List<Map<String, dynamic>> localMaps = await db.query(
        'penerimaan_barang',
        where: 'is_synced = 0',
        orderBy: 'tgl_terima DESC',
      );

      for (var map in localMaps) {
        final detailsMap = await db.query(
          'detail_penerimaan',
          where: 'penerimaan_barang_id = ?',
          whereArgs: [map['id']],
        );

        final details = detailsMap.map((d) => DetailPenerimaan.fromJson(d)).toList();
        localUnsynced.add(PenerimaanBarang.fromJson({...map, 'details': details, 'is_synced': 0}));
      }
      developer.log('Found ${localUnsynced.length} unsynced items in Local DB', name: 'InventoryRepository');
    } catch (e) {
      developer.log('Error loading local unsynced history: $e', name: 'InventoryRepository');
    }

    // Gabungkan: Data lokal yang belum sinkron diletakkan paling atas
    return [...localUnsynced, ...apiHistory];
  }

  @override
  Future<int> getUnsyncedCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM penerimaan_barang WHERE is_synced = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<void> syncPenerimaan(PenerimaanBarang penerimaan) async {
    XFile? compressedFile;
    try {
      Map<String, dynamic> formDataMap = {
        'id': penerimaan.id,
        'no_terima': penerimaan.noTerima,
        'supplier_id': penerimaan.supplierId,
        'tgl_terima': DateFormat('yyyy-MM-dd').format(penerimaan.tglTerima),
      };

      for (int i = 0; i < penerimaan.details.length; i++) {
        final detail = penerimaan.details[i];
        formDataMap['items[$i][id]'] = detail.id ?? _uuid.v4();
        formDataMap['items[$i][barang_id]'] = detail.barangId;
        formDataMap['items[$i][jumlah]'] = detail.jumlah;
      }

      if (penerimaan.fotoBonPath != null && penerimaan.fotoBonPath!.isNotEmpty) {
        final File file = File(penerimaan.fotoBonPath!);
        if (await file.exists()) {
          final String targetPath = '${file.parent.path}/compressed_${penerimaan.noTerima}.jpg';
          compressedFile = await FlutterImageCompress.compressAndGetFile(
            file.absolute.path,
            targetPath,
            quality: 70,
          );

          formDataMap['foto_bon'] = await MultipartFile.fromFile(
            compressedFile?.path ?? penerimaan.fotoBonPath!,
            filename: 'bon.jpg',
          );
        }
      }

      developer.log('Syncing ${penerimaan.noTerima} to server...', name: 'InventoryRepository');
      final response = await _apiClient.dio.post('/penerimaan-barang', data: FormData.fromMap(formDataMap));

      if (response.statusCode == 201 || response.statusCode == 200) {
        developer.log('Sync Success for ${penerimaan.noTerima}', name: 'InventoryRepository');
        
        // Extract server-generated no_terima to keep in sync with local DB
        String? serverNoTerima;
        if (response.data != null && response.data['data'] != null) {
          serverNoTerima = response.data['data']['no_terima']?.toString();
        }

        final db = await _dbHelper.database;
        final Map<String, dynamic> updateData = {'is_synced': 1};
        if (serverNoTerima != null) {
          updateData['no_terima'] = serverNoTerima;
        }

        int count = await db.update('penerimaan_barang', updateData, where: 'id = ?', whereArgs: [penerimaan.id]);
        developer.log('Local DB update count: $count', name: 'InventoryRepository');
        if (compressedFile != null) await File(compressedFile.path).delete();
      } else {
        developer.log('Sync Failed for ${penerimaan.noTerima}: ${response.statusCode} - ${response.statusMessage}', name: 'InventoryRepository');
      }
    } catch (e) {
      if (e is DioException) {
        developer.log('Sync Exception: ${e.response?.statusCode} - ${e.message}', name: 'InventoryRepository');
        if (e.response?.statusCode == 405) {
          developer.log('CRITICAL: 405 Method Not Allowed. Check if the URL has trailing slashes or is being redirected.', name: 'InventoryRepository');
        }
        developer.log('Response data: ${e.response?.data}', name: 'InventoryRepository');
      } else {
        developer.log('Sync Unknown Error: $e', name: 'InventoryRepository');
      }
      rethrow;
    }
  }
}
