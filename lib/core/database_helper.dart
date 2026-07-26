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
      version: 8,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 6) {
          await db.execute('DROP TABLE IF EXISTS barang_stoks');
          await db.execute('DROP TABLE IF EXISTS detail_penerimaan');
          await db.execute('DROP TABLE IF EXISTS penerimaan_barang');
          await db.execute('DROP TABLE IF EXISTS barangs');
          await db.execute('DROP TABLE IF EXISTS suppliers');
          await _createDB(db, newVersion);
        } else if (oldVersion < 7) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS barang_keluar (
              id TEXT PRIMARY KEY,
              no_keluar TEXT,
              user_id INTEGER,
              tgl_keluar TEXT NOT NULL,
              keterangan TEXT,
              is_synced INTEGER DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS detail_barang_keluar (
              id TEXT PRIMARY KEY,
              barang_keluar_id TEXT NOT NULL,
              barang_id TEXT NOT NULL,
              barang_nama TEXT NOT NULL,
              jumlah INTEGER NOT NULL,
              FOREIGN KEY (barang_keluar_id) REFERENCES barang_keluar (id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 8) {
          await db.execute('ALTER TABLE barangs ADD COLUMN isi INTEGER DEFAULT 1');
          await db.execute('ALTER TABLE detail_barang_keluar ADD COLUMN barang_satuan TEXT');
          await db.execute('ALTER TABLE detail_barang_keluar ADD COLUMN barang_isi INTEGER DEFAULT 1');
        }
      },
    );
  }

  Future _createDB(Database db, int version) async {
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL';
    const intNullable = 'INTEGER';

    await db.execute('''
      CREATE TABLE suppliers (
        id TEXT PRIMARY KEY,
        nama_supplier $textType,
        alamat $textNullable,
        no_telp $textNullable
      )
    ''');

    await db.execute('''
      CREATE TABLE barangs (
        id TEXT PRIMARY KEY,
        kode_barang $textType,
        nama_barang $textType,
        satuan $textType,
        isi INTEGER DEFAULT 1,
        stok $intType,
        stok_minimal $intType DEFAULT 10,
        harga_beli $intNullable
      )
    ''');

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

    await db.execute('''
      CREATE TABLE detail_penerimaan (
        id TEXT PRIMARY KEY,
        penerimaan_barang_id TEXT NOT NULL,
        barang_id TEXT NOT NULL,
        barang_nama $textType,
        jumlah $intType,
        batch_number $textNullable,
        tgl_kadaluarsa $textNullable,
        FOREIGN KEY (penerimaan_barang_id) REFERENCES penerimaan_barang (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE barang_keluar (
        id TEXT PRIMARY KEY,
        no_keluar TEXT,
        user_id INTEGER,
        tgl_keluar $textType,
        keterangan $textNullable,
        is_synced $intType DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE detail_barang_keluar (
        id TEXT PRIMARY KEY,
        barang_keluar_id TEXT NOT NULL,
        barang_id TEXT NOT NULL,
        barang_nama $textType,
        barang_satuan TEXT,
        barang_isi INTEGER DEFAULT 1,
        jumlah $intType,
        FOREIGN KEY (barang_keluar_id) REFERENCES barang_keluar (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE barang_stoks (
        id TEXT PRIMARY KEY,
        barang_id TEXT NOT NULL,
        batch_number $textNullable,
        stok $intType,
        tgl_kadaluarsa $textNullable,
        tgl_masuk $textType,
        harga_beli $intType DEFAULT 0,
        FOREIGN KEY (barang_id) REFERENCES barangs (id) ON DELETE CASCADE
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
