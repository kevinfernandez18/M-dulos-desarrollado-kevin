class SizeModel {
  const SizeModel({required this.id, required this.code, required this.label});

  final int? id;
  final String code;
  final String label;

  Map<String, Object?> toMap() => {'id': id, 'code': code, 'label': label};

  factory SizeModel.fromMap(Map<String, Object?> map) {
    return SizeModel(
      id: map['id'] as int?,
      code: map['code'] as String,
      label: map['label'] as String,
    );
  }
}
