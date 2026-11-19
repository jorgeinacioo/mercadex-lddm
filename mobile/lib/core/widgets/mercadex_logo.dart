import 'package:flutter/material.dart';
import 'package:mercadex/core/theme/app_colors.dart';

class MercadexLogo extends StatelessWidget {
  const MercadexLogo({
    super.key,
    this.markSize = 40,
    this.showWord = true,
    this.showSlogan = false,
    this.centered = false,
    this.onDark = false,
  });

  const MercadexLogo.compact({super.key, this.markSize = 40})
    : showWord = false,
      showSlogan = false,
      centered = false,
      onDark = false;

  final double markSize;
  final bool showWord;
  final bool showSlogan;
  final bool centered;
  final bool onDark;

  static const slogan = 'Comparar hoje. Economizar sempre.';

  @override
  Widget build(BuildContext context) {
    final mark = MercadexMark(
      size: markSize,
      onDark: onDark || Theme.of(context).brightness == Brightness.dark,
    );
    final word = _Wordmark(fontSize: markSize * 0.56, onDark: onDark);
    final tagline = Text(
      slogan,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        fontFamily: 'Inter',
        color: onDark
            ? AppColors.surface
            : Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: markSize * 0.28,
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
    );

    final Widget content;
    if (!showWord) {
      content = mark;
    } else if (centered) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          SizedBox(height: markSize * 0.22),
          word,
          if (showSlogan) ...[SizedBox(height: markSize * 0.14), tagline],
        ],
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          SizedBox(width: markSize * 0.28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              word,
              if (showSlogan) ...[SizedBox(height: markSize * 0.08), tagline],
            ],
          ),
        ],
      );
    }

    return Semantics(
      label: showSlogan ? 'Mercadex. $slogan' : 'Mercadex',
      child: ExcludeSemantics(child: content),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.fontSize, required this.onDark});

  final double fontSize;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
      height: 1,
    );
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(
            text: 'Mercad',
            style: TextStyle(
              color: onDark
                  ? AppColors.surface
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          TextSpan(
            text: 'ex',
            style: TextStyle(
              color: onDark
                  ? AppColors.surface
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class MercadexMark extends StatelessWidget {
  const MercadexMark({super.key, required this.size, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CartPainter(onDark: onDark)),
    );
  }
}

class _CartPainter extends CustomPainter {
  const _CartPainter({required this.onDark});

  final bool onDark;

  @override
  void paint(Canvas canvas, Size size) {
    final basket = Paint()
      ..color = onDark ? AppColors.surface : AppColors.primary;
    final handle = Paint()
      ..color = onDark ? AppColors.surface : AppColors.deepGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.34, size.height * 0.16)
        ..lineTo(size.width * 0.52, size.height * 0.16)
        ..lineTo(size.width * 0.60, size.height * 0.34),
      handle,
    );

    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.16, size.height * 0.36)
        ..lineTo(size.width * 0.84, size.height * 0.36)
        ..lineTo(size.width * 0.74, size.height * 0.70)
        ..lineTo(size.width * 0.26, size.height * 0.70)
        ..close(),
      basket,
    );

    final detail = Paint()
      ..color = onDark
          ? AppColors.primaryLight
          : AppColors.surface.withValues(alpha: 0.85);
    canvas.drawCircle(
      Offset(size.width * 0.40, size.height * 0.52),
      size.width * 0.045,
      detail,
    );
    canvas.drawCircle(
      Offset(size.width * 0.56, size.height * 0.52),
      size.width * 0.045,
      Paint()
        ..color = onDark
            ? AppColors.surface
            : AppColors.primaryLight.withValues(alpha: 0.95),
    );

    canvas.drawCircle(
      Offset(size.width * 0.36, size.height * 0.82),
      size.width * 0.075,
      Paint()..color = onDark ? AppColors.surface : const Color(0xFFF8FAFC),
    );
    canvas.drawCircle(
      Offset(size.width * 0.64, size.height * 0.82),
      size.width * 0.075,
      Paint()..color = AppColors.amber,
    );
  }

  @override
  bool shouldRepaint(covariant _CartPainter oldDelegate) {
    return oldDelegate.onDark != onDark;
  }
}
