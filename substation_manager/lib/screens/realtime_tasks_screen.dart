// lib/screens/realtime_tasks_screen.dart
// Placeholder for the "Daily Operations" tab (formerly "Real-Time Tasks")

import 'package:flutter/material.dart';
import 'package:substation_manager/models/user_profile.dart';
import 'package:substation_manager/models/task.dart'; // Import Task model
import 'package:substation_manager/services/task_service.dart'; // Task service
import 'package:substation_manager/services/daily_reading_firestore_service.dart'; // Daily reading service
import 'package:substation_manager/models/daily_reading.dart'; // Daily Reading model
import 'package:substation_manager/models/equipment.dart'; // Equipment model
import 'package:substation_manager/services/equipment_firestore_service.dart'; // Equipment service
import 'package:substation_manager/utils/snackbar_utils.dart'; // Snackbar utility
import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'dart:async';

class RealTimeTasksScreen extends StatefulWidget {
  final UserProfile? currentUserProfile;

  const RealTimeTasksScreen({super.key, required this.currentUserProfile});

  @override
  State<RealTimeTasksScreen> createState() => _RealTimeTasksScreenState();
}

class _RealTimeTasksScreenState extends State<RealTimeTasksScreen> {
  List<Task> _assignedTasks = []; // Daily reading assignment templates
  List<DailyReading> _dailyReadings = [];
  List<Equipment> _allEquipment = [];
  bool _isLoading = true;

  final TaskService _taskService = TaskService();
  final DailyReadingFirestoreService _dailyReadingService =
      DailyReadingFirestoreService();
  final EquipmentFirestoreService _equipmentService =
      EquipmentFirestoreService();

  StreamSubscription? _tasksSubscription;
  StreamSubscription? _dailyReadingsSubscription;
  StreamSubscription? _equipmentSubscription;

  @override
  void initState() {
    super.initState();
    _loadOperationalData();
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    _dailyReadingsSubscription?.cancel();
    _equipmentSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RealTimeTasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUserProfile != oldWidget.currentUserProfile) {
      _loadOperationalData();
    }
  }

  Future<void> _loadOperationalData() async {
    if (!mounted || widget.currentUserProfile == null) return;
    setState(() {
      _isLoading = true;
    });

    final UserProfile user = widget.currentUserProfile!;

    try {
      _equipmentSubscription?.cancel();
      _equipmentSubscription = _equipmentService
          .getEquipmentStream(
            substationId: user.assignedSubstationIds.isNotEmpty
                ? user.assignedSubstationIds.first
                : null,
          )
          .listen((equipment) {
            if (mounted) {
              _allEquipment = equipment;
              _updateDisplay();
            }
          });

      // SSO only sees tasks assigned to them
      if (user.role == 'SSO') {
        _tasksSubscription?.cancel();
        _tasksSubscription = _taskService.streamTasksForSso(user.uid).listen((
          tasks,
        ) {
          if (mounted) {
            _assignedTasks = tasks;
            _updateDisplay();
          }
        });
        _dailyReadingsSubscription?.cancel();
        _dailyReadingsSubscription = _dailyReadingService
            .getDailyReadingsForSsoAndDateRange(
              user.uid,
              DateTime.now().subtract(const Duration(days: 7)), // Last 7 days
              DateTime.now(),
            )
            .listen((readings) {
              if (mounted) {
                _dailyReadings = readings;
                _updateDisplay();
              }
            });
      } else {
        // SDO/JE/Admin see all tasks
        _tasksSubscription?.cancel();
        _tasksSubscription = _taskService.streamAllTasks().listen((tasks) {
          if (mounted) {
            _assignedTasks = tasks;
            _updateDisplay();
          }
        });
        _dailyReadingsSubscription?.cancel();
        _dailyReadingsSubscription = _dailyReadingService
            .streamAllDailyReadings()
            .listen((readings) {
              if (mounted) {
                _dailyReadings = readings;
                _updateDisplay();
              }
            });
      }
    } catch (e) {
      print('Error loading operational data: $e');
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Error loading operational data.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateDisplay() {
    if (!mounted) return;
    setState(() {
      // Logic to filter _assignedTasks and _dailyReadings based on role and combine/process data
      // For example, for SSOs, calculate if today's readings are complete for each assigned equipment.
      // This is a complex calculation that will be built out when the "Daily Operations" module is fully implemented.

      // Placeholder: Mark tasks as due/incomplete
      final now = DateTime.now();
      _assignedTasks = _assignedTasks.map((task) {
        // Find daily readings for this task's equipment for today
        int completedReadingsCount = 0;
        for (String eqId in task.targetEquipmentIds) {
          final readingsForToday = _dailyReadings.firstWhereOrNull(
            (dr) =>
                dr.equipmentId == eqId &&
                dr.readingForDate.year == now.year &&
                dr.readingForDate.month == now.month &&
                dr.readingForDate.day == now.day,
          );
          if (readingsForToday != null) {
            completedReadingsCount++;
          }
        }
        return task.copyWith(
          completedCount: completedReadingsCount,
          expectedCount: task.targetEquipmentIds.length,
        );
      }).toList();
    });
  }

  // Placeholder for navigating to enter daily readings
  void _navigateToDailyReadingEntry(Task task, Equipment equipment) {
    if (mounted) {
      SnackBarUtils.showSnackBar(
        context,
        'Navigate to Daily Reading Entry for ${equipment.name}',
      );
      // TODO: Implement navigation to a screen where SSO can input readings for this equipment.
      // This screen will need the Task, Equipment, and ideally the MasterEquipmentTemplate for field definitions.
    }
  }

  // Placeholder for assigning new daily reading tasks (for JE/SDO)
  void _assignNewDailyReadingTask() {
    if (mounted) {
      SnackBarUtils.showSnackBar(
        context,
        'Assign New Daily Reading Task functionality coming soon!',
      );
      // TODO: Implement navigation to a screen where JE/SDO can assign tasks.
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final UserProfile? currentUser = widget.currentUserProfile;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentUser == null ||
        currentUser.status != 'approved' ||
        !['Admin', 'SDO', 'JE', 'SSO'].contains(currentUser.role)) {
      return Center(
        child: Text('Access Denied for Daily Operations.'),
      ); // Fallback
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            currentUser.role == 'SSO'
                ? 'Your Daily Reading Assignments:'
                : 'Daily Reading Assignments Overview:',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
        if (currentUser.role == 'JE' ||
            currentUser.role == 'SDO') // Only JE/SDO can assign
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: ElevatedButton.icon(
              onPressed: _assignNewDailyReadingTask,
              icon: const Icon(Icons.assignment_add),
              label: const Text('Assign Daily Reading Task'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                foregroundColor: colorScheme.onSecondary,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        const SizedBox(height: 10),
        Expanded(
          child: _assignedTasks.isEmpty
              ? Center(
                  child: Text(
                    'No daily reading assignments found for your role.',
                  ),
                )
              : ListView.builder(
                  itemCount: _assignedTasks.length,
                  itemBuilder: (context, index) {
                    final task = _assignedTasks[index];
                    // Find associated substation and equipment names for display
                    String substationName =
                        task.substationName; // Task already has substation name
                    String equipmentNames = task.targetEquipmentIds
                        .map((eqId) {
                          final eq = _allEquipment.firstWhereOrNull(
                            (e) => e.id == eqId,
                          );
                          return eq?.name ?? 'Unknown Equipment';
                        })
                        .join(', ');

                    IconData statusIcon;
                    Color iconColor;
                    if (task.derivedStatus == 'Completed') {
                      statusIcon = Icons.check_circle;
                      iconColor = Colors.green;
                    } else if (task.isOverdue) {
                      statusIcon = Icons.error;
                      iconColor = Colors.red;
                    } else if (task.derivedStatus == 'In Progress') {
                      statusIcon = Icons.hourglass_empty;
                      iconColor = colorScheme.tertiary;
                    } else {
                      statusIcon = Icons.pending;
                      iconColor = Colors.grey;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 3,
                      child: ExpansionTile(
                        title: Text('Substation: $substationName'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Equipment: $equipmentNames'),
                            Text(
                              'Due: ${task.dueDate.toLocal().toString().split(' ')[0]}',
                            ),
                            Text('Status: ${task.derivedStatus}'),
                            if (currentUser.role !=
                                'SSO') // SSO doesn't see who assigned it here
                              Text(
                                'Assigned to: ${task.assignedToUserName ?? 'N/A'}',
                              ),
                          ],
                        ),
                        trailing: Icon(statusIcon, color: iconColor),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Expected Readings: ${task.expectedCount}',
                                ),
                                Text(
                                  'Completed Readings (Today): ${task.completedCount}',
                                ),
                                if (currentUser.role == 'SSO' &&
                                    task.targetEquipmentIds.isNotEmpty)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // If SSO, provide option to enter reading for the first equipment in the task
                                      final Equipment? equipmentToRead =
                                          _allEquipment.firstWhereOrNull(
                                            (eq) =>
                                                eq.id ==
                                                task.targetEquipmentIds.first,
                                          );
                                      if (equipmentToRead != null) {
                                        _navigateToDailyReadingEntry(
                                          task,
                                          equipmentToRead,
                                        );
                                      } else {
                                        SnackBarUtils.showSnackBar(
                                          context,
                                          'Equipment not found for this assignment.',
                                          isError: true,
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Enter Daily Readings'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
                                      minimumSize: const Size(
                                        double.infinity,
                                        40,
                                      ),
                                    ),
                                  ),
                                // TODO: Add more details or action buttons based on role.
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
