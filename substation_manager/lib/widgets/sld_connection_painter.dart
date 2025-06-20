// lib/widgets/sld_connection_painter.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:substation_manager/models/equipment.dart';
import 'package:substation_manager/models/electrical_connection.dart';
import 'package:collection/collection.dart'; // Import for listEquals

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

  // Helper to get the center of an equipment for connection drawing
  Offset _getEquipmentCenter(String equipmentId) {
    final eq = equipment.firstWhereOrNull((e) => e.id == equipmentId);
    if (eq == null) return Offset.zero;

    // These sizes must match the sizes used in SldEquipmentNode
    Size nodeSize;
    switch (eq.equipmentType) {
      case 'Busbar':
        nodeSize = const Size(120, 15);
        break;
      default:
        nodeSize = const Size(60, 60);
        break;
    }

    // Adjust for the padding and label height in SldEquipmentNode to find the center of the symbol
    double symbolCenterX = eq.positionX! + nodeSize.width / 2;
    double symbolCenterY =
        eq.positionY! +
        (nodeSize.height * 1.5) / 2; // Full height of the node including label

    return Offset(symbolCenterX, symbolCenterY);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = colorScheme.onSurface.withOpacity(0.6)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final Paint selectedLinePaint = Paint()
      ..color = colorScheme
          .secondary // A distinct color for selected connections
      ..strokeWidth =
          5.0 // Thicker for selected connections
      ..strokeCap = StrokeCap.round;

    for (final conn in connections) {
      final startPoint = _getEquipmentCenter(conn.fromEquipmentId);
      final endPoint = _getEquipmentCenter(conn.toEquipmentId);

      if (startPoint != Offset.zero && endPoint != Offset.zero) {
        final currentPaint = selectedConnection?.id == conn.id
            ? selectedLinePaint
            : linePaint;
        canvas.drawLine(startPoint, endPoint, currentPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) {
    return !listEquals(oldDelegate.equipment, equipment) ||
        !listEquals(oldDelegate.connections, connections) ||
        oldDelegate.selectedConnection != selectedConnection ||
        oldDelegate.colorScheme != colorScheme;
  }

  // Helper function to compare lists for changes
  @override
  // ignore: unnecessary_overrides
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionPainter &&
          runtimeType == other.runtimeType &&
          listEquals(equipment, other.equipment) &&
          listEquals(connections, other.connections) &&
          selectedConnection == other.selectedConnection &&
          colorScheme == other.colorScheme;

  @override
  int get hashCode => Object.hash(
    listEquals(equipment, equipment),
    listEquals(connections, connections),
    selectedConnection,
    colorScheme,
  );
}
