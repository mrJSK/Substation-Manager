// lib/screens/dashboard_tab.dart
// DashboardTab for Substation Manager app.

import 'package:flutter/material.dart';
import 'package:substation_manager/models/user_profile.dart';
import 'package:substation_manager/models/substation.dart';
import 'package:substation_manager/models/task.dart';
import 'package:substation_manager/models/daily_reading.dart';
import 'package:substation_manager/services/core_firestore_service.dart';
import 'package:substation_manager/services/task_service.dart';
import 'package:substation_manager/services/daily_reading_firestore_service.dart';
import 'package:substation_manager/services/auth_service.dart';
import 'package:substation_manager/utils/snackbar_utils.dart';
import 'package:collection/collection.dart'; // For .firstWhereOrNull extension method
import 'dart:async'; // For StreamSubscription

// Removed unnecessary imports from Line Survey Pro:
// import 'package:substation_manager/models/survey_record.dart';
// import 'package:substation_manager/models/transmission_line.dart';
// import 'package:substation_manager/screens/line_detail_screen.dart';
// import 'package:substation_manager/screens/line_patrolling_details_screen.dart';
// import 'package:substation_manager/screens/manager_worker_detail_screen.dart'; // Re-add this import if needed for _navigateToUserDetails

class DashboardTab extends StatefulWidget {
  final UserProfile? currentUserProfile;

  const DashboardTab({super.key, required this.currentUserProfile});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  // Service instances
  final CoreFirestoreService _coreFirestoreService = CoreFirestoreService();
  final TaskService _taskService = TaskService();
  final DailyReadingFirestoreService _dailyReadingService =
      DailyReadingFirestoreService();
  final AuthService _authService = AuthService();

  // Data lists
  List<Substation> _allSubstations = [];
  List<Task> _allTasks = [];
  List<DailyReading> _allDailyReadings = [];
  List<UserProfile> _allUsers = []; // All users in system for Admin/SDO
  List<UserProfile> _juniorStaff = []; // JEs and SSOs for progress summaries
  Map<String, UserProgressSummary> _userProgressSummaries = {};

  bool _isLoading = true;

  // Stream Subscriptions
  StreamSubscription? _substationsSubscription;
  StreamSubscription? _tasksSubscription;
  StreamSubscription? _dailyReadingsSubscription;
  StreamSubscription? _usersSubscription;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _substationsSubscription?.cancel();
    _tasksSubscription?.cancel();
    _dailyReadingsSubscription?.cancel();
    _usersSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DashboardTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUserProfile != oldWidget.currentUserProfile) {
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    if (!mounted || widget.currentUserProfile == null) return;
    setState(() {
      _isLoading = true;
    });

    try {
      _substationsSubscription?.cancel();
      _substationsSubscription = _coreFirestoreService
          .getSubstationsStream()
          .listen((substations) {
            if (mounted) {
              _allSubstations = substations;
              _updateDashboardContent();
            }
          });

      _tasksSubscription?.cancel();
      _tasksSubscription = _taskService.streamAllTasks().listen((tasks) {
        if (mounted) {
          _allTasks = tasks;
          _updateDashboardContent();
        }
      });

      _dailyReadingsSubscription?.cancel();
      _dailyReadingsSubscription = _dailyReadingService
          .streamAllDailyReadings()
          .listen((readings) {
            if (mounted) {
              _allDailyReadings = readings;
              _updateDashboardContent();
            }
          });

      _usersSubscription?.cancel();
      _usersSubscription = _authService.streamAllUserProfiles().listen((users) {
        if (mounted) {
          _allUsers = users;
          _juniorStaff = users
              .where((u) => u.role == 'JE' || u.role == 'SSO')
              .toList();
          _updateDashboardContent();
        }
      });
    } catch (e) {
      print('Error loading dashboard data streams: $e');
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Error loading dashboard data: ${e.toString()}',
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

  void _updateDashboardContent() {
    if (!mounted || widget.currentUserProfile == null) return;

    final UserProfile currentUser = widget.currentUserProfile!;

    // Filter data based on current user's role and assignments
    List<Substation> displayedSubstations = [];
    List<Task> displayedTasks = []; // These are the assignment templates
    List<DailyReading> relevantDailyReadings =
        []; // Readings relevant to the current view

    // Filter substations, tasks, and daily readings based on user's role and access
    if (currentUser.role == 'Admin') {
      displayedSubstations = List.from(_allSubstations);
      displayedTasks = List.from(_allTasks);
      relevantDailyReadings = List.from(_allDailyReadings);
    } else if (currentUser.role == 'SDO') {
      final Set<String> assignedAreaIds = currentUser.assignedAreaIds.toSet();
      displayedSubstations = _allSubstations
          .where((s) => assignedAreaIds.contains(s.areaId))
          .toList();
      final Set<String> sdoSubstationIds = displayedSubstations
          .map((s) => s.id)
          .toSet();
      displayedTasks = _allTasks
          .where((t) => sdoSubstationIds.contains(t.substationId))
          .toList();
      relevantDailyReadings = _allDailyReadings
          .where((dr) => sdoSubstationIds.contains(dr.substationId))
          .toList();
    } else if (currentUser.role == 'JE') {
      final Set<String> assignedSubstationIds = currentUser
          .assignedSubstationIds
          .toSet();
      displayedSubstations = _allSubstations
          .where((s) => assignedSubstationIds.contains(s.id))
          .toList();
      final Set<String> jeSubstationIds = displayedSubstations
          .map((s) => s.id)
          .toSet();
      displayedTasks = _allTasks
          .where((t) => jeSubstationIds.contains(t.substationId))
          .toList();
      relevantDailyReadings = _allDailyReadings
          .where((dr) => jeSubstationIds.contains(dr.substationId))
          .toList();
    } else if (currentUser.role == 'SSO') {
      final String? ssoAssignedSubstationId =
          currentUser.assignedSubstationIds.isNotEmpty
          ? currentUser.assignedSubstationIds.first
          : null;
      if (ssoAssignedSubstationId != null) {
        displayedSubstations = _allSubstations
            .where((s) => s.id == ssoAssignedSubstationId)
            .toList();
        displayedTasks = _allTasks
            .where(
              (t) =>
                  t.substationId == ssoAssignedSubstationId &&
                  t.assignedToUserId == currentUser.id,
            )
            .toList();
        relevantDailyReadings = _allDailyReadings
            .where(
              (dr) =>
                  dr.recordedByUserId == currentUser.id &&
                  dr.substationId == ssoAssignedSubstationId,
            )
            .toList();
      }
    }

    // Calculate progress for tasks (assignment templates)
    final now = DateTime.now();
    final List<Task> tasksWithProgress = displayedTasks.map((task) {
      int completedCount = 0;
      for (String eqId in task.targetEquipmentIds) {
        final readingsForEqToday = relevantDailyReadings.firstWhereOrNull(
          (dr) =>
              dr.equipmentId == eqId &&
              dr.readingForDate.year == now.year &&
              dr.readingForDate.month == now.month &&
              dr.readingForDate.day == now.day,
        );
        if (readingsForEqToday != null) {
          completedCount++;
        }
      }
      int expectedCount = task
          .targetEquipmentIds
          .length; // Number of equipment assigned for daily reading

      return task.copyWith(
        completedCount: completedCount,
        expectedCount: expectedCount,
      );
    }).toList();

    // Calculate progress summaries for JEs/SSOs (for Admin/SDO views)
    final Map<String, UserProgressSummary> summaries = {};
    if (currentUser.role == 'Admin' || currentUser.role == 'SDO') {
      _juniorStaff.forEach((user) {
        int assignedSubstations = _allSubstations
            .where((s) => user.assignedSubstationIds.contains(s.id))
            .length;
        int completedSubstations = 0;
        int workingPendingSubstations = 0;

        Set<String> completedSubsToday = {};
        Set<String> workingSubsToday = {};

        // Loop through tasks assigned to this JE/SSO
        _allTasks.where((task) => task.assignedToUserId == user.id).forEach((
          task,
        ) {
          final Task currentDayTaskStatus =
              tasksWithProgress.firstWhereOrNull((t) => t.id == task.id) ??
              task; // Get updated task progress
          if (currentDayTaskStatus.derivedStatus == 'Completed') {
            completedSubsToday.add(task.substationId);
          } else if (currentDayTaskStatus.derivedStatus == 'In Progress' ||
              currentDayTaskStatus.derivedStatus == 'Pending') {
            workingSubsToday.add(task.substationId);
          }
        });
        completedSubstations = completedSubsToday.length;
        workingPendingSubstations = workingSubsToday.length;

        summaries[user.id] = UserProgressSummary(
          user: user,
          substationsAssigned: assignedSubstations,
          substationsCompleted: completedSubstations,
          substationsWorkingPending: workingPendingSubstations,
        );
      });
    }

    setState(() {
      // _allSubstations is already filtered by the `if/else if` blocks above
      _allTasks =
          tasksWithProgress; // This is the list for display with calculated progress
      _userProgressSummaries = summaries;
    });
  }

  // Helper method to build a stat row for summary cards
  Widget _buildStatRow(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  // Navigation methods (Placeholders - you will create these screens)
  void _navigateToUserDetails(UserProfile userProfile) {
    // Example: Navigate to a detailed screen for the user
    // Navigator.push(context, MaterialPageRoute(builder: (context) => UserDetailScreen(userProfile: userProfile)));
    SnackBarUtils.showSnackBar(context, 'User details screen coming soon!');
  }

  void _navigateToSubstationDetail(Substation substation) {
    // Example: Navigate to a detailed screen for the substation
    // Navigator.push(context, MaterialPageRoute(builder: (context) => SubstationDetailScreen(substation: substation)));
    SnackBarUtils.showSnackBar(
      context,
      'Substation detail screen coming soon!',
    );
  }

  void _navigateToDailyReadingEntryForTask(Task task) {
    // This will navigate to the screen where SSO enters readings
    // Navigator.push(context, MaterialPageRoute(builder: (context) => DailyReadingEntryScreen(task: task)));
    SnackBarUtils.showSnackBar(
      context,
      'Daily Reading Entry screen coming soon!',
    );
  }

  // Dummy getters for Dashboard Summary (Admin role)
  int get _totalSDOsCount => _allUsers
      .where((user) => user.role == 'SDO' && user.status == 'approved')
      .length;
  int get _totalJEsCount => _allUsers
      .where((user) => user.role == 'JE' && user.status == 'approved')
      .length;
  int get _totalSSOsCount => _allUsers
      .where((user) => user.role == 'SSO' && user.status == 'approved')
      .length;
  int get _totalManagersCount => _allUsers
      .where((user) => user.role == 'Manager' && user.status == 'approved')
      .length; // If Manager is a role

  List<UserProfile> get _latestPendingRequests =>
      _allUsers.where((user) => user.status == 'pending').toList()
        ..sort((a, b) => (b.email).compareTo(a.email));

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final UserProfile? currentUser = widget.currentUserProfile;

    if (currentUser == null ||
        currentUser.status != 'approved' ||
        !['Admin', 'SDO', 'JE', 'SSO', 'Manager'].contains(currentUser.role)) {
      // Include Manager in check
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 80, color: colorScheme.error),
              const SizedBox(height: 20),
              Text(
                'Access Denied',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                'Your account is not approved or your role is not recognized. Please contact your administrator.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Overall progress calculation for the whole app, based on all daily readings (simplified)
    int totalCompletedReadings =
        _allDailyReadings.length; // Count of all readings submitted
    int totalExpectedReadings = _allTasks
        .map((task) => task.expectedCount)
        .fold(
          0,
          (sum, count) => sum + count,
        ); // Sum expected counts from all tasks

    double overallProgressPercentage = totalExpectedReadings > 0
        ? totalCompletedReadings / totalExpectedReadings
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Substation Operations Overview',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 15),

          // Admin Dashboard Summary
          if (currentUser.role == 'Admin') ...[
            Text(
              'Admin Dashboard Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildStatRow(
                      'Total Substations:',
                      _allSubstations.length.toString(),
                      Icons.factory,
                      colorScheme.primary,
                    ),
                    _buildStatRow(
                      'Total Areas:',
                      _coreFirestoreService.getAreasStream().length.toString(),
                      Icons.location_city,
                      colorScheme.secondary,
                    ),
                    _buildStatRow(
                      'Total SDOs:',
                      _totalSDOsCount.toString(),
                      Icons.person_pin,
                      colorScheme.primary,
                    ),
                    _buildStatRow(
                      'Total JEs:',
                      _totalJEsCount.toString(),
                      Icons.engineering,
                      colorScheme.secondary,
                    ),
                    _buildStatRow(
                      'Total SSOs:',
                      _totalSSOsCount.toString(),
                      Icons.security,
                      colorScheme.secondary,
                    ),
                    _buildStatRow(
                      'Pending Approvals:',
                      _latestPendingRequests.length.toString(),
                      Icons.hourglass_empty,
                      colorScheme.error,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Latest Pending Requests',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            _latestPendingRequests.isEmpty
                ? Text(
                    'No pending requests.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : Column(
                    children: _latestPendingRequests
                        .map(
                          (user) => Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(user.email),
                              subtitle: Text('Status: ${user.status}'),
                            ),
                          ),
                        )
                        .toList(),
                  ),
            const SizedBox(height: 30),
            Text(
              'Role-Based Progress Overview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            _allUsers.isEmpty
                ? const Text('No users to display.')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _allUsers.length,
                    itemBuilder: (context, index) {
                      final user = _allUsers[index];
                      if (user.role == 'Admin')
                        return const SizedBox.shrink(); // Admins don't need progress summary here

                      final summary =
                          _userProgressSummaries[user
                              .id]; // Access the calculated summary

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 0,
                        ),
                        elevation: 4,
                        child: ListTile(
                          title: Text(
                            user.displayName ?? user.email,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Role: ${user.role ?? 'N/A'}'),
                              if (summary != null) ...[
                                Text(
                                  'Substations Assigned: ${summary.substationsAssigned}',
                                ),
                                Text(
                                  'Substations Completed (Overall): ${summary.substationsCompleted}',
                                ),
                                Text(
                                  'Substations Active/Pending: ${summary.substationsWorkingPending}',
                                ),
                              ],
                            ],
                          ),
                          trailing: TextButton(
                            onPressed: () => _navigateToUserDetails(user),
                            child: Text(
                              'View >',
                              style: TextStyle(color: colorScheme.primary),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 30),
          ],

          // Display Assigned Substations & Daily Operations Status
          Text(
            currentUser.role == 'SSO'
                ? 'Your Daily Reading Assignments:'
                : currentUser.role == 'JE'
                ? 'Your Assigned Substations & Tasks:'
                : currentUser.role == 'SDO'
                ? 'Substations in Your Areas:'
                : 'All Substations Overview:',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          _allSubstations.isEmpty && _allTasks.isEmpty
              ? Center(child: Text('No data available for your role.'))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _allTasks.length, // Primarily show tasks
                  itemBuilder: (context, index) {
                    final task = _allTasks[index];
                    String equipmentNames = task.targetEquipmentIds.isEmpty
                        ? 'No equipment assigned'
                        : task.targetEquipmentIds.join(
                            ', ',
                          ); // Simplified, ideally look up names

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
                        title: Text('Substation: ${task.substationName}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assigned Equipment Count: ${task.targetEquipmentIds.length}',
                            ),
                            Text(
                              'Due: ${task.dueDate.toLocal().toString().split(' ')[0]}',
                            ),
                            Text('Status: ${task.derivedStatus}'),
                            if (currentUser.role == 'Admin' ||
                                currentUser.role == 'SDO' ||
                                currentUser.role == 'JE')
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
                                  'Expected Readings (Today): ${task.expectedCount}',
                                ),
                                Text(
                                  'Completed Readings (Today): ${task.completedCount}',
                                ),
                                if (currentUser.role == 'SSO')
                                  ElevatedButton(
                                    onPressed: () {
                                      _navigateToDailyReadingEntryForTask(task);
                                    },
                                    child: const Text(
                                      'Enter Readings for Today',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          const SizedBox(height: 30),

          // Overall Daily Operations Progress
          Text(
            'Overall Daily Operations Progress',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 15),
          Card(
            margin: EdgeInsets.zero,
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double indicatorSize = constraints.maxWidth * 0.45;
                      if (indicatorSize > 120) indicatorSize = 120;
                      if (indicatorSize < 80) indicatorSize = 80;

                      return SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: indicatorSize,
                                  height: indicatorSize,
                                  child: CircularProgressIndicator(
                                    value: overallProgressPercentage,
                                    strokeWidth: indicatorSize / 10,
                                    backgroundColor: colorScheme.primary
                                        .withOpacity(0.2),
                                    color: colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  '${(overallProgressPercentage * 100).toStringAsFixed(1)}%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: colorScheme.primary,
                                        fontSize: indicatorSize * 0.25,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$totalCompletedReadings / $totalExpectedReadings Readings',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.7,
                                    ),
                                    fontSize: 16,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class for UserProgressSummary
class UserProgressSummary {
  final UserProfile user;
  final int substationsAssigned;
  final int substationsCompleted;
  final int substationsWorkingPending;

  UserProgressSummary({
    required this.user,
    required this.substationsAssigned,
    required this.substationsCompleted,
    required this.substationsWorkingPending,
  });
}
