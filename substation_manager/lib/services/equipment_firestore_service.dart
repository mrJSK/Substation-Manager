// substation_manager/lib/services/equipment_firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:substation_manager/models/equipment.dart';
import 'package:substation_manager/services/core_firestore_service.dart'; // Import CoreFirestoreService to get bays
import 'dart:async'; // Required for StreamController
import 'package:async/async.dart'; // Import for StreamGroup - ensure this is needed, or remove if not.

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

  DocumentReference<Equipment> getEquipmentDocRef(
    // This method already existed, but explicitly mentioned here for clarity
    String substationId,
    String bayId,
    String equipmentId,
  ) {
    return _equipmentRef(substationId, bayId).doc(equipmentId);
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

  Stream<List<Equipment>> getEquipmentForBayStream(
    String substationId,
    String bayId,
  ) {
    return _equipmentRef(substationId, bayId).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
    );
  }

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

  Stream<List<Equipment>> getEquipmentForSubstationIdsStream(
    List<String> substationIds,
  ) {
    if (substationIds.isEmpty) {
      return Stream.value([]);
    }

    final combinedEquipmentController =
        StreamController<List<Equipment>>.broadcast();

    final Map<String, Map<String, Equipment>> bayEquipmentCache = {};

    final List<StreamSubscription> subscriptions = [];

    Future<void> startListening() async {
      for (String subId in substationIds) {
        final bays = await _coreFirestoreService.getBaysOnce(
          substationId: subId,
        );
        for (var bay in bays) {
          final bayId = bay.id;
          bayEquipmentCache[bayId] = {};

          final streamForBay = getEquipmentForBayStream(subId, bayId);
          subscriptions.add(
            streamForBay.listen(
              (equipmentListForBay) {
                final currentBayEquipmentMap = <String, Equipment>{};
                for (var eq in equipmentListForBay) {
                  currentBayEquipmentMap[eq.id] = eq;
                }
                bayEquipmentCache[bayId] = currentBayEquipmentMap;

                _emitAllEquipment(
                  combinedEquipmentController,
                  bayEquipmentCache,
                );
              },
              onError: (e) {
                print('Error in equipment stream for bay $bayId: $e');
              },
            ),
          );
        }
      }
      _emitAllEquipment(combinedEquipmentController, bayEquipmentCache);
    }

    startListening().catchError((e) {
      print('Error starting equipment listeners: $e');
      combinedEquipmentController.addError(e);
    });

    combinedEquipmentController.onCancel = () {
      for (var sub in subscriptions) {
        sub.cancel();
      }
      subscriptions.clear();
      print('EquipmentForSubstationIdsStream: All subscriptions cancelled.');
    };

    return combinedEquipmentController.stream;
  }

  void _emitAllEquipment(
    StreamController<List<Equipment>> controller,
    Map<String, Map<String, Equipment>> bayEquipmentCache,
  ) {
    final List<Equipment> allEquipment = [];
    for (var bayMap in bayEquipmentCache.values) {
      allEquipment.addAll(bayMap.values);
    }
    controller.add(allEquipment);
  }

  Stream<List<Equipment>> getEquipmentForSubstationStream(String substationId) {
    final controller = StreamController<List<Equipment>>.broadcast();
    final List<StreamSubscription> bayEquipmentSubscriptions = [];
    final Map<String, Map<String, Equipment>> equipmentCache = {};

    final baysSubscription = _coreFirestoreService
        .getBaysStream(substationId: substationId)
        .listen(
          (bays) {
            for (var sub in bayEquipmentSubscriptions) {
              sub.cancel();
            }
            bayEquipmentSubscriptions.clear();
            equipmentCache.clear();

            if (bays.isEmpty) {
              controller.add([]);
              return;
            }

            for (var bay in bays) {
              equipmentCache[bay.id] = {};

              final equipmentStream = getEquipmentForBayStream(
                substationId,
                bay.id,
              );
              bayEquipmentSubscriptions.add(
                equipmentStream.listen(
                  (equipmentList) {
                    equipmentCache[bay.id] = {
                      for (var eq in equipmentList) eq.id: eq,
                    };
                    _emitAllEquipment(controller, equipmentCache);
                  },
                  onError: (e) {
                    print('Error in equipment stream for bay ${bay.id}: $e');
                    controller.addError(e);
                  },
                ),
              );
            }
          },
          onError: (e) {
            print('Error in bays stream for substation $substationId: $e');
            controller.addError(e);
          },
        );

    controller.onCancel = () {
      baysSubscription.cancel();
      for (var sub in bayEquipmentSubscriptions) {
        sub.cancel();
      }
      bayEquipmentSubscriptions.clear();
      print('EquipmentForSubstationStream: All subscriptions cancelled.');
    };

    return controller.stream;
  }

  // NEW: Batch write operations for equipment (correctly implemented here)
  Future<void> batchWriteEquipment({
    required String
    substationId, // Substation ID for context, but doc path uses eq.substationId and eq.bayId
    required List<Equipment> equipmentToAdd,
    required List<Equipment> equipmentToUpdate,
    required List<Equipment> equipmentToDelete,
  }) async {
    final batch = _db.batch(); // Use the class's _db instance

    // Handling additions
    for (var eq in equipmentToAdd) {
      if (eq.bayId.isEmpty || eq.substationId.isEmpty) {
        print(
          'Skipping equipment ${eq.id} for add: missing bayId or substationId. Equipment: ${eq.name}',
        );
        continue;
      }
      // Use _equipmentRef to get the correct CollectionReference with converter
      final docRef = _equipmentRef(eq.substationId, eq.bayId).doc(eq.id);
      batch.set(docRef, eq); // Use set with the converter
    }

    // Handling updates
    for (var eq in equipmentToUpdate) {
      if (eq.bayId.isEmpty || eq.substationId.isEmpty) {
        print(
          'Skipping equipment ${eq.id} for update: missing bayId or substationId. Equipment: ${eq.name}',
        );
        continue;
      }
      // Use _equipmentRef to get the correct CollectionReference with converter
      final docRef = _equipmentRef(eq.substationId, eq.bayId).doc(eq.id);
      batch.set(
        docRef,
        eq,
        SetOptions(merge: true),
      ); // Use set with merge for existing documents with converter
    }

    // Handling deletions
    for (var eq in equipmentToDelete) {
      if (eq.bayId.isEmpty || eq.substationId.isEmpty) {
        print(
          'Skipping equipment ${eq.id} for delete: missing bayId or substationId. Equipment: ${eq.name}',
        );
        continue;
      }
      // Use _equipmentRef to get the correct CollectionReference for deletion
      final docRef = _equipmentRef(eq.substationId, eq.bayId).doc(eq.id);
      batch.delete(docRef);
    }

    await batch.commit();
  }
}
