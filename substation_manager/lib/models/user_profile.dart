// lib/models/user_profile.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String
  uid; // Renamed 'id' to 'uid' to match CoreFirestoreService expectation
  final String email;
  String? role;
  final String?
  displayName; // Corresponds to 'name' in previous discussion, check usage.
  final String? mobile;
  String status;
  List<String> assignedSubstationIds;
  List<String> assignedAreaIds;

  UserProfile({
    required this.uid, // Changed from id to uid
    required this.email,
    this.role,
    this.displayName,
    this.mobile,
    this.status = 'pending',
    this.assignedSubstationIds = const [],
    this.assignedAreaIds = const [],
  });

  // Factory constructor to create a UserProfile from a Firestore DocumentSnapshot
  // This is what CoreFirestoreService expects for .withConverter
  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('missing data for userProfileId: ${snapshot.id}');
    }
    // Call your existing fromMap method, ensuring 'id' field is mapped to 'uid'
    // Also, ensure that the document ID (snapshot.id) is used as the uid.
    return UserProfile.fromMap({
      ...data, // Spread existing data
      'id': snapshot.id, // Explicitly use snapshot.id as 'id' for fromMap
    });
  }

  // Your existing fromMap method (remains the same)
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['id'] as String, // Map 'id' from the map to 'uid'
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

  // Method to convert UserProfile to a Map for Firestore
  // This is what CoreFirestoreService expects for .withConverter
  Map<String, dynamic> toFirestore() {
    // Call your existing toMap method
    // Firestore uses the document ID for the uid, so 'uid' field itself
    // is often not stored within the document's map, but rather as the doc ID.
    // However, if you wish to store it for redundancy or specific queries, you can.
    // For .withConverter, it mainly needs the map representation of fields.
    return toMap();
  }

  // Your existing toMap method (remains the same)
  Map<String, dynamic> toMap() {
    return {
      // 'id': uid, // 'id' from the map will now be 'uid'
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
    String? uid, // Changed from id to uid
    String? email,
    String? role,
    String? displayName,
    String? mobile,
    String? status,
    List<String>? assignedSubstationIds,
    List<String>? assignedAreaIds,
  }) {
    return UserProfile(
      uid: uid ?? this.uid, // Changed from id to uid
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
