import 'package:flutter/material.dart';

import '../../app/theme.dart';

class ServiceItem {
  const ServiceItem(
    this.title,
    this.icon,
    this.background, {
    this.urgent = false,
    this.sectionKey,
  });

  final String title;
  final IconData icon;
  final Color background;
  final bool urgent;
  final String? sectionKey;
}

class ServiceScreen extends StatelessWidget {
  const ServiceScreen({super.key, required this.service});

  final ServiceItem service;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(service.title)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: service.background,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    service.icon,
                    size: 52,
                    color: service.urgent
                        ? AppColors.danger
                        : AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  service.title,
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'This navigation path is ready. We will build its real API-backed screens feature by feature.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to assistant'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
