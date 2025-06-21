// lib/services/electrical_connection_firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:substation_manager/models/electrical_connection.dart';
// Note: Equipment import is not needed here as batchWriteEquipment is moved
// import 'package:substation_manager/models/equipment.dart'; // Remove if not used by any other methods here

class ElectricalConnectionFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- ElectricalConnection Collection Reference ---
  CollectionReference<ElectricalConnection> get _connectionsRef {
    return _db
        .collection(
          'electrical_connections',
        ) // This is a top-level collection, adjust if nested under substation
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
  // CORRECTED: Removed the extra 'id' parameter from getConnectionsStream signature
  Stream<List<ElectricalConnection>> getConnectionsStream(
  // FIXED: Removed 'String id' parameter
  {
    String? substationId,
    String?
    bayId, // BayId might not be relevant for connections if they are top-level under substation
  }) {
    Query<ElectricalConnection> query = _connectionsRef;
    if (substationId != null) {
      // NOTE: If connections are nested under substations, you need to adjust _connectionsRef or this query
      // For now, assuming if connections are top-level, they have a 'substationId' field
      query = query.where('substationId', isEqualTo: substationId);
    }
    if (bayId != null) {
      query = query.where(
        'bayId',
        isEqualTo: bayId,
      ); // If connections also have a bayId
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
      // If connections are nested under substations, adjust this path:
      // await _db.collection('substations').doc(connection.substationId).collection('connections').doc(connection.id).set(connection.toFirestore());
      await _connectionsRef.doc(connection.id).set(connection);
    } catch (e) {
      print('Error adding connection ${connection.id}: $e');
      rethrow;
    }
  }

  Future<void> updateConnection(ElectricalConnection connection) async {
    try {
      // If connections are nested under substations, adjust this path:
      // await _db.collection('substations').doc(connection.substationId).collection('connections').doc(connection.id).set(connection.toFirestore(), SetOptions(merge: true));
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
      // If connections are nested under substations and you need substationId for path,
      // you'll need to pass it here, e.g., deleteConnection(substationId, connectionId)
      // await _db.collection('substations').doc(substationId).collection('connections').doc(connectionId).delete();
      await _connectionsRef.doc(connectionId).delete();
    } catch (e) {
      print('Error deleting connection $connectionId: $e');
      rethrow;
    }
  }

  // This is the correct batch method for ElectricalConnections, now referencing the correct path.
  // Assuming 'electrical_connections' is a top-level collection and documents have a 'substationId' field,
  // OR that _connectionsRef is already correctly configured for your nested structure if that's the case.
  Future<void> batchWriteConnections({
    required String
    substationId, // Used for context or if connections are sub-collections of substation
    required List<ElectricalConnection> connectionsToAdd,
    required List<ElectricalConnection> connectionsToUpdate,
    required List<String> connectionsToDeleteIds,
  }) async {
    final batch = _db.batch(); // Use the class's _db instance

    // Path reference for connections. ADJUST THIS if your connections are NOT top-level
    // and ARE nested directly under substations:
    final CollectionReference<ElectricalConnection>
    connectionsCollectionForSubstation = _db
        .collection('substations')
        .doc(substationId)
        .collection(
          'connections',
        ) // This assumes 'connections' is a sub-collection of 'substation'
        .withConverter<ElectricalConnection>(
          // Apply converter for batch operations
          fromFirestore: (snapshot, _) =>
              ElectricalConnection.fromFirestore(snapshot),
          toFirestore: (connection, _) => connection.toFirestore(),
        );

    // Add new connections
    for (var conn in connectionsToAdd) {
      final docRef = connectionsCollectionForSubstation.doc(conn.id);
      batch.set(docRef, conn); // Using set with the converter
    }

    // Update existing connections
    for (var conn in connectionsToUpdate) {
      final docRef = connectionsCollectionForSubstation.doc(conn.id);
      batch.set(
        docRef,
        conn,
        SetOptions(merge: true),
      ); // Use set with merge for existing documents with converter
    }

    // Delete connections
    for (var id in connectionsToDeleteIds) {
      final docRef = connectionsCollectionForSubstation.doc(id);
      batch.delete(docRef);
    }

    await batch.commit();
  }
}
