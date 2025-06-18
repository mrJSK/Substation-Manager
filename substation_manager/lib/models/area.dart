// lib/models/area.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // Import for JSON encoding/decoding

// Model for Indian States/Union Territories
class StateModel {
  final double id;
  final String name;

  StateModel({required this.id, required this.name});

  factory StateModel.fromMap(Map<String, dynamic> map) {
    return StateModel(
      id: (map['id'] as num).toDouble(),
      name: map['name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }
}

// Model for Indian Cities/Districts
class CityModel {
  final double id;
  final String name;
  final double stateId;

  CityModel({required this.id, required this.name, required this.stateId});

  factory CityModel.fromMap(Map<String, dynamic> map) {
    return CityModel(
      id: (map['id'] as num).toDouble(),
      name: map['name'] as String,
      stateId: (map['state_id'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'state_id': stateId};
  }
}

// Main Area Model
class Area {
  final String id;
  final String name;
  final String? description;
  final StateModel state;
  final List<CityModel> cities;

  Area({
    required this.id,
    required this.name,
    this.description,
    required this.state,
    this.cities = const [],
  });

  // Factory constructor to create an Area from a Firestore DocumentSnapshot
  factory Area.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    return Area(
      id: snapshot.id,
      name: data?['name'] as String? ?? 'Unknown Area',
      description: data?['description'] as String?,
      state: StateModel.fromMap(
        Map<String, dynamic>.from(data?['state'] ?? {}),
      ),
      cities:
          (data?['cities'] as List<dynamic>?)
              ?.map((e) => CityModel.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  // Method to convert an Area object into a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'state': state.toMap(),
      'cities': cities.map((city) => city.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Factory constructor to create an Area from a Map (for SQLite retrieval or other uses)
  factory Area.fromMap(Map<String, dynamic> map) {
    return Area(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      state: StateModel.fromMap(
        jsonDecode(map['state'] as String),
      ), // Deserialize nested map from JSON string
      cities:
          (jsonDecode(map['cities'] as String)
                  as List<
                    dynamic
                  >?) // Deserialize list of nested maps from JSON string
              ?.map((e) => CityModel.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  // Method to convert an Area object to a Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'state': jsonEncode(
        state.toMap(),
      ), // Serialize nested object to JSON string
      'cities': jsonEncode(
        cities.map((city) => city.toMap()).toList(),
      ), // Serialize list of nested objects to JSON string
    };
  }

  // copyWith method for immutability
  Area copyWith({
    String? id,
    String? name,
    String? description,
    StateModel? state,
    List<CityModel>? cities,
  }) {
    return Area(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      state: state ?? this.state,
      cities: cities ?? this.cities,
    );
  }
}
