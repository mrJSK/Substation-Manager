// lib/screens/admin_user_management_screen.dart

import 'package:flutter/material.dart';
import 'package:substation_manager/models/user_profile.dart';
import 'package:substation_manager/services/auth_service.dart';
import 'package:substation_manager/utils/snackbar_utils.dart';
import 'package:substation_manager/screens/assign_areas_to_sdo_screen.dart';
import 'package:substation_manager/screens/assign_substations_to_user_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Firestore operations in modal
import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'dart:async';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final AuthService _authService = AuthService();
  List<UserProfile> _allUsers = [];
  List<UserProfile> _filteredUsers = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<String, Set<String>> _selectedFilters = {};

  final Map<String, List<String>> _filterOptions = {
    'role': ['Admin', 'SDO', 'JE', 'SSO', 'None'],
    'status': ['pending', 'approved', 'rejected'],
  };

  StreamSubscription? _usersSubscription;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _usersSubscription?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  void _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _usersSubscription?.cancel();
      _usersSubscription = _authService.streamAllUserProfiles().listen(
        (users) {
          if (mounted) {
            setState(() {
              _allUsers = users;
              _applyFilters();
              _isLoading = false;
            });
          }
        },
        onError: (e) {
          if (mounted) {
            SnackBarUtils.showSnackBar(
              context,
              'Error loading users: ${e.toString()}',
              isError: true,
            );
            setState(() {
              _isLoading = false;
            });
          }
          print('Error streaming all user profiles: $e');
        },
      );
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Error initiating user stream: ${e.toString()}',
          isError: true,
        );
        setState(() {
          _isLoading = false;
        });
      }
      print('Error initiating user stream: $e');
    }
  }

  void _applyFilters() {
    List<UserProfile> tempUsers = List.from(_allUsers);

    if (_searchQuery.isNotEmpty) {
      final String lowerCaseQuery = _searchQuery.toLowerCase();
      tempUsers = tempUsers.where((user) {
        return (user.displayName?.toLowerCase().contains(lowerCaseQuery) ??
                false) ||
            user.email.toLowerCase().contains(lowerCaseQuery) ||
            (user.role?.toLowerCase().contains(lowerCaseQuery) ?? false) ||
            user.status.toLowerCase().contains(lowerCaseQuery);
      }).toList();
    }

    _selectedFilters.forEach((fieldName, selectedOptions) {
      if (selectedOptions.isNotEmpty) {
        tempUsers = tempUsers.where((user) {
          String? fieldValue;
          if (fieldName == 'role') {
            fieldValue = user.role;
          } else if (fieldName == 'status') {
            fieldValue = user.status;
          }
          if (selectedOptions.contains('None') && fieldName == 'role') {
            return fieldValue == null || selectedOptions.contains(fieldValue);
          }
          return fieldValue != null && selectedOptions.contains(fieldValue);
        }).toList();
      }
    });

    setState(() {
      _filteredUsers = tempUsers;
    });
  }

  void _toggleFilterOption(String fieldName, String option) {
    setState(() {
      _selectedFilters.putIfAbsent(fieldName, () => {});
      if (_selectedFilters[fieldName]!.contains(option)) {
        _selectedFilters[fieldName]!.remove(option);
      } else {
        _selectedFilters[fieldName]!.add(option);
      }
      _applyFilters();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedFilters.clear();
      _searchController.clear();
      _searchQuery = '';
      _applyFilters();
    });
  }

  String _toHumanReadable(String camelCase) {
    return camelCase
        .replaceAllMapped(
          RegExp(r'(^[a-z])|[A-Z]'),
          (m) => m[1] == null ? ' ${m[0] ?? ''}' : (m[0]?.toUpperCase() ?? ''),
        )
        .trim();
  }

  Widget _buildFilterPanel() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Filter Users',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Expanded(
              child: ListView(
                children: _filterOptions.entries.map((entry) {
                  final fieldName = entry.key;
                  final options = entry.value;
                  return ExpansionTile(
                    title: Text(_toHumanReadable(fieldName)),
                    children: options.map((option) {
                      final bool isSelected =
                          _selectedFilters[fieldName]?.contains(option) ??
                          false;
                      return CheckboxListTile(
                        title: Text(option),
                        value: isSelected,
                        onChanged: (bool? value) {
                          _toggleFilterOption(fieldName, option);
                        },
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _clearFilters,
                child: const Text('Clear Filters & Search'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateUserRole(String userId, String? newRole) async {
    try {
      await _authService.updateUserRole(userId, newRole);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _updateUserStatus(String userId, String newStatus) async {
    try {
      if (newStatus == 'rejected') {
        final bool? confirmDelete = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Confirm Rejection and Deletion'),
              content: Text(
                // Use user.uid instead of user.id
                'Are you sure you want to REJECT and DELETE this user\'s profile (${_allUsers.firstWhere((u) => u.uid == userId).email})? This action is irreversible.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );

        if (confirmDelete == true) {
          await _authService.deleteUserProfile(userId);
          if (mounted) {
            SnackBarUtils.showSnackBar(
              context,
              'User profile rejected and deleted successfully!',
            );
          }
        } else {
          if (mounted) {
            SnackBarUtils.showSnackBar(
              context,
              'Rejection/deletion cancelled.',
              isError: false,
            );
          }
          throw Exception('Rejection/deletion cancelled.');
        }
      } else {
        await _authService.updateUserStatus(userId, newStatus);
        if (mounted) {
          SnackBarUtils.showSnackBar(
            context,
            'User status updated to $newStatus.',
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _showManageUserModal(UserProfile user) async {
    // We get a fresh copy of the user to ensure modal reflects latest data
    // Use user.uid for comparison and fetching
    UserProfile? latestUser = await _authService.getCurrentUserProfile();
    if (latestUser?.uid != user.uid) {
      // Use uid for comparison
      final allUsers = await _authService.getAllUserProfiles();
      latestUser = allUsers.firstWhereOrNull(
        (u) => u.uid == user.uid,
      ); // Use uid for lookup
    }

    if (latestUser == null) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'User not found or deleted.',
          isError: true,
        );
      }
      return;
    }

    String? selectedRole = latestUser.role;
    String selectedStatus = latestUser.status;
    String? currentMobile = latestUser.mobile; // Capture current mobile

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage User',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text('Email: ${latestUser!.email}'),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: currentMobile,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    onChanged: (value) {
                      setModalState(() {
                        currentMobile = value.isEmpty ? null : value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ...['Admin', 'SDO', 'JE', 'SSO'].map(
                        (role) =>
                            DropdownMenuItem(value: role, child: Text(role)),
                      ),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        selectedRole = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: ['pending', 'approved', 'rejected']
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() {
                          selectedStatus = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(modalContext).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            // Update mobile number if it changed
                            if (currentMobile != user.mobile) {
                              // Here 'user' refers to the original UserProfile passed to modal
                              await FirebaseFirestore.instance
                                  .collection('userProfiles')
                                  .doc(latestUser!.uid) // Use uid here
                                  .update({'mobile': currentMobile});
                              await _authService.getCurrentUserProfile(
                                forceFetch: true,
                              ); // Force refresh cache
                            }

                            if (selectedRole != user.role) {
                              // Here 'user' refers to the original UserProfile passed to modal
                              await _updateUserRole(
                                latestUser!.uid, // Use uid here
                                selectedRole,
                              );
                            }
                            if (selectedStatus != user.status) {
                              // Here 'user' refers to the original UserProfile passed to modal
                              await _updateUserStatus(
                                latestUser!.uid, // Use uid here
                                selectedStatus,
                              );
                            }
                            if (mounted) {
                              Navigator.of(modalContext).pop();
                            }
                          } catch (e) {
                            if (mounted) {
                              SnackBarUtils.showSnackBar(
                                context,
                                'Failed to update user: ${e.toString()}',
                                isError: true,
                              );
                            }
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _assignAreasToSdo(UserProfile user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AssignAreasToSdoScreen(sdo: user),
      ),
    );
  }

  void _assignSubstationsToUser(UserProfile user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AssignSubstationsToUserScreen(userProfile: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
      endDrawer: _buildFilterPanel(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Users',
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty && _selectedFilters.isEmpty
                          ? 'No user profiles found in the system.'
                          : 'No users found matching current filters/search.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName ?? user.email,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                'Mobile: ${user.mobile ?? 'N/A'}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'Role: ',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Expanded(
                                    child: Text(
                                      user.role?.toUpperCase() ?? 'NONE',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Status: ',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Expanded(
                                    child: Text(
                                      user.status.toUpperCase(),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.circle,
                                    size: 12,
                                    color: _getStatusColor(user.status),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 4.0,
                                alignment: WrapAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _showManageUserModal(user),
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Manage'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary
                                          .withOpacity(0.8),
                                      foregroundColor: colorScheme.onPrimary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      textStyle: Theme.of(
                                        context,
                                      ).textTheme.labelSmall,
                                    ),
                                  ),
                                  if (user.role == 'SDO' &&
                                      user.status == 'approved')
                                    ElevatedButton.icon(
                                      onPressed: () => _assignAreasToSdo(user),
                                      icon: const Icon(Icons.map),
                                      label: const Text('Assign Areas'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.secondary,
                                        foregroundColor:
                                            colorScheme.onSecondary,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        textStyle: Theme.of(
                                          context,
                                        ).textTheme.labelSmall,
                                      ),
                                    ),
                                  if ((user.role == 'JE' ||
                                          user.role == 'SSO') &&
                                      user.status == 'approved')
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _assignSubstationsToUser(user),
                                      icon: const Icon(Icons.factory),
                                      label: const Text('Assign Substations'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.tertiary,
                                        foregroundColor: colorScheme.onTertiary,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        textStyle: Theme.of(
                                          context,
                                        ).textTheme.labelSmall,
                                      ),
                                    ),
                                  if (user.status == 'approved' &&
                                      user.role != null)
                                    OutlinedButton(
                                      onPressed: () async {
                                        final bool?
                                        confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (BuildContext dialogContext) {
                                            return AlertDialog(
                                              title: const Text(
                                                'Confirm Deletion',
                                              ),
                                              content: Text(
                                                'Are you sure you want to delete the profile for ${user.email}? This action is irreversible.',
                                              ),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    dialogContext,
                                                  ).pop(false),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.of(
                                                    dialogContext,
                                                  ).pop(true),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            colorScheme.error,
                                                      ),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                        if (confirm == true) {
                                          try {
                                            await _authService
                                                .deleteUserProfile(
                                                  user.uid,
                                                ); // Use uid here
                                            if (mounted) {
                                              SnackBarUtils.showSnackBar(
                                                context,
                                                'User profile for ${user.email} deleted.',
                                              );
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              SnackBarUtils.showSnackBar(
                                                context,
                                                'Failed to delete user profile: ${e.toString()}',
                                                isError: true,
                                              );
                                            }
                                          }
                                        }
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(
                                          color: Colors.red,
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Icon(Icons.delete_forever),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
