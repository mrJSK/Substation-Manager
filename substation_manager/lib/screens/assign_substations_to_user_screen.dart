// lib/screens/assign_substations_to_user_screen.dart
// Placeholder for Assign Substations to JE/SSO Screen

import 'package:flutter/material.dart';
import 'package:substation_manager/models/user_profile.dart';
import 'package:substation_manager/models/substation.dart';
import 'package:substation_manager/services/auth_service.dart';
import 'package:substation_manager/services/core_firestore_service.dart';
import 'package:substation_manager/utils/snackbar_utils.dart';
import 'dart:async';

class AssignSubstationsToUserScreen extends StatefulWidget {
  final UserProfile userProfile; // Can be JE or SSO

  const AssignSubstationsToUserScreen({super.key, required this.userProfile});

  @override
  State<AssignSubstationsToUserScreen> createState() =>
      _AssignSubstationsToUserScreenState();
}

class _AssignSubstationsToUserScreenState
    extends State<AssignSubstationsToUserScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Substation> _allSubstations = [];
  List<Substation> _filteredSubstations = [];
  bool _isLoading = true;
  Set<String> _selectedSubstationIds = {};

  final CoreFirestoreService _coreFirestoreService = CoreFirestoreService();
  final AuthService _authService = AuthService();
  StreamSubscription? _substationsSubscription;

  @override
  void initState() {
    super.initState();
    _selectedSubstationIds = Set.from(widget.userProfile.assignedSubstationIds);
    _searchController.addListener(_onSearchChanged);
    _loadSubstations();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _substationsSubscription?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterSubstations();
    });
  }

  Future<void> _loadSubstations() async {
    setState(() {
      _isLoading = true;
    });
    _substationsSubscription?.cancel();

    _substationsSubscription = _coreFirestoreService
        .getSubstationsStream()
        .listen(
          (substations) {
            if (mounted) {
              setState(() {
                _allSubstations = substations;
                _filterSubstations();
                _isLoading = false;
              });
            }
          },
          onError: (e) {
            if (mounted) {
              SnackBarUtils.showSnackBar(
                context,
                'Error loading substations: ${e.toString()}',
                isError: true,
              );
              setState(() {
                _isLoading = false;
              });
            }
            print('Error loading substations for assignment: $e');
          },
        );
  }

  void _filterSubstations() {
    _filteredSubstations = _allSubstations.where((substation) {
      final String lowerCaseQuery = _searchQuery.toLowerCase();
      return substation.name.toLowerCase().contains(lowerCaseQuery) ||
          substation.voltageLevels.any(
            (level) => level.toLowerCase().contains(lowerCaseQuery),
          ) ||
          (substation.address?.toLowerCase().contains(lowerCaseQuery) ?? false);
    }).toList();

    _filteredSubstations.sort((a, b) => a.name.compareTo(b.name));
  }

  void _toggleSubstationSelection(String substationId, bool? isSelected) {
    setState(() {
      if (isSelected == true) {
        _selectedSubstationIds.add(substationId);
      } else {
        _selectedSubstationIds.remove(substationId);
      }
    });
  }

  Future<void> _saveAssignments() async {
    List<String> substationsToAdd = _selectedSubstationIds
        .difference(Set.from(widget.userProfile.assignedSubstationIds))
        .toList();
    List<String> substationsToRemove = Set.from(
      widget.userProfile.assignedSubstationIds,
    ).difference(_selectedSubstationIds).toList().cast<String>();

    if (substationsToAdd.isEmpty && substationsToRemove.isEmpty) {
      if (mounted)
        SnackBarUtils.showSnackBar(
          context,
          'No changes to save.',
          isError: false,
        );
      Navigator.of(context).pop();
      return;
    }

    try {
      if (substationsToAdd.isNotEmpty) {
        await _authService.assignSubstationsToUser(
          widget.userProfile.id,
          substationsToAdd,
        );
      }
      if (substationsToRemove.isNotEmpty) {
        await _authService.unassignSubstationsFromUser(
          widget.userProfile.id,
          substationsToRemove,
        );
      }
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Substations assigned to ${widget.userProfile.displayName ?? widget.userProfile.email} successfully!',
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Failed to update assigned substations: ${e.toString()}',
          isError: true,
        );
      }
      print('Error saving substation assignments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Assign Substations to ${widget.userProfile.displayName ?? widget.userProfile.email}',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Substations',
                hintText: 'e.g., Firozabad, 400kV',
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
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
                : _filteredSubstations.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No substations available to assign.'
                          : 'No substations found matching your search.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredSubstations.length,
                    itemBuilder: (context, index) {
                      final substation = _filteredSubstations[index];
                      final bool isSelected = _selectedSubstationIds.contains(
                        substation.id,
                      );
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        elevation: 2,
                        child: CheckboxListTile(
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            substation.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            '${substation.voltageLevels.join(', ')} | Area: ${substation.areaId}',
                          ), // You might want to fetch Area name here
                          value: isSelected,
                          onChanged: (bool? newValue) {
                            _toggleSubstationSelection(substation.id, newValue);
                          },
                          activeColor: colorScheme.secondary,
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      side: BorderSide(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveAssignments,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
