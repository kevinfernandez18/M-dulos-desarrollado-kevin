import 'package:flutter/material.dart';

import '../data/sizes_repository.dart';
import '../domain/measurement.dart';
import '../domain/size_model.dart';

class SizesScreen extends StatefulWidget {
  const SizesScreen({super.key});

  @override
  State<SizesScreen> createState() => _SizesScreenState();
}

class _SizesScreenState extends State<SizesScreen> {
  final _repository = SizesRepository();
  final _garments = const ['Blusa', 'Vestido'];

  List<SizeModel> _sizes = [];
  SizeModel? _selectedSize;
  String _selectedGarment = 'Blusa';
  List<Measurement> _measurements = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sizes = await _repository.getSizes();
    setState(() {
      _sizes = sizes;
      _selectedSize = sizes.isNotEmpty ? sizes.first : null;
    });
    await _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    if (_selectedSize == null) return;
    final values = await _repository.getMeasurements(_selectedSize!.id!, _selectedGarment);
    setState(() => _measurements = values);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tallas y medidas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<SizeModel>(
                    value: _selectedSize,
                    items: _sizes
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.code)))
                        .toList(),
                    onChanged: (value) async {
                      setState(() => _selectedSize = value);
                      await _loadMeasurements();
                    },
                    decoration: const InputDecoration(labelText: 'Talla'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedGarment,
                    items: _garments
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (value) async {
                      if (value == null) return;
                      setState(() => _selectedGarment = value);
                      await _loadMeasurements();
                    },
                    decoration: const InputDecoration(labelText: 'Prenda'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _measurements.length,
                itemBuilder: (context, index) {
                  final measurement = _measurements[index];
                  final controller = TextEditingController(
                    text: measurement.valueCm.toStringAsFixed(1),
                  );
                  return Card(
                    child: ListTile(
                      title: Text(measurement.field),
                      subtitle: TextField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'cm'),
                        onSubmitted: (value) async {
                          final parsed = double.tryParse(value);
                          if (parsed == null) return;
                          await _repository.updateMeasurement(
                            Measurement(
                              id: measurement.id,
                              sizeId: measurement.sizeId,
                              garment: measurement.garment,
                              field: measurement.field,
                              valueCm: parsed,
                            ),
                          );
                          await _loadMeasurements();
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
