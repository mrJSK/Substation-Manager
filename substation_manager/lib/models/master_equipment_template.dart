// lib/models/master_equipment_template.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // Import for JSON encoding/decoding

class MasterEquipmentTemplate {
  final String id;
  final String equipmentType;
  final List<Map<String, dynamic>> customFields;
  final List<String> associatedRelays;

  MasterEquipmentTemplate({
    required this.id,
    required this.equipmentType,
    this.customFields = const [],
    this.associatedRelays = const [],
  });

  // Factory constructor from Firestore DocumentSnapshot
  factory MasterEquipmentTemplate.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    return MasterEquipmentTemplate(
      id: snapshot.id,
      equipmentType: data?['equipmentType'] as String? ?? '',
      customFields:
          (data?['customFields'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      associatedRelays: List<String>.from(data?['associatedRelays'] ?? []),
    );
  }

  // Method to convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'equipmentType': equipmentType,
      'customFields': customFields,
      'associatedRelays': associatedRelays,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Factory constructor from Map (for SQLite retrieval or other uses)
  factory MasterEquipmentTemplate.fromMap(Map<String, dynamic> map) {
    return MasterEquipmentTemplate(
      id: map['id'] as String,
      equipmentType: map['equipmentType'] as String,
      customFields:
          (jsonDecode(map['customFields'] as String) as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      associatedRelays: List<String>.from(
        jsonDecode(map['associatedRelays'] as String) ?? [],
      ),
    );
  }

  // Method to convert to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'equipmentType': equipmentType,
      'customFields': jsonEncode(customFields),
      'associatedRelays': jsonEncode(associatedRelays),
    };
  }

  // copyWith method for immutability
  MasterEquipmentTemplate copyWith({
    String? id,
    String? equipmentType,
    List<Map<String, dynamic>>? customFields,
    List<String>? associatedRelays,
  }) {
    return MasterEquipmentTemplate(
      id: id ?? this.id,
      equipmentType: equipmentType ?? this.equipmentType,
      customFields: customFields ?? this.customFields,
      associatedRelays: associatedRelays ?? this.associatedRelays,
    );
  }
}
