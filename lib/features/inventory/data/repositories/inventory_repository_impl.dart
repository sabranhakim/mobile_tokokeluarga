import 'dart:developer' as developer;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../../core/api_client.dart';
import '../models/barang_model.dart';
import '../models/barang_keluar_model.dart';
import '../models/penerimaan_barang_model.dart';
import '../models/supplier_model.dart';
import 'inventory_repository.dart';
import 'package:intl/intl.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<List<Supplier>> getSuppliers() async {
    final response = await _apiClient.dio.get('/suppliers');
    final List data = response.data['data'];
    return data.map((e) => Supplier.fromJson(e)).toList();
  }

  @override
  Future<List<Barang>> getBarangs() async {
    final response = await _apiClient.dio.get('/barangs');
    final List data = response.data['data'];
    return data.map((e) => Barang.fromJson(e)).toList();
  }

  @override
  Future<List<PenerimaanBarang>> getPenerimaanHistory() async {
    final response = await _apiClient.dio.get('/penerimaan-barang');
    final List data = response.data['data'];
    developer.log('Fetched ${data.length} items from API', name: 'InventoryRepository');
    return data.map((e) => PenerimaanBarang.fromJson(e)).toList();
  }

  @override
  Future<void> submitPenerimaan(PenerimaanBarang penerimaan) async {
    final List<XFile> compressedFiles = [];
    try {
      final validPaths = penerimaan.fotoBonPaths.where((p) {
        return p.isNotEmpty && File(p).existsSync();
      }).toList();

      if (validPaths.isNotEmpty) {
        // With photos → kirim sebagai FormData (multipart)
        final formData = FormData.fromMap({
          'no_terima': penerimaan.noTerima,
          'supplier_id': penerimaan.supplierId,
          'tgl_terima': DateFormat('yyyy-MM-dd').format(penerimaan.tglTerima),
        });

        for (int i = 0; i < penerimaan.details.length; i++) {
          final detail = penerimaan.details[i];
          formData.fields.addAll([
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

        developer.log('Submitting ${penerimaan.noTerima} to server (multipart, ${validPaths.length} photos)...', name: 'InventoryRepository');
        final response = await _apiClient.dio.post('/penerimaan-barang', data: formData);
        if (response.statusCode != 200 && response.statusCode != 201) {
          developer.log('Submit Failed for ${penerimaan.noTerima}: ${response.statusCode} - ${response.statusMessage}', name: 'InventoryRepository');
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
          );
        }
      } else {
        // Without photo → kirim sebagai JSON biasa
        final body = {
          'no_terima': penerimaan.noTerima,
          'supplier_id': penerimaan.supplierId,
          'tgl_terima': DateFormat('yyyy-MM-dd').format(penerimaan.tglTerima),
          'items': penerimaan.details.asMap().entries.map((entry) {
            final detail = entry.value;
            return {
              'barang_id': detail.barangId,
              'jumlah': detail.jumlah,
              if (detail.batchNumber != null)
                'batch_number': detail.batchNumber,
              if (detail.tglKadaluarsa != null)
                'tgl_kadaluarsa': detail.tglKadaluarsa,
            };
          }).toList(),
        };

        developer.log('Submitting ${penerimaan.noTerima} to server (JSON)...', name: 'InventoryRepository');
        final response = await _apiClient.dio.post('/penerimaan-barang', data: body);
        if (response.statusCode != 200 && response.statusCode != 201) {
          developer.log('Submit Failed for ${penerimaan.noTerima}: ${response.statusCode} - ${response.statusMessage}', name: 'InventoryRepository');
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
          );
        }
      }
    } catch (e) {
      if (e is DioException) {
        developer.log('Submit Exception: ${e.response?.statusCode} - ${e.message}', name: 'InventoryRepository');
      } else {
        developer.log('Submit Unknown Error: $e', name: 'InventoryRepository');
      }
      rethrow;
    } finally {
      for (final f in compressedFiles) {
        try { await File(f.path).delete(); } catch (_) {}
      }
    }
  }

  @override
  Future<void> verifyPenerimaan(PenerimaanBarang penerimaan, {String? catatan}) async {
    final response = await _apiClient.dio.post(
      '/penerimaan-barang/${penerimaan.id}/verify',
      data: {'catatan_verifikasi': catatan},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      developer.log('Verify API Success for ${penerimaan.noTerima}', name: 'InventoryRepository');
    }
  }

  @override
  Future<List<BarangKeluar>> getBarangKeluarHistory() async {
    final response = await _apiClient.dio.get('/barang-keluar');
    final List data = response.data['data'];
    developer.log('Fetched ${data.length} barang keluar from API', name: 'InventoryRepository');
    return data.map((e) => BarangKeluar.fromJson(e)).toList();
  }

  @override
  Future<void> submitBarangKeluar(BarangKeluar barangKeluar) async {
    try {
      final body = {
        'tgl_keluar': DateFormat('yyyy-MM-dd').format(barangKeluar.tglKeluar),
        'jenis_keluar': barangKeluar.jenisKeluar ?? 'penjualan',
        'keterangan': barangKeluar.keterangan,
        'items': barangKeluar.details.asMap().entries.map((entry) {
          final detail = entry.value;
          return {
            'barang_id': detail.barangId,
            'jumlah': detail.jumlah,
          };
        }).toList(),
      };

      developer.log('Submitting ${barangKeluar.noKeluar} to server...', name: 'InventoryRepository');
      final response = await _apiClient.dio.post('/barang-keluar', data: body);

      if (response.statusCode != 200 && response.statusCode != 201) {
        developer.log('Submit Barang Keluar Failed: ${response.statusCode} - ${response.statusMessage}', name: 'InventoryRepository');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } catch (e) {
      if (e is DioException) {
        developer.log('Submit Barang Keluar Exception: ${e.response?.statusCode} - ${e.message}', name: 'InventoryRepository');
      } else {
        developer.log('Submit Barang Keluar Unknown Error: $e', name: 'InventoryRepository');
      }
      rethrow;
    }
  }
}
