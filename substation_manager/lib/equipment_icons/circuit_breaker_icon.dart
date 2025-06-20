// lib/equipment_icons/circuit_breaker_icon.dart

import 'package:flutter/material.dart';
import 'package:substation_manager/equipment_icons/transformer_icon.dart'; // Import base EquipmentPainter

class CircuitBreakerIconPainter extends EquipmentPainter {
  CircuitBreakerIconPainter({required super.color, super.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5; // Circle radius, with padding

    canvas.drawCircle(center, radius, paint);

    // Cross lines for breaker
    canvas.drawLine(
      Offset(center.dx - radius * 0.7, center.dy - radius * 0.7),
      Offset(center.dx + radius * 0.7, center.dy + radius * 0.7),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + radius * 0.7, center.dy - radius * 0.7),
      Offset(center.dx - radius * 0.7, center.dy + radius * 0.7),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CircuitBreakerIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
