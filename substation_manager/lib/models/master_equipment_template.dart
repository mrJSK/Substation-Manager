// lib/models/master_equipment_template.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // Import for JSON encoding/decoding

class MasterEquipmentTemplate {
  final String id;
  final String equipmentType;
  final List<Map<String, dynamic>> equipmentCustomFields;

  // New: List of maps, each representing a defined relay instance for this equipment template.
  // Each map will contain: {'name': String, 'fields': List<Map<String, dynamic>>}
  final List<Map<String, dynamic>> definedRelays;

  // New: List of maps, each representing a defined energy meter instance for this equipment template.
  // Each map will contain: {'name': String, 'fields': List<Map<String, dynamic>>}
  final List<Map<String, dynamic>> definedEnergyMeters;

  // This `associatedRelays` (simple string list) will be removed as it's replaced by definedRelays.
  // If you still need a simple list of specific relay models, we can re-add it.
  // For now, focusing on the new, more flexible structure.
  final List<String>
  associatedRelays; // Keeping this for now as per your last code.
  // We might refine this later if definedRelays fully covers the use case.

  MasterEquipmentTemplate({
    required this.id,
    required this.equipmentType,
    this.equipmentCustomFields = const [],
    this.definedRelays = const [], // Initialize new lists
    this.definedEnergyMeters = const [], // Initialize new lists
    this.associatedRelays = const [], // Keeping this for now
  });

  // Factory constructor to create a MasterEquipmentTemplate from a Firestore document snapshot
  factory MasterEquipmentTemplate.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data()!;
    return MasterEquipmentTemplate(
      id: snapshot.id,
      equipmentType: data['equipmentType'] as String,
      // Ensure safe casting for lists of maps
      equipmentCustomFields:
          (data['equipmentCustomFields'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      definedRelays: // Deserialize new field
          (data['definedRelays'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      definedEnergyMeters: // Deserialize new field
          (data['definedEnergyMeters'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      associatedRelays:
          (data['associatedRelays'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  // Method to convert MasterEquipmentTemplate to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'equipmentType': equipmentType,
      'equipmentCustomFields': equipmentCustomFields,
      'definedRelays': definedRelays, // Serialize new field
      'definedEnergyMeters': definedEnergyMeters, // Serialize new field
      'associatedRelays': associatedRelays, // Keeping for now
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Factory constructor from Map (for SQLite retrieval or other uses)
  factory MasterEquipmentTemplate.fromMap(Map<String, dynamic> map) {
    return MasterEquipmentTemplate(
      id: map['id'] as String,
      equipmentType: map['equipmentType'] as String,
      equipmentCustomFields:
          (jsonDecode(map['equipmentCustomFields'] as String) as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      definedRelays:
          (jsonDecode(map['definedRelays'] as String) as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      definedEnergyMeters:
          (jsonDecode(map['definedEnergyMeters'] as String) as List<dynamic>?)
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
      'equipmentCustomFields': jsonEncode(equipmentCustomFields),
      'definedRelays': jsonEncode(definedRelays),
      'definedEnergyMeters': jsonEncode(definedEnergyMeters),
      'associatedRelays': jsonEncode(associatedRelays),
    };
  }

  // copyWith method for immutability
  MasterEquipmentTemplate copyWith({
    String? id,
    String? equipmentType,
    List<Map<String, dynamic>>? equipmentCustomFields,
    List<Map<String, dynamic>>? definedRelays,
    List<Map<String, dynamic>>? definedEnergyMeters,
    List<String>? associatedRelays,
  }) {
    return MasterEquipmentTemplate(
      id: id ?? this.id,
      equipmentType: equipmentType ?? this.equipmentType,
      equipmentCustomFields:
          equipmentCustomFields ?? this.equipmentCustomFields,
      definedRelays: definedRelays ?? this.definedRelays,
      definedEnergyMeters: definedEnergyMeters ?? this.definedEnergyMeters,
      associatedRelays: associatedRelays ?? this.associatedRelays,
    );
  }
}
