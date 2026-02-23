import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../patterns/domain/pattern_entity.dart';
import '../../patterns/domain/pattern_model.dart';

class PdfExportService {
  Future<File> generateA4Mosaic({
    required PatternModel pattern,
    required PatternEntity entity,
    required double seamAllowanceCm,
  }) async {
    final pdf = pw.Document();

    final pointsCm = entity.points
        .map((p) => (x: p.dx * pattern.calibrationCmPerPixel, y: p.dy * pattern.calibrationCmPerPixel))
        .toList();

    const printableCmWidth = 19.0;
    const printableCmHeight = 27.7;
    final maxX = pointsCm.fold<double>(0, (prev, p) => p.x > prev ? p.x : prev);
    final maxY = pointsCm.fold<double>(0, (prev, p) => p.y > prev ? p.y : prev);
    final pagesX = (maxX / printableCmWidth).ceil().clamp(1, 99);
    final pagesY = (maxY / printableCmHeight).ceil().clamp(1, 99);

    for (var y = 0; y < pagesY; y++) {
      for (var x = 0; x < pagesX; x++) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) {
              return pw.Stack(
                children: [
                  pw.Positioned(
                    top: 6,
                    left: 6,
                    child: pw.Text('${pattern.garment} ${pattern.modelName} · Talla ${pattern.sizeCode}'),
                  ),
                  pw.Positioned(
                    right: 6,
                    top: 6,
                    child: pw.Text(DateFormat('yyyy-MM-dd').format(pattern.createdAt)),
                  ),
                  pw.Positioned(
                    right: 8,
                    bottom: 8,
                    child: pw.Container(
                      width: 50,
                      height: 50,
                      decoration: pw.BoxDecoration(border: pw.Border.all()),
                      child: pw.Center(child: pw.Text('5x5 cm')),
                    ),
                  ),
                  pw.Center(
                    child: pw.Text('Página ${x + 1}-${y + 1}\nMargen: ${seamAllowanceCm.toStringAsFixed(1)} cm'),
                  ),
                ],
              );
            },
          ),
        );
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/patron_${pattern.id}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
