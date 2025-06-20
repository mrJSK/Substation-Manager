// lib/widgets/sld_equipment_node.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:substation_manager/models/equipment.dart';
import 'package:substation_manager/services/equipment_firestore_service.dart';
import 'package:substation_manager/utils/snackbar_utils.dart';
import 'package:substation_manager/state/sld_state.dart';
import 'package:collection/collection.dart' as collection;
import 'package:uuid/uuid.dart';
import 'package:substation_manager/models/electrical_connection.dart';

class SldEquipmentNode extends StatelessWidget {
  final Equipment equipment;
  final ColorScheme colorScheme;
  final Function(Equipment equipment) onDoubleTap;
  final Function(Equipment equipment) onLongPress;

  const SldEquipmentNode({
    super.key,
    required this.equipment,
    required this.colorScheme,
    required this.onDoubleTap,
    required this.onLongPress,
  });

  IconData _getIconForEquipmentType(String type) {
    switch (type.toLowerCase()) {
      case 'power transformer':
        return Icons.power;
      case 'circuit breaker':
        return Icons.flash_on;
      case 'isolator':
        return Icons.flip_to_front;
      case 'current transformer (ct)':
      case 'voltage transformer (vt/pt)':
        return Icons.bolt;
      case 'busbar':
        return Icons.horizontal_rule;
      case 'lightning arrester (la)':
        return Icons.shield;
      case 'wave trap':
        return Icons.waves;
      case 'shunt reactor':
        return Icons.device_thermostat;
      case 'capacitor bank':
        return Icons.battery_charging_full;
      case 'line':
        return Icons.linear_scale;
      case 'control panel':
        return Icons.settings_remote;
      case 'relay panel':
        return Icons.vpn_key;
      case 'battery bank':
        return Icons.battery_full;
      case 'ac/dc distribution board':
        return Icons.dashboard;
      case 'earthing system':
        return Icons.public;
      case 'energy meter':
        return Icons.electric_meter;
      case 'auxiliary transformer':
        return Icons.power_input;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sldState = context.watch<SldState>();
    final isSelected =
        sldState.selectedEquipment?.id == equipment.id ||
        sldState.connectionStartEquipment?.id == equipment.id;

    return GestureDetector(
      onTap: () {
        if (sldState.connectionStartEquipment != null) {
          // If in connection mode, this tap is to complete the connection
          final startEq = sldState.connectionStartEquipment!;
          if (startEq.id == equipment.id) {
            SnackBarUtils.showSnackBar(
              context,
              'Cannot connect equipment to itself.',
              isError: true,
            );
            sldState.setConnectionStartEquipment(null);
            return;
          }

          final existingConnection = sldState.connections.firstWhereOrNull(
            (conn) =>
                (conn.fromEquipmentId == startEq.id &&
                    conn.toEquipmentId == equipment.id) ||
                (conn.fromEquipmentId == equipment.id &&
                    conn.toEquipmentId == startEq.id),
          );

          if (existingConnection != null) {
            SnackBarUtils.showSnackBar(
              context,
              'Connection already exists between these equipment.',
              isError: true,
            );
            sldState.setConnectionStartEquipment(null);
            return;
          }

          final newConnection = ElectricalConnection(
            id: const Uuid().v4(),
            substationId: equipment.substationId,
            fromEquipmentId: startEq.id,
            toEquipmentId: equipment.id,
            connectionType: 'line-segment',
          );
          sldState.addConnection(newConnection);
          sldState.selectConnection(newConnection);
          sldState.setConnectionStartEquipment(null);
          SnackBarUtils.showSnackBar(
            context,
            'Connection created! Remember to save your changes.',
          );
        } else {
          // Normal selection mode
          sldState.selectEquipment(equipment);
        }
      },
      onDoubleTap: () => onDoubleTap(equipment),
      onLongPress: () => onLongPress(equipment),
      onPanStart: (details) {
        sldState.setIsDragging(true);
        sldState.selectEquipment(equipment);
      },
      onPanUpdate: (details) {
        sldState.updateEquipmentPosition(
          equipment.id,
          Offset(
            equipment.positionX! + details.delta.dx,
            equipment.positionY! + details.delta.dy,
          ),
        );
      },
      onPanEnd: (details) {
        sldState.setIsDragging(false);
        // Persist position change to Firestore
        final updatedEquipment = sldState.placedEquipment[equipment.id];
        if (updatedEquipment != null) {
          EquipmentFirestoreService().updateEquipment(updatedEquipment);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.tertiary.withOpacity(0.7)
              : colorScheme.primary.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: colorScheme.onTertiary, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.4 : 0.2),
              spreadRadius: isSelected ? 2 : 1,
              blurRadius: isSelected ? 6 : 3,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForEquipmentType(equipment.equipmentType),
              color: isSelected
                  ? colorScheme.onTertiary
                  : colorScheme.onPrimary,
              size: 30,
            ),
            const SizedBox(height: 4),
            Text(
              equipment.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? colorScheme.onTertiary
                    : colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
