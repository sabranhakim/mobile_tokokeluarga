import 'package:sqflite/sqflite.dart';
import '../../../../core/api_client.dart';
import '../../../../core/database_helper.dart';
import '../models/barang_model.dart';
import '../models/detail_penerimaan_model.dart';
import '../models/penerimaan_barang_model.dart';
import '../models/supplier_model.dart';
import 'inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final ApiClient _apiClient = ApiClient.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<Supplier>> getSuppliers() async {
    try {
      final response = await _apiClient.dio.get('/suppliers');
      final List data = response.data['data'];
      final suppliers = data.map((e) => Supplier.fromJson(e)).toList();

      // Cache to local
      final db = await _dbHelper.database;
      await db.delete('suppliers');
      for (var s in suppliers) {
        await db.insert('suppliers', s.toJson());
      }
      return suppliers;
    } catch (e) {
      // Load from cache if offline
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

      // Cache to local
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
    await db.transaction((txn) async {
      final id = await txn.insert('penerimaan_barang', penerimaan.toMap());
      for (var detail in penerimaan.details) {
        await txn.insert('detail_penerimaan', {
          ...detail.toMap(),
          'penerimaan_barang_id': id,
        });
      }
    });
  }

  @override
  Future<List<PenerimaanBarang>> getPenerimaanHistoryLocal() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('penerimaan_barang', orderBy: 'id DESC');
    
    List<PenerimaanBarang> list = [];
    for (var map in maps) {
      final detailsMap = await db.query(
        'detail_penerimaan',
        where: 'penerimaan_barang_id = ?',
        whereArgs: [map['id']],
      );
      
      final details = detailsMap.map((d) => DetailPenerimaan.fromJson(d)).toList();
      list.add(PenerimaanBarang.fromJson({...map, 'details': details}));
    }
    return list;
  }

  @override
  Future<int> getUnsyncedCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM penerimaan_barang WHERE is_synced = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<void> syncPenerimaan(PenerimaanBarang penerimaan) async {
    // Logic for multipart upload with image
    // Implement using Dio FormData
  }
}
