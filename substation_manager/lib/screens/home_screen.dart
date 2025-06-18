// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:substation_manager/screens/sign_in_screen.dart';
import 'package:substation_manager/screens/dashboard_tab.dart';
import 'package:substation_manager/screens/export_screen.dart';
import 'package:substation_manager/screens/realtime_tasks_screen.dart'; // This will eventually be for "Daily Operations"
import 'package:substation_manager/utils/snackbar_utils.dart';
import 'package:substation_manager/screens/info_screen.dart';
import 'package:substation_manager/services/auth_service.dart';
import 'package:substation_manager/models/user_profile.dart';
import 'package:substation_manager/screens/admin_user_management_screen.dart';
import 'package:substation_manager/screens/waiting_for_approval_screen.dart';

// NEW IMPORTS FOR SUBSTATION APP MANAGEMENT SCREENS (Ensure these files exist!)
import 'package:substation_manager/screens/area_management_screen.dart';
import 'package:substation_manager/screens/substation_management_screen.dart';
import 'package:substation_manager/screens/master_equipment_management_screen.dart';
import 'package:substation_manager/screens/substation_sld_builder_screen.dart'; // This is the SLD builder screen
import 'package:substation_manager/services/core_firestore_service.dart'; // Service to fetch substations
import 'package:substation_manager/models/substation.dart'; // Substation model
import 'package:collection/collection.dart'; // For .firstWhereOrNull extension method

final GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final AuthService _authService = AuthService();
  final CoreFirestoreService _coreFirestoreService = CoreFirestoreService();

  @override
  void initState() {
    super.initState();
  }

  void changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Error signing out: ${e.toString()}',
          isError: true,
        );
      }
      print('Error signing out: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToInfoScreen() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InfoScreen()),
    );
  }

  void _navigateToAreaManagementScreen() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AreaManagementScreen()),
    );
  }

  void _navigateToSubstationManagementScreen() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SubstationManagementScreen(),
      ),
    );
  }

  void _navigateToMasterEquipmentManagementScreen() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MasterEquipmentManagementScreen(),
      ),
    );
  }

  void _navigateToAdminUserManagementScreen() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminUserManagementScreen(),
      ),
    );
  }

  // NEW: Navigate to SLD Builder Screen
  Future<void> _navigateToSLDBuilderScreen(
    UserProfile currentUserProfile,
  ) async {
    Navigator.pop(context); // Close the drawer
    if (!mounted) return;

    List<Substation> substations = [];
    try {
      // Fetch all substations based on the user's role and assigned areas/substations
      if (currentUserProfile.role == 'Admin') {
        substations = await _coreFirestoreService.getSubstationsOnce();
      } else if (currentUserProfile.role == 'SDO') {
        final allSubstations = await _coreFirestoreService.getSubstationsOnce();
        substations = allSubstations
            .where((s) => currentUserProfile.assignedAreaIds.contains(s.areaId))
            .toList();
      } else if (currentUserProfile.role == 'JE' ||
          currentUserProfile.role == 'SSO') {
        final allSubstations = await _coreFirestoreService.getSubstationsOnce();
        substations = allSubstations
            .where(
              (s) => currentUserProfile.assignedSubstationIds.contains(s.id),
            )
            .toList();
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Error fetching substations: $e',
          isError: true,
        );
      }
      print('Error fetching substations for SLD Builder: $e');
      return;
    }

    if (substations.isNotEmpty && mounted) {
      // For demo purposes, we'll just open the SLD builder for the first available substation.
      // In a real app, you'd have a list of substations and let the user choose one to view its SLD.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SubstationSLDBuilderScreen(substation: substations.first),
        ),
      );
    } else {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'No substations found or assigned to you to build/view SLD. Please add a substation first.',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle;
    switch (_selectedIndex) {
      case 0:
        appBarTitle = 'Substation Dashboard';
        break;
      case 1:
        appBarTitle = 'Export Records';
        break;
      case 2:
        appBarTitle = 'Daily Operations';
        break;
      default:
        appBarTitle = 'Substation Manager';
    }

    return StreamBuilder<UserProfile?>(
      stream: _authService.userProfileStream,
      builder: (context, snapshot) {
        final UserProfile? currentUserProfile = snapshot.data;
        final bool isLoadingProfile =
            snapshot.connectionState == ConnectionState.waiting;

        // Define the list of tab widgets. Ensure all these screen files exist.
        final List<Widget> _widgetOptions = <Widget>[
          DashboardTab(currentUserProfile: currentUserProfile),
          ExportScreen(currentUserProfile: currentUserProfile),
          RealTimeTasksScreen(
            currentUserProfile: currentUserProfile,
          ), // This is the "Operations" tab
        ];

        // Handle loading and unapproved user states
        if (isLoadingProfile) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (currentUserProfile == null ||
            currentUserProfile.status != 'approved') {
          // If profile is null or not approved, redirect to approval/sign-in screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (currentUserProfile == null) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const SignInScreen()),
                (Route<dynamic> route) => false,
              );
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) =>
                      WaitingForApprovalScreen(userProfile: currentUserProfile),
                ),
                (Route<dynamic> route) => false,
              );
            }
          });
          return const Scaffold(
            // Show loading indicator while navigating
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Main Scaffold for approved users
        return Scaffold(
          appBar: AppBar(title: Text(appBarTitle), centerTitle: true),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                // Drawer Header (User info)
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Substation Manager',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentUserProfile.email,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                      if (currentUserProfile.role != null)
                        Text(
                          'Role: ${currentUserProfile.role}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                    ],
                  ),
                ),
                // Info Screen Link (available to all roles)
                ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Info'),
                  onTap: _navigateToInfoScreen,
                ),
                // Admin-specific menu items
                if (currentUserProfile.role == 'Admin') ...[
                  ListTile(
                    leading: Icon(
                      Icons.people,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('User Management'),
                    onTap: _navigateToAdminUserManagementScreen,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.location_city,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Manage Areas'),
                    onTap: _navigateToAreaManagementScreen,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.electrical_services,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Manage Substations'),
                    onTap: _navigateToSubstationManagementScreen,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.construction,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Master Equipment'),
                    onTap: _navigateToMasterEquipmentManagementScreen,
                  ),
                  // SLD Builder link (for Admin/Dev access - or any role you grant it to)
                  ListTile(
                    leading: Icon(
                      Icons.schema,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('SLD Builder (Dev)'),
                    onTap: () =>
                        _navigateToSLDBuilderScreen(currentUserProfile),
                  ),
                ],
                // Separator before Logout
                const Divider(),
                // Logout Link
                ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: const Text('Logout'),
                  onTap: () {
                    Navigator.pop(context); // Close drawer before logging out
                    _signOut();
                  },
                ),
              ],
            ),
          ),
          // Main content area, showing the selected tab
          body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
          // Bottom Navigation Bar
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.upload_file),
                label: 'Export',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.view_timeline), // "Operations" tab
                label: 'Operations',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Theme.of(context).hintColor,
            backgroundColor: Theme.of(context).canvasColor,
            type: BottomNavigationBarType
                .fixed, // Ensures labels are always visible
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }
}
