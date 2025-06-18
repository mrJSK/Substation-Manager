// lib/models/equipment.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert'; // Import for JSON encoding/decoding

class Equipment {
  final String id;
  final String substationId;
  final String bayId;
  final String equipmentType;
  final String name;
  final int yearOfManufacturing;
  final int yearOfCommissioning;
  final String make;
  final String? serialNumber;
  final String ratedVoltage;
  final String? ratedCurrent;
  final String status;
  final String phaseConfiguration;
  final double positionX;
  final double positionY;
  final Map<String, dynamic> details;

  Equipment({
    String? id,
    required this.substationId,
    required this.bayId,
    required this.equipmentType,
    required this.name,
    required this.yearOfManufacturing,
    required this.yearOfCommissioning,
    required this.make,
    this.serialNumber,
    required this.ratedVoltage,
    this.ratedCurrent,
    this.status = 'Operational',
    this.phaseConfiguration = 'Single Unit',
    this.positionX = 0.0,
    this.positionY = 0.0,
    this.details = const {},
  }) : id = id ?? const Uuid().v4();

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
      name: data?['name'] as String? ?? 'Unknown Equipment',
      yearOfManufacturing: data?['yearOfManufacturing'] as int? ?? 0,
      yearOfCommissioning: data?['yearOfCommissioning'] as int? ?? 0,
      make: data?['make'] as String? ?? '',
      serialNumber: data?['serialNumber'] as String?,
      ratedVoltage: data?['ratedVoltage'] as String? ?? '',
      ratedCurrent: data?['ratedCurrent'] as String?,
      status: data?['status'] as String? ?? 'Operational',
      phaseConfiguration:
          data?['phaseConfiguration'] as String? ?? 'Single Unit',
      positionX: (data?['positionX'] as num?)?.toDouble() ?? 0.0,
      positionY: (data?['positionY'] as num?)?.toDouble() ?? 0.0,
      details: Map<String, dynamic>.from(data?['details'] ?? {}),
    );
  }

  // Method to convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'substationId': substationId,
      'bayId': bayId,
      'equipmentType': equipmentType,
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
      'details': details,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Factory constructor from Map (for SQLite retrieval)
  factory Equipment.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> deserializedDetails = {};
    if (map['details'] is String) {
      deserializedDetails = json.decode(map['details'] as String);
    } else {
      deserializedDetails =
          (map['details'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ??
          {};
    }

    return Equipment(
      id: map['id'] as String,
      substationId: map['substationId'] as String,
      bayId: map['bayId'] as String,
      equipmentType: map['equipmentType'] as String,
      name: map['name'] as String,
      yearOfManufacturing: map['yearOfManufacturing'] as int,
      yearOfCommissioning: map['yearOfCommissioning'] as int,
      make: map['make'] as String,
      serialNumber: map['serialNumber'] as String?,
      ratedVoltage: map['ratedVoltage'] as String,
      ratedCurrent: map['ratedCurrent'] as String?,
      status: map['status'] as String,
      phaseConfiguration: map['phaseConfiguration'] as String? ?? 'Single Unit',
      positionX: (map['positionX'] as num?)?.toDouble() ?? 0.0,
      positionY: (map['positionY'] as num?)?.toDouble() ?? 0.0,
      details: deserializedDetails,
    );
  }

  // Method to convert to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'substationId': substationId,
      'bayId': bayId,
      'equipmentType': equipmentType,
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
      'details': jsonEncode(details),
    };
  }

  // copyWith method for immutability
  Equipment copyWith({
    String? id,
    String? substationId,
    String? bayId,
    String? equipmentType,
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
    Map<String, dynamic>? details,
  }) {
    return Equipment(
      id: id ?? this.id,
      substationId: substationId ?? this.substationId,
      bayId: bayId ?? this.bayId,
      equipmentType: equipmentType ?? this.equipmentType,
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
      details: details ?? this.details,
    );
  }
}
