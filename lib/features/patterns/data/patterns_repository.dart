import '../domain/pattern_entity.dart';
import '../domain/pattern_model.dart';
import 'app_database.dart';

class PatternsRepository {
  final AppDatabase _database = AppDatabase.instance;

  Future<List<PatternModel>> getPatterns() async {
    final db = await _database.database;
    final rows = await db.query('patterns', orderBy: 'created_at DESC');
    return rows.map(PatternModel.fromMap).toList();
  }

  Future<int> createPattern(PatternModel pattern, PatternEntity entity) async {
    final db = await _database.database;
    final patternId = await db.insert('patterns', pattern.toMap());
    final versionId = await db.insert('pattern_versions', {
      'pattern_id': patternId,
      'version_label': 'v1',
      'created_at': DateTime.now().toIso8601String(),
    });
    await db.insert('pattern_entities', {
      'pattern_version_id': versionId,
      'entity_json': entity.toJsonString(),
    });
    return patternId;
  }

  Future<PatternEntity?> getLatestEntity(int patternId) async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
      SELECT pe.entity_json FROM pattern_entities pe
      INNER JOIN pattern_versions pv ON pv.id = pe.pattern_version_id
      WHERE pv.pattern_id = ?
      ORDER BY pv.created_at DESC
      LIMIT 1
    ''', [patternId]);
    if (rows.isEmpty) return null;
    return PatternEntity.fromJsonString(rows.first['entity_json'] as String);
  }
}
