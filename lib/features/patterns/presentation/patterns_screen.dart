import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../sizes/data/sizes_repository.dart';
import '../data/patterns_repository.dart';
import '../domain/pattern_entity.dart';
import '../domain/pattern_model.dart';
import 'widgets/pattern_editor_canvas.dart';

class PatternsScreen extends StatefulWidget {
  const PatternsScreen({super.key});

  @override
  State<PatternsScreen> createState() => _PatternsScreenState();
}

class _PatternsScreenState extends State<PatternsScreen> {
  final _repo = PatternsRepository();
  final _sizesRepo = SizesRepository();
  final _picker = ImagePicker();

  List<PatternModel> _patterns = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final patterns = await _repo.getPatterns();
    setState(() => _patterns = patterns);
  }

  Future<void> _createPattern() async {
    final photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null || !mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _PatternCreationFlow(photoPath: photo.path, repo: _repo, sizesRepo: _sizesRepo)),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patrones')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPattern,
        label: const Text('Nuevo patrón'),
        icon: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _patterns.length,
        itemBuilder: (_, index) {
          final p = _patterns[index];
          return Card(
            child: ListTile(
              title: Text('${p.garment} ${p.modelName}'),
              subtitle: Text('Talla ${p.sizeCode} · ${p.createdAt.toLocal()}'),
              trailing: const Icon(Icons.chevron_right),
            ),
          );
        },
      ),
    );
  }
}

class _PatternCreationFlow extends StatefulWidget {
  const _PatternCreationFlow({
    required this.photoPath,
    required this.repo,
    required this.sizesRepo,
  });

  final String photoPath;
  final PatternsRepository repo;
  final SizesRepository sizesRepo;

  @override
  State<_PatternCreationFlow> createState() => _PatternCreationFlowState();
}

class _PatternCreationFlowState extends State<_PatternCreationFlow> {
  final _modelController = TextEditingController(text: 'Base');
  final _distanceController = TextEditingController(text: '21.0');

  final List<Offset> _calibrationPoints = [];
  final List<Offset> _points = [];
  final List<List<int>> _paths = [];
  String _sizeCode = 'M';
  String _garment = 'Blusa';

  double get _cmPerPixel {
    if (_calibrationPoints.length < 2) return 0.0;
    final px = (_calibrationPoints[1] - _calibrationPoints[0]).distance;
    final refCm = double.tryParse(_distanceController.text) ?? 21.0;
    return refCm / px;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear patrón')),
      body: Stepper(
        controlsBuilder: (context, details) => Row(
          children: [
            ElevatedButton(onPressed: details.onStepContinue, child: const Text('Continuar')),
            const SizedBox(width: 8),
            TextButton(onPressed: details.onStepCancel, child: const Text('Atrás')),
          ],
        ),
        currentStep: _calibrationPoints.length < 2 ? 0 : 1,
        steps: [
          Step(
            title: const Text('Calibración'),
            content: Column(
              children: [
                Image.file(File(widget.photoPath), height: 180, fit: BoxFit.cover),
                TextField(
                  controller: _distanceController,
                  decoration: const InputDecoration(
                    labelText: 'Distancia real entre puntos (cm)',
                    helperText: 'Ejemplo: ancho A4 = 21.0 cm',
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Toca 2 puntos en el editor para calibrar.'),
                Text('Escala actual: ${_cmPerPixel.toStringAsFixed(4)} cm/pixel'),
              ],
            ),
            isActive: true,
          ),
          Step(
            title: const Text('Editor'),
            content: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _garment,
                  items: const ['Blusa', 'Vestido']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _garment = v ?? 'Blusa'),
                  decoration: const InputDecoration(labelText: 'Prenda'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _sizeCode,
                  items: const ['XS', 'S', 'M', 'L', 'XL']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _sizeCode = v ?? 'M'),
                  decoration: const InputDecoration(labelText: 'Talla'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _modelController,
                  decoration: const InputDecoration(labelText: 'Modelo'),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 320,
                  child: PatternEditorCanvas(
                    points: _points,
                    paths: _paths,
                    onTap: (position) {
                      setState(() {
                        if (_calibrationPoints.length < 2) {
                          _calibrationPoints.add(position);
                        }
                        _points.add(position);
                        if (_points.length >= 2) {
                          _paths.add([_points.length - 2, _points.length - 1]);
                        }
                      });
                    },
                  ),
                ),
                const Text('Tap para añadir punto. Conecta líneas automáticamente.'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _save,
                  child: const Text('Guardar patrón'),
                ),
              ],
            ),
            isActive: _calibrationPoints.length >= 2,
          ),
        ],
        onStepContinue: () {},
        onStepCancel: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _save() async {
    final pattern = PatternModel(
      id: null,
      garment: _garment,
      sizeCode: _sizeCode,
      modelName: _modelController.text.trim(),
      photoPath: widget.photoPath,
      calibrationCmPerPixel: _cmPerPixel == 0 ? 0.1 : _cmPerPixel,
      createdAt: DateTime.now(),
    );

    final entity = PatternEntity(
      points: _points,
      paths: _paths,
      annotations: [
        PatternAnnotation(type: 'text', text: _modelController.text, x: 24, y: 24),
        const PatternAnnotation(type: 'notch', text: 'Piquete', x: 40, y: 50),
      ],
    );

    await widget.repo.createPattern(pattern, entity);
    if (mounted) Navigator.pop(context);
  }
}
