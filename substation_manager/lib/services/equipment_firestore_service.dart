// lib/services/equipment_firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:substation_manager/models/equipment.dart';
import 'package:substation_manager/services/core_firestore_service.dart'; // Import CoreFirestoreService to get bays
import 'dart:async'; // Required for StreamController

class EquipmentFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CoreFirestoreService _coreFirestoreService =
      CoreFirestoreService(); // To fetch bays

  CollectionReference<Equipment> _equipmentRef(
    String substationId,
    String bayId,
  ) {
    return _db
        .collection('substations')
        .doc(substationId)
        .collection('bays')
        .doc(bayId)
        .collection('equipment')
        .withConverter<Equipment>(
          fromFirestore: (snapshot, _) => Equipment.fromFirestore(snapshot),
          toFirestore: (equipment, _) => equipment.toFirestore(),
        );
  }

  // Add Equipment
  Future<void> addEquipment(Equipment equipment) async {
    try {
      await _equipmentRef(
        equipment.substationId,
        equipment.bayId,
      ).doc(equipment.id).set(equipment);
    } catch (e) {
      print('Error adding equipment ${equipment.id}: $e');
      rethrow;
    }
  }

  // Update Equipment
  Future<void> updateEquipment(Equipment equipment) async {
    try {
      await _equipmentRef(
        equipment.substationId,
        equipment.bayId,
      ).doc(equipment.id).set(equipment, SetOptions(merge: true));
    } catch (e) {
      print('Error updating equipment ${equipment.id}: $e');
      rethrow;
    }
  }

  // Delete Equipment
  Future<void> deleteEquipment(
    String substationId,
    String bayId,
    String equipmentId,
  ) async {
    try {
      await _equipmentRef(substationId, bayId).doc(equipmentId).delete();
    } catch (e) {
      print('Error deleting equipment $equipmentId: $e');
      rethrow;
    }
  }

  // Get single Equipment by ID
  Future<Equipment?> getEquipmentById(
    String substationId,
    String bayId,
    String equipmentId,
  ) async {
    try {
      final docSnapshot = await _equipmentRef(
        substationId,
        bayId,
      ).doc(equipmentId).get();
      return docSnapshot.data();
    } catch (e) {
      print('Error fetching equipment $equipmentId: $e');
      return null;
    }
  }

  // Get stream of Equipment for a specific Bay
  Stream<List<Equipment>> getEquipmentForBayStream(
    String substationId,
    String bayId,
  ) {
    return _equipmentRef(substationId, bayId).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
    );
  }

  // Get all Equipment for a specific Bay (one-time fetch)
  Future<List<Equipment>> getEquipmentForBayOnce(
    String substationId,
    String bayId,
  ) async {
    try {
      final querySnapshot = await _equipmentRef(substationId, bayId).get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching equipment for bay: $e');
      rethrow;
    }
  }

  // Get all Equipment for a specific Substation (across all bays) - one-time fetch
  Future<List<Equipment>> getEquipmentForSubstationOnce(
    String substationId,
  ) async {
    try {
      final baysSnapshot = await _db
          .collection('substations')
          .doc(substationId)
          .collection('bays')
          .get();
      List<Equipment> allEquipment = [];
      for (var bayDoc in baysSnapshot.docs) {
        final equipmentSnapshot = await _equipmentRef(
          substationId,
          bayDoc.id,
        ).get();
        allEquipment.addAll(equipmentSnapshot.docs.map((doc) => doc.data()));
      }
      return allEquipment;
    } catch (e) {
      print('Error fetching all equipment for substation: $e');
      rethrow;
    }
  }

  // NEW: Get a combined stream of all equipment for a list of substation IDs
  Stream<List<Equipment>> getEquipmentForSubstationIdsStream(
    List<String> substationIds,
  ) {
    if (substationIds.isEmpty) {
      return Stream.value([]); // Return an empty stream if no substations
    }

    // Use a StreamController to combine data from multiple streams
    final _combinedEquipmentController =
        StreamController<List<Equipment>>.broadcast();

    // Map to store current equipment for each bay, to allow merging updates
    final Map<String, Map<String, Equipment>> _bayEquipmentCache =
        {}; // {bayId: {equipmentId: Equipment}}

    // List to keep track of all active subscriptions so they can be cancelled
    final List<StreamSubscription> _subscriptions = [];

    Future<void> _startListening() async {
      // First, get all bays for the given substations (one-time fetch for bays)
      for (String subId in substationIds) {
        final bays = await _coreFirestoreService.getBaysOnce(
          substationId: subId,
        );
        for (var bay in bays) {
          final bayId = bay.id;
          _bayEquipmentCache[bayId] = {}; // Initialize cache for this bay

          // Listen to the stream of equipment for each bay
          final streamForBay = getEquipmentForBayStream(subId, bayId);
          _subscriptions.add(
            streamForBay.listen(
              (equipmentListForBay) {
                // Update the cache for this specific bay
                final currentBayEquipmentMap = <String, Equipment>{};
                for (var eq in equipmentListForBay) {
                  currentBayEquipmentMap[eq.id] = eq;
                }
                _bayEquipmentCache[bayId] = currentBayEquipmentMap;

                _emitAllEquipment(
                  _combinedEquipmentController,
                  _bayEquipmentCache,
                );
              },
              onError: (e) {
                print('Error in equipment stream for bay $bayId: $e');
                // Propagate error or handle gracefully
              },
            ),
          );
        }
      }
      // Emit initial state even if no equipment streams have fired yet, but bays are known
      _emitAllEquipment(_combinedEquipmentController, _bayEquipmentCache);
    }

    _startListening().catchError((e) {
      print('Error starting equipment listeners: $e');
      _combinedEquipmentController.addError(e);
    });

    // Handle closing the stream
    _combinedEquipmentController.onCancel = () {
      for (var sub in _subscriptions) {
        sub.cancel();
      }
      _subscriptions.clear();
      print('EquipmentForSubstationIdsStream: All subscriptions cancelled.');
    };

    return _combinedEquipmentController.stream;
  }

  // Helper to combine all equipment from the cache and add to the main controller
  void _emitAllEquipment(
    StreamController<List<Equipment>> controller,
    Map<String, Map<String, Equipment>> bayEquipmentCache,
  ) {
    final List<Equipment> allEquipment = [];
    bayEquipmentCache.values.forEach((bayMap) {
      allEquipment.addAll(bayMap.values);
    });
    controller.add(allEquipment);
  }
}
