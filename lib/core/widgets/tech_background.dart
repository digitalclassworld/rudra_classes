import 'dart:math';
import 'package:flutter/material.dart';

class TechBackground extends StatefulWidget {
  final Widget child;
  const TechBackground({Key? key, required this.child}) : super(key: key);

  @override
  State<TechBackground> createState() => _TechBackgroundState();
}

class _TechBackgroundState extends State<TechBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40), // Very slow subtle animation
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base light blue gradient
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF4F9FF),
                  Color(0xFFE6F0FA),
                ],
              ),
            ),
          ),
        ),
        
        // Animated Custom Painter for lines, grids, dots
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _TechPainter(animationValue: _controller.value),
              );
            },
          ),
        ),
        
        // The actual content
        widget.child,
      ],
    );
  }
}

class _TechPainter extends CustomPainter {
  final double animationValue;

  _TechPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCDE2F5) // Very faint blue
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = const Color(0xFFB5D3F0)
      ..style = PaintingStyle.fill;

    // 1. Draw subtle grid
    const double gridSize = 50.0;
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint..color = const Color(0xFFEBF3FB));
    }
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint..color = const Color(0xFFEBF3FB));
    }

    // 2. Draw animated sweeping curves
    paint.color = const Color(0xFFCDE2F5);
    paint.strokeWidth = 1.5;
    
    final center1 = Offset(
      size.width * 0.2 + cos(animationValue * 2 * pi) * 30, 
      size.height * 0.3 + sin(animationValue * 2 * pi) * 30
    );
    canvas.drawCircle(center1, size.width * 0.8, paint);
    canvas.drawCircle(center1, size.width * 1.1, paint);

    final center2 = Offset(
      size.width * 0.8 + sin(animationValue * 2 * pi) * 40, 
      size.height * 0.8 + cos(animationValue * 2 * pi) * 40
    );
    canvas.drawCircle(center2, size.width * 0.6, paint);

    // 3. Draw dot matrix (top right area)
    const int dotRows = 4;
    const int dotCols = 6;
    const double dotSpacing = 20.0;
    final double startX = size.width * 0.6;
    final double startY = size.height * 0.1;

    for (int r = 0; r < dotRows; r++) {
      for (int c = 0; c < dotCols; c++) {
        // Add a slight wave to the dots
        double wave = sin((animationValue * 2 * pi) + (c * 0.5) + (r * 0.5)) * 3;
        canvas.drawCircle(
          Offset(startX + (c * dotSpacing), startY + (r * dotSpacing) + wave), 
          2.0, 
          dotPaint
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TechPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
