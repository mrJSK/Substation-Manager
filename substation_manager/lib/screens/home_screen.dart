// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:substation_manager/models/user_profile.dart'; // Ensure UserProfile model is available
import 'package:substation_manager/models/area.dart'; // Ensure Area model is available
import 'package:substation_manager/models/substation.dart'; // Ensure Substation model is available
import 'package:substation_manager/services/auth_service.dart'; // Ensure AuthService is available
import 'package:substation_manager/services/core_firestore_service.dart'; // Ensure CoreFirestoreService is available
import 'package:substation_manager/utils/snackbar_utils.dart'; // Ensure SnackBarUtils is available
import 'package:substation_manager/screens/sign_in_screen.dart'; // Ensure SignInScreen is available
import 'package:substation_manager/screens/admin_user_management_screen.dart'; // Ensure AdminUserManagementScreen is available
import 'package:substation_manager/screens/substation_management_screen.dart'; // Ensure SubstationManagementScreen is available
import 'package:substation_manager/screens/area_management_screen.dart'; // Ensure AreaManagementScreen is available
import 'package:substation_manager/screens/assign_areas_to_sdo_screen.dart'; // Corrected import
import 'package:substation_manager/screens/assign_substations_to_user_screen.dart'; // Corrected import
import 'package:substation_manager/screens/master_equipment_management_screen.dart'; // Ensure MasterEquipmentManagementScreen is available
import 'package:substation_manager/screens/realtime_tasks_screen.dart'; // Ensure RealtimeTasksScreen is available
import 'package:substation_manager/screens/dashboard_tab.dart'; // Ensure DashboardTab is available
import 'package:substation_manager/screens/info_screen.dart'; // Ensure InfoScreen is available
import 'package:substation_manager/screens/export_screen.dart'; // Ensure ExportScreen is available
import 'package:substation_manager/screens/waiting_for_approval_screen.dart'; // Ensure WaitingForApprovalScreen is available
import 'package:substation_manager/screens/sld_selection_screen.dart'; // Ensure SldSelectionScreen is available

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final CoreFirestoreService _coreFirestoreService = CoreFirestoreService();
  UserProfile? _currentUserProfile;
  List<Area> _assignedAreas = [];
  List<Substation> _assignedSubstations = [];
  bool _isProfileLoading = true;
  int _selectedIndex = 0; // For BottomNavigationBar

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    // You might want to cancel subscriptions if they are managed here and not in the service itself
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Listen to UserProfile stream from Firestore
      _coreFirestoreService.getUserProfileStream(user.uid).listen((profile) {
        if (mounted) {
          setState(() {
            _currentUserProfile = profile;
            _isProfileLoading = false; // Set loading to false regardless
            if (_currentUserProfile != null) {
              // Load assigned areas/substations based on the fetched profile
              _loadAssignedData(_currentUserProfile!);
            } else {
              // If profile is null (not found), navigate to sign in.
              // This handles the case where getUserProfileStream returns null.
              _navigateToSignIn();
            }
          });
        }
      });
    } else {
      if (mounted) {
        setState(() {
          _isProfileLoading = false;
          // If no user, navigate to sign in
          _navigateToSignIn();
        });
      }
    }
  }

  // Separate function to navigate to sign-in, to avoid issues during build
  void _navigateToSignIn() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SignInScreen()),
        (Route<dynamic> route) => false,
      );
    });
  }

  Future<void> _loadAssignedData(UserProfile profile) async {
    try {
      if (profile.role == 'Admin') {
        _assignedAreas = await _coreFirestoreService.getAreasOnce();
        _assignedSubstations = await _coreFirestoreService.getSubstationsOnce();
      } else if (profile.role == 'SDO') {
        // Use profile.uid for getting assigned areas
        _assignedAreas = await _coreFirestoreService.getAssignedAreasForSdo(
          profile.uid,
        );
        _assignedSubstations = await _coreFirestoreService
            .getSubstationsByAreaIds(_assignedAreas.map((e) => e.id).toList());
      } else if (profile.role == 'JE' || profile.role == 'SSO') {
        // SSO also needs assigned substations for their tasks
        // Use profile.uid for getting assigned substations
        _assignedSubstations = await _coreFirestoreService
            .getAssignedSubstationsForJe(profile.uid);
        // Determine areas based on assigned substations, if needed for display
        final Set<String> areaIds = _assignedSubstations
            .map((s) => s.areaId)
            .toSet();
        _assignedAreas = (await _coreFirestoreService.getAreasOnce())
            .where((a) => areaIds.contains(a.id))
            .toList();
      }
      setState(() {}); // Update UI after loading assigned data
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Error loading assigned data: ${e.toString()}',
          isError: true,
        );
      }
      print('Error loading assigned data: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SignInScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  // Navigation methods
  void _navigateToUserManagementScreen() {
    Navigator.pop(context); // Close the drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminUserManagementScreen(),
      ),
    );
  }

  void _navigateToAreaManagementScreen() {
    Navigator.pop(context); // Close the drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AreaManagementScreen()),
    );
  }

  void _navigateToSubstationManagementScreen() {
    Navigator.pop(context); // Close the drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SubstationManagementScreen(),
      ),
    );
  }

  void _navigateToAssignAreasToSdoScreen() {
    Navigator.pop(context); // Close the drawer
    // Corrected class name capitalization
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignAreasToSdoScreen(
          sdo: _currentUserProfile!, // Pass the current user profile as 'sdo'
        ),
      ),
    );
  }

  void _navigateToAssignSubstationsToUserScreen() {
    Navigator.pop(context); // Close the drawer
    // Corrected class name capitalization
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AssignSubstationsToUserScreen(userProfile: _currentUserProfile!),
      ),
    );
  }

  void _navigateToMasterEquipmentManagementScreen() {
    Navigator.pop(context); // Close the drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MasterEquipmentManagementScreen(),
      ),
    );
  }

  // New: Navigate to SLD Builder Selection Screen
  void _navigateToSLDBuilderSelectionScreen() {
    Navigator.pop(context); // Close the drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const SldSelectionScreen(), // Navigate to selection screen
      ),
    );
  }

  void _navigateToExportScreen() {
    Navigator.pop(context); // Close the drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ExportScreen(currentUserProfile: _currentUserProfile!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isProfileLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentUserProfile = _currentUserProfile;

    if (currentUserProfile == null) {
      // If profile is null after loading, it means the user's Firestore profile
      // does not exist or could not be fetched.
      // This path will now be taken if CoreFirestoreService.getUserProfileStream returns null.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToSignIn(); // Force sign out and go to sign in screen
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Check if status is explicitly 'rejected' or 'pending' and redirect
    if (currentUserProfile.status == 'rejected' ||
        currentUserProfile.status == 'pending') {
      // Ensure navigation happens once after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) =>
                WaitingForApprovalScreen(userProfile: currentUserProfile),
          ),
          (Route<dynamic> route) => false,
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Determine the content for the body based on the selected index
    Widget buildBodyContent() {
      switch (_selectedIndex) {
        case 0:
          // Dashboard tab now takes currentUserProfile directly
          return DashboardTab(
            currentUserProfile: currentUserProfile, // Pass the actual profile
          );
        case 1:
          // RealTimeTasksScreen now takes currentUserProfile directly
          return RealTimeTasksScreen(
            currentUserProfile: currentUserProfile, // Pass the actual profile
          );
        case 2:
          return const InfoScreen(); // Info screen
        default:
          return const Center(child: Text('Unknown Screen'));
      }
    }

    // Determine AppBar title based on selected index
    String appBarTitle = 'Dashboard';
    switch (_selectedIndex) {
      case 0:
        appBarTitle = 'Dashboard';
        break;
      case 1:
        appBarTitle = 'Daily Operations'; // Changed label from 'Realtime Tasks'
        break;
      case 2:
        appBarTitle = 'Info & Help';
        break;
    }

    // Main Scaffold for approved users
    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle), centerTitle: true),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentUserProfile.displayName ??
                        currentUserProfile
                            .email, // Use displayName, fallback to email
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  Text(
                    currentUserProfile.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  Text(
                    'Role: ${currentUserProfile.role ?? 'N/A'}', // Display 'N/A' if role is null
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.dashboard,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Dashboard'),
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: Icon(
                Icons.task,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text(
                'Daily Operations',
              ), // Changed label to 'Daily Operations'
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: Icon(
                Icons.info,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Info & Help'),
              onTap: () {
                _onItemTapped(2);
                Navigator.pop(context); // Close the drawer
              },
            ),
            const Divider(), // Divider for separation
            // Admin-specific menu items
            if (currentUserProfile.role == 'Admin') ...[
              ListTile(
                leading: Icon(
                  Icons.people,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('User Management'),
                onTap: _navigateToUserManagementScreen,
              ),
              ListTile(
                leading: Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Area Management'),
                onTap: _navigateToAreaManagementScreen,
              ),
              ListTile(
                leading: Icon(
                  Icons.electrical_services,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Substation Management'),
                onTap: _navigateToSubstationManagementScreen,
              ),
              ListTile(
                leading: Icon(
                  Icons.assignment_ind,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Assign Areas to SDO'),
                onTap: _navigateToAssignAreasToSdoScreen,
              ),
              ListTile(
                leading: Icon(
                  Icons.assignment,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Assign Substations to JE'),
                onTap: _navigateToAssignSubstationsToUserScreen,
              ),
              ListTile(
                leading: Icon(
                  Icons.construction,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Master Equipment Management'),
                onTap: _navigateToMasterEquipmentManagementScreen,
              ),
              ListTile(
                leading: Icon(
                  Icons.schema,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('SLD Builder (Dev)'),
                onTap: () =>
                    _navigateToSLDBuilderSelectionScreen(), // Navigates to selection screen
              ),
              ListTile(
                leading: Icon(
                  Icons.download,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Export Data'),
                onTap: _navigateToExportScreen,
              ),
            ],
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Sign Out'),
              onTap: _signOut,
            ),
          ],
        ),
      ),
      body: buildBodyContent(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: 'Operations', // Changed label
          ),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Info'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
      ),
    );
  }
}
