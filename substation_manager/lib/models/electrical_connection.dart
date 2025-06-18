// lib/models/electrical_connection.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert'; // Import for JSON encoding/decoding

class ElectricalConnection {
  final String id;
  final String substationId;
  final String? bayId;
  final String fromEquipmentId;
  final String toEquipmentId;
  final String connectionType;
  final List<Map<String, double>> points;

  ElectricalConnection({
    String? id,
    required this.substationId,
    this.bayId,
    required this.fromEquipmentId,
    required this.toEquipmentId,
    this.connectionType = 'line-segment',
    this.points = const [],
  }) : id = id ?? const Uuid().v4();

  // Factory constructor from Firestore DocumentSnapshot
  factory ElectricalConnection.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    return ElectricalConnection(
      id: snapshot.id,
      substationId: data?['substationId'] as String? ?? '',
      bayId: data?['bayId'] as String?,
      fromEquipmentId: data?['fromEquipmentId'] as String? ?? '',
      toEquipmentId: data?['toEquipmentId'] as String? ?? '',
      connectionType: data?['connectionType'] as String? ?? 'line-segment',
      points:
          (data?['points'] as List<dynamic>?)
              ?.map((e) => Map<String, double>.from(e))
              .toList() ??
          [],
    );
  }

  // Method to convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'substationId': substationId,
      'bayId': bayId,
      'fromEquipmentId': fromEquipmentId,
      'toEquipmentId': toEquipmentId,
      'connectionType': connectionType,
      'points': points,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Factory constructor from Map (for SQLite retrieval)
  factory ElectricalConnection.fromMap(Map<String, dynamic> map) {
    return ElectricalConnection(
      id: map['id'] as String,
      substationId: map['substationId'] as String,
      bayId: map['bayId'] as String?,
      fromEquipmentId: map['fromEquipmentId'] as String,
      toEquipmentId: map['toEquipmentId'] as String,
      connectionType: map['connectionType'] as String,
      points:
          (jsonDecode(map['points'] as String) as List<dynamic>?)
              ?.map((e) => Map<String, double>.from(e))
              .toList() ??
          [],
    );
  }

  // Method to convert to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'substationId': substationId,
      'bayId': bayId,
      'fromEquipmentId': fromEquipmentId,
      'toEquipmentId': toEquipmentId,
      'connectionType': connectionType,
      'points': jsonEncode(points),
    };
  }

  // copyWith method for immutability
  ElectricalConnection copyWith({
    String? id,
    String? substationId,
    String? bayId,
    String? fromEquipmentId,
    String? toEquipmentId,
    String? connectionType,
    List<Map<String, double>>? points,
  }) {
    return ElectricalConnection(
      id: id ?? this.id,
      substationId: substationId ?? this.substationId,
      bayId: bayId ?? this.bayId,
      fromEquipmentId: fromEquipmentId ?? this.fromEquipmentId,
      toEquipmentId: toEquipmentId ?? this.toEquipmentId,
      connectionType: connectionType ?? this.connectionType,
      points: points ?? this.points,
    );
  }
}
