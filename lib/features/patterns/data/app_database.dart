import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._();
  AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'taller_patrones.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sizes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE NOT NULL,
            label TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE measurements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            size_id INTEGER NOT NULL,
            garment TEXT NOT NULL,
            field TEXT NOT NULL,
            value_cm REAL NOT NULL,
            FOREIGN KEY(size_id) REFERENCES sizes(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE patterns (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            garment TEXT NOT NULL,
            size_code TEXT NOT NULL,
            model_name TEXT NOT NULL,
            photo_path TEXT NOT NULL,
            calibration_cm_per_pixel REAL NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE pattern_versions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pattern_id INTEGER NOT NULL,
            version_label TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY(pattern_id) REFERENCES patterns(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE pattern_entities (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pattern_version_id INTEGER NOT NULL,
            entity_json TEXT NOT NULL,
            FOREIGN KEY(pattern_version_id) REFERENCES pattern_versions(id)
          )
        ''');

        for (final code in ['XS', 'S', 'M', 'L', 'XL']) {
          final sizeId = await db.insert('sizes', {'code': code, 'label': 'Talla $code'});
          for (final garment in ['Blusa', 'Vestido']) {
            for (final field in ['Busto', 'Cintura', 'Cadera', 'Largo', 'Hombro']) {
              await db.insert('measurements', {
                'size_id': sizeId,
                'garment': garment,
                'field': field,
                'value_cm': 0.0,
              });
            }
          }
        }
      },
    );
  }
}
