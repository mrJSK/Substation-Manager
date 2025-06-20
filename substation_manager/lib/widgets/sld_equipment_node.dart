// lib/widgets/sld_equipment_node.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:substation_manager/models/electrical_connection.dart';
import 'package:substation_manager/models/equipment.dart';
import 'package:substation_manager/state/sld_state.dart';

// Abstract class for all equipment painters
abstract class EquipmentPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  EquipmentPainter({required this.color, this.strokeWidth = 2.0});
}

// Implement specific painters for each equipment type
class TransformerPainter extends EquipmentPainter {
  TransformerPainter({required super.color, super.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final width = size.width;
    final height = size.height;

    // Coils
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(width * 0.1, height * 0.25, width * 0.25, height * 0.5),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(width * 0.65, height * 0.25, width * 0.25, height * 0.5),
        const Radius.circular(2),
      ),
      paint,
    );

    // Connecting lines between coils (simplified for visual clarity)
    canvas.drawLine(
      Offset(width * 0.35, height * 0.35),
      Offset(width * 0.65, height * 0.35),
      paint,
    );
    canvas.drawLine(
      Offset(width * 0.35, height * 0.65),
      Offset(width * 0.65, height * 0.65),
      paint,
    );

    // Terminals
    canvas.drawLine(
      Offset(width * 0.225, height * 0.1),
      Offset(width * 0.225, height * 0.25),
      paint,
    );
    canvas.drawLine(
      Offset(width * 0.775, height * 0.1),
      Offset(width * 0.775, height * 0.25),
      paint,
    );
    canvas.drawLine(
      Offset(width * 0.225, height * 0.75),
      Offset(width * 0.225, height * 0.9),
      paint,
    );
    canvas.drawLine(
      Offset(width * 0.775, height * 0.75),
      Offset(width * 0.775, height * 0.9),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant TransformerPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

class BusbarPainter extends EquipmentPainter {
  BusbarPainter({required super.color, super.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill; // Busbars are typically filled rectangles

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant BusbarPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

class CircuitBreakerPainter extends EquipmentPainter {
  CircuitBreakerPainter({required super.color, super.strokeWidth});

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
  bool shouldRepaint(covariant CircuitBreakerPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

class DisconnectorPainter extends EquipmentPainter {
  DisconnectorPainter({required super.color, super.strokeWidth});

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
  bool shouldRepaint(covariant DisconnectorPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

class CurrentTransformerPainter extends EquipmentPainter {
  CurrentTransformerPainter({required super.color, super.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    // Toroidal core
    canvas.drawCircle(center, radius, paint);
    // Primary winding passing through
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CurrentTransformerPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

class PotentialTransformerPainter extends EquipmentPainter {
  PotentialTransformerPainter({required super.color, super.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.7,
      height: size.height * 0.7,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      paint,
    );

    // Terminals
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(size.width / 2, rect.bottom),
      Offset(size.width / 2, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant PotentialTransformerPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

class GroundPainter extends EquipmentPainter {
  GroundPainter({required super.color, super.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(
      center.translate(0, -size.height * 0.4),
      center.translate(0, 0),
      paint,
    ); // Vertical line
    canvas.drawLine(
      center.translate(-size.width * 0.3, 0),
      center.translate(size.width * 0.3, 0),
      paint,
    ); // Top horizontal
    canvas.drawLine(
      center.translate(-size.width * 0.2, size.height * 0.15),
      center.translate(size.width * 0.2, size.height * 0.15),
      paint,
    ); // Middle horizontal
    canvas.drawLine(
      center.translate(-size.width * 0.1, size.height * 0.3),
      center.translate(size.width * 0.1, size.height * 0.3),
      paint,
    ); // Bottom horizontal
  }

  @override
  bool shouldRepaint(covariant GroundPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

// Main SldEquipmentNode widget
class SldEquipmentNode extends StatefulWidget {
  final Equipment equipment;
  final ColorScheme colorScheme;
  final Function(Equipment) onDoubleTap;
  final Function(Equipment)? onLongPress; // Made optional

  const SldEquipmentNode({
    super.key,
    required this.equipment,
    required this.colorScheme,
    required this.onDoubleTap,
    this.onLongPress, // Now optional
  });

  @override
  State<SldEquipmentNode> createState() => _SldEquipmentNodeState();
}

class _SldEquipmentNodeState extends State<SldEquipmentNode> {
  // Define default sizes for each equipment type
  Size _getEquipmentSize(String equipmentType) {
    switch (equipmentType) {
      case 'Busbar':
        return const Size(120, 15); // Busbar is typically wider and thinner
      default:
        return const Size(60, 60); // Default square size for others
    }
  }

  EquipmentPainter _getEquipmentPainter(String equipmentType, Color color) {
    switch (equipmentType) {
      case 'Transformer':
        return TransformerPainter(color: color);
      case 'Busbar':
        return BusbarPainter(color: color);
      case 'Circuit Breaker':
        return CircuitBreakerPainter(color: color);
      case 'Disconnector':
        return DisconnectorPainter(color: color);
      case 'Current Transformer':
        return CurrentTransformerPainter(color: color);
      case 'Potential Transformer':
        return PotentialTransformerPainter(color: color);
      case 'Ground':
        return GroundPainter(color: color);
      default:
        // Fallback for unknown types
        return TransformerPainter(color: color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sldState = context.read<SldState>();
    final isSelected = sldState.selectedEquipment?.id == widget.equipment.id;
    final isConnectionStart =
        sldState.connectionStartEquipment?.id == widget.equipment.id;

    final nodeSize = _getEquipmentSize(widget.equipment.equipmentType);
    final borderColor = isSelected
        ? widget
              .colorScheme
              .primary // Highlight selected
        : (isConnectionStart
              ? widget
                    .colorScheme
                    .tertiary // Highlight connection start
              : Colors.transparent);
    final borderWidth = isSelected || isConnectionStart ? 3.0 : 0.0;

    // Determine the base color for the equipment symbol
    final equipmentSymbolColor = isSelected || isConnectionStart
        ? Colors
              .white // Symbol color when selected or connecting
        : widget.colorScheme.onSurface.withOpacity(0.8); // Default symbol color

    // Determine the background color of the equipment node
    final nodeBackgroundColor = isSelected
        ? widget.colorScheme.primary.withOpacity(0.8) // Selected background
        : (isConnectionStart
              ? widget.colorScheme.tertiary.withOpacity(
                  0.8,
                ) // Connection start background
              : widget.colorScheme.surface); // Default background

    return GestureDetector(
      onTap: () {
        sldState.selectEquipment(widget.equipment);
        if (sldState.connectionStartEquipment != null &&
            sldState.connectionStartEquipment?.id != widget.equipment.id) {
          // Complete the connection
          final newConnection = ElectricalConnection(
            substationId: widget.equipment.substationId,
            fromEquipmentId: sldState.connectionStartEquipment!.id,
            toEquipmentId: widget.equipment.id,
          );
          sldState.addConnection(newConnection);
          sldState.setConnectionStartEquipment(null);
          // Show a snackbar message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Connected ${sldState.connectionStartEquipment!.name} to ${widget.equipment.name}',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (sldState.connectionStartEquipment?.id ==
            widget.equipment.id) {
          // Tapping the same equipment again cancels connection mode
          sldState.setConnectionStartEquipment(null);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connection mode cancelled.'),
              duration: Duration(seconds: 1),
            ),
          );
        } else {
          // Normal selection
          sldState.selectEquipment(widget.equipment);
        }
      },
      onDoubleTap: () => widget.onDoubleTap(widget.equipment),
      onLongPress: widget.onLongPress != null
          ? () => widget.onLongPress!(widget.equipment)
          : null,
      onPanStart: (details) {
        sldState.setIsDragging(true);
        sldState.selectEquipment(widget.equipment);
      },
      onPanUpdate: (details) {
        if (sldState.isDragging) {
          sldState.updateEquipmentPosition(
            widget.equipment.id,
            Offset(
              widget.equipment.positionX! + details.delta.dx,
              widget.equipment.positionY! + details.delta.dy,
            ),
          );
        }
      },
      onPanEnd: (details) {
        sldState.setIsDragging(false);
      },
      child: Material(
        elevation: isSelected ? 8 : 4,
        borderRadius: BorderRadius.circular(
          nodeSize.height / 4,
        ), // Rounded corners
        color: nodeBackgroundColor,
        child: Container(
          width: nodeSize.width,
          height: nodeSize.height * 1.5, // Make space for label
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: borderWidth),
            borderRadius: BorderRadius.circular(nodeSize.height / 4),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: widget.colorScheme.primary.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 3,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomPaint(
                size: Size(
                  nodeSize.width * 0.8,
                  nodeSize.height * 0.8,
                ), // Adjust size for symbol
                painter: _getEquipmentPainter(
                  widget.equipment.equipmentType,
                  equipmentSymbolColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.equipment.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : widget.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
