import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/jadwal_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'jadwalku.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTable,
    );
  }

  Future<void> _createTable(Database db, int version) async {
    await db.execute('''
      CREATE TABLE jadwal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mata_kuliah TEXT NOT NULL,
        dosen TEXT NOT NULL,
        ruangan TEXT NOT NULL,
        hari TEXT NOT NULL,
        jam_mulai TEXT NOT NULL,
        jam_selesai TEXT NOT NULL,
        semester TEXT NOT NULL,
        warna TEXT DEFAULT '#6C63FF',
        aktif_notif INTEGER DEFAULT 1
      )
    ''');
  }

  // INSERT
  Future<int> insertJadwal(Jadwal jadwal) async {
    final db = await database;
    return await db.insert(
      'jadwal',
      jadwal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // READ ALL
  Future<List<Jadwal>> getAllJadwal() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'jadwal',
      orderBy: 'hari, jam_mulai',
    );
    return maps.map((m) => Jadwal.fromMap(m)).toList();
  }

  // READ BY HARI
  Future<List<Jadwal>> getJadwalByHari(String hari) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'jadwal',
      where: 'hari = ?',
      whereArgs: [hari],
      orderBy: 'jam_mulai',
    );
    return maps.map((m) => Jadwal.fromMap(m)).toList();
  }

  // UPDATE
  Future<int> updateJadwal(Jadwal jadwal) async {
    final db = await database;
    return await db.update(
      'jadwal',
      jadwal.toMap(),
      where: 'id = ?',
      whereArgs: [jadwal.id],
    );
  }

  // DELETE
  Future<int> deleteJadwal(int id) async {
    final db = await database;
    return await db.delete(
      'jadwal',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // COUNT
  Future<int> countJadwal() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM jadwal');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // CLOSE
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
