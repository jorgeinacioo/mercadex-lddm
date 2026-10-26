import 'dart:async';

import 'package:flutter/material.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  static const _adCount = 3;
  static const _initialPage = 3000;

  final controller = PageController(initialPage: _initialPage);
  Timer? timer;
  int currentPage = _initialPage;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !controller.hasClients) {
        return;
      }

      controller.animateToPage(
        currentPage + 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PageView.builder(
              controller: controller,
              onPageChanged: (page) => setState(() => currentPage = page),
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Anúncio ${index % _adCount + 1}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              bottom: 12,
              child: Row(
                children: List.generate(_adCount, (index) {
                  final isActive = index == currentPage % _adCount;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
