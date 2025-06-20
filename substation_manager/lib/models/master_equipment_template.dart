// lib/models/master_equipment_template.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // Import for JSON encoding/decoding

class MasterEquipmentTemplate {
  final String id;
  final String equipmentType;
  final List<Map<String, dynamic>> equipmentCustomFields;
  final String
  symbolKey; // NEW: Field to store the key for the visual symbol (e.g., 'Transformer', 'Busbar')

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
    this.symbolKey = 'Transformer', // NEW: Provide a default symbolKey
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
        return MasterEquipmentTemplate(
          id: snapshot.id,
          equipmentType: 'ERROR_NULL_DATA',
        );
      }
      return MasterEquipmentTemplate(
        id: snapshot.id,
        equipmentType: data['equipmentType'] as String? ?? 'Unknown Type',
        equipmentCustomFields:
            (data['equipmentCustomFields'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [],
        definedRelays:
            (data['definedRelays'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [],
        definedEnergyMeters:
            (data['definedEnergyMeters'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [],
        associatedRelays:
            (data['associatedRelays'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        symbolKey:
            data['symbolKey'] as String? ??
            'Transformer', // NEW: Deserialize symbolKey
      );
    } catch (e, stackTrace) {
      print(
        'ERROR: Failed to parse MasterEquipmentTemplate from Firestore document ${snapshot.id}: $e',
      );
      print('StackTrace: $stackTrace');
      return MasterEquipmentTemplate(
        id: snapshot.id,
        equipmentType: 'PARSE_ERROR',
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
      'symbolKey': symbolKey, // NEW: Serialize symbolKey
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Factory constructor from Map (for SQLite retrieval or other uses) - Update if SQLite is used
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
      symbolKey:
          map['symbolKey'] as String? ??
          'Transformer', // NEW: Deserialize symbolKey from Map
    );
  }

  // Method to convert to Map for SQLite storage - Update if SQLite is used
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'equipmentType': equipmentType,
      'equipmentCustomFields': jsonEncode(equipmentCustomFields),
      'definedRelays': jsonEncode(definedRelays),
      'definedEnergyMeters': jsonEncode(definedEnergyMeters),
      'associatedRelays': jsonEncode(associatedRelays),
      'symbolKey': symbolKey, // NEW: Serialize symbolKey to Map
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
    String? symbolKey, // NEW: Add symbolKey to copyWith
  }) {
    return MasterEquipmentTemplate(
      id: id ?? this.id,
      equipmentType: equipmentType ?? this.equipmentType,
      equipmentCustomFields:
          equipmentCustomFields ?? this.equipmentCustomFields,
      definedRelays: definedRelays ?? this.definedRelays,
      definedEnergyMeters: definedEnergyMeters ?? this.definedEnergyMeters,
      associatedRelays: associatedRelays ?? this.associatedRelays,
      symbolKey: symbolKey ?? this.symbolKey, // NEW: Copy symbolKey
    );
  }
}
