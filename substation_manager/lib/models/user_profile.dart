// lib/models/user_profile.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid; // Unique User ID (renamed from 'id')
  final String email;
  String? role;
  final String? displayName;
  final String? mobile;
  String status;
  List<String> assignedSubstationIds;
  List<String> assignedAreaIds;

  UserProfile({
    required this.uid,
    required this.email,
    this.role,
    this.displayName,
    this.mobile,
    this.status = 'pending', // Default status for new users
    this.assignedSubstationIds = const [],
    this.assignedAreaIds = const [],
  });

  // Factory constructor to create a UserProfile from a Firestore DocumentSnapshot
  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('missing data for userProfileId: ${snapshot.id}');
    }
    // Call the fromMap method, ensuring 'id' field is mapped to 'uid'.
    // Firestore document ID (snapshot.id) is used as the 'id' for fromMap.
    return UserProfile.fromMap({...data, 'id': snapshot.id});
  }

  // Factory method to create a UserProfile from a general Map (e.g., from SharedPreferences or direct Firestore data)
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['id'] as String, // Map 'id' from the map to 'uid' property
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

  // Method to convert UserProfile to a Map for Firestore (used by .withConverter)
  Map<String, dynamic> toFirestore() {
    return toMap(); // Simply delegate to toMap()
  }

  // Method to convert UserProfile to a general Map (e.g., for caching in SharedPreferences)
  Map<String, dynamic> toMap() {
    return {
      'id':
          uid, // Include uid in the map when converting to map, for fromMap compatibility
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
    String? uid,
    String? email,
    String? role,
    String? displayName,
    String? mobile,
    String? status,
    List<String>? assignedSubstationIds,
    List<String>? assignedAreaIds,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
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
    return 'UserProfile(uid: $uid, email: $email, role: $role, displayName: $displayName, mobile: $mobile, status: $status, assignedSubstationIds: $assignedSubstationIds, assignedAreaIds: $assignedAreaIds)';
  }
}
