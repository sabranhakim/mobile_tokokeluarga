import 'dart:developer' as developer;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/api_client.dart';
import '../../../../core/database_helper.dart';
import '../models/barang_model.dart';
import '../models/barang_keluar_model.dart';
import '../models/detail_barang_keluar_model.dart';
import '../models/detail_penerimaan_model.dart';
import '../models/penerimaan_barang_model.dart';
import '../models/supplier_model.dart';
import 'inventory_repository.dart';
import 'package:intl/intl.dart';
import '../../../../core/time_service.dart';

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
    String noTerima = penerimaan.noTerima ?? 'TRX-${DateFormat('yyyyMMddHHmmss').format(TimeService.instance.now())}';

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
    bool apiSuccess = false;

    // 1. Ambil data dari API
    try {
      final response = await _apiClient.dio.get('/penerimaan-barang');
      if (response.statusCode == 200) {
        final List data = response.data['data'];
        apiHistory = data.map((e) => PenerimaanBarang.fromJson(e)).toList();
        apiSuccess = true;
        developer.log('Fetched ${apiHistory.length} items from API', name: 'InventoryRepository');
      }
    } catch (e) {
      developer.log('Fetch History API Error: $e', name: 'InventoryRepository');
    }

    // 2. Ambil data dari Database Lokal
    final db = await _dbHelper.database;
    List<PenerimaanBarang> localItems = [];
    try {
      // Jika API gagal, ambil SEMUA data lokal (synced + unsynced) sebagai fallback
      // Jika API sukses, ambil hanya yang belum sync
      final localMaps = await (apiSuccess
        ? db.query('penerimaan_barang', where: 'is_synced = 0', orderBy: 'tgl_terima DESC')
        : db.query('penerimaan_barang', orderBy: 'tgl_terima DESC')
      );

      for (var map in localMaps) {
        final detailsMap = await db.query(
          'detail_penerimaan',
          where: 'penerimaan_barang_id = ?',
          whereArgs: [map['id']],
        );

        final details = detailsMap.map((d) => DetailPenerimaan.fromJson(d)).toList();
        final isSynced = map['is_synced'] ?? 0;
        localItems.add(PenerimaanBarang.fromJson({
          ...map,
          'details': details,
          'is_synced': isSynced,
        }));
      }
      developer.log('Found ${localItems.length} items in Local DB${apiSuccess ? ' (unsynced only)' : ' (fallback all)'}', name: 'InventoryRepository');
    } catch (e) {
      developer.log('Error loading local history: $e', name: 'InventoryRepository');
    }

    // Gabungkan: Data lokal diletakkan paling atas, lalu data dari API
    return [...localItems, ...apiHistory];
  }

  @override
  Future<int> getUnsyncedCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM penerimaan_barang WHERE is_synced = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<void> syncPenerimaan(PenerimaanBarang penerimaan) async {
    final List<XFile> compressedFiles = [];
    try {
      final validPaths = penerimaan.fotoBonPaths.where((p) {
        return p.isNotEmpty && File(p).existsSync();
      }).toList();

      if (validPaths.isNotEmpty) {
        // With photos → kirim sebagai FormData (multipart)
        final formData = FormData.fromMap({
          'id': penerimaan.id,
          'no_terima': penerimaan.noTerima,
          'supplier_id': penerimaan.supplierId,
          'tgl_terima': DateFormat('yyyy-MM-dd').format(penerimaan.tglTerima),
        });

        for (int i = 0; i < penerimaan.details.length; i++) {
          final detail = penerimaan.details[i];
          formData.fields.addAll([
            MapEntry('items[$i][id]', detail.id ?? _uuid.v4()),
            MapEntry('items[$i][barang_id]', detail.barangId),
            MapEntry('items[$i][jumlah]', detail.jumlah.toString()),
            if (detail.batchNumber != null)
              MapEntry('items[$i][batch_number]', detail.batchNumber!),
            if (detail.tglKadaluarsa != null)
              MapEntry('items[$i][tgl_kadaluarsa]', detail.tglKadaluarsa!),
          ]);
        }

        for (int idx = 0; idx < validPaths.length; idx++) {
          final path = validPaths[idx];
          final fieldName = idx == 0 ? 'foto_bon' : 'foto_bon_${idx + 1}';
          final targetPath = '${Directory(path).parent.path}/compressed_${penerimaan.noTerima}_$idx.jpg';
          final compressed = await FlutterImageCompress.compressAndGetFile(
            File(path).absolute.path,
            targetPath,
            quality: 70,
          );
          if (compressed != null) {
            compressedFiles.add(compressed);
            formData.files.add(MapEntry(
              fieldName,
              await MultipartFile.fromFile(compressed.path, filename: 'bon_$idx.jpg'),
            ));
          }
        }

        developer.log('Syncing ${penerimaan.noTerima} to server (multipart, ${validPaths.length} photos)...', name: 'InventoryRepository');
        final response = await _apiClient.dio.post('/penerimaan-barang', data: formData);
        await _handleSyncResponse(response, penerimaan);
      } else {
        // Without photo → kirim sebagai JSON biasa
        final body = {
          'id': penerimaan.id,
          'no_terima': penerimaan.noTerima,
          'supplier_id': penerimaan.supplierId,
          'tgl_terima': DateFormat('yyyy-MM-dd').format(penerimaan.tglTerima),
          'items': penerimaan.details.asMap().entries.map((entry) {
            final detail = entry.value;
            return {
              'id': detail.id ?? _uuid.v4(),
              'barang_id': detail.barangId,
              'jumlah': detail.jumlah,
              if (detail.batchNumber != null)
                'batch_number': detail.batchNumber,
              if (detail.tglKadaluarsa != null)
                'tgl_kadaluarsa': detail.tglKadaluarsa,
            };
          }).toList(),
        };

        developer.log('Syncing ${penerimaan.noTerima} to server (JSON)...', name: 'InventoryRepository');
        final response = await _apiClient.dio.post('/penerimaan-barang', data: body);
        await _handleSyncResponse(response, penerimaan);
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
    } finally {
      for (final f in compressedFiles) {
        try { await File(f.path).delete(); } catch (_) {}
      }
    }
  }

  Future<void> _handleSyncResponse(Response response, PenerimaanBarang penerimaan) async {
    if (response.statusCode == 201 || response.statusCode == 200) {
      developer.log('Sync Success for ${penerimaan.noTerima}', name: 'InventoryRepository');

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
    } else {
      developer.log('Sync Failed for ${penerimaan.noTerima}: ${response.statusCode} - ${response.statusMessage}', name: 'InventoryRepository');
    }
  }

  @override
  Future<void> verifyPenerimaanLocal(String id, {String? catatan}) async {
    final db = await _dbHelper.database;
    await db.update(
      'penerimaan_barang',
      {
        'status_verifikasi': 'verified',
        'catatan_verifikasi': catatan,
        'verified_at': TimeService.instance.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    developer.log('Verified locally: $id', name: 'InventoryRepository');
  }

  // ==================== BARANG KELUAR ====================

  @override
  Future<void> saveBarangKeluarLocal(BarangKeluar barangKeluar, {bool forceSynced = false}) async {
    final db = await _dbHelper.database;

    String id = barangKeluar.id ?? _uuid.v4();
    String noKeluar = barangKeluar.noKeluar ?? 'KLR-${DateFormat('yyyyMMddHHmmss').format(TimeService.instance.now())}';

    Map<String, dynamic> data = barangKeluar.toMap();
    data['id'] = id;
    data['no_keluar'] = noKeluar;
    if (forceSynced) {
      data['is_synced'] = 1;
    }

    await db.transaction((txn) async {
      await txn.insert('barang_keluar', data, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete('detail_barang_keluar', where: 'barang_keluar_id = ?', whereArgs: [id]);

      for (var detail in barangKeluar.details) {
        String detailId = detail.id ?? _uuid.v4();
        await txn.insert('detail_barang_keluar', {
          ...detail.toMap(),
          'id': detailId,
          'barang_keluar_id': id,
        });
      }
    });
  }

  @override
  Future<List<BarangKeluar>> getBarangKeluarHistoryLocal() async {
    List<BarangKeluar> apiHistory = [];
    bool apiSuccess = false;

    try {
      final response = await _apiClient.dio.get('/barang-keluar');
      if (response.statusCode == 200) {
        final List data = response.data['data'];
        apiHistory = data.map((e) => BarangKeluar.fromJson(e)).toList();
        apiSuccess = true;
        developer.log('Fetched ${apiHistory.length} barang keluar from API', name: 'InventoryRepository');
      }
    } catch (e) {
      developer.log('Fetch Barang Keluar API Error: $e', name: 'InventoryRepository');
    }

    final db = await _dbHelper.database;
    List<BarangKeluar> localItems = [];
    try {
      final localMaps = await (apiSuccess
        ? db.query('barang_keluar', where: 'is_synced = 0', orderBy: 'tgl_keluar DESC')
        : db.query('barang_keluar', orderBy: 'tgl_keluar DESC')
      );

      for (var map in localMaps) {
        final detailsMap = await db.query(
          'detail_barang_keluar',
          where: 'barang_keluar_id = ?',
          whereArgs: [map['id']],
        );
        final details = detailsMap.map((d) => DetailBarangKeluar.fromJson(d)).toList();
        final isSynced = map['is_synced'] ?? 0;
        localItems.add(BarangKeluar.fromJson({
          ...map,
          'details': details,
          'is_synced': isSynced,
        }));
      }
      developer.log('Found ${localItems.length} barang keluar in Local DB', name: 'InventoryRepository');
    } catch (e) {
      developer.log('Error loading local barang keluar: $e', name: 'InventoryRepository');
    }

    return [...localItems, ...apiHistory];
  }

  @override
  Future<void> syncBarangKeluar(BarangKeluar barangKeluar) async {
    try {
      final body = {
        'id': barangKeluar.id,
        'tgl_keluar': DateFormat('yyyy-MM-dd').format(barangKeluar.tglKeluar),
        'jenis_keluar': barangKeluar.jenisKeluar ?? 'penjualan',
        'keterangan': barangKeluar.keterangan,
        'items': barangKeluar.details.asMap().entries.map((entry) {
          final detail = entry.value;
          return {
            'id': detail.id ?? _uuid.v4(),
            'barang_id': detail.barangId,
            'jumlah': detail.jumlah,
          };
        }).toList(),
      };

      developer.log('Syncing ${barangKeluar.noKeluar} to server...', name: 'InventoryRepository');
      final response = await _apiClient.dio.post('/barang-keluar', data: body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        developer.log('Sync Success for ${barangKeluar.noKeluar}', name: 'InventoryRepository');
        String? serverNoKeluar;
        if (response.data != null && response.data['data'] != null) {
          serverNoKeluar = response.data['data']['no_keluar']?.toString();
        }

        final db = await _dbHelper.database;
        final Map<String, dynamic> updateData = {'is_synced': 1};
        if (serverNoKeluar != null) {
          updateData['no_keluar'] = serverNoKeluar;
        }
        await db.update('barang_keluar', updateData, where: 'id = ?', whereArgs: [barangKeluar.id]);
      }
    } catch (e) {
      if (e is DioException) {
        developer.log('Sync Barang Keluar Exception: ${e.response?.statusCode} - ${e.message}', name: 'InventoryRepository');
      } else {
        developer.log('Sync Barang Keluar Unknown Error: $e', name: 'InventoryRepository');
      }
      rethrow;
    }
  }

  @override
  Future<int> getUnsyncedBarangKeluarCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM barang_keluar WHERE is_synced = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<void> verifyPenerimaan(PenerimaanBarang penerimaan, {String? catatan}) async {
    try {
      final response = await _apiClient.dio.post(
        '/penerimaan-barang/${penerimaan.id}/verify',
        data: {'catatan_verifikasi': catatan},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        developer.log('Verify API Success for ${penerimaan.noTerima}', name: 'InventoryRepository');
        await verifyPenerimaanLocal(penerimaan.id!, catatan: catatan);
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        developer.log('Verify offline — menyimpan lokal untuk sync nanti: $e', name: 'InventoryRepository');
        await verifyPenerimaanLocal(penerimaan.id!, catatan: catatan);
      } else {
        developer.log('Verify API Error: ${e.response?.statusCode} — ${e.message}', name: 'InventoryRepository');
        rethrow;
      }
    }
  }
}
