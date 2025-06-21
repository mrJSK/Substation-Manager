// lib/widgets/sld_grid_painter.dart

import 'package:flutter/material.dart';
import 'package:substation_manager/utils/grid_utils.dart'; // Import gridSize

class SldGridPainter extends CustomPainter {
  final double canvasWidth;
  final double canvasHeight;
  final Color gridColor;

  SldGridPainter({
    required this.canvasWidth,
    required this.canvasHeight,
    this.gridColor = Colors.grey,
    required double gridSize, // Default grid color
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = gridColor
          .withOpacity(0.3) // Slightly transparent
      ..strokeWidth = 0.5; // Thin lines

    // Draw vertical lines
    for (double x = 0; x <= canvasWidth; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, canvasHeight), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y <= canvasHeight; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(0, y),
        paint,
      ); // Fixed: Should draw across width
      canvas.drawLine(
        Offset(0, y),
        Offset(canvasWidth, y),
        paint,
      ); // Corrected line
    }
  }

  @override
  bool shouldRepaint(covariant SldGridPainter oldDelegate) {
    // Only repaint if canvas size or grid color changes
    return oldDelegate.canvasWidth != canvasWidth ||
        oldDelegate.canvasHeight != canvasHeight ||
        oldDelegate.gridColor != gridColor;
  }
}
