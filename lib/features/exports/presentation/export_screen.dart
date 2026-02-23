import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../patterns/data/patterns_repository.dart';
import '../../patterns/domain/pattern_model.dart';
import '../services/pdf_export_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _repo = PatternsRepository();
  final _service = PdfExportService();
  List<PatternModel> _patterns = [];
  PatternModel? _selected;
  double _seamAllowance = 1.5;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final patterns = await _repo.getPatterns();
    setState(() {
      _patterns = patterns;
      _selected = patterns.isNotEmpty ? patterns.first : null;
    });
  }

  Future<void> _export() async {
    final selected = _selected;
    if (selected == null) return;
    final entity = await _repo.getLatestEntity(selected.id!);
    if (entity == null) return;

    final file = await _service.generateA4Mosaic(
      pattern: selected,
      entity: entity,
      seamAllowanceCm: _seamAllowance,
    );

    await Share.shareXFiles([XFile(file.path)], text: 'Patrón ${selected.modelName}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exportaciones')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<PatternModel>(
              value: _selected,
              items: _patterns
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text('${p.garment} - ${p.modelName} (${p.sizeCode})'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selected = v),
              decoration: const InputDecoration(labelText: 'Seleccionar patrón'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<double>(
              value: _seamAllowance,
              items: const [1.0, 1.5, 2.0]
                  .map((e) => DropdownMenuItem(value: e, child: Text('$e cm')))
                  .toList(),
              onChanged: (v) => setState(() => _seamAllowance = v ?? 1.5),
              decoration: const InputDecoration(labelText: 'Margen de costura'),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _selected == null ? null : _export,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Generar PDF mosaico A4 (1:1)'),
            ),
          ],
        ),
      ),
    );
  }
}
