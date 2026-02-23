import '../../patterns/data/app_database.dart';
import '../domain/measurement.dart';
import '../domain/size_model.dart';

class SizesRepository {
  final AppDatabase _database = AppDatabase.instance;

  Future<List<SizeModel>> getSizes() async {
    final db = await _database.database;
    final rows = await db.query('sizes', orderBy: 'id ASC');
    return rows.map(SizeModel.fromMap).toList();
  }

  Future<int> upsertSize(SizeModel size) async {
    final db = await _database.database;
    if (size.id == null) {
      return db.insert('sizes', size.toMap());
    }
    return db.update('sizes', size.toMap(), where: 'id = ?', whereArgs: [size.id]);
  }

  Future<void> deleteSize(int id) async {
    final db = await _database.database;
    await db.delete('measurements', where: 'size_id = ?', whereArgs: [id]);
    await db.delete('sizes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Measurement>> getMeasurements(int sizeId, String garment) async {
    final db = await _database.database;
    final rows = await db.query(
      'measurements',
      where: 'size_id = ? AND garment = ?',
      whereArgs: [sizeId, garment],
    );
    return rows.map(Measurement.fromMap).toList();
  }

  Future<void> updateMeasurement(Measurement measurement) async {
    final db = await _database.database;
    await db.update(
      'measurements',
      measurement.toMap(),
      where: 'id = ?',
      whereArgs: [measurement.id],
    );
  }
}
