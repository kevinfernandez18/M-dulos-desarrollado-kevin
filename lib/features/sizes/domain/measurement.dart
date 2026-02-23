class Measurement {
  const Measurement({
    required this.id,
    required this.sizeId,
    required this.garment,
    required this.field,
    required this.valueCm,
  });

  final int? id;
  final int sizeId;
  final String garment;
  final String field;
  final double valueCm;

  Map<String, Object?> toMap() => {
        'id': id,
        'size_id': sizeId,
        'garment': garment,
        'field': field,
        'value_cm': valueCm,
      };

  factory Measurement.fromMap(Map<String, Object?> map) {
    return Measurement(
      id: map['id'] as int?,
      sizeId: map['size_id'] as int,
      garment: map['garment'] as String,
      field: map['field'] as String,
      valueCm: (map['value_cm'] as num).toDouble(),
    );
  }
}
