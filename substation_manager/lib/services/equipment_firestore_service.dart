// lib/services/equipment_firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:substation_manager/models/equipment.dart';

class EquipmentFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Equipment Collection Reference ---
  CollectionReference<Equipment> get _equipmentRef {
    return _db
        .collection('equipment')
        .withConverter<Equipment>(
          fromFirestore: (snapshot, _) => Equipment.fromFirestore(snapshot),
          toFirestore: (equipment, _) => equipment.toFirestore(),
        );
  }

  // --- Equipment Methods ---
  Stream<List<Equipment>> getEquipmentStream({
    String? substationId,
    String? bayId,
  }) {
    Query<Equipment> query = _equipmentRef;
    if (substationId != null) {
      query = query.where('substationId', isEqualTo: substationId);
    }
    if (bayId != null) {
      query = query.where('bayId', isEqualTo: bayId);
    }
    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
    );
  }

  Future<List<Equipment>> getEquipmentOnce({
    String? substationId,
    String? bayId,
  }) async {
    try {
      Query<Equipment> query = _equipmentRef;
      if (substationId != null) {
        query = query.where('substationId', isEqualTo: substationId);
      }
      if (bayId != null) {
        query = query.where('bayId', isEqualTo: bayId);
      }
      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching equipment: $e');
      rethrow;
    }
  }

  Future<void> addEquipment(Equipment equipment) async {
    try {
      await _equipmentRef.doc(equipment.id).set(equipment);
    } catch (e) {
      print('Error adding equipment ${equipment.id}: $e');
      rethrow;
    }
  }

  Future<void> updateEquipment(Equipment equipment) async {
    try {
      await _equipmentRef
          .doc(equipment.id)
          .set(equipment, SetOptions(merge: true));
    } catch (e) {
      print('Error updating equipment ${equipment.id}: $e');
      rethrow;
    }
  }

  Future<void> deleteEquipment(String equipmentId) async {
    try {
      await _equipmentRef.doc(equipmentId).delete();
    } catch (e) {
      print('Error deleting equipment $equipmentId: $e');
      rethrow;
    }
  }
}
