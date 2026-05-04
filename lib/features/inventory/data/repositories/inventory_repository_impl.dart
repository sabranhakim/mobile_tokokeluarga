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
  Future<void> savePenerimaanLocal(PenerimaanBarang penerimaan) async {
    final db = await _dbHelper.database;

    // Generate UUID if not exists
    String receiptId = penerimaan.id ?? _uuid.v4();
    
    // Generate no_terima if not exists (offline case)
    String noTerima =
        penerimaan.noTerima ??
        'TRX-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}';

    Map<String, dynamic> data = penerimaan.toMap();
    data['id'] = receiptId;
    data['no_terima'] = noTerima;

    await db.transaction((txn) async {
      await txn.insert('penerimaan_barang', data);
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
    List<PenerimaanBarang> allHistory = [];

    // 1. Try to get from API first
    try {
      final response = await _apiClient.dio.get('/penerimaan-barang');
      if (response.statusCode == 200) {
        final List data = response.data['data'];
        allHistory = data.map((e) => PenerimaanBarang.fromJson(e)).toList();
      }
    } catch (e) {
      developer.log('Fetch History API Error: $e', name: 'InventoryRepository');
      // If fails, we continue with empty and rely on local
    }

    // 2. Get Unsynced from Local SQLite
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> localMaps = await db.query(
      'penerimaan_barang',
      where: 'is_synced = 0',
      orderBy: 'tgl_terima DESC', // Changed from id DESC
    );

    for (var map in localMaps) {
      final detailsMap = await db.query(
        'detail_penerimaan',
        where: 'penerimaan_barang_id = ?',
        whereArgs: [map['id']],
      );

      final details =
          detailsMap.map((d) => DetailPenerimaan.fromJson(d)).toList();
      // Add local unsynced items to the top of the list
      allHistory.insert(
        0,
        PenerimaanBarang.fromJson({...map, 'details': details}),
      );
    }

    // 3. Get cached synced items from Local (if offline and API failed)
    if (allHistory.isEmpty) {
      final List<Map<String, dynamic>> syncedMaps = await db.query(
        'penerimaan_barang',
        where: 'is_synced = 1',
        orderBy: 'tgl_terima DESC', // Changed from id DESC
      );
      for (var map in syncedMaps) {
        final detailsMap = await db.query(
          'detail_penerimaan',
          where: 'penerimaan_barang_id = ?',
          whereArgs: [map['id']],
        );
        final details =
            detailsMap.map((d) => DetailPenerimaan.fromJson(d)).toList();
        allHistory.add(PenerimaanBarang.fromJson({...map, 'details': details}));
      }
    }

    return allHistory;
  }

  @override
  Future<int> getUnsyncedCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM penerimaan_barang WHERE is_synced = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<void> syncPenerimaan(PenerimaanBarang penerimaan) async {
    XFile? compressedFile;
    try {
      // Prepare details for Laravel (items array)
      List<Map<String, dynamic>> items =
          penerimaan.details
              .map((d) => {
                'id': d.id, // Pass UUID of detail
                'barang_id': d.barangId, 
                'jumlah': d.jumlah
              })
              .toList();

      // Create FormData for Multipart
      FormData formData = FormData.fromMap({
        'id': penerimaan.id, // Pass UUID of receipt
        'no_terima': penerimaan.noTerima,
        'supplier_id': penerimaan.supplierId,
        'tgl_terima': DateFormat('yyyy-MM-dd').format(penerimaan.tglTerima),
        'items':
            items, // Dio automatically handles nested lists in FormData since v5+
      });

      // Add image if exists with compression
      if (penerimaan.fotoBonPath != null &&
          penerimaan.fotoBonPath!.isNotEmpty) {
        
        final File file = File(penerimaan.fotoBonPath!);
        final String targetPath = '${file.parent.path}/compressed_${penerimaan.noTerima ?? DateTime.now().millisecondsSinceEpoch}.jpg';

        // Kompresi gambar client-side sebelum upload
        compressedFile = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: 70, // Kompresi ke kualitas 70% untuk menghemat bandwidth
        );

        formData.files.add(
          MapEntry(
            'foto_bon',
            await MultipartFile.fromFile(
              compressedFile?.path ?? penerimaan.fotoBonPath!,
              filename: 'bon.jpg',
            ),
          ),
        );
      }

      final response = await _apiClient.dio.post(
        '/penerimaan-barang',
        data: formData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Update local status to synced
        final db = await _dbHelper.database;
        await db.update(
          'penerimaan_barang',
          {'is_synced': 1},
          where: 'id = ?',
          whereArgs: [penerimaan.id],
        );
        
        // Hapus file kompresi setelah berhasil sync
        if (compressedFile != null) {
          try {
            await File(compressedFile.path).delete();
          } catch (e) {
            developer.log('Cleanup error: $e');
          }
        }
      }
    } catch (e) {
      developer.log('Sync Error: $e', name: 'InventoryRepository');
      rethrow;
    }
  }
}
