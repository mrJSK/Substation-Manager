// lib/services/daily_reading_firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:substation_manager/models/daily_reading.dart';

class DailyReadingFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- DailyReading Collection Reference ---
  CollectionReference<DailyReading> get _dailyReadingsRef {
    return _firestore
        .collection('daily_readings')
        .withConverter<DailyReading>(
          fromFirestore: (snapshot, _) => DailyReading.fromFirestore(snapshot),
          toFirestore: (reading, _) => reading.toFirestore(),
        );
  }

  // --- DailyReading Methods ---
  Future<void> addDailyReading(DailyReading reading) async {
    try {
      await _dailyReadingsRef.doc(reading.id).set(reading);
    } catch (e) {
      print('Error adding daily reading ${reading.id}: $e');
      rethrow;
    }
  }

  Future<void> updateDailyReading(DailyReading reading) async {
    try {
      await _dailyReadingsRef
          .doc(reading.id)
          .set(reading, SetOptions(merge: true));
    } catch (e) {
      print('Error updating daily reading ${reading.id}: $e');
      rethrow;
    }
  }

  Future<void> deleteDailyReading(String readingId) async {
    try {
      await _dailyReadingsRef.doc(readingId).delete();
    } catch (e) {
      print('Error deleting daily reading $readingId: $e');
      rethrow;
    }
  }

  // Get daily readings for a specific equipment on a specific date.
  Stream<List<DailyReading>> getDailyReadingsForEquipmentAndDate(
    String equipmentId,
    DateTime readingDate,
  ) {
    final startOfDay = DateTime(
      readingDate.year,
      readingDate.month,
      readingDate.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _dailyReadingsRef
        .where('equipmentId', isEqualTo: equipmentId)
        .where('readingForDate', isGreaterThanOrEqualTo: startOfDay)
        .where('readingForDate', isLessThan: endOfDay)
        .orderBy('readingForDate')
        .orderBy('readingTimeOfDay')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Get all daily readings for a specific SSO for a given date range.
  Stream<List<DailyReading>> getDailyReadingsForSsoAndDateRange(
    String ssoId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _dailyReadingsRef
        .where('recordedByUserId', isEqualTo: ssoId)
        .where('readingForDate', isGreaterThanOrEqualTo: startDate)
        .where('readingForDate', isLessThanOrEqualTo: endDate)
        .orderBy('readingForDate')
        .orderBy('readingTimeOfDay')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Get all daily readings for a specific substation within a date range.
  Stream<List<DailyReading>> getDailyReadingsForSubstationAndDateRange(
    String substationId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _dailyReadingsRef
        .where('substationId', isEqualTo: substationId)
        .where('readingForDate', isGreaterThanOrEqualTo: startDate)
        .where('readingForDate', isLessThanOrEqualTo: endDate)
        .orderBy('readingForDate')
        .orderBy('readingTimeOfDay')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Get all daily readings in real-time (e.g., for SDO/Admin overview).
  Stream<List<DailyReading>> streamAllDailyReadings() {
    return _dailyReadingsRef
        .orderBy('recordDateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
