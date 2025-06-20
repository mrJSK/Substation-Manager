// lib/services/electrical_connection_firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:substation_manager/models/electrical_connection.dart';

class ElectricalConnectionFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- ElectricalConnection Collection Reference ---
  CollectionReference<ElectricalConnection> get _connectionsRef {
    return _db
        .collection('electrical_connections')
        .withConverter<ElectricalConnection>(
          fromFirestore: (snapshot, _) =>
              ElectricalConnection.fromFirestore(snapshot),
          toFirestore: (connection, _) => connection.toFirestore(),
        );
  }

  // This method is required for batch operations in SldState
  DocumentReference<ElectricalConnection> getConnectionDocRef(
    String connectionId,
  ) {
    return _connectionsRef.doc(connectionId);
  }

  // --- ElectricalConnection Methods ---
  Stream<List<ElectricalConnection>> getConnectionsStream({
    String? substationId,
    String? bayId,
  }) {
    Query<ElectricalConnection> query = _connectionsRef;
    if (substationId != null) {
      query = query.where('substationId', isEqualTo: substationId);
    }
    if (bayId != null) {
      query = query.where('bayId', isEqualTo: bayId);
    }
    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
    );
  }

  Future<List<ElectricalConnection>> getConnectionsOnce({
    String? substationId,
    String? bayId,
  }) async {
    try {
      Query<ElectricalConnection> query = _connectionsRef;
      if (substationId != null) {
        query = query.where('substationId', isEqualTo: substationId);
      }
      if (bayId != null) {
        query = query.where('bayId', isEqualTo: bayId);
      }
      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching electrical connections: $e');
      rethrow;
    }
  }

  Future<void> addConnection(ElectricalConnection connection) async {
    try {
      await _connectionsRef.doc(connection.id).set(connection);
    } catch (e) {
      print('Error adding connection ${connection.id}: $e');
      rethrow;
    }
  }

  Future<void> updateConnection(ElectricalConnection connection) async {
    try {
      await _connectionsRef
          .doc(connection.id)
          .set(connection, SetOptions(merge: true));
    } catch (e) {
      print('Error updating connection ${connection.id}: $e');
      rethrow;
    }
  }

  Future<void> deleteConnection(String connectionId) async {
    try {
      await _connectionsRef.doc(connectionId).delete();
    } catch (e) {
      print('Error deleting connection $connectionId: $e');
      rethrow;
    }
  }
}
