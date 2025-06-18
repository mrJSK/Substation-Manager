// lib/screens/area_management_screen.dart

import 'package:flutter/material.dart';
import 'package:substation_manager/models/area.dart'; // Area, StateModel, CityModel
import 'package:substation_manager/services/core_firestore_service.dart';
import 'package:substation_manager/utils/snackbar_utils.dart';
import 'package:uuid/uuid.dart'; // For generating IDs
import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'dart:async'; // For StreamSubscription
import 'package:substation_manager/services/local_database_service.dart'; // To pre-populate states/cities

class AreaManagementScreen extends StatefulWidget {
  const AreaManagementScreen({super.key});

  @override
  State<AreaManagementScreen> createState() => _AreaManagementScreenState();
}

class _AreaManagementScreenState extends State<AreaManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _areaNameController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _citiesController = TextEditingController();

  StateModel?
  _selectedState; // Holds the full StateModel object for the selected state
  List<StateModel> _availableStates = []; // All states for the bottom sheet

  List<CityModel> _allCitiesFromDB = []; // All cities loaded from DB
  List<CityModel> _selectedCities =
      []; // Full CityModel objects for display/saving

  String? _selectedAreaPurpose; // Holds the selected area purpose
  final List<String> _areaPurposeOptions = [
    'Transmission',
    'Testing & Commissioning',
  ];

  List<Area> _areas = [];
  bool _isLoading = true; // Overall loading for initial data fetch
  Area? _areaToEdit;

  // NEW: Separate loading state for the save button
  bool _isSaving = false;

  final CoreFirestoreService _coreFirestoreService = CoreFirestoreService();
  final LocalDatabaseService _localDatabaseService = LocalDatabaseService();
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _areaNameController.dispose();
    _stateController.dispose();
    _citiesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    print('DEBUG: _loadInitialData started.');
    if (mounted) {
      SnackBarUtils.showSnackBar(
        context,
        'Initializing Area Management data...',
        isError: false,
      );
    }

    setState(() {
      _isLoading = true;
    });
    try {
      _availableStates = await _localDatabaseService.getAllStates();
      print('DEBUG: Loaded ${_availableStates.length} states from local DB.');
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Loaded ${_availableStates.length} states.',
          isError: false,
        );
      }

      _allCitiesFromDB = await _localDatabaseService.getAllCities();
      print('DEBUG: Loaded ${_allCitiesFromDB.length} cities from local DB.');
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Loaded ${_allCitiesFromDB.length} cities.',
          isError: false,
        );
      }

      _coreFirestoreService.getAreasStream().listen(
        (areas) {
          if (mounted) {
            setState(() {
              _areas = areas;
              print('DEBUG: Loaded ${_areas.length} areas from Firestore.');
              if (_areaToEdit != null) {
                // Re-find the area in the updated list to ensure it's fresh
                final updatedArea = _areas.firstWhereOrNull(
                  (a) => a.id == _areaToEdit!.id,
                );
                if (updatedArea != null) {
                  _editArea(updatedArea);
                }
              }
            });
          }
        },
        onError: (e) {
          print('DEBUG ERROR: Error streaming areas from Firestore: $e');
          if (mounted) {
            SnackBarUtils.showSnackBar(
              context,
              'Error loading areas from Firestore: ${e.toString()}',
              isError: true,
            );
          }
        },
      );
    } catch (e) {
      print('DEBUG ERROR: Error in _loadInitialData: $e');
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Error loading initial data: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          print('DEBUG: _isLoading set to false. UI should be ready.');
        });
      }
    }
  }

  void _editArea(Area area) {
    setState(() {
      _areaToEdit = area;
      _areaNameController.text = area.name;
      _selectedState = area.state; // Assign the full StateModel
      _stateController.text =
          area.state.name; // Set controller text for editing
      _selectedCities = List.from(area.cities);
      _citiesController.text = _selectedCities
          .map((c) => c.name)
          .join(', '); // Set cities controller text for editing
      _selectedAreaPurpose = area.areaPurpose;
      print(
        'DEBUG: Editing Area: ${area.name}, State: ${_selectedState?.name}, Purpose: $_selectedAreaPurpose',
      );
    });
  }

  void _clearForm() {
    setState(() {
      _areaToEdit = null;
      _areaNameController.clear();
      _selectedState = null; // Clear the selected state
      _stateController.clear(); // Clear the state controller text
      _selectedCities = [];
      _citiesController.clear(); // Clear the cities controller text
      _selectedAreaPurpose = null;
      _formKey.currentState?.reset();
      print('DEBUG: Form cleared.');
    });
  }

  Future<void> _saveArea() async {
    if (!_formKey.currentState!.validate()) {
      SnackBarUtils.showSnackBar(
        context,
        'Please correct form errors.',
        isError: true,
      );
      return;
    }
    // Validation for _selectedState should use its nullability directly
    if (_selectedState == null) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Please select a state.',
          isError: true,
        );
      }
      return;
    }
    if (_selectedCities.isEmpty) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Please select at least one city.',
          isError: true,
        );
      }
      return;
    }
    if (_selectedAreaPurpose == null) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Please select an area purpose.',
          isError: true,
        );
      }
      return;
    }

    setState(() {
      _isSaving = true; // NEW: Set saving state to true
    });

    try {
      final Area area = Area(
        id: _areaToEdit?.id ?? Uuid().v4(),
        name: _areaNameController.text.trim(),
        areaPurpose: _selectedAreaPurpose!,
        state: _selectedState!, // Use the full StateModel
        cities: _selectedCities,
      );

      if (_areaToEdit == null) {
        await _coreFirestoreService.addArea(area);
        if (mounted) {
          SnackBarUtils.showSnackBar(context, 'Area added successfully!');
        }
      } else {
        await _coreFirestoreService.updateArea(area);
        if (mounted) {
          SnackBarUtils.showSnackBar(context, 'Area updated successfully!');
        }
      }
      _clearForm();
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Error saving area: ${e.toString()}',
          isError: true,
        );
      }
      print('Error saving area: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false; // NEW: Set saving state to false
        });
      }
    }
  }

  Future<void> _deleteArea(String id) async {
    final bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text(
              'Are you sure you want to delete this area? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await _coreFirestoreService.deleteArea(id);
        if (mounted) {
          SnackBarUtils.showSnackBar(context, 'Area deleted successfully!');
        }
      } catch (e) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
            context,
            'Error deleting area: $e',
            isError: true,
          );
        }
        print('Error deleting area: $e');
      }
    }
  }

  Future<void> _selectState() async {
    final StateModel? result = await showModalBottomSheet<StateModel>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _StateSingleSelectModal(
          availableStates: _availableStates,
          initialSelectedState: _selectedState,
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedState = result;
        _stateController.text =
            result.name; // Update controller text when state is selected
        _selectedCities = []; // Clear selected cities when state changes
        _citiesController
            .clear(); // Clear cities controller text as cities are reset
      });
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Selected State: ${result.name}',
          isError: false,
        );
      }
    }
  }

  Future<void> _selectCities() async {
    if (_selectedState == null) {
      SnackBarUtils.showSnackBar(
        context,
        'Please select a state first to choose cities.',
        isError: true,
      );
      return;
    }

    final List<CityModel> citiesForState = _allCitiesFromDB
        .where(
          (city) => city.stateId == _selectedState!.id,
        ) // Use _selectedState.id
        .toList();

    if (citiesForState.isEmpty) {
      SnackBarUtils.showSnackBar(
        context,
        'No cities available for the selected state.',
        isError: false,
      );
      return;
    }

    final List<CityModel>? result = await showModalBottomSheet<List<CityModel>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _CityMultiSelectModal(
          availableCities: citiesForState,
          initialSelectedCities: _selectedCities,
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedCities = result;
        _citiesController.text = _selectedCities
            .map((c) => c.name)
            .join(', '); // Update controller text with selected cities
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Remove the top-level _isLoading check that replaced the entire screen
    // if (_isLoading) {
    //   return const Center(child: CircularProgressIndicator());
    // }

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Areas')),
      // Show a full-screen loading indicator ONLY for initial data load
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _areaToEdit == null ? 'Add New Area' : 'Edit Area',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _areaNameController,
                          decoration: InputDecoration(
                            labelText: 'Area Name',
                            prefixIcon: Icon(
                              Icons.map,
                              color: colorScheme.primary,
                            ),
                          ),
                          validator: (value) => value!.isEmpty
                              ? 'Area name cannot be empty'
                              : null,
                        ),
                        const SizedBox(height: 15),

                        // State Selection (TextFormField that acts like a button)
                        TextFormField(
                          controller: _stateController,
                          readOnly: true, // Make it non-editable
                          onTap: _selectState, // Open bottom sheet on tap
                          decoration: InputDecoration(
                            labelText: 'State',
                            prefixIcon: Icon(
                              Icons.location_on,
                              color: colorScheme.primary,
                            ),
                            suffixIcon: Icon(
                              Icons.arrow_drop_down,
                              color: colorScheme.onSurface,
                            ), // Dropdown arrow
                          ),
                          validator: (value) => _selectedState == null
                              ? 'Please select a state'
                              : null, // Validate based on _selectedState
                        ),
                        const SizedBox(height: 15),

                        // City Selection (TextFormField that acts like a button)
                        TextFormField(
                          controller: _citiesController,
                          readOnly: true, // Make it non-editable
                          onTap: _selectCities, // Open bottom sheet on tap
                          maxLines:
                              null, // Allow text to wrap if many cities are selected
                          decoration: InputDecoration(
                            labelText: 'Cities',
                            prefixIcon: Icon(
                              Icons.location_city,
                              color: colorScheme.primary,
                            ),
                            suffixIcon: Icon(
                              Icons.arrow_drop_down,
                              color: colorScheme.onSurface,
                            ), // Dropdown arrow
                          ),
                          validator: (value) => _selectedCities.isEmpty
                              ? 'Please select at least one city'
                              : null, // Validate based on _selectedCities
                        ),
                        const SizedBox(
                          height: 15,
                        ), // Added SizedBox for consistent spacing

                        DropdownButtonFormField<String>(
                          value: _selectedAreaPurpose,
                          decoration: InputDecoration(
                            labelText: 'Area Purpose',
                            prefixIcon: Icon(
                              Icons.work,
                              color: colorScheme.primary,
                            ),
                          ),
                          items: _areaPurposeOptions.map((purpose) {
                            return DropdownMenuItem<String>(
                              value: purpose,
                              child: Text(purpose),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedAreaPurpose = newValue;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Select area purpose' : null,
                        ),
                        const SizedBox(height: 30),

                        // ElevatedButton for saving/updating - NOW WITH IN-BUTTON SPINNER
                        ElevatedButton.icon(
                          onPressed: _isSaving
                              ? null
                              : _saveArea, // Disable button if _isSaving is true
                          icon:
                              _isSaving // Conditionally show spinner or icon
                              ? SizedBox(
                                  width: 24, // Adjust size as needed
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2, // Make it thinner
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.onPrimary,
                                    ), // Match button text color
                                  ),
                                )
                              : Icon(
                                  _areaToEdit == null ? Icons.add : Icons.save,
                                ),
                          label: Text(
                            _areaToEdit == null ? 'Add Area' : 'Update Area',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                        if (_areaToEdit != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: OutlinedButton.icon(
                              onPressed: _clearForm,
                              icon: const Icon(Icons.cancel),
                              label: const Text('Cancel Edit'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.onSurface,
                                side: BorderSide(
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Existing Areas',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _areas.isEmpty
                      ? Center(
                          child: Text(
                            'No areas added yet.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontStyle: FontStyle.italic),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _areas.length,
                          itemBuilder: (context, index) {
                            final area = _areas[index];
                            String cityNames = area.cities
                                .map((c) => c.name)
                                .join(', ');
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 3,
                              child: ListTile(
                                title: Text(area.name),
                                subtitle: Text(
                                  '${area.state.name} (${area.areaPurpose})${cityNames.isNotEmpty ? ' ($cityNames)' : ''}',
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (String result) {
                                    if (result == 'edit') {
                                      _editArea(area);
                                    } else if (result == 'delete') {
                                      _deleteArea(area.id);
                                    }
                                  },
                                  itemBuilder: (BuildContext context) =>
                                      <PopupMenuEntry<String>>[
                                        const PopupMenuItem<String>(
                                          value: 'edit',
                                          child: ListTile(
                                            leading: Icon(Icons.edit),
                                            title: Text('Edit'),
                                          ),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'delete',
                                          child: ListTile(
                                            leading: Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            title: Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}

// Reusable City Multi-Select Modal
class _CityMultiSelectModal extends StatefulWidget {
  final List<CityModel> availableCities;
  final List<CityModel> initialSelectedCities;

  const _CityMultiSelectModal({
    required this.availableCities,
    required this.initialSelectedCities,
  });

  @override
  _CityMultiSelectModalState createState() => _CityMultiSelectModalState();
}

class _CityMultiSelectModalState extends State<_CityMultiSelectModal> {
  final TextEditingController _searchController = TextEditingController();
  List<CityModel> _filteredCities = [];
  Set<double> _currentSelectedCityIds = {};

  @override
  void initState() {
    super.initState();
    _currentSelectedCityIds = widget.initialSelectedCities
        .map((c) => c.id)
        .toSet();
    _filteredCities = List.from(widget.availableCities);
    _searchController.addListener(_filterCities);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCities);
    _searchController.dispose();
    super.dispose();
  }

  void _filterCities() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCities = widget.availableCities.where((city) {
        return city.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: Column(
        children: [
          Text('Select Cities', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search City',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _filteredCities.isEmpty
                ? const Center(child: Text('No cities found.'))
                : ListView.builder(
                    itemCount: _filteredCities.length,
                    itemBuilder: (context, index) {
                      final city = _filteredCities[index];
                      final isSelected = _currentSelectedCityIds.contains(
                        city.id,
                      );
                      return CheckboxListTile(
                        title: Text(city.name),
                        subtitle: Text('State ID: ${city.stateId}'),
                        value: isSelected,
                        onChanged: (bool? selected) {
                          setState(() {
                            if (selected == true) {
                              _currentSelectedCityIds.add(city.id);
                            } else {
                              _currentSelectedCityIds.remove(city.id);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final List<CityModel> result = widget.availableCities
                  .where((city) => _currentSelectedCityIds.contains(city.id))
                  .toList();
              Navigator.pop(context, result);
            },
            child: const Text('Confirm Selection'),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// State Single-Select Modal
class _StateSingleSelectModal extends StatefulWidget {
  final List<StateModel> availableStates;
  final StateModel? initialSelectedState;

  const _StateSingleSelectModal({
    required this.availableStates,
    this.initialSelectedState,
  });

  @override
  _StateSingleSelectModalState createState() => _StateSingleSelectModalState();
}

class _StateSingleSelectModalState extends State<_StateSingleSelectModal> {
  final TextEditingController _searchController = TextEditingController();
  List<StateModel> _filteredStates = [];
  StateModel? _currentSelectedState;

  @override
  void initState() {
    super.initState();
    _currentSelectedState = widget.initialSelectedState;
    _filteredStates = List.from(widget.availableStates);
    _searchController.addListener(_filterStates);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterStates);
    _searchController.dispose();
    super.dispose();
  }

  void _filterStates() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStates = widget.availableStates.where((state) {
        return state.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: Column(
        children: [
          Text('Select State', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search State',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _filteredStates.isEmpty
                ? const Center(child: Text('No states found.'))
                : ListView.builder(
                    itemCount: _filteredStates.length,
                    itemBuilder: (context, index) {
                      final state = _filteredStates[index];
                      // Use RadioListTile for single selection
                      return RadioListTile<StateModel>(
                        title: Text(state.name),
                        value: state,
                        groupValue:
                            _currentSelectedState, // Group all radio buttons
                        onChanged: (StateModel? selected) {
                          setState(() {
                            _currentSelectedState = selected;
                          });
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, _currentSelectedState);
            },
            child: const Text('Confirm Selection'),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
