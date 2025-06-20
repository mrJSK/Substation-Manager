// lib/models/equipment.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert'; // Required for jsonDecode/jsonEncode

class Equipment {
  final String id;
  final String substationId;
  final String bayId;
  final String equipmentType;
  final String masterTemplateId;
  String name;
  double positionX;
  double positionY;
  final Map<String, dynamic>
  customFieldValues; // Store dynamic custom field values
  final List<Map<String, dynamic>>
  relays; // Store specific relay instances and their custom fields
  final List<Map<String, dynamic>>
  energyMeters; // Store specific energy meter instances and their custom fields
  final int? yearOfManufacturing;
  final int? yearOfCommissioning;
  final String? make;
  final String? serialNumber;
  final String? ratedVoltage;
  final String? ratedCurrent;
  final String? status;
  final String? phaseConfiguration;
  final String
  symbolKey; // NEW: Field to store the key for the visual symbol (e.g., 'Transformer', 'Busbar')

  Equipment({
    String? id,
    required this.substationId,
    required this.bayId,
    required this.equipmentType,
    required this.masterTemplateId,
    required this.name,
    required this.positionX,
    required this.positionY,
    this.customFieldValues = const {},
    this.relays = const [],
    this.energyMeters = const [],
    this.yearOfManufacturing,
    this.yearOfCommissioning,
    this.make,
    this.serialNumber,
    this.ratedVoltage,
    this.ratedCurrent,
    this.status,
    this.phaseConfiguration,
    this.symbolKey = 'Transformer', // NEW: Default symbolKey
  }) : id = id ?? const Uuid().v4();

  // Factory constructor from Firestore DocumentSnapshot
  factory Equipment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Missing data for Equipment ID: ${snapshot.id}');
    }
    return Equipment(
      id: snapshot.id,
      substationId: data['substationId'] as String? ?? '',
      bayId: data['bayId'] as String? ?? '',
      equipmentType: data['equipmentType'] as String? ?? '',
      masterTemplateId: data['masterTemplateId'] as String? ?? '',
      name: data['name'] as String? ?? 'Unnamed Equipment',
      positionX: (data['positionX'] as num?)?.toDouble() ?? 0.0,
      positionY: (data['positionY'] as num?)?.toDouble() ?? 0.0,
      customFieldValues: Map<String, dynamic>.from(
        data['customFieldValues'] ?? {},
      ),
      relays:
          (data['relays'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      energyMeters:
          (data['energyMeters'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      yearOfManufacturing: data['yearOfManufacturing'] as int?,
      yearOfCommissioning: data['yearOfCommissioning'] as int?,
      make: data['make'] as String?,
      serialNumber: data['serialNumber'] as String?,
      ratedVoltage: data['ratedVoltage'] as String?,
      ratedCurrent: data['ratedCurrent'] as String?,
      status: data['status'] as String?,
      phaseConfiguration: data['phaseConfiguration'] as String?,
      symbolKey:
          data['symbolKey'] as String? ??
          'Transformer', // NEW: Deserialize symbolKey
    );
  }

  // Method to convert Equipment to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'substationId': substationId,
      'bayId': bayId,
      'equipmentType': equipmentType,
      'masterTemplateId': masterTemplateId,
      'name': name,
      'positionX': positionX,
      'positionY': positionY,
      'customFieldValues': customFieldValues,
      'relays': relays,
      'energyMeters': energyMeters,
      'yearOfManufacturing': yearOfManufacturing,
      'yearOfCommissioning': yearOfCommissioning,
      'make': make,
      'serialNumber': serialNumber,
      'ratedVoltage': ratedVoltage,
      'ratedCurrent': ratedCurrent,
      'status': status,
      'phaseConfiguration': phaseConfiguration,
      'symbolKey': symbolKey, // NEW: Serialize symbolKey
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Factory constructor from Map (for SQLite retrieval)
  factory Equipment.fromMap(Map<String, dynamic> map) {
    return Equipment(
      id: map['id'] as String,
      substationId: map['substationId'] as String,
      bayId: map['bayId'] as String,
      equipmentType: map['equipmentType'] as String,
      masterTemplateId: map['masterTemplateId'] as String,
      name: map['name'] as String,
      positionX: (map['positionX'] as num).toDouble(),
      positionY: (map['positionY'] as num).toDouble(),
      customFieldValues: Map<String, dynamic>.from(
        jsonDecode(map['customFieldValues'] as String),
      ),
      relays: (jsonDecode(map['relays'] as String) as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      energyMeters: (jsonDecode(map['energyMeters'] as String) as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      yearOfManufacturing: map['yearOfManufacturing'] as int?,
      yearOfCommissioning: map['yearOfCommissioning'] as int?,
      make: map['make'] as String?,
      serialNumber: map['serialNumber'] as String?,
      ratedVoltage: map['ratedVoltage'] as String?,
      ratedCurrent: map['ratedCurrent'] as String?,
      status: map['status'] as String?,
      phaseConfiguration: map['phaseConfiguration'] as String?,
      symbolKey:
          map['symbolKey'] as String? ??
          'Transformer', // NEW: Deserialize symbolKey from map
    );
  }

  // Method to convert to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'substationId': substationId,
      'bayId': bayId,
      'equipmentType': equipmentType,
      'masterTemplateId': masterTemplateId,
      'name': name,
      'positionX': positionX,
      'positionY': positionY,
      'customFieldValues': jsonEncode(customFieldValues),
      'relays': jsonEncode(relays),
      'energyMeters': jsonEncode(energyMeters),
      'yearOfManufacturing': yearOfManufacturing,
      'yearOfCommissioning': yearOfCommissioning,
      'make': make,
      'serialNumber': serialNumber,
      'ratedVoltage': ratedVoltage,
      'ratedCurrent': ratedCurrent,
      'status': status,
      'phaseConfiguration': phaseConfiguration,
      'symbolKey': symbolKey, // NEW: Serialize symbolKey to map
    };
  }

  // copyWith method for immutability
  Equipment copyWith({
    String? id,
    String? substationId,
    String? bayId,
    String? equipmentType,
    String? masterTemplateId,
    String? name,
    double? positionX,
    double? positionY,
    Map<String, dynamic>? customFieldValues,
    List<Map<String, dynamic>>? relays,
    List<Map<String, dynamic>>? energyMeters,
    int? yearOfManufacturing,
    int? yearOfCommissioning,
    String? make,
    String? serialNumber,
    String? ratedVoltage,
    String? ratedCurrent,
    String? status,
    String? phaseConfiguration,
    String? symbolKey, // NEW: Add symbolKey to copyWith
  }) {
    return Equipment(
      id: id ?? this.id,
      substationId: substationId ?? this.substationId,
      bayId: bayId ?? this.bayId,
      equipmentType: equipmentType ?? this.equipmentType,
      masterTemplateId: masterTemplateId ?? this.masterTemplateId,
      name: name ?? this.name,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      customFieldValues: customFieldValues ?? this.customFieldValues,
      relays: relays ?? this.relays,
      energyMeters: energyMeters ?? this.energyMeters,
      yearOfManufacturing: yearOfManufacturing ?? this.yearOfManufacturing,
      yearOfCommissioning: yearOfCommissioning ?? this.yearOfCommissioning,
      make: make ?? this.make,
      serialNumber: serialNumber ?? this.serialNumber,
      ratedVoltage: ratedVoltage ?? this.ratedVoltage,
      ratedCurrent: ratedCurrent ?? this.ratedCurrent,
      status: status ?? this.status,
      phaseConfiguration: phaseConfiguration ?? this.phaseConfiguration,
      symbolKey: symbolKey ?? this.symbolKey, // NEW: Copy symbolKey
    );
  }
}
