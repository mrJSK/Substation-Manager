// lib/models/task.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert'; // Import for JSON encoding/decoding

class Task {
  final String id;
  final String assignedToUserId;
  final String? assignedToUserName;
  final String assignedByUserId;
  final String? assignedByUserName;
  final String substationId;
  final String substationName;
  final List<String> targetEquipmentIds;
  final List<String> targetReadingFields;
  final String frequency;
  final DateTime dueDate;
  String status;
  final DateTime createdAt;
  DateTime? completionDate;
  String? reviewNotes;
  List<String> associatedReadingIds;

  // These are calculated fields, not stored in Firestore
  int _completedCount;
  int _expectedCount;

  Task({
    String? id,
    required this.assignedToUserId,
    this.assignedToUserName,
    required this.assignedByUserId,
    this.assignedByUserName,
    required this.substationId,
    required this.substationName,
    this.targetEquipmentIds = const [],
    this.targetReadingFields = const [],
    this.frequency = 'Daily',
    required this.dueDate,
    this.status = 'Active',
    required this.createdAt,
    this.completionDate,
    this.reviewNotes,
    this.associatedReadingIds = const [],
    int completedCount = 0,
    int expectedCount = 0,
  }) : id = id ?? const Uuid().v4(),
       _completedCount = completedCount,
       _expectedCount = expectedCount;

  // Factory constructor from Firestore Map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      assignedToUserId: map['assignedToUserId'] as String,
      assignedToUserName: map['assignedToUserName'] as String?,
      assignedByUserId: map['assignedByUserId'] as String,
      assignedByUserName: map['assignedByUserName'] as String?,
      substationId: map['substationId'] as String? ?? '',
      substationName: map['substationName'] as String,
      targetEquipmentIds: List<String>.from(map['targetEquipmentIds'] ?? []),
      targetReadingFields: List<String>.from(map['targetReadingFields'] ?? []),
      frequency: map['frequency'] as String? ?? 'Daily',
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      status: map['status'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      completionDate: (map['completionDate'] as Timestamp?)?.toDate(),
      reviewNotes: map['reviewNotes'] as String?,
      associatedReadingIds: List<String>.from(
        map['associatedReadingIds'] ?? [],
      ),
    );
  }

  // Method to convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assignedToUserId': assignedToUserId,
      'assignedToUserName': assignedToUserName,
      'assignedByUserId': assignedByUserId,
      'assignedByUserName': assignedByUserName,
      'substationId': substationId,
      'substationName': substationName,
      'targetEquipmentIds': targetEquipmentIds,
      'targetReadingFields': targetReadingFields,
      'frequency': frequency,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'completionDate': completionDate != null
          ? Timestamp.fromDate(completionDate!)
          : null,
      'reviewNotes': reviewNotes,
      'associatedReadingIds': associatedReadingIds,
    };
  }

  // Getters and setters for calculated fields
  int get completedCount => _completedCount;
  set completedCount(int count) => _completedCount = count;

  int get expectedCount => _expectedCount;
  set expectedCount(int count) => _expectedCount = count;

  // Derived status based on progress
  String get derivedStatus {
    if (expectedCount > 0 && completedCount >= expectedCount) {
      return 'Completed';
    } else if (completedCount > 0) {
      return 'In Progress';
    } else {
      return 'Pending';
    }
  }

  // Getter to check if the task is overdue
  bool get isOverdue {
    return dueDate.isBefore(DateTime.now()) && derivedStatus != 'Completed';
  }

  // copyWith method for immutability and setting calculated fields
  Task copyWith({
    String? id,
    String? assignedToUserId,
    String? assignedToUserName,
    String? assignedByUserId,
    String? assignedByUserName,
    String? substationId,
    String? substationName,
    List<String>? targetEquipmentIds,
    List<String>? targetReadingFields,
    String? frequency,
    DateTime? dueDate,
    String? status,
    DateTime? createdAt,
    DateTime? completionDate,
    String? reviewNotes,
    List<String>? associatedReadingIds,
    int? completedCount,
    int? expectedCount,
  }) {
    return Task(
      id: id ?? this.id,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      assignedToUserName: assignedToUserName ?? this.assignedToUserName,
      assignedByUserId: assignedByUserId ?? this.assignedByUserId,
      assignedByUserName: assignedByUserName ?? this.assignedByUserName,
      substationId: substationId ?? this.substationId,
      substationName: substationName ?? this.substationName,
      targetEquipmentIds: targetEquipmentIds ?? this.targetEquipmentIds,
      targetReadingFields: targetReadingFields ?? this.targetReadingFields,
      frequency: frequency ?? this.frequency,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completionDate: completionDate ?? this.completionDate,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      associatedReadingIds: associatedReadingIds ?? this.associatedReadingIds,
      completedCount: completedCount ?? this._completedCount,
      expectedCount: expectedCount ?? this._expectedCount,
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, substation: $substationName, status: $status, assignedTo: $assignedToUserName)';
  }
}
