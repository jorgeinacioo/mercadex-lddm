import 'package:flutter/material.dart';
import 'package:mercadex/core/config/app_config.dart';

/// Shown while the app runs on the bundled demo catalog instead of the API.
class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.useMockData) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Dados de demonstração, sem conexão com o servidor',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: scheme.secondary.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 14, color: scheme.onSurface),
            const SizedBox(width: 5),
            Text(
              'Modo demo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
