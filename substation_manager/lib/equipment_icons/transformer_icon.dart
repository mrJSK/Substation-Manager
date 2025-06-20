// lib/equipment_icons/transformer_icon.dart

import 'package:flutter/material.dart';
import 'dart:math'; // For min and sqrt

// Abstract base class for all equipment painters (moved here for consistency)
abstract class EquipmentPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  EquipmentPainter({required this.color, this.strokeWidth = 2.0});
}

class TransformerIconPainter extends EquipmentPainter {
  TransformerIconPainter({required super.color, super.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius =
        min(size.width, size.height) / 3; // Radius for circles

    // Three overlapping circles for 3-phase transformer
    canvas.drawCircle(Offset(centerX - radius / 2, centerY), radius, paint);
    canvas.drawCircle(Offset(centerX + radius / 2, centerY), radius, paint);
    canvas.drawCircle(
      Offset(centerX, centerY - radius * sqrt(3) / 2),
      radius,
      paint,
    ); // Top circle

    // Input/Output lines
    canvas.drawLine(
      Offset(centerX - radius / 2, centerY - radius),
      Offset(centerX - radius / 2, centerY - size.height * 0.45),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + radius / 2, centerY - radius),
      Offset(centerX + radius / 2, centerY - size.height * 0.45),
      paint,
    );
    canvas.drawLine(
      Offset(centerX, centerY + radius),
      Offset(centerX, centerY + size.height * 0.45),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant TransformerIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
