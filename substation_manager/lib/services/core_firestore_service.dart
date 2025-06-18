// lib/services/core_firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:substation_manager/models/area.dart';
import 'package:substation_manager/models/substation.dart';
import 'package:substation_manager/models/bay.dart';
import 'package:substation_manager/models/master_equipment_template.dart';

class CoreFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Area Collection Reference ---
  CollectionReference<Area> get _areasRef {
    return _db
        .collection('areas')
        .withConverter<Area>(
          fromFirestore: (snapshot, _) => Area.fromFirestore(snapshot),
          toFirestore: (area, _) => area.toFirestore(),
        );
  }

  // --- Substation Collection Reference ---
  CollectionReference<Substation> get _substationsRef {
    return _db
        .collection('substations')
        .withConverter<Substation>(
          fromFirestore: (snapshot, _) => Substation.fromFirestore(snapshot),
          toFirestore: (substation, _) => substation.toFirestore(),
        );
  }

  // --- Bay Collection Reference ---
  CollectionReference<Bay> get _baysRef {
    return _db
        .collection('bays')
        .withConverter<Bay>(
          fromFirestore: (snapshot, _) => Bay.fromFirestore(snapshot),
          toFirestore: (bay, _) => bay.toFirestore(),
        );
  }

  // --- MasterEquipmentTemplate Collection Reference ---
  CollectionReference<MasterEquipmentTemplate>
  get _masterEquipmentTemplatesRef {
    return _db
        .collection('master_equipment_templates')
        .withConverter<MasterEquipmentTemplate>(
          fromFirestore: (snapshot, _) =>
              MasterEquipmentTemplate.fromFirestore(snapshot),
          toFirestore: (template, _) => template.toFirestore(),
        );
  }

  // --- Area Methods ---
  Stream<List<Area>> getAreasStream() {
    return _areasRef.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
    );
  }

  Future<List<Area>> getAreasOnce() async {
    try {
      final querySnapshot = await _areasRef.get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching areas: $e');
      rethrow;
    }
  }

  Future<void> addArea(Area area) async {
    try {
      await _areasRef.doc(area.id).set(area);
    } catch (e) {
      print('Error adding area ${area.id}: $e');
      rethrow;
    }
  }

  Future<void> updateArea(Area area) async {
    try {
      await _areasRef.doc(area.id).set(area, SetOptions(merge: true));
    } catch (e) {
      print('Error updating area ${area.id}: $e');
      rethrow;
    }
  }

  Future<void> deleteArea(String areaId) async {
    try {
      await _areasRef.doc(areaId).delete();
    } catch (e) {
      print('Error deleting area $areaId: $e');
      rethrow;
    }
  }

  // --- Substation Methods ---
  Stream<List<Substation>> getSubstationsStream() {
    return _substationsRef.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
    );
  }

  Future<List<Substation>> getSubstationsOnce() async {
    try {
      final querySnapshot = await _substationsRef.get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching substations: $e');
      rethrow;
    }
  }

  Future<void> addSubstation(Substation substation) async {
    try {
      await _substationsRef.doc(substation.id).set(substation);
    } catch (e) {
      print('Error adding substation ${substation.id}: $e');
      rethrow;
    }
  }

  Future<void> updateSubstation(Substation substation) async {
    try {
      await _substationsRef
          .doc(substation.id)
          .set(substation, SetOptions(merge: true));
    } catch (e) {
      print('Error updating substation ${substation.id}: $e');
      rethrow;
    }
  }

  Future<void> deleteSubstation(String substationId) async {
    try {
      await _substationsRef.doc(substationId).delete();
    } catch (e) {
      print('Error deleting substation $substationId: $e');
      rethrow;
    }
  }

  // --- Bay Methods ---
  Stream<List<Bay>> getBaysStream({String? substationId}) {
    Query<Bay> query = _baysRef;
    if (substationId != null) {
      query = query.where('substationId', isEqualTo: substationId);
    }
    return query
        .orderBy('sequenceNumber')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<List<Bay>> getBaysOnce({String? substationId}) async {
    try {
      Query<Bay> query = _baysRef;
      if (substationId != null) {
        query = query.where('substationId', isEqualTo: substationId);
      }
      final querySnapshot = await query.orderBy('sequenceNumber').get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching bays: $e');
      rethrow;
    }
  }

  Future<void> addBay(Bay bay) async {
    try {
      await _baysRef.doc(bay.id).set(bay);
    } catch (e) {
      print('Error adding bay ${bay.id}: $e');
      rethrow;
    }
  }

  Future<void> updateBay(Bay bay) async {
    try {
      await _baysRef.doc(bay.id).set(bay, SetOptions(merge: true));
    } catch (e) {
      print('Error updating bay ${bay.id}: $e');
      rethrow;
    }
  }

  Future<void> deleteBay(String bayId) async {
    try {
      await _baysRef.doc(bayId).delete();
    } catch (e) {
      print('Error deleting bay $bayId: $e');
      rethrow;
    }
  }

  // --- MasterEquipmentTemplate Methods ---
  Stream<List<MasterEquipmentTemplate>> getMasterEquipmentTemplatesStream() {
    return _masterEquipmentTemplatesRef.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
    );
  }

  Future<List<MasterEquipmentTemplate>>
  getMasterEquipmentTemplatesOnce() async {
    try {
      final querySnapshot = await _masterEquipmentTemplatesRef.get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching master equipment templates: $e');
      rethrow;
    }
  }

  Future<void> addMasterEquipmentTemplate(
    MasterEquipmentTemplate template,
  ) async {
    try {
      await _masterEquipmentTemplatesRef.doc(template.id).set(template);
    } catch (e) {
      print('Error adding master equipment template ${template.id}: $e');
      rethrow;
    }
  }

  Future<void> updateMasterEquipmentTemplate(
    MasterEquipmentTemplate template,
  ) async {
    try {
      await _masterEquipmentTemplatesRef
          .doc(template.id)
          .set(template, SetOptions(merge: true));
    } catch (e) {
      print('Error updating master equipment template ${template.id}: $e');
      rethrow;
    }
  }

  Future<void> deleteMasterEquipmentTemplate(String templateId) async {
    try {
      await _masterEquipmentTemplatesRef.doc(templateId).delete();
    } catch (e) {
      print('Error deleting master equipment template $templateId: $e');
      rethrow;
    }
  }
}
