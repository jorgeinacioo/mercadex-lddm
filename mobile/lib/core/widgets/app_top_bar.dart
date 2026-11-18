import 'package:flutter/material.dart';
import 'package:mercadex/core/widgets/demo_badge.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, required this.title, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        ...actions,
        const Padding(
          padding: EdgeInsets.only(right: 16),
          child: Center(child: DemoBadge()),
        ),
      ],
    );
  }
}
