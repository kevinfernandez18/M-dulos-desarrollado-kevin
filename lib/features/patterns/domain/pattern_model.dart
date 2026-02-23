class PatternModel {
  const PatternModel({
    required this.id,
    required this.garment,
    required this.sizeCode,
    required this.modelName,
    required this.photoPath,
    required this.calibrationCmPerPixel,
    required this.createdAt,
  });

  final int? id;
  final String garment;
  final String sizeCode;
  final String modelName;
  final String photoPath;
  final double calibrationCmPerPixel;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'garment': garment,
        'size_code': sizeCode,
        'model_name': modelName,
        'photo_path': photoPath,
        'calibration_cm_per_pixel': calibrationCmPerPixel,
        'created_at': createdAt.toIso8601String(),
      };

  factory PatternModel.fromMap(Map<String, Object?> map) {
    return PatternModel(
      id: map['id'] as int?,
      garment: map['garment'] as String,
      sizeCode: map['size_code'] as String,
      modelName: map['model_name'] as String,
      photoPath: map['photo_path'] as String,
      calibrationCmPerPixel: (map['calibration_cm_per_pixel'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
