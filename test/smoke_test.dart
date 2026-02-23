import 'package:flutter_test/flutter_test.dart';
import 'package:taller_de_patrones/app.dart';

void main() {
  testWidgets('home renders title', (tester) async {
    await tester.pumpWidget(const TallerDePatronesApp());
    expect(find.text('Taller de Patrones'), findsOneWidget);
  });
}
