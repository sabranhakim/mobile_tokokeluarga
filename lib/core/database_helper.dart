import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('grosirkue.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5, // Version bumped to support verifikasi penerimaan
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < newVersion) {
          // Drop tables to resolve datatype mismatch and ensure clean schema
          await db.execute('DROP TABLE IF EXISTS detail_penerimaan');
          await db.execute('DROP TABLE IF EXISTS penerimaan_barang');
          await db.execute('DROP TABLE IF EXISTS barangs');
          await db.execute('DROP TABLE IF EXISTS suppliers');
          await _createDB(db, newVersion);
        }
      },
    );
  }

  Future _createDB(Database db, int version) async {
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL';
    const intNullable = 'INTEGER';

    // Suppliers Cache - id is UUID (TEXT)
    await db.execute('''
      CREATE TABLE suppliers (
        id TEXT PRIMARY KEY,
        nama_supplier $textType,
        alamat $textNullable,
        no_telp $textNullable
      )
    ''');

    // Barangs Cache - id is UUID (TEXT)
    await db.execute('''
      CREATE TABLE barangs (
        id TEXT PRIMARY KEY,
        kode_barang $textType,
        nama_barang $textType,
        satuan $textType,
        stok $intType,
        stok_minimal $intType DEFAULT 10,
        harga_beli $intNullable
      )
    ''');

    // Penerimaan Offline
    await db.execute('''
      CREATE TABLE penerimaan_barang (
        id TEXT PRIMARY KEY,
        no_terima $textNullable,
        supplier_id TEXT NOT NULL,
        supplier_nama $textType,
        user_id $intNullable,
        tgl_terima $textType,
        foto_bon_path $textNullable,
        is_synced $intType DEFAULT 0,
        status_verifikasi $textType DEFAULT 'pending',
        catatan_verifikasi $textNullable,
        verified_at $textNullable
      )
    ''');

    // Detail Penerimaan Offline
    await db.execute('''
      CREATE TABLE detail_penerimaan (
        id TEXT PRIMARY KEY,
        penerimaan_barang_id TEXT NOT NULL,
        barang_id TEXT NOT NULL,
        barang_nama $textType,
        jumlah $intType,
        FOREIGN KEY (penerimaan_barang_id) REFERENCES penerimaan_barang (id) ON DELETE CASCADE
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
