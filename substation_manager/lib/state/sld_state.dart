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

class SldState extends ChangeNotifier {
  final Map<String, Equipment> _placedEquipment = {};
  final List<ElectricalConnection> _connections = [];
  Equipment? _selectedEquipment;
  ElectricalConnection? _selectedConnection;
  Equipment? _connectionStartEquipment;
  bool _isLoadingTemplates = false;
  List<MasterEquipmentTemplate> _availableTemplates = [];

  MasterEquipmentTemplate? _selectedTemplateInModal;
  Equipment? _selectedEquipmentInModal;

  final Map<String, Equipment> _initialEquipmentSnapshot = {};
  final List<ElectricalConnection> _initialConnectionSnapshot = [];

  bool _hasPendingChanges = false;
  bool _isDragging = false; // Add this new property

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
  bool get hasPendingChanges => _hasPendingChanges;
  bool get isDragging => _isDragging; // Add getter for _isDragging

  void addEquipment(Equipment equipment) {
    _placedEquipment[equipment.id] = equipment;
    _hasPendingChanges = true;
    notifyListeners();
  }

  void updateEquipment(Equipment equipment) {
    if (_placedEquipment.containsKey(equipment.id)) {
      _placedEquipment[equipment.id] = equipment;
      _hasPendingChanges = true;
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
      notifyListeners();
    }
  }

  void removeEquipment(String id) {
    _placedEquipment.remove(id);
    _hasPendingChanges = true;
    notifyListeners();
  }

  void addConnection(ElectricalConnection connection) {
    _connections.add(connection);
    _hasPendingChanges = true;
    notifyListeners();
  }

  void removeConnection(String id) {
    _connections.removeWhere((conn) => conn.id == id);
    _hasPendingChanges = true;
    notifyListeners();
  }

  void selectEquipment(Equipment? equipment) {
    _selectedEquipment = equipment;
    _selectedConnection = null;
    _connectionStartEquipment = null;
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
    _selectedEquipment = null;
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
    notifyListeners();
  }

  void setIsLoadingTemplates(bool loading) {
    _isLoadingTemplates = loading;
    notifyListeners();
  }

  // Add this new method
  void setIsDragging(bool dragging) {
    _isDragging = dragging;
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
    final batch = FirebaseFirestore.instance.batch();
    final EquipmentFirestoreService equipmentFirestoreService =
        EquipmentFirestoreService();
    final ElectricalConnectionFirestoreService connectionFirestoreService =
        ElectricalConnectionFirestoreService();

    for (var initialEqId in _initialEquipmentSnapshot.keys) {
      if (!_placedEquipment.containsKey(initialEqId)) {
        final deletedEq = _initialEquipmentSnapshot[initialEqId]!;
        batch.delete(
          equipmentFirestoreService.getEquipmentDocRef(
            deletedEq.substationId,
            deletedEq.bayId,
            deletedEq.id,
          ),
        );
      }
    }

    final Set<String> initialConnectionIds = _initialConnectionSnapshot
        .map((c) => c.id)
        .toSet();
    final Set<String> currentConnectionIds = _connections
        .map((c) => c.id)
        .toSet();
    for (var deletedConnId in initialConnectionIds.difference(
      currentConnectionIds,
    )) {
      batch.delete(
        connectionFirestoreService.getConnectionDocRef(deletedConnId),
      );
    }

    for (var currentEq in _placedEquipment.values) {
      if (!_initialEquipmentSnapshot.containsKey(currentEq.id)) {
        batch.set(
          equipmentFirestoreService.getEquipmentDocRef(
            currentEq.substationId,
            currentEq.bayId,
            currentEq.id,
          ),
          currentEq.toFirestore(),
        );
      } else {
        final initialEq = _initialEquipmentSnapshot[currentEq.id]!;
        if (!mapEquals(currentEq.toFirestore(), initialEq.toFirestore())) {
          batch.set(
            equipmentFirestoreService.getEquipmentDocRef(
              currentEq.substationId,
              currentEq.bayId,
              currentEq.id,
            ),
            currentEq.toFirestore(),
            SetOptions(merge: true),
          );
        }
      }
    }

    for (var currentConn in _connections) {
      if (!initialConnectionIds.contains(currentConn.id)) {
        batch.set(
          connectionFirestoreService.getConnectionDocRef(currentConn.id),
          currentConn.toFirestore(),
        );
      }
    }

    try {
      await batch.commit();
      _initialEquipmentSnapshot.clear();
      _placedEquipment.forEach(
        (id, eq) => _initialEquipmentSnapshot[id] = eq.copyWith(),
      );
      _initialConnectionSnapshot.clear();
      _connections.forEach(
        (conn) => _initialConnectionSnapshot.add(conn.copyWith()),
      );

      _hasPendingChanges = false;
      notifyListeners();
      print('SLD changes saved successfully!');
    } catch (e) {
      print('Error committing SLD batch: $e');
      rethrow;
    }
  }
}
