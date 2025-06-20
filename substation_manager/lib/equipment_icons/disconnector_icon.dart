// lib/equipment_icons/disconnector_icon.dart

import 'package:flutter/material.dart';
import 'package:substation_manager/equipment_icons/transformer_icon.dart'; // Import base EquipmentPainter

class DisconnectorIconPainter extends EquipmentPainter {
  DisconnectorIconPainter({required super.color, super.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Line representing the disconnector blade (open position)
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.1),
      Offset(size.width * 0.9, size.height * 0.9),
      paint,
    );
    // Connection points (circles)
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.1), 3, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.9), 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant DisconnectorIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
