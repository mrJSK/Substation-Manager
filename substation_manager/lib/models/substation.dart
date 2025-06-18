// lib/models/substation.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // Import for JSON encoding/decoding

class Substation {
  final String id;
  final String name;
  final String areaId;
  final List<String> voltageLevels;
  final double latitude;
  final double longitude;
  final String? address;
  final double cityId;
  final double stateId;
  final String? type;
  final int yearOfCommissioning;
  final double? totalConnectedCapacityMVA;
  final String? notes;
  // REMOVED: final String? sldImagePath;
  // REMOVED: final List<Map<String, dynamic>> sldHotspots;

  Substation({
    required this.id,
    required this.name,
    required this.areaId,
    required this.voltageLevels,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.cityId,
    required this.stateId,
    this.type,
    required this.yearOfCommissioning,
    this.totalConnectedCapacityMVA,
    this.notes,
    // sldImagePath, // Removed from constructor
    // sldHotspots = const [], // Removed from constructor
  });

  // Factory constructor from Firestore DocumentSnapshot
  factory Substation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    return Substation(
      id: snapshot.id,
      name: data?['name'] as String? ?? 'Unknown Substation',
      areaId: data?['areaId'] as String? ?? '',
      voltageLevels: List<String>.from(data?['voltageLevels'] ?? []),
      latitude: (data?['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data?['longitude'] as num?)?.toDouble() ?? 0.0,
      address: data?['address'] as String?,
      cityId: (data?['cityId'] as num?)?.toDouble() ?? 0.0,
      stateId: (data?['stateId'] as num?)?.toDouble() ?? 0.0,
      type: data?['type'] as String?,
      yearOfCommissioning: data?['yearOfCommissioning'] as int? ?? 0,
      totalConnectedCapacityMVA: (data?['totalConnectedCapacityMVA'] as num?)
          ?.toDouble(),
      notes: data?['notes'] as String?,
      // sldImagePath: data?['sldImagePath'] as String?, // Removed from fromFirestore
      // sldHotspots: (data?['sldHotspots'] as List<dynamic>?) // Removed from fromFirestore
      //         ?.map((e) => Map<String, dynamic>.from(e))
      //         .toList() ??
      //     [],
    );
  }

  // Method to convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'areaId': areaId,
      'voltageLevels': voltageLevels,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'cityId': cityId,
      'stateId': stateId,
      'type': type,
      'yearOfCommissioning': yearOfCommissioning,
      'totalConnectedCapacityMVA': totalConnectedCapacityMVA,
      'notes': notes,
      // 'sldImagePath': sldImagePath, // Removed from toFirestore
      // 'sldHotspots': sldHotspots, // Removed from toFirestore
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Factory constructor from Map (for SQLite retrieval)
  factory Substation.fromMap(Map<String, dynamic> map) {
    return Substation(
      id: map['id'] as String,
      name: map['name'] as String,
      areaId: map['areaId'] as String,
      voltageLevels: List<String>.from(
        jsonDecode(map['voltageLevels'] as String) ?? [],
      ),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      address: map['address'] as String?,
      cityId: (map['cityId'] as num).toDouble(),
      stateId: (map['stateId'] as num).toDouble(),
      type: map['type'] as String?,
      yearOfCommissioning: map['yearOfCommissioning'] as int,
      totalConnectedCapacityMVA: (map['totalConnectedCapacityMVA'] as num?)
          ?.toDouble(),
      notes: map['notes'] as String?,
      // sldImagePath: map['sldImagePath'] as String?, // Removed from fromMap
      // sldHotspots: (jsonDecode(map['sldHotspots'] as String) as List<dynamic>?) // Removed from fromMap
      //         ?.map((e) => Map<String, dynamic>.from(e))
      //         .toList() ??
      //     [],
    );
  }

  // Method to convert to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'areaId': areaId,
      'voltageLevels': jsonEncode(voltageLevels),
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'cityId': cityId,
      'stateId': stateId,
      'type': type,
      'yearOfCommissioning': yearOfCommissioning,
      'totalConnectedCapacityMVA': totalConnectedCapacityMVA,
      'notes': notes,
      // 'sldImagePath': sldImagePath, // Removed from toMap
      // 'sldHotspots': jsonEncode(sldHotspots), // Removed from toMap
    };
  }

  // copyWith method for immutability
  Substation copyWith({
    String? id,
    String? name,
    String? areaId,
    List<String>? voltageLevels,
    double? latitude,
    double? longitude,
    String? address,
    double? cityId,
    double? stateId,
    String? type,
    int? yearOfCommissioning,
    double? totalConnectedCapacityMVA,
    String? notes,
    // String? sldImagePath, // Removed from copyWith
    // List<Map<String, dynamic>>? sldHotspots, // Removed from copyWith
  }) {
    return Substation(
      id: id ?? this.id,
      name: name ?? this.name,
      areaId: areaId ?? this.areaId,
      voltageLevels: voltageLevels ?? this.voltageLevels,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      cityId: cityId ?? this.cityId,
      stateId: stateId ?? this.stateId,
      type: type ?? this.type,
      yearOfCommissioning: yearOfCommissioning ?? this.yearOfCommissioning,
      totalConnectedCapacityMVA:
          totalConnectedCapacityMVA ?? this.totalConnectedCapacityMVA,
      notes: notes ?? this.notes,
      // sldImagePath: sldImagePath ?? this.sldImagePath, // Removed from copyWith
      // sldHotspots: sldHotspots ?? this.sldHotspots, // Removed from copyWith
    );
  }
}
