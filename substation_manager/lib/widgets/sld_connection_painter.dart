// lib/widgets/sld_connection_painter.dart

import 'package:flutter/material.dart';
import 'package:substation_manager/models/equipment.dart';
import 'package:substation_manager/models/electrical_connection.dart';
import 'package:collection/collection.dart';
import 'package:substation_manager/widgets/sld_equipment_node.dart'; // Import for _poleHeight
import 'package:substation_manager/utils/grid_utils.dart'; // Import for gridSize
import 'dart:math'; // For min/max

// Define the pole height used for connection calculations
const double _poleHeight = 24.0;

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
    required double gridSize,
  });

  // Helper to get the connection point of an equipment (top or bottom pole end, or busbar line)
  Offset _getEquipmentConnectionPoint(
    String equipmentId,
    bool isConnectingTo,
    Offset otherComponentCenter,
  ) {
    final eq = equipment.firstWhereOrNull((e) => e.id == equipmentId);
    if (eq == null) return Offset.zero;

    // Base position of the equipment node
    final double nodeX = eq.positionX;
    final double nodeY = eq.positionY;

    // Use equipment's actual width and height
    final double symbolWidth = eq.width;
    final double symbolHeight = eq.height;

    if (eq.symbolKey == 'Busbar') {
      // For Busbars, the connection point is on the horizontal line itself.
      final double busbarLineY =
          nodeY + (symbolHeight / 2); // Center of the busbar's own drawing area

      // Calculate the X position on the busbar. It should align with the connecting component's X.
      // Clamp the X to stay within the busbar's horizontal extent.
      double connectionX = otherComponentCenter.dx;
      // Snap this X to the nearest grid line for a cleaner look if desired
      connectionX = snapToGrid(Offset(connectionX, 0)).dx;

      // Ensure the connectionX is within the bounds of the busbar's visual width
      connectionX = max(nodeX, min(nodeX + symbolWidth, connectionX));

      return Offset(connectionX, busbarLineY);
    } else if (eq.symbolKey == 'Ground') {
      // Ground only has a top connection point (line extending upwards from the symbol)
      final double connectionX = nodeX + symbolWidth / 2;
      return Offset(connectionX, nodeY + _poleHeight / 2);
    } else {
      // For other equipment, connect to the center of the pole.
      // The overall height of the SldEquipmentNode includes symbol + 2 * _poleHeight + labels
      // The symbol itself starts at _poleHeight from the top of the SldEquipmentNode container.
      final double symbolTopYInNode = _poleHeight;
      final double symbolBottomYInNode = _poleHeight + symbolHeight;

      final double connectionX = nodeX + symbolWidth / 2;

      if (isConnectingTo) {
        // If this is the 'to' component (line connects to its top)
        // Connection point is at the end of the top pole
        return Offset(
          connectionX,
          nodeY + symbolTopYInNode - _poleHeight / 2,
        ); // Half pole height from node's top edge
      } else {
        // If this is the 'from' component (line connects from its bottom)
        // Connection point is at the end of the bottom pole
        return Offset(
          connectionX,
          nodeY + symbolBottomYInNode + _poleHeight / 2,
        ); // Half pole height from node's bottom edge
      }
    }
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
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    for (final conn in connections) {
      final fromEq = equipment.firstWhereOrNull(
        (e) => e.id == conn.fromEquipmentId,
      );
      final toEq = equipment.firstWhereOrNull(
        (e) => e.id == conn.toEquipmentId,
      );

      if (fromEq == null || toEq == null) {
        continue; // Skip if either equipment not found
      }

      // Get approximate centers for calculation of connection points relative to each other
      // Note: This is simplified. For more complex layouts, a nearest connection point algorithm might be better.
      final Offset fromEqCenter = Offset(
        fromEq.positionX + fromEq.width / 2,
        fromEq.positionY + fromEq.height / 2,
      );
      final Offset toEqCenter = Offset(
        toEq.positionX + toEq.width / 2,
        toEq.positionY + toEq.height / 2,
      );

      final Offset startPoint = _getEquipmentConnectionPoint(
        conn.fromEquipmentId,
        false,
        toEqCenter,
      ); // Connect from bottom of 'from' towards 'to'
      final Offset endPoint = _getEquipmentConnectionPoint(
        conn.toEquipmentId,
        true,
        fromEqCenter,
      ); // Connect to top of 'to' from 'from'

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
    // Repaint if number of equipment or connections changes, or if any equipment position/size changes
    // or if selectedConnection changes
    return oldDelegate.equipment.length != equipment.length ||
        oldDelegate.connections.length != connections.length ||
        oldDelegate.selectedConnection != selectedConnection ||
        oldDelegate.colorScheme != colorScheme ||
        !listEquals(
          oldDelegate.equipment.map((e) => e.positionX).toList(),
          equipment.map((e) => e.positionX).toList(),
        ) ||
        !listEquals(
          oldDelegate.equipment.map((e) => e.positionY).toList(),
          equipment.map((e) => e.positionY).toList(),
        ) ||
        !listEquals(
          oldDelegate.equipment.map((e) => e.width).toList(),
          equipment.map((e) => e.width).toList(),
        ) ||
        !listEquals(
          oldDelegate.equipment.map((e) => e.height).toList(),
          equipment.map((e) => e.height).toList(),
        );
  }

  // Helper function to compare lists for changes
  bool listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
