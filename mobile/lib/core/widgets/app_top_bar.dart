import 'package:flutter/material.dart';
import 'package:mercadex/core/config/app_config.dart';
import 'package:mercadex/core/widgets/mercadex_logo.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, required this.title, this.showBrand = false});

  final String title;
  final bool showBrand;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: showBrand ? const MercadexLogo(markSize: 32) : Text(title),
      actions: [
        if (AppConfig.useMockData)
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(99)),
                  border: Border.fromBorderSide(
                    BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'DEBUG',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
