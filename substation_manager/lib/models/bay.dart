// lib/models/bay.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
// Import for JSON encoding/decoding

class Bay {
  final String id;
  final String substationId;
  final String name;
  final String type;
  final String voltageLevel;
  final bool isIncoming;
  final int sequenceNumber;
  final String? description;
  final double? positionX; // Added for SLD placement
  final double? positionY; // Added for SLD placement

  Bay({
    String? id,
    required this.substationId,
    required this.name,
    required this.type,
    required this.voltageLevel,
    this.isIncoming = false,
    required this.sequenceNumber,
    this.description,
    this.positionX, // Added
    this.positionY, // Added
  }) : id = id ?? const Uuid().v4();

  // Factory constructor from Firestore DocumentSnapshot
  factory Bay.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    return Bay(
      id: snapshot.id,
      substationId: data?['substationId'] as String? ?? '',
      name: data?['name'] as String? ?? 'Unknown Bay',
      type: data?['type'] as String? ?? 'Line',
      voltageLevel: data?['voltageLevel'] as String? ?? '',
      isIncoming: data?['isIncoming'] as bool? ?? false,
      sequenceNumber: data?['sequenceNumber'] as int? ?? 0,
      description: data?['description'] as String?,
      positionX: (data?['positionX'] as num?)?.toDouble(), // Deserialized
      positionY: (data?['positionY'] as num?)?.toDouble(), // Deserialized
    );
  }

  // Method to convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'substationId': substationId,
      'name': name,
      'type': type,
      'voltageLevel': voltageLevel,
      'isIncoming': isIncoming,
      'sequenceNumber': sequenceNumber,
      'description': description,
      'positionX': positionX, // Serialized
      'positionY': positionY, // Serialized
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Factory constructor from Map (for SQLite retrieval)
  factory Bay.fromMap(Map<String, dynamic> map) {
    return Bay(
      id: map['id'] as String,
      substationId: map['substationId'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      voltageLevel: map['voltageLevel'] as String,
      isIncoming: map['isIncoming'] == 1,
      sequenceNumber: map['sequenceNumber'] as int,
      description: map['description'] as String?,
      positionX: map['positionX'] as double?, // Deserialized
      positionY: map['positionY'] as double?, // Deserialized
    );
  }

  // Method to convert to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'substationId': substationId,
      'name': name,
      'type': type,
      'voltageLevel': voltageLevel,
      'isIncoming': isIncoming ? 1 : 0,
      'sequenceNumber': sequenceNumber,
      'description': description,
      'positionX': positionX, // Serialized
      'positionY': positionY, // Serialized
    };
  }

  // copyWith method for immutability
  Bay copyWith({
    String? id,
    String? substationId,
    String? name,
    String? type,
    String? voltageLevel,
    bool? isIncoming,
    int? sequenceNumber,
    String? description,
    double? positionX, // Added to copyWith
    double? positionY, // Added to copyWith
  }) {
    return Bay(
      id: id ?? this.id,
      substationId: substationId ?? this.substationId,
      name: name ?? this.name,
      type: type ?? this.type,
      voltageLevel: voltageLevel ?? this.voltageLevel,
      isIncoming: isIncoming ?? this.isIncoming,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      description: description ?? this.description,
      positionX: positionX ?? this.positionX, // Used in copyWith
      positionY: positionY ?? this.positionY, // Used in copyWith
    );
  }
}
