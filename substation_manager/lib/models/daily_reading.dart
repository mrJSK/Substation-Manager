// lib/models/daily_reading.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert'; // Import for JSON encoding/decoding

class DailyReading {
  final String id;
  final String equipmentId;
  final String substationId;
  final DateTime readingForDate;
  final String readingTimeOfDay;
  final Map<String, dynamic> readings;
  final String recordedByUserId;
  final DateTime recordDateTime;
  final String status;
  final String? notes;
  final String? photoPath;

  DailyReading({
    String? id,
    required this.equipmentId,
    required this.substationId,
    required this.readingForDate,
    required this.readingTimeOfDay,
    required this.readings,
    required this.recordedByUserId,
    required this.recordDateTime,
    this.status = 'Submitted',
    this.notes,
    this.photoPath,
  }) : id = id ?? const Uuid().v4();

  // Factory constructor from Firestore DocumentSnapshot
  factory DailyReading.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    return DailyReading(
      id: snapshot.id,
      equipmentId: data?['equipmentId'] as String? ?? '',
      substationId: data?['substationId'] as String? ?? '',
      readingForDate: (data?['readingForDate'] as Timestamp).toDate(),
      readingTimeOfDay: data?['readingTimeOfDay'] as String? ?? '',
      readings: Map<String, dynamic>.from(data?['readings'] ?? {}),
      recordedByUserId: data?['recordedByUserId'] as String? ?? '',
      recordDateTime: (data?['recordDateTime'] as Timestamp).toDate(),
      status: data?['status'] as String? ?? 'Submitted',
      notes: data?['notes'] as String?,
      photoPath: data?['photoPath'] as String?,
    );
  }

  // Method to convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'equipmentId': equipmentId,
      'substationId': substationId,
      'readingForDate': Timestamp.fromDate(readingForDate),
      'readingTimeOfDay': readingTimeOfDay,
      'readings': readings,
      'recordedByUserId': recordedByUserId,
      'recordDateTime': Timestamp.fromDate(recordDateTime),
      'status': status,
      'notes': notes,
      'photoPath': photoPath,
    };
  }

  // Factory constructor from Map (for SQLite retrieval)
  factory DailyReading.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> deserializedReadings = {};
    if (map['readings'] is String) {
      deserializedReadings = json.decode(map['readings'] as String);
    } else {
      deserializedReadings =
          (map['readings'] as Map<dynamic, dynamic>?)
              ?.cast<String, dynamic>() ??
          {};
    }

    return DailyReading(
      id: map['id'] as String,
      equipmentId: map['equipmentId'] as String,
      substationId: map['substationId'] as String,
      readingForDate: DateTime.parse(map['readingForDate'] as String),
      readingTimeOfDay: map['readingTimeOfDay'] as String,
      readings: deserializedReadings,
      recordedByUserId: map['recordedByUserId'] as String,
      recordDateTime: DateTime.parse(map['recordDateTime'] as String),
      status: map['status'] as String,
      notes: map['notes'] as String?,
      photoPath: map['photoPath'] as String?,
    );
  }

  // Method to convert to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'equipmentId': equipmentId,
      'substationId': substationId,
      'readingForDate': readingForDate.toIso8601String(),
      'readingTimeOfDay': readingTimeOfDay,
      'readings': jsonEncode(readings),
      'recordedByUserId': recordedByUserId,
      'recordDateTime': recordDateTime.toIso8601String(),
      'status': status,
      'notes': notes,
      'photoPath': photoPath,
    };
  }

  // copyWith method for immutability
  DailyReading copyWith({
    String? id,
    String? equipmentId,
    String? substationId,
    DateTime? readingForDate,
    String? readingTimeOfDay,
    Map<String, dynamic>? readings,
    String? recordedByUserId,
    DateTime? recordDateTime,
    String? status,
    String? notes,
    String? photoPath,
  }) {
    return DailyReading(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      substationId: substationId ?? this.substationId,
      readingForDate: readingForDate ?? this.readingForDate,
      readingTimeOfDay: readingTimeOfDay ?? this.readingTimeOfDay,
      readings: readings ?? this.readings,
      recordedByUserId: recordedByUserId ?? this.recordedByUserId,
      recordDateTime: recordDateTime ?? this.recordDateTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}
