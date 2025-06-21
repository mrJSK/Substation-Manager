// lib/widgets/sld_equipment_node.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:substation_manager/models/equipment.dart';
import 'package:substation_manager/state/sld_state.dart';
import 'package:substation_manager/models/electrical_connection.dart';
import 'package:substation_manager/utils/snackbar_utils.dart';
import 'package:substation_manager/utils/grid_utils.dart'; // For snapToGrid
import 'package:collection/collection.dart'; // For firstWhereOrNull

// Import all individual equipment icon painters
import 'package:substation_manager/equipment_icons/transformer_icon.dart';
import 'package:substation_manager/equipment_icons/busbar_icon.dart'; // Ensure this is the updated one
import 'package:substation_manager/equipment_icons/circuit_breaker_icon.dart';
import 'package:substation_manager/equipment_icons/disconnector_icon.dart';
import 'package:substation_manager/equipment_icons/ct_icon.dart';
import 'package:substation_manager/equipment_icons/pt_icon.dart';
import 'package:substation_manager/equipment_icons/ground_icon.dart';
import 'package:substation_manager/equipment_icons/isolator_icon.dart';

// The abstract base class for EquipmentPainter is in transformer_icon.dart

// Define the fixed height for the connection poles (vertical lines extending from components)
const double _poleHeight =
    15.0; // Height of the connection lines above/below symbol
const double _labelVerticalPadding =
    4.0; // Padding between symbol and name/additional label
const double _handleSize =
    10.0; // Size of the draggable dots for busbar resizing

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
  // Method to map equipment symbolKey to the correct CustomPainter
  EquipmentPainter _getEquipmentPainter(
    String symbolKey,
    Color color,
    Size equipmentSize, {
    String? voltageText,
  }) {
    switch (symbolKey) {
      case 'Transformer':
        return TransformerIconPainter(
          color: color,
          equipmentSize: equipmentSize,
          symbolSize: equipmentSize,
        );
      case 'Busbar':
        return BusbarIconPainter(
          color: color,
          equipmentSize: equipmentSize,
          voltageText: voltageText,
          symbolSize: equipmentSize,
        );
      case 'Circuit Breaker':
        return CircuitBreakerIconPainter(
          color: color,
          equipmentSize: equipmentSize,
          symbolSize: equipmentSize,
        );
      case 'Disconnector':
        return DisconnectorIconPainter(
          color: color,
          equipmentSize: equipmentSize,
          symbolSize: equipmentSize,
        );
      case 'Current Transformer':
        return CurrentTransformerIconPainter(
          color: color,
          equipmentSize: equipmentSize,
          symbolSize: equipmentSize,
        );
      case 'Potential Transformer':
        return PotentialTransformerIconPainter(
          color: color,
          equipmentSize: equipmentSize,
          symbolSize: equipmentSize,
        );
      case 'Ground':
        return GroundIconPainter(
          color: color,
          equipmentSize: equipmentSize,
          symbolSize: equipmentSize,
        );
      case 'Isolator':
        return IsolatorIconPainter(color: color, equipmentSize: equipmentSize);
      default:
        return TransformerIconPainter(
          color: color,
          equipmentSize: equipmentSize,
          symbolSize: equipmentSize,
        ); // Default to transformer
    }
  }

  // Helper to build the connection poles/lines for equipment
  Widget _buildConnectionPoles(ColorScheme colorScheme) {
    // Busbars do not have vertical poles from this painter, connections go directly to the horizontal line.
    // The BusbarIconPainter itself draws the main horizontal line.
    if (widget.equipment.symbolKey == 'Busbar') {
      return Container(); // No poles drawn by _ConnectionPolePainter for busbars
    }

    // For other equipment (excluding Busbar), draw top and/or bottom poles
    final Color poleColor = colorScheme.onSurface.withOpacity(0.8);
    final double strokeWidth = 2.0;

    return Positioned.fill(
      // Fills the entire node container to draw poles
      child: CustomPaint(
        painter: _ConnectionPolePainter(
          poleColor: poleColor,
          strokeWidth: strokeWidth,
          isGround: widget.equipment.symbolKey == 'Ground',
        ),
        child: Container(),
      ),
    );
  }

  // Get voltage text for Busbar from its custom fields
  String? _getBusbarVoltageText() {
    if (widget.equipment.symbolKey == 'Busbar') {
      final template = context.read<SldState>().getTemplateForEquipment(
        widget.equipment,
      );
      final voltageFieldDef = template?.equipmentCustomFields.firstWhereOrNull(
        (field) => (field['name'] as String).toLowerCase() == 'voltage',
      );

      if (voltageFieldDef != null &&
          widget.equipment.customFieldValues.containsKey(
            voltageFieldDef['name'],
          )) {
        final voltageValue =
            widget.equipment.customFieldValues[voltageFieldDef['name']];
        final units = voltageFieldDef['units'] as String? ?? '';
        return voltageValue?.toString() != null &&
                voltageValue.toString().isNotEmpty
            ? '${voltageValue.toString()} $units'
            : null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final sldState = context.read<SldState>();
    final isSelected = sldState.selectedEquipment?.id == widget.equipment.id;
    final isConnectionStart =
        sldState.connectionStartEquipment?.id == widget.equipment.id;

    // Node dimensions are now directly from equipment.width/height
    final nodeWidth = widget.equipment.width;
    final nodeHeight = widget.equipment.height; // This is the symbol's height

    // Calculate the total height of the node's GestureDetector area, including poles and labels
    // Name label: 10px font height, Additional label: 9px font height
    // Each label has _labelVerticalPadding above and below it.
    final double nameLabelHeight = 10.0;
    final double additionalLabelHeight =
        widget.equipment.additionalLabel != null &&
            widget.equipment.additionalLabel!.isNotEmpty
        ? 9.0
        : 0.0;

    // Base height for symbol + labels and their padding
    double contentHeight = nodeHeight + _labelVerticalPadding + nameLabelHeight;
    if (additionalLabelHeight > 0) {
      contentHeight += (_labelVerticalPadding + additionalLabelHeight);
    }

    double totalNodeHeight = contentHeight;

    // Add pole height for non-busbar symbols.
    // Busbar doesn't have poles added by _ConnectionPolePainter, its line is its connection.
    // Ground only has a top pole.
    if (widget.equipment.symbolKey != 'Busbar') {
      totalNodeHeight += (widget.equipment.symbolKey == 'Ground'
          ? _poleHeight
          : (2 * _poleHeight));
    }

    final borderColor = isSelected
        ? widget
              .colorScheme
              .primary // Primary color for selected
        : (isConnectionStart
              ? widget
                    .colorScheme
                    .tertiary // Tertiary color for connection start
              : Colors.transparent); // Transparent when not selected/connecting
    final borderWidth = isSelected || isConnectionStart ? 3.0 : 0.0;

    final equipmentSymbolColor = isSelected || isConnectionStart
        ? widget
              .colorScheme
              .onPrimary // Text/symbol color contrasting with primary/tertiary
        : widget.colorScheme.onSurface.withOpacity(
            0.8,
          ); // Default text/symbol color

    final nodeBackgroundColor = isSelected
        ? widget.colorScheme.primary.withOpacity(
            0.8,
          ) // Background color for selection
        : (isConnectionStart
              ? widget.colorScheme.tertiary.withOpacity(
                  0.8,
                ) // Background for connection start
              : Colors.transparent); // Transparent by default

    return GestureDetector(
      onTap: () {
        sldState.selectEquipment(widget.equipment);
        if (sldState.connectionStartEquipment != null &&
            sldState.connectionStartEquipment?.id != widget.equipment.id) {
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
          sldState.setConnectionStartEquipment(null);
          SnackBarUtils.showSnackBar(context, 'Connection mode cancelled.');
        } else {
          sldState.selectEquipment(widget.equipment);
        }
      },
      onDoubleTap: () => widget.onDoubleTap(widget.equipment),
      onLongPress: widget.onLongPress != null
          ? () => widget.onLongPress!(widget.equipment)
          : null,
      onPanStart: (details) {
        // Only allow dragging if not a busbar (busbar handles resizing separately)
        if (widget.equipment.symbolKey != 'Busbar') {
          sldState.setIsDragging(true);
          sldState.selectEquipment(widget.equipment);
        }
      },
      onPanUpdate: (details) {
        if (sldState.isDragging && widget.equipment.symbolKey != 'Busbar') {
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
        if (widget.equipment.symbolKey != 'Busbar') {
          sldState.setIsDragging(false);
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
        }
      },
      child: Container(
        width: nodeWidth, // Use equipment's actual width
        height: totalNodeHeight, // Calculated total height
        // Removed default padding here, relying on symbol and label positioning
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: borderWidth),
          borderRadius: BorderRadius.circular(8),
          color: nodeBackgroundColor,
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Connection Poles (lines extending above and below the symbol, if applicable)
            _buildConnectionPoles(widget.colorScheme),

            // Main Symbol (positioned between poles or at top if no top pole)
            Positioned(
              // Position depends on whether a top pole exists for this symbol type
              top:
                  widget.equipment.symbolKey == 'Busbar' ||
                      widget.equipment.symbolKey == 'Ground'
                  ? 0
                  : _poleHeight,
              left: 0,
              right: 0,
              height:
                  nodeHeight, // Symbol's actual height (from equipment.height)
              child: CustomPaint(
                size: Size(
                  nodeWidth,
                  nodeHeight,
                ), // Pass equipment's actual width/height for the painter's drawing area
                painter: _getEquipmentPainter(
                  widget.equipment.symbolKey,
                  equipmentSymbolColor,
                  Size(nodeWidth, nodeHeight), // equipmentSize for the painter
                  voltageText:
                      _getBusbarVoltageText(), // Pass voltage for Busbar
                ),
              ),
            ),

            // Equipment Name (below the symbol)
            Positioned(
              top:
                  (widget.equipment.symbolKey == 'Busbar' ||
                          widget.equipment.symbolKey == 'Ground'
                      ? nodeHeight
                      : (_poleHeight + nodeHeight)) +
                  _labelVerticalPadding,
              left: 0,
              right: 0,
              child: Text(
                widget.equipment.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : widget.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Additional Label (below the name, if available)
            if (widget.equipment.additionalLabel != null &&
                widget.equipment.additionalLabel!.isNotEmpty)
              Positioned(
                top:
                    (widget.equipment.symbolKey == 'Busbar' ||
                            widget.equipment.symbolKey == 'Ground'
                        ? nodeHeight
                        : (_poleHeight + nodeHeight)) +
                    _labelVerticalPadding +
                    nameLabelHeight +
                    _labelVerticalPadding,
                left: 0,
                right: 0,
                child: Text(
                  widget.equipment.additionalLabel!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    color: isSelected
                        ? Colors.white70
                        : widget.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // NEW: Draggable handles for Busbar resizing (visible only when selected)
            if (isSelected && widget.equipment.symbolKey == 'Busbar') ...[
              // Left handle
              Positioned(
                left:
                    -_handleSize /
                    2, // Position handle outside the busbar's drawn width
                top: totalNodeHeight / 2 - _handleSize / 2,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    sldState.selectEquipment(
                      widget.equipment,
                    ); // Keep selected while resizing
                    final newWidth = widget.equipment.width - details.delta.dx;
                    final newX = widget.equipment.positionX + details.delta.dx;
                    if (newWidth > widget.equipment.minWidth) {
                      final snappedWidth = snapToGrid(Offset(newWidth, 0)).dx;
                      final snappedX = snapToGrid(Offset(newX, 0)).dx;
                      sldState.updateEquipment(
                        widget.equipment.copyWith(
                          width: snappedWidth,
                          positionX: snappedX,
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: _handleSize,
                    height: _handleSize,
                    decoration: BoxDecoration(
                      color: widget.colorScheme.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
              ),
              // Right handle
              Positioned(
                right:
                    -_handleSize /
                    2, // Position handle outside the busbar's drawn width
                top: totalNodeHeight / 2 - _handleSize / 2,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    sldState.selectEquipment(
                      widget.equipment,
                    ); // Keep selected while resizing
                    final newWidth = widget.equipment.width + details.delta.dx;
                    if (newWidth > widget.equipment.minWidth) {
                      final snappedWidth = snapToGrid(Offset(newWidth, 0)).dx;
                      sldState.updateEquipment(
                        widget.equipment.copyWith(width: snappedWidth),
                      );
                    }
                  },
                  child: Container(
                    width: _handleSize,
                    height: _handleSize,
                    decoration: BoxDecoration(
                      color: widget.colorScheme.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Painter for drawing the connection poles/lines for equipment (excluding busbars)
class _ConnectionPolePainter extends CustomPainter {
  final Color poleColor;
  final double strokeWidth;
  final bool isGround;

  _ConnectionPolePainter({
    required this.poleColor,
    required this.strokeWidth,
    this.isGround = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = poleColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final double centerX = size.width / 2;
    final double topPoleY = 0;
    final double bottomPoleY = size.height;

    // Ground only has a top connection point (line extending upwards from the symbol)
    if (isGround) {
      canvas.drawLine(
        Offset(centerX, topPoleY),
        Offset(centerX, topPoleY + _poleHeight),
        paint,
      );
    } else {
      // For other equipment (non-busbar, non-ground)
      canvas.drawLine(
        Offset(centerX, topPoleY),
        Offset(centerX, topPoleY + _poleHeight),
        paint,
      ); // Top pole
      canvas.drawLine(
        Offset(centerX, bottomPoleY),
        Offset(centerX, bottomPoleY - _poleHeight),
        paint,
      ); // Bottom pole
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionPolePainter oldDelegate) {
    return oldDelegate.poleColor != poleColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.isGround != isGround;
  }
}
