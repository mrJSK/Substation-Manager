// lib/state/sld_state.dart

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:substation_manager/models/master_equipment_template.dart';
import 'package:substation_manager/models/equipment.dart';
import 'package:substation_manager/models/electrical_connection.dart';
import 'package:substation_manager/models/substation.dart';
import 'package:substation_manager/services/equipment_firestore_service.dart';
import 'package:substation_manager/services/electrical_connection_firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart'; // Added for Uuid

class SldState extends ChangeNotifier {
  // Add a unique ID for debugging instances
  final String debugId = const Uuid().v4().substring(0, 4);

  final Map<String, Equipment> _placedEquipment = {};
  final List<ElectricalConnection> _connections = [];
  Equipment? _selectedEquipment;
  ElectricalConnection? _selectedConnection;
  Equipment? _connectionStartEquipment;
  bool _isLoadingTemplates = false;
  List<MasterEquipmentTemplate> _availableTemplates = [];

  final EquipmentFirestoreService _equipmentFirestoreService =
      EquipmentFirestoreService();
  final ElectricalConnectionFirestoreService _connectionFirestoreService =
      ElectricalConnectionFirestoreService();

  MasterEquipmentTemplate? _selectedTemplateInModal;
  Equipment? _selectedEquipmentInModal;

  final Map<String, Equipment> _initialEquipmentSnapshot = {};
  final List<ElectricalConnection> _initialConnectionSnapshot = [];

  bool _hasPendingChanges = false;
  bool _isDragging = false; // Add this flag
  // Removed _isCanvasPanEnabled as it's now controlled by _isDragging

  void clearAllSldElements() {
    _placedEquipment.clear();
    _connections.clear();
    _selectedEquipment = null;
    _selectedConnection = null;
    _connectionStartEquipment = null;
    _hasPendingChanges = true;
    print(
      'DEBUG: SldState($debugId).clearAllSldElements called. _hasPendingChanges = $_hasPendingChanges',
    );
    notifyListeners();
  }

  Map<String, Equipment> get placedEquipment => _placedEquipment;
  List<ElectricalConnection> get connections => _connections;
  Equipment? get selectedEquipment => _selectedEquipment;
  ElectricalConnection? get selectedConnection => _selectedConnection;
  Equipment? get connectionStartEquipment => _connectionStartEquipment;
  bool get isLoadingTemplates => _isLoadingTemplates;
  List<MasterEquipmentTemplate> get availableTemplates => _availableTemplates;
  MasterEquipmentTemplate? get selectedTemplateInModal =>
      _selectedTemplateInModal;
  Equipment? get selectedEquipmentInModal => _selectedEquipmentInModal;
  bool get hasPendingChanges {
    print(
      'DEBUG: SldState($debugId).hasPendingChanges getter called: $_hasPendingChanges',
    );
    return _hasPendingChanges;
  }

  bool get isDragging => _isDragging; // Getter for the new flag

  // Setter for the new flag
  void setIsDragging(bool dragging) {
    if (_isDragging != dragging) {
      _isDragging = dragging;
      notifyListeners(); // Notify listeners when this changes
    }
  }

  void addEquipment(Equipment equipment) {
    _placedEquipment[equipment.id] = equipment;
    _hasPendingChanges = true;
    print(
      'DEBUG: SldState($debugId).addEquipment called. _hasPendingChanges = $_hasPendingChanges',
    );
    notifyListeners();
  }

  void updateEquipment(Equipment equipment) {
    if (_placedEquipment.containsKey(equipment.id)) {
      _placedEquipment[equipment.id] = equipment;
      _hasPendingChanges = true;
      print(
        'DEBUG: SldState($debugId).updateEquipment called. _hasPendingChanges = $_hasPendingChanges',
      );
      notifyListeners();
    }
  }

  void updateEquipmentPosition(String id, Offset newPosition) {
    if (_placedEquipment.containsKey(id)) {
      _placedEquipment[id] = _placedEquipment[id]!.copyWith(
        positionX: newPosition.dx,
        positionY: newPosition.dy,
      );
      _hasPendingChanges = true;
      print(
        'DEBUG: SldState($debugId).updateEquipmentPosition called. _hasPendingChanges = $_hasPendingChanges',
      );
      notifyListeners();
    }
  }

  void removeEquipment(String id) {
    _placedEquipment.remove(id);
    _hasPendingChanges = true;
    print(
      'DEBUG: SldState($debugId).removeEquipment called. _hasPendingChanges = $_hasPendingChanges',
    );
    notifyListeners();
  }

  void addConnection(ElectricalConnection connection) {
    // Prevent adding duplicate connections (by checking if from/to pair already exists,
    // regardless of order, or if the exact connection ID already exists)
    final isDuplicate = _connections.any((existingConn) {
      return (existingConn.fromEquipmentId == connection.fromEquipmentId &&
              existingConn.toEquipmentId == connection.toEquipmentId) ||
          (existingConn.fromEquipmentId == connection.toEquipmentId &&
              existingConn.toEquipmentId == connection.fromEquipmentId);
    });

    if (!isDuplicate) {
      _connections.add(connection);
      _hasPendingChanges = true;
      print(
        'DEBUG: SldState($debugId).addConnection called. _hasPendingChanges = $_hasPendingChanges',
      );
      notifyListeners();
    } else {
      print('DEBUG: Attempted to add duplicate connection. Ignored.');
    }
  }

  void removeConnection(String id) {
    _connections.removeWhere((conn) => conn.id == id);
    _hasPendingChanges = true;
    print(
      'DEBUG: SldState($debugId).removeConnection called. _hasPendingChanges = $_hasPendingChanges',
    );
    notifyListeners();
  }

  void selectEquipment(Equipment? equipment) {
    _selectedEquipment = equipment;
    _selectedConnection = null;
    // Keep _connectionStartEquipment if it's the same equipment being selected again,
    // otherwise, clear it to prevent accidental connections.
    if (equipment?.id != _connectionStartEquipment?.id) {
      _connectionStartEquipment = null;
    }
    notifyListeners();
  }

  void selectConnection(ElectricalConnection? connection) {
    _selectedConnection = connection;
    _selectedEquipment = null;
    _connectionStartEquipment = null;
    notifyListeners();
  }

  void setConnectionStartEquipment(Equipment? equipment) {
    _connectionStartEquipment = equipment;
    _selectedEquipment =
        null; // Deselect equipment when entering connection mode
    _selectedConnection = null;
    notifyListeners();
  }

  void setSelectedTemplateInModal(MasterEquipmentTemplate? template) {
    _selectedTemplateInModal = template;
    _selectedEquipmentInModal = null;
    notifyListeners();
  }

  void setSelectedEquipmentInModal(Equipment? equipment) {
    _selectedEquipmentInModal = equipment;
    _selectedTemplateInModal = null;
    notifyListeners();
  }

  void setAvailableTemplates(List<MasterEquipmentTemplate> templates) {
    _availableTemplates = templates;
    print(
      'DEBUG: SldState($debugId).setAvailableTemplates called. Templates count: ${templates.length}',
    );
    notifyListeners();
  }

  void setIsLoadingTemplates(bool loading) {
    _isLoadingTemplates = loading;
    notifyListeners();
  }

  void updateAllEquipment(List<Equipment> equipmentList) {
    _placedEquipment.clear();
    _initialEquipmentSnapshot.clear();
    for (var eq in equipmentList) {
      _placedEquipment[eq.id] = eq;
      _initialEquipmentSnapshot[eq.id] = eq.copyWith();
    }
    _hasPendingChanges = false;
    notifyListeners();
  }

  void updateAllConnections(List<ElectricalConnection> connections) {
    _connections.clear();
    _initialConnectionSnapshot.clear();
    _connections.addAll(connections);
    for (var conn in connections) {
      _initialConnectionSnapshot.add(conn.copyWith());
    }
    _hasPendingChanges = false;
    notifyListeners();
  }

  Future<void> saveSldChanges(Substation substation) async {
    print(
      'DEBUG: SldState($debugId).saveSldChanges started for substation ${substation.name}',
    );
    try {
      final Map<String, Equipment> originalEquipmentMap = {
        for (var eq
            in await _equipmentFirestoreService.getEquipmentForSubstationOnce(
              substation.id,
            ))
          eq.id: eq,
      };

      // Fetch existing connections from Firestore for comparison
      final existingConnectionsFromFirestore = await _connectionFirestoreService
          .getConnectionsOnce(substationId: substation.id);
      final existingConnectionIds = existingConnectionsFromFirestore
          .map((c) => c.id)
          .toSet();

      final equipmentToAdd = _placedEquipment.values
          .where((eq) => !originalEquipmentMap.containsKey(eq.id))
          .toList();
      final equipmentToUpdate = _placedEquipment.values
          .where((eq) => originalEquipmentMap.containsKey(eq.id))
          .toList();
      final List<Equipment> actualEquipmentToDelete = originalEquipmentMap
          .values
          .where((eq) => !_placedEquipment.containsKey(eq.id))
          .toList();

      // Connections: find added, updated, deleted
      final List<ElectricalConnection> connectionsToAdd = [];
      final List<ElectricalConnection> connectionsToUpdate = [];
      final List<String> connectionsToDeleteIds = [];

      // Determine connections to add/update
      for (var currentConn in _connections) {
        if (!existingConnectionIds.contains(currentConn.id)) {
          connectionsToAdd.add(currentConn);
        } else {
          // You might need a more robust way to check if a connection is "updated"
          // For now, if its ID exists, it's considered for update (merge)
          connectionsToUpdate.add(currentConn);
        }
      }

      // Determine connections to delete
      final currentConnectionIds = _connections.map((c) => c.id).toSet();
      for (var existingConn in existingConnectionsFromFirestore) {
        if (!currentConnectionIds.contains(existingConn.id)) {
          connectionsToDeleteIds.add(existingConn.id);
        }
      }

      await _equipmentFirestoreService.batchWriteEquipment(
        substationId: substation.id,
        equipmentToAdd: equipmentToAdd,
        equipmentToUpdate: equipmentToUpdate,
        equipmentToDelete: actualEquipmentToDelete,
      );
      print('DEBUG: SldState($debugId).batchWriteEquipment completed.');

      await _connectionFirestoreService.batchWriteConnections(
        substationId: substation.id,
        connectionsToAdd: connectionsToAdd,
        connectionsToUpdate: connectionsToUpdate,
        connectionsToDeleteIds: connectionsToDeleteIds,
      );
      print('DEBUG: SldState($debugId).batchWriteConnections completed.');

      _hasPendingChanges = false;
      print(
        'DEBUG: SldState($debugId).saveSldChanges completed successfully. _hasPendingChanges = $_hasPendingChanges',
      );
    } catch (e) {
      print('ERROR: SldState($debugId).saveSldChanges failed: $e');
      _hasPendingChanges = true;
      rethrow;
    } finally {
      notifyListeners();
    }
  }
}
