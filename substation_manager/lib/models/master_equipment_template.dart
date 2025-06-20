// lib/models/master_equipment_template.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // Import for JSON encoding/decoding

class MasterEquipmentTemplate {
  final String id;
  final String equipmentType;
  final List<Map<String, dynamic>> equipmentCustomFields;

  final List<Map<String, dynamic>> definedRelays;
  final List<Map<String, dynamic>> definedEnergyMeters;

  final List<String> associatedRelays;

  MasterEquipmentTemplate({
    required this.id,
    required this.equipmentType,
    this.equipmentCustomFields = const [],
    this.definedRelays = const [],
    this.definedEnergyMeters = const [],
    this.associatedRelays = const [],
  });

  // Factory constructor to create a MasterEquipmentTemplate from a Firestore document snapshot
  factory MasterEquipmentTemplate.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    try {
      final data = snapshot.data();
      if (data == null) {
        print(
          'ERROR: MasterEquipmentTemplate.fromFirestore: Document data is null for ID: ${snapshot.id}',
        );
        // Return a default/error template to prevent crashes and indicate issue
        return MasterEquipmentTemplate(
          id: snapshot.id,
          equipmentType: 'ERROR_NULL_DATA',
        );
      }
      return MasterEquipmentTemplate(
        id: snapshot.id,
        equipmentType:
            data['equipmentType'] as String? ??
            'Unknown Type', // Added null check and default
        equipmentCustomFields:
            (data['equipmentCustomFields'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [],
        definedRelays: // Deserialize new field with null check
            (data['definedRelays'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [],
        definedEnergyMeters: // Deserialize new field with null check
            (data['definedEnergyMeters'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [],
        associatedRelays: // Deserialize with null check
            (data['associatedRelays'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
    } catch (e, stackTrace) {
      print(
        'ERROR: Failed to parse MasterEquipmentTemplate from Firestore document ${snapshot.id}: $e',
      );
      print('StackTrace: $stackTrace');
      // Return a default/error template to allow the stream to continue,
      return MasterEquipmentTemplate(
        id: snapshot.id,
        equipmentType: 'PARSE_ERROR', // Indicate a parsing error
      );
    }
  }

  // Method to convert MasterEquipmentTemplate to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'equipmentType': equipmentType,
      'equipmentCustomFields': equipmentCustomFields,
      'definedRelays': definedRelays,
      'definedEnergyMeters': definedEnergyMeters,
      'associatedRelays': associatedRelays,
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
