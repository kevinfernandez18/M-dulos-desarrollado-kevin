import 'package:flutter/material.dart';

import '../../exports/presentation/export_screen.dart';
import '../../patterns/presentation/patterns_screen.dart';
import '../../sizes/presentation/sizes_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Taller de Patrones')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'MVP offline para blusas y vestidos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _HomeButton(
              label: 'Tallas',
              icon: Icons.straighten,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SizesScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _HomeButton(
              label: 'Patrones',
              icon: Icons.design_services,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PatternsScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _HomeButton(
              label: 'Exportaciones',
              icon: Icons.picture_as_pdf,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExportScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  const _HomeButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 26),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(label),
      ),
    );
  }
}
