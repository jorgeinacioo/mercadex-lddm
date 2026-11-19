import 'dart:async';

import 'package:flutter/material.dart';

OverlayEntry? _activeNotification;
Timer? _dismissTimer;

void showAppNotification(BuildContext context, String message) {
  _dismissTimer?.cancel();
  _activeNotification?.remove();

  late final OverlayEntry entry;
  void dismiss() {
    if (!identical(_activeNotification, entry)) return;
    _dismissTimer?.cancel();
    entry.remove();
    _activeNotification = null;
  }

  entry = OverlayEntry(
    builder: (context) => Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(child: Text(message)),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: dismiss,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  _activeNotification = entry;
  Overlay.of(context, rootOverlay: true).insert(entry);
  _dismissTimer = Timer(const Duration(seconds: 3), dismiss);
}
