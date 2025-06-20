// lib/widgets/sld_connection_painter.dart

import 'package:flutter/material.dart';
import 'package:substation_manager/models/equipment.dart';
import 'package:substation_manager/models/electrical_connection.dart';

class ConnectionPainter extends CustomPainter {
  final List<Equipment> equipment;
  final List<ElectricalConnection> connections;
  final Function(ElectricalConnection) onConnectionTap;
  final ElectricalConnection? selectedConnection;
  final ColorScheme colorScheme;

  ConnectionPainter({
    required this.equipment,
    required this.connections,
    required this.onConnectionTap,
    this.selectedConnection,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Map<String, Equipment> equipmentMap = {
      for (var eq in equipment) eq.id: eq,
    };

    for (var connection in connections) {
      final fromEq = equipmentMap[connection.fromEquipmentId];
      final toEq = equipmentMap[connection.toEquipmentId];

      if (fromEq != null &&
          toEq != null &&
          fromEq.positionX != null &&
          fromEq.positionY != null &&
          toEq.positionX != null &&
          toEq.positionY != null) {
        final Offset startPoint = Offset(
          fromEq.positionX! + 45,
          fromEq.positionY! + 45,
        );
        final Offset endPoint = Offset(
          toEq.positionX! + 45,
          toEq.positionY! + 45,
        );

        final Paint paint = Paint()
          ..color = (selectedConnection?.id == connection.id)
              ? colorScheme.tertiary
              : Colors.blue.shade700
          ..strokeWidth = (selectedConnection?.id == connection.id) ? 4.0 : 3.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(startPoint, endPoint, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is ConnectionPainter) {
      return oldDelegate.equipment != equipment ||
          oldDelegate.connections != connections ||
          oldDelegate.selectedConnection != selectedConnection ||
          oldDelegate.colorScheme != colorScheme;
    }
    return true;
  }
}
