// lib/models/equipment.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // For jsonEncode/jsonDecode

class Equipment {
  final String id;
  final String substationId;
  final String bayId;
  final String
  equipmentType; // References the equipmentType from MasterEquipmentTemplate
  final String masterTemplateId; // New: To link to the MasterEquipmentTemplate
  final String name;
  final int? yearOfManufacturing;
  final int? yearOfCommissioning;
  final String? make;
  final String? serialNumber;
  final String? ratedVoltage;
  final String? ratedCurrent;
  final String? status;
  final String? phaseConfiguration;
  final double? positionX;
  final double? positionY;

  // New: Dynamically stored custom field values for THIS equipment instance.
  // Example: {'field_name_key': 'field_value', ...}
  final Map<String, dynamic> customFieldValues;

  // New: List to store actual relay instances associated with THIS equipment.
  // Each map will contain: {'name': 'Relay A', 'type': '7SJ80', 'serial': 'XYZ', 'field_values': {'field_name_key': 'value'}}
  final List<Map<String, dynamic>> relays;

  // New: List to store actual energy meter instances associated with THIS equipment.
  // Each map will contain: {'name': 'Meter A', 'make': 'Secure', 'model': 'Elite 440', 'field_values': {'field_name_key': 'value'}}
  final List<Map<String, dynamic>> energyMeters;

  Equipment({
    required this.id,
    required this.substationId,
    required this.bayId,
    required this.equipmentType,
    required this.masterTemplateId, // Initialize new field
    required this.name,
    this.yearOfManufacturing,
    this.yearOfCommissioning,
    this.make,
    this.serialNumber,
    this.ratedVoltage,
    this.ratedCurrent,
    this.status,
    this.phaseConfiguration,
    this.positionX,
    this.positionY,
    this.customFieldValues = const {}, // Initialize new field
    this.relays = const [], // Initialize new field
    this.energyMeters = const [], // Initialize new field
  });

  // Factory constructor from Firestore DocumentSnapshot
  factory Equipment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    return Equipment(
      id: snapshot.id,
      substationId: data?['substationId'] as String? ?? '',
      bayId: data?['bayId'] as String? ?? '',
      equipmentType: data?['equipmentType'] as String? ?? '',
      masterTemplateId:
          data?['masterTemplateId'] as String? ?? '', // Deserialize new field
      name: data?['name'] as String? ?? '',
      yearOfManufacturing: data?['yearOfManufacturing'] as int?,
      yearOfCommissioning: data?['yearOfCommissioning'] as int?,
      make: data?['make'] as String?,
      serialNumber: data?['serialNumber'] as String?,
      ratedVoltage: data?['ratedVoltage'] as String?,
      ratedCurrent: data?['ratedCurrent'] as String?,
      status: data?['status'] as String?,
      phaseConfiguration: data?['phaseConfiguration'] as String?,
      positionX: (data?['positionX'] as num?)?.toDouble(),
      positionY: (data?['positionY'] as num?)?.toDouble(),
      customFieldValues:
          (data?['customFieldValues'] as Map<String, dynamic>?) ??
          {}, // Deserialize new field
      relays:
          (data?['relays'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [], // Deserialize new field
      energyMeters:
          (data?['energyMeters'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [], // Deserialize new field
    );
  }

  // Method to convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'substationId': substationId,
      'bayId': bayId,
      'equipmentType': equipmentType,
      'masterTemplateId': masterTemplateId, // Serialize new field
      'name': name,
      'yearOfManufacturing': yearOfManufacturing,
      'yearOfCommissioning': yearOfCommissioning,
      'make': make,
      'serialNumber': serialNumber,
      'ratedVoltage': ratedVoltage,
      'ratedCurrent': ratedCurrent,
      'status': status,
      'phaseConfiguration': phaseConfiguration,
      'positionX': positionX,
      'positionY': positionY,
      'customFieldValues': customFieldValues, // Serialize new field
      'relays': relays, // Serialize new field
      'energyMeters': energyMeters, // Serialize new field
      'createdAt':
          FieldValue.serverTimestamp(), // Assuming you have this for creation time
    };
  }

  // Factory constructor from Map (for SQLite retrieval or other uses)
  factory Equipment.fromMap(Map<String, dynamic> map) {
    return Equipment(
      id: map['id'] as String,
      substationId: map['substationId'] as String,
      bayId: map['bayId'] as String,
      equipmentType: map['equipmentType'] as String,
      masterTemplateId:
          map['masterTemplateId'] as String, // Deserialize new field
      name: map['name'] as String,
      yearOfManufacturing: map['yearOfManufacturing'] as int?,
      yearOfCommissioning: map['yearOfCommissioning'] as int?,
      make: map['make'] as String?,
      serialNumber: map['serialNumber'] as String?,
      ratedVoltage: map['ratedVoltage'] as String?,
      ratedCurrent: map['ratedCurrent'] as String?,
      status: map['status'] as String?,
      phaseConfiguration: map['phaseConfiguration'] as String?,
      positionX: map['positionX'] as double?,
      positionY: map['positionY'] as double?,
      customFieldValues:
          jsonDecode(map['customFieldValues'] as String)
              as Map<String, dynamic>, // Deserialize new field
      relays:
          (jsonDecode(map['relays'] as String) as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [], // Deserialize new field
      energyMeters:
          (jsonDecode(map['energyMeters'] as String) as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [], // Deserialize new field
    );
  }

  // Method to convert to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'substationId': substationId,
      'bayId': bayId,
      'equipmentType': equipmentType,
      'masterTemplateId': masterTemplateId, // Serialize new field
      'name': name,
      'yearOfManufacturing': yearOfManufacturing,
      'yearOfCommissioning': yearOfCommissioning,
      'make': make,
      'serialNumber': serialNumber,
      'ratedVoltage': ratedVoltage,
      'ratedCurrent': ratedCurrent,
      'status': status,
      'phaseConfiguration': phaseConfiguration,
      'positionX': positionX,
      'positionY': positionY,
      'customFieldValues': jsonEncode(customFieldValues), // Serialize new field
      'relays': jsonEncode(relays), // Serialize new field
      'energyMeters': jsonEncode(energyMeters), // Serialize new field
    };
  }

  // copyWith method for immutability
  Equipment copyWith({
    String? id,
    String? substationId,
    String? bayId,
    String? equipmentType,
    String? masterTemplateId, // Add to copyWith
    String? name,
    int? yearOfManufacturing,
    int? yearOfCommissioning,
    String? make,
    String? serialNumber,
    String? ratedVoltage,
    String? ratedCurrent,
    String? status,
    String? phaseConfiguration,
    double? positionX,
    double? positionY,
    Map<String, dynamic>? customFieldValues, // Add to copyWith
    List<Map<String, dynamic>>? relays, // Add to copyWith
    List<Map<String, dynamic>>? energyMeters, // Add to copyWith
  }) {
    return Equipment(
      id: id ?? this.id,
      substationId: substationId ?? this.substationId,
      bayId: bayId ?? this.bayId,
      equipmentType: equipmentType ?? this.equipmentType,
      masterTemplateId:
          masterTemplateId ?? this.masterTemplateId, // Use in copyWith
      name: name ?? this.name,
      yearOfManufacturing: yearOfManufacturing ?? this.yearOfManufacturing,
      yearOfCommissioning: yearOfCommissioning ?? this.yearOfCommissioning,
      make: make ?? this.make,
      serialNumber: serialNumber ?? this.serialNumber,
      ratedVoltage: ratedVoltage ?? this.ratedVoltage,
      ratedCurrent: ratedCurrent ?? this.ratedCurrent,
      status: status ?? this.status,
      phaseConfiguration: phaseConfiguration ?? this.phaseConfiguration,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      customFieldValues:
          customFieldValues ?? this.customFieldValues, // Use in copyWith
      relays: relays ?? this.relays, // Use in copyWith
      energyMeters: energyMeters ?? this.energyMeters, // Use in copyWith
    );
  }
}
