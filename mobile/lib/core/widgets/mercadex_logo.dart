import 'package:flutter/material.dart';
import 'package:mercadex/core/theme/app_colors.dart';

class MercadexLogo extends StatelessWidget {
  const MercadexLogo({
    super.key,
    this.markSize = 40,
    this.showWord = true,
    this.showSlogan = false,
    this.centered = false,
  });

  const MercadexLogo.compact({super.key, this.markSize = 40})
    : showWord = false,
      showSlogan = false,
      centered = false;

  final double markSize;
  final bool showWord;
  final bool showSlogan;
  final bool centered;

  static const slogan = 'Compare preços. Compre melhor.';

  @override
  Widget build(BuildContext context) {
    final mark = MercadexMark(size: markSize);
    final word = Text(
      'Mercadex',
      style: TextStyle(
        color: AppColors.ink,
        fontSize: markSize * 0.58,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1,
      ),
    );
    final tagline = Text(
      slogan,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: markSize * 0.30,
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
          SizedBox(height: markSize * 0.28),
          word,
          if (showSlogan) ...[SizedBox(height: markSize * 0.16), tagline],
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
              if (showSlogan) ...[SizedBox(height: markSize * 0.12), tagline],
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

class MercadexMark extends StatelessWidget {
  const MercadexMark({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MercadexMarkPainter()),
    );
  }
}

class _MercadexMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.width * 0.28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, radius),
      Paint()..color = AppColors.primary,
    );

    final stroke = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.105
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.26, size.height * 0.72)
        ..lineTo(size.width * 0.26, size.height * 0.28)
        ..lineTo(size.width * 0.50, size.height * 0.50)
        ..lineTo(size.width * 0.74, size.height * 0.28)
        ..lineTo(size.width * 0.74, size.height * 0.72),
      stroke,
    );

    canvas.drawCircle(
      Offset(size.width * 0.74, size.height * 0.74),
      size.width * 0.075,
      Paint()..color = AppColors.amber,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
