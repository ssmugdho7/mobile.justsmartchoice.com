import 'package:flutter/material.dart';

class ToolboxUnavailable extends StatelessWidget {
  const ToolboxUnavailable({super.key, required this.onNavigate});
  final ValueChanged<Uri> onNavigate;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.description_outlined, size: 40),
          const SizedBox(height: 16),
          Text(
            'This resource is currently unavailable',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'The requested document is not currently available on the Smart Choice website. You can browse the Forms Library or return to Toolbox.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () =>
                onNavigate(Uri.parse('https://justsmartchoice.com/forms.php')),
            icon: const Icon(Icons.description_outlined),
            label: const Text('View Forms Library'),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => onNavigate(
              Uri.parse('https://justsmartchoice.com/toolbox.php'),
            ),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Toolbox'),
          ),
        ],
      ),
    ),
  );
}
