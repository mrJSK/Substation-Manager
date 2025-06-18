// lib/services/task_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:substation_manager/models/task.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Task Collection Reference ---
  CollectionReference<Task> get _tasksRef {
    return _firestore
        .collection('tasks')
        .withConverter<Task>(
          fromFirestore: (snapshot, _) => Task.fromMap(snapshot.data()!),
          toFirestore: (task, _) => task.toMap(),
        );
  }

  // Get daily reading assignment tasks for a specific SSO.
  Stream<List<Task>> streamTasksForSso(String ssoId) {
    return _tasksRef
        .where('assignedToUserId', isEqualTo: ssoId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Get all daily reading assignment tasks (for SDO/JE/Admin roles).
  Stream<List<Task>> streamAllTasks() {
    return _tasksRef
        .orderBy('substationName')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Create a new daily reading assignment template.
  Future<void> createTaskAssignment(Task task) async {
    try {
      await _tasksRef.doc(task.id).set(task);
      print('Daily reading assignment ${task.id} created successfully.');
    } catch (e) {
      print('Error creating daily reading assignment ${task.id}: $e');
      rethrow;
    }
  }

  // Update an existing daily reading assignment template.
  Future<void> updateTaskAssignment(Task task) async {
    try {
      await _tasksRef.doc(task.id).set(task, SetOptions(merge: true));
      print('Daily reading assignment ${task.id} updated successfully.');
    } catch (e) {
      print('Error updating daily reading assignment ${task.id}: $e');
      rethrow;
    }
  }

  // Delete a daily reading assignment template.
  Future<void> deleteTaskAssignment(String taskId) async {
    try {
      await _tasksRef.doc(taskId).delete();
      print('Daily reading assignment $taskId deleted successfully.');
    } catch (e) {
      print('Error deleting daily reading assignment $taskId: $e');
      rethrow;
    }
  }

  // Get a single task assignment by its ID.
  Future<Task?> getTaskAssignmentById(String taskId) async {
    try {
      final docSnapshot = await _tasksRef.doc(taskId).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return docSnapshot.data();
      }
    } catch (e) {
      print('Error fetching task assignment $taskId: $e');
    }
    return null;
  }
}
