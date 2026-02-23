import 'dart:convert';
import 'dart:ui';

class PatternEntity {
  const PatternEntity({
    required this.points,
    required this.paths,
    required this.annotations,
  });

  final List<Offset> points;
  final List<List<int>> paths;
  final List<PatternAnnotation> annotations;

  String toJsonString() => jsonEncode({
        'points': points.map((e) => {'x': e.dx, 'y': e.dy}).toList(),
        'paths': paths,
        'annotations': annotations.map((e) => e.toMap()).toList(),
      });

  factory PatternEntity.fromJsonString(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    return PatternEntity(
      points: (map['points'] as List)
          .map((p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble()))
          .toList(),
      paths: (map['paths'] as List)
          .map((row) => (row as List).map((e) => e as int).toList())
          .toList(),
      annotations: (map['annotations'] as List)
          .map((e) => PatternAnnotation.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PatternAnnotation {
  const PatternAnnotation({
    required this.type,
    required this.text,
    required this.x,
    required this.y,
  });

  final String type;
  final String text;
  final double x;
  final double y;

  Map<String, Object?> toMap() => {
        'type': type,
        'text': text,
        'x': x,
        'y': y,
      };

  factory PatternAnnotation.fromMap(Map<String, dynamic> map) {
    return PatternAnnotation(
      type: map['type'] as String,
      text: map['text'] as String,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
    );
  }
}
