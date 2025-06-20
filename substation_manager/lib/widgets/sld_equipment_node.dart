// lib/widgets/sld_equipment_node.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:substation_manager/models/equipment.dart';
import 'package:substation_manager/state/sld_state.dart';
import 'package:substation_manager/models/electrical_connection.dart';
import 'package:substation_manager/utils/snackbar_utils.dart';
import 'package:substation_manager/utils/grid_utils.dart';

// Import all individual equipment icon painters
import 'package:substation_manager/equipment_icons/transformer_icon.dart';
import 'package:substation_manager/equipment_icons/busbar_icon.dart';
import 'package:substation_manager/equipment_icons/circuit_breaker_icon.dart';
import 'package:substation_manager/equipment_icons/disconnector_icon.dart';
import 'package:substation_manager/equipment_icons/ct_icon.dart';
import 'package:substation_manager/equipment_icons/pt_icon.dart';
import 'package:substation_manager/equipment_icons/ground_icon.dart';

// The abstract base class for EquipmentPainter is now in transformer_icon.dart
// (or any other icon file, as long as it's imported by all)

// Main SldEquipmentNode widget
class SldEquipmentNode extends StatefulWidget {
  final Equipment equipment;
  final ColorScheme colorScheme;
  final Function(Equipment) onDoubleTap;
  final Function(Equipment)? onLongPress;

  const SldEquipmentNode({
    super.key,
    required this.equipment,
    required this.colorScheme,
    required this.onDoubleTap,
    this.onLongPress,
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
      case 'Current Transformer': // CT/PT might need more horizontal space for text
      case 'Potential Transformer':
        return const Size(80, 60); // Wider to accommodate text beside symbol
      default:
        return const Size(60, 60); // Default square size for others
    }
  }

  // Method to map equipment symbolKey to the correct CustomPainter
  EquipmentPainter _getEquipmentPainter(String symbolKey, Color color) {
    switch (symbolKey) {
      case 'Transformer':
        return TransformerIconPainter(color: color);
      case 'Busbar':
        return BusbarIconPainter(color: color);
      case 'Circuit Breaker':
        return CircuitBreakerIconPainter(color: color);
      case 'Disconnector':
        return DisconnectorIconPainter(color: color);
      case 'Current Transformer':
        return CurrentTransformerIconPainter(color: color);
      case 'Potential Transformer':
        return PotentialTransformerIconPainter(color: color);
      case 'Ground':
        return GroundIconPainter(color: color);
      default:
        // Fallback for unknown symbol keys
        return TransformerIconPainter(color: color); // Default to transformer
    }
  }

  @override
  Widget build(BuildContext context) {
    final sldState = context.read<SldState>();
    final isSelected = sldState.selectedEquipment?.id == widget.equipment.id;
    final isConnectionStart =
        sldState.connectionStartEquipment?.id == widget.equipment.id;

    // Use equipmentType for logical sizing, but symbolKey for visual representation
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
          SnackBarUtils.showSnackBar(
            context,
            'Connected ${sldState.connectionStartEquipment!.name} to ${widget.equipment.name}',
          );
        } else if (sldState.connectionStartEquipment?.id ==
            widget.equipment.id) {
          // Tapping the same equipment again cancels connection mode
          sldState.setConnectionStartEquipment(null);
          SnackBarUtils.showSnackBar(context, 'Connection mode cancelled.');
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
              widget.equipment.positionX + details.delta.dx,
              widget.equipment.positionY + details.delta.dy,
            ),
          );
        }
      },
      onPanEnd: (details) {
        sldState.setIsDragging(false);
        // Snap the equipment to the grid on pan end
        final snappedPosition = snapToGrid(
          Offset(widget.equipment.positionX, widget.equipment.positionY),
        );
        if (snappedPosition !=
            Offset(widget.equipment.positionX, widget.equipment.positionY)) {
          sldState.updateEquipmentPosition(
            widget.equipment.id,
            snappedPosition,
          );
        }
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
                  widget.equipment.symbolKey,
                  equipmentSymbolColor,
                ), // NOW USES symbolKey
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
