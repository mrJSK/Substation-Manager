// lib/screens/assign_areas_to_sdo_screen.dart
// Placeholder for Assign Areas to SDO Screen

import 'package:flutter/material.dart';
import 'package:substation_manager/models/user_profile.dart';
import 'package:substation_manager/models/area.dart';
import 'package:substation_manager/services/auth_service.dart';
import 'package:substation_manager/services/core_firestore_service.dart';
import 'package:substation_manager/utils/snackbar_utils.dart';
import 'dart:async';

class AssignAreasToSdoScreen extends StatefulWidget {
  final UserProfile sdo;

  const AssignAreasToSdoScreen({super.key, required this.sdo});

  @override
  State<AssignAreasToSdoScreen> createState() => _AssignAreasToSdoScreenState();
}

class _AssignAreasToSdoScreenState extends State<AssignAreasToSdoScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Area> _allAreas = [];
  List<Area> _filteredAreas = [];
  bool _isLoading = true;
  Set<String> _selectedAreaIds = {};

  final CoreFirestoreService _coreFirestoreService = CoreFirestoreService();
  final AuthService _authService = AuthService();
  StreamSubscription? _areasSubscription;

  @override
  void initState() {
    super.initState();
    // Use sdo.assignedAreaIds directly, which is now List<String>
    _selectedAreaIds = Set.from(widget.sdo.assignedAreaIds);
    _searchController.addListener(_onSearchChanged);
    _loadAreas();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _areasSubscription?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterAreas();
    });
  }

  Future<void> _loadAreas() async {
    setState(() {
      _isLoading = true;
    });
    _areasSubscription?.cancel();

    _areasSubscription = _coreFirestoreService.getAreasStream().listen(
      (areas) {
        if (mounted) {
          setState(() {
            _allAreas = areas;
            _filterAreas();
            _isLoading = false;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
            context,
            'Error loading areas: ${e.toString()}',
            isError: true,
          );
          setState(() {
            _isLoading = false;
          });
        }
        print('Error loading areas for SDO assignment: $e');
      },
    );
  }

  void _filterAreas() {
    _filteredAreas = _allAreas.where((area) {
      final String lowerCaseQuery = _searchQuery.toLowerCase();
      return area.name.toLowerCase().contains(lowerCaseQuery) ||
          area.state.name.toLowerCase().contains(lowerCaseQuery) ||
          area.cities.any(
            (city) => city.name.toLowerCase().contains(lowerCaseQuery),
          );
    }).toList();

    _filteredAreas.sort((a, b) => a.name.compareTo(b.name));
  }

  void _toggleAreaSelection(String areaId, bool? isSelected) {
    setState(() {
      if (isSelected == true) {
        _selectedAreaIds.add(areaId);
      } else {
        _selectedAreaIds.remove(areaId);
      }
    });
  }

  Future<void> _saveAssignments() async {
    // Explicitly convert assignedAreaIds to a Set<String>
    final Set<String> currentAssignedAreaIds = Set<String>.from(
      widget.sdo.assignedAreaIds,
    );

    List<String> areasToAdd = _selectedAreaIds
        .difference(currentAssignedAreaIds) // Use the explicitly typed set
        .toList();
    List<String> areasToRemove =
        currentAssignedAreaIds // Use the explicitly typed set
            .difference(_selectedAreaIds)
            .toList();

    if (areasToAdd.isEmpty && areasToRemove.isEmpty) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'No changes to save.',
          isError: false,
        );
      }
      Navigator.of(context).pop();
      return;
    }

    try {
      if (areasToAdd.isNotEmpty) {
        await _authService.assignAreasToSdo(
          widget.sdo.uid,
          areasToAdd,
        ); // Use uid
      }
      if (areasToRemove.isNotEmpty) {
        await _authService.unassignAreasFromSdo(
          widget.sdo.uid,
          areasToRemove,
        ); // Use uid
      }
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Areas assigned to ${widget.sdo.displayName ?? widget.sdo.email} successfully!',
        );
        Navigator.of(context).pop(true); // Pop back to Admin User Management
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Failed to update assigned areas: ${e.toString()}',
          isError: true,
        );
      }
      print('Error saving area assignments: $e');
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
          'Assign Areas to ${widget.sdo.displayName ?? widget.sdo.email}',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Areas',
                hintText: 'e.g., Firozabad, Uttar Pradesh',
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
                : _filteredAreas.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No areas available to assign.'
                          : 'No areas found matching your search.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredAreas.length,
                    itemBuilder: (context, index) {
                      final area = _filteredAreas[index];
                      final bool isSelected = _selectedAreaIds.contains(
                        area.id,
                      );
                      String cityNames = area.cities
                          .map((c) => c.name)
                          .join(', ');
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        elevation: 2,
                        child: CheckboxListTile(
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            area.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            '${area.state.name} ${cityNames.isNotEmpty ? '($cityNames)' : ''}',
                          ),
                          value: isSelected,
                          onChanged: (bool? newValue) {
                            _toggleAreaSelection(area.id, newValue);
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
