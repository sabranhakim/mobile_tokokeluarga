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

    String receiptId = penerimaan.id ?? _uuid.v4();
    String noTerima = penerimaan.noTerima ?? 'TRX-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}';

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

    try {
      final response = await _apiClient.dio.get('/penerimaan-barang');
      if (response.statusCode == 200) {
        final List data = response.data['data'];
        allHistory = data.map((e) => PenerimaanBarang.fromJson(e)).toList();
      }
    } catch (e) {
      developer.log('Fetch History API Error: $e', name: 'InventoryRepository');
    }

    final db = await _dbHelper.database;
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
        
        try {
          allHistory.insert(0, PenerimaanBarang.fromJson({...map, 'details': details}));
        } catch (e) {
          developer.log('Error parsing local item: $e', name: 'InventoryRepository');
        }
      }
    } catch (e) {
      developer.log('Error loading local history: $e', name: 'InventoryRepository');
    }

    return allHistory;
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

      final response = await _apiClient.dio.post('/penerimaan-barang', data: FormData.fromMap(formDataMap));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final db = await _dbHelper.database;
        await db.update('penerimaan_barang', {'is_synced': 1}, where: 'id = ?', whereArgs: [penerimaan.id]);
        if (compressedFile != null) await File(compressedFile.path).delete();
      }
    } catch (e) {
      developer.log('Sync Error: $e', name: 'InventoryRepository');
      rethrow;
    }
  }
}
