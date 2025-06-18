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

  double? _selectedStateId; // Holds the ID of the selected state
  List<StateModel> _availableStates = []; // All states for the dropdown

  List<CityModel> _allCitiesFromDB = []; // All cities loaded from DB
  List<CityModel> _selectedCities =
      []; // Full CityModel objects for display/saving

  String? _selectedAreaPurpose; // Holds the selected area purpose
  final List<String> _areaPurposeOptions = [
    'Transmission',
    'Testing & Commissioning',
  ];

  List<Area> _areas = [];
  bool _isLoading = true;
  Area? _areaToEdit;

  final CoreFirestoreService _coreFirestoreService = CoreFirestoreService();
  final LocalDatabaseService _localDatabaseService = LocalDatabaseService();
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    // Schedule the initial data load to run AFTER the first frame has rendered,
    // ensuring BuildContext is fully available for SnackBar calls.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _areaNameController.dispose();
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
                _editArea(_areaToEdit!);
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
      _selectedStateId = area.state.id;
      _selectedCities = List.from(area.cities);
      _selectedAreaPurpose = area.areaPurpose;
      print(
        'DEBUG: Editing Area: ${area.name}, State ID: $_selectedStateId, Purpose: $_selectedAreaPurpose',
      );
    });
  }

  void _clearForm() {
    setState(() {
      _areaToEdit = null;
      _areaNameController.clear();
      _selectedStateId = null;
      _selectedCities = [];
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
    if (_selectedStateId == null) {
      if (mounted)
        SnackBarUtils.showSnackBar(
          context,
          'Please select a state.',
          isError: true,
        );
      return;
    }
    if (_selectedCities.isEmpty) {
      if (mounted)
        SnackBarUtils.showSnackBar(
          context,
          'Please select at least one city.',
          isError: true,
        );
      return;
    }
    if (_selectedAreaPurpose == null) {
      if (mounted)
        SnackBarUtils.showSnackBar(
          context,
          'Please select an area purpose.',
          isError: true,
        );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final StateModel? selectedState = _availableStates.firstWhereOrNull(
        (state) => state.id == _selectedStateId,
      );
      if (selectedState == null) {
        if (mounted)
          SnackBarUtils.showSnackBar(
            context,
            'Selected state not found.',
            isError: true,
          );
        return;
      }

      final Area area = Area(
        id: _areaToEdit?.id ?? Uuid().v4(),
        name: _areaNameController.text.trim(),
        areaPurpose: _selectedAreaPurpose!,
        state: selectedState,
        cities: _selectedCities,
      );

      if (_areaToEdit == null) {
        await _coreFirestoreService.addArea(area);
        if (mounted)
          SnackBarUtils.showSnackBar(context, 'Area added successfully!');
      } else {
        await _coreFirestoreService.updateArea(area);
        if (mounted)
          SnackBarUtils.showSnackBar(context, 'Area updated successfully!');
      }
      _clearForm();
    } catch (e) {
      if (mounted)
        SnackBarUtils.showSnackBar(
          context,
          'Error saving area: ${e.toString()}',
          isError: true,
        );
      print('Error saving area: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
        if (mounted)
          SnackBarUtils.showSnackBar(context, 'Area deleted successfully!');
      } catch (e) {
        if (mounted)
          SnackBarUtils.showSnackBar(
            context,
            'Error deleting area: $e',
            isError: true,
          );
        print('Error deleting area: $e');
      }
    }
  }

  Future<void> _selectCities() async {
    if (_selectedStateId == null) {
      SnackBarUtils.showSnackBar(
        context,
        'Please select a state first to choose cities.',
        isError: true,
      );
      return;
    }

    final List<CityModel> citiesForState = _allCitiesFromDB
        .where((city) => city.stateId == _selectedStateId)
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Areas')),
      body: SingleChildScrollView(
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
                      prefixIcon: Icon(Icons.map, color: colorScheme.primary),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Area name cannot be empty' : null,
                  ),
                  const SizedBox(height: 15),

                  DropdownButtonFormField<double>(
                    value: _selectedStateId,
                    decoration: InputDecoration(
                      labelText: 'State',
                      prefixIcon: Icon(
                        Icons.location_on,
                        color: colorScheme.primary,
                      ),
                    ),
                    items: _availableStates.map((state) {
                      return DropdownMenuItem<double>(
                        value: state.id,
                        child: Text(state.name),
                      );
                    }).toList(),
                    onChanged: (double? newValue) {
                      print(
                        'DEBUG: State Dropdown onChanged triggered. New Value: $newValue',
                      );
                      if (mounted) {
                        setState(() {
                          _selectedStateId = newValue;
                          _selectedCities = [];
                        });
                        final selectedStateName =
                            _availableStates
                                .firstWhereOrNull((s) => s.id == newValue)
                                ?.name ??
                            'N/A';
                        SnackBarUtils.showSnackBar(
                          context,
                          'Selected State: $selectedStateName',
                          isError: false,
                        );
                      }
                    },
                    validator: (value) =>
                        value == null ? 'Select a state' : null,
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: _selectedAreaPurpose,
                    decoration: InputDecoration(
                      labelText: 'Area Purpose',
                      prefixIcon: Icon(Icons.work, color: colorScheme.primary),
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
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: _selectCities,
                    icon: Icon(
                      Icons.location_city,
                      color: colorScheme.onPrimary,
                    ),
                    label: Text(
                      _selectedCities.isEmpty
                          ? 'Select Cities'
                          : 'Cities Selected (${_selectedCities.length})',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  if (_selectedCities.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 8.0,
                        children: _selectedCities
                            .map((city) => Chip(label: Text(city.name)))
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 30),

                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          onPressed: _saveArea,
                          icon: Icon(
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
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
                                        style: TextStyle(color: Colors.red),
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
