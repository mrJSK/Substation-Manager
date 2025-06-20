// lib/equipment_icons/pt_icon.dart

import 'package:flutter/material.dart';
import 'package:substation_manager/equipment_icons/transformer_icon.dart'; // Import base EquipmentPainter
import 'dart:math';

class PotentialTransformerIconPainter extends EquipmentPainter {
  PotentialTransformerIconPainter({required super.color, super.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final coilRadius = min(size.width, size.height) * 0.2;

    // Simple coil shape (spiral or overlapping circles)
    // For simplicity, let's draw two overlapping circles for the coil
    canvas.drawCircle(
      Offset(centerX, centerY - coilRadius / 2),
      coilRadius,
      paint,
    );
    canvas.drawCircle(
      Offset(centerX, centerY + coilRadius / 2),
      coilRadius,
      paint,
    );

    // Primary lines
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, centerY - coilRadius),
      paint,
    );
    canvas.drawLine(
      Offset(centerX, size.height),
      Offset(centerX, centerY + coilRadius),
      paint,
    );

    // Draw "PT" text
    final textSpan = TextSpan(
      text: 'PT',
      style: TextStyle(
        color: color,
        fontSize: size.width * 0.25, // Adjust font size
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    // Position the text slightly to the right of the symbol
    textPainter.paint(
      canvas,
      Offset(centerX + coilRadius + 5, centerY - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant PotentialTransformerIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
