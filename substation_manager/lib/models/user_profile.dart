// lib/models/user_profile.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String email;
  String? role;
  final String? displayName;
  final String? mobile;
  String status;
  List<String> assignedSubstationIds;
  List<String> assignedAreaIds;

  UserProfile({
    required this.id,
    required this.email,
    this.role,
    this.displayName,
    this.mobile,
    this.status = 'pending',
    this.assignedSubstationIds = const [],
    this.assignedAreaIds = const [],
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String,
      role: map['role'] as String?,
      displayName: map['displayName'] as String?,
      mobile: map['mobile'] as String?,
      status: map['status'] as String? ?? 'pending',
      assignedSubstationIds: List<String>.from(
        map['assignedSubstationIds'] ?? [],
      ),
      assignedAreaIds: List<String>.from(map['assignedAreaIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'displayName': displayName,
      'mobile': mobile,
      'status': status,
      'assignedSubstationIds': assignedSubstationIds,
      'assignedAreaIds': assignedAreaIds,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? role,
    String? displayName,
    String? mobile,
    String? status,
    List<String>? assignedSubstationIds,
    List<String>? assignedAreaIds,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      mobile: mobile ?? this.mobile,
      status: status ?? this.status,
      assignedSubstationIds:
          assignedSubstationIds ?? this.assignedSubstationIds,
      assignedAreaIds: assignedAreaIds ?? this.assignedAreaIds,
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, role: $role, displayName: $displayName, mobile: $mobile, status: $status, assignedSubstationIds: $assignedSubstationIds, assignedAreaIds: $assignedAreaIds)';
  }
}
