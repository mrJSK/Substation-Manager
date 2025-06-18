// lib/screens/substation_management_screen.dart

import 'package:flutter/material.dart';
import 'package:substation_manager/models/substation.dart';
import 'package:substation_manager/models/area.dart'; // Import Area, StateModel, CityModel
import 'package:substation_manager/services/core_firestore_service.dart';
import 'package:substation_manager/utils/snackbar_utils.dart';
import 'package:uuid/uuid.dart'; // For generating IDs
// Removed: import 'package:image_picker/image_picker.dart';
// Removed: import 'package:firebase_storage/firebase_storage.dart';
// Removed: import 'dart:io'; // Not needed if File is no longer used here
import 'package:path/path.dart'
    as p; // Still needed for path.basename if any other file use it.
import 'package:collection/collection.dart'; // For firstWhereOrNull

class SubstationManagementScreen extends StatefulWidget {
  const SubstationManagementScreen({super.key});

  @override
  State<SubstationManagementScreen> createState() =>
      _SubstationManagementScreenState();
}

class _SubstationManagementScreenState
    extends State<SubstationManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Area? _selectedArea;
  StateModel? _selectedState;
  CityModel? _selectedCity;
  List<Area> _allAreas = [];
  List<StateModel> _allStates = []; // From LocalDB or hardcoded for demo
  List<CityModel> _citiesInSelectedState = []; // Filtered from LocalDB
  String? _selectedSubstationType;
  final List<String> _substationTypes = ['AIS', 'GIS', 'Hybrid'];
  final List<String> _voltageLevels = [
    '765kV',
    '400kV',
    '220kV',
    '132kV',
    '33kV',
    '11kV',
  ];
  final Set<String> _selectedVoltageLevels = {};
  int? _selectedYearOfCommissioning;

  // Removed: File? _pickedSldImage;
  // Removed: String? _existingSldImageUrl; // This information is now only managed via SLD Builder screen or removed entirely.

  List<Substation> _substations = [];
  bool _isLoading = true;
  Substation? _substationToEdit;

  final CoreFirestoreService _coreFirestoreService = CoreFirestoreService();
  final Uuid _uuid = const Uuid();
  // Removed: final ImagePicker _picker = ImagePicker();
  // Removed: final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _capacityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _allAreas = await _coreFirestoreService.getAreasOnce();
      _allStates = [
        StateModel(id: 34, name: 'Uttar Pradesh'),
        StateModel(id: 29, name: 'Rajasthan'),
      ]; // Dummy States for testing

      _coreFirestoreService.getSubstationsStream().listen((substations) {
        if (mounted) {
          setState(() {
            _substations = substations;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Error loading initial data: $e',
          isError: true,
        );
      }
      print('Error loading substation management data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _editSubstation(Substation substation) {
    setState(() {
      _substationToEdit = substation;
      _nameController.text = substation.name;
      _selectedArea = _allAreas.firstWhereOrNull(
        (area) => area.id == substation.areaId,
      );
      _addressController.text = substation.address ?? '';
      _latitudeController.text = substation.latitude.toString();
      _longitudeController.text = substation.longitude.toString();
      _selectedState = _allStates.firstWhereOrNull(
        (state) => state.id == substation.stateId,
      );
      _filterCitiesForState(_selectedState);
      _selectedCity = _citiesInSelectedState.firstWhereOrNull(
        (city) => city.id == substation.cityId,
      );
      _selectedSubstationType = substation.type;
      _selectedVoltageLevels.clear();
      _selectedVoltageLevels.addAll(substation.voltageLevels);
      _selectedYearOfCommissioning = substation.yearOfCommissioning;
      _capacityController.text =
          substation.totalConnectedCapacityMVA?.toString() ?? '';
      _notesController.text = substation.notes ?? '';
      // Removed: _existingSldImageUrl = substation.sldImagePath; // No longer managed here
      // Removed: _pickedSldImage = null; // No longer managed here
    });
  }

  void _clearForm() {
    setState(() {
      _substationToEdit = null;
      _nameController.clear();
      _addressController.clear();
      _latitudeController.clear();
      _longitudeController.clear();
      _capacityController.clear();
      _notesController.clear();
      _selectedArea = null;
      _selectedState = null;
      _selectedCity = null;
      _citiesInSelectedState = [];
      _selectedSubstationType = null;
      _selectedVoltageLevels.clear();
      _selectedYearOfCommissioning = null;
      // Removed: _pickedSldImage = null;
      // Removed: _existingSldImageUrl = null;
      _formKey.currentState?.reset();
    });
  }

  // Removed: Future<void> _pickSldImage() method
  // Removed: Future<String?> _uploadSldImage(String substationId) method

  Future<void> _saveSubstation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedArea == null) {
      if (mounted)
        SnackBarUtils.showSnackBar(
          context,
          'Please select an Area.',
          isError: true,
        );
      return;
    }
    if (_selectedState == null || _selectedCity == null) {
      if (mounted)
        SnackBarUtils.showSnackBar(
          context,
          'Please select State and City.',
          isError: true,
        );
      return;
    }
    if (_selectedVoltageLevels.isEmpty) {
      if (mounted)
        SnackBarUtils.showSnackBar(
          context,
          'Please select at least one Voltage Level.',
          isError: true,
        );
      return;
    }
    if (_selectedYearOfCommissioning == null) {
      if (mounted)
        SnackBarUtils.showSnackBar(
          context,
          'Please select Year of Commissioning.',
          isError: true,
        );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String substationId = _substationToEdit?.id ?? _uuid.v4();
      // Removed: final String? sldImageUrl = await _uploadSldImage(substationId); // No longer uploading here

      final Substation substation = Substation(
        id: substationId,
        name: _nameController.text.trim(),
        areaId: _selectedArea!.id,
        voltageLevels: _selectedVoltageLevels.toList(),
        latitude: double.parse(_latitudeController.text.trim()),
        longitude: double.parse(_longitudeController.text.trim()),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        cityId: _selectedCity!.id,
        stateId: _selectedState!.id,
        type: _selectedSubstationType,
        yearOfCommissioning: _selectedYearOfCommissioning!,
        totalConnectedCapacityMVA: double.tryParse(
          _capacityController.text.trim(),
        ),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        // Removed: sldImagePath: _substationToEdit?.sldImagePath, // No longer updated here
        // Removed: sldHotspots: _substationToEdit?.sldHotspots ?? [], // No longer updated here
      );

      if (_substationToEdit == null) {
        await _coreFirestoreService.addSubstation(substation);
        if (mounted)
          SnackBarUtils.showSnackBar(context, 'Substation added successfully!');
      } else {
        await _coreFirestoreService.updateSubstation(substation);
        if (mounted)
          SnackBarUtils.showSnackBar(
            context,
            'Substation updated successfully!',
          );
      }
      _clearForm();
    } catch (e) {
      if (mounted)
        SnackBarUtils.showSnackBar(
          context,
          'Error saving substation: $e',
          isError: true,
        );
      print('Error saving substation: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteSubstation(String id) async {
    final bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text(
              'Are you sure you want to delete this substation? This cannot be undone.',
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
        await _coreFirestoreService.deleteSubstation(id);
        // Removed: Also delete image from storage if it exists (no longer handled here)
        if (mounted)
          SnackBarUtils.showSnackBar(
            context,
            'Substation deleted successfully!',
          );
        _clearForm();
      } catch (e) {
        if (mounted)
          SnackBarUtils.showSnackBar(
            context,
            'Error deleting substation: $e',
            isError: true,
          );
        print('Error deleting substation: $e');
      }
    }
  }

  void _filterCitiesForState(StateModel? state) {
    setState(() {
      _selectedCity = null;
      _citiesInSelectedState = [];
      if (state != null) {
        // Dummy data for testing if no DB populated:
        if (state.name == 'Uttar Pradesh') {
          _citiesInSelectedState = [
            CityModel(id: 682, name: 'Firozabad', stateId: 34),
          ];
        } else if (state.name == 'Rajasthan') {
          _citiesInSelectedState = [
            CityModel(id: 552, name: 'Jaipur', stateId: 29),
          ];
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Substations')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _substationToEdit == null
                  ? 'Add New Substation'
                  : 'Edit Substation',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Substation Name',
                      prefixIcon: Icon(
                        Icons.factory,
                        color: colorScheme.primary,
                      ),
                    ),
                    validator: (value) => value!.isEmpty
                        ? 'Substation name cannot be empty'
                        : null,
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<Area>(
                    value: _selectedArea,
                    decoration: InputDecoration(
                      labelText: 'Assigned Area',
                      prefixIcon: Icon(Icons.map, color: colorScheme.primary),
                    ),
                    items: _allAreas
                        .map(
                          (area) => DropdownMenuItem(
                            value: area,
                            child: Text(area.name),
                          ),
                        )
                        .toList(),
                    onChanged: (Area? newValue) =>
                        setState(() => _selectedArea = newValue),
                    validator: (value) =>
                        value == null ? 'Select an area' : null,
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<StateModel>(
                    value: _selectedState,
                    decoration: InputDecoration(
                      labelText: 'State',
                      prefixIcon: Icon(
                        Icons.location_on,
                        color: colorScheme.primary,
                      ),
                    ),
                    items: _allStates
                        .map(
                          (state) => DropdownMenuItem(
                            value: state,
                            child: Text(state.name),
                          ),
                        )
                        .toList(),
                    onChanged: (StateModel? newValue) {
                      setState(() {
                        _selectedState = newValue;
                        _filterCitiesForState(newValue);
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Select a state' : null,
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<CityModel>(
                    value: _selectedCity,
                    decoration: InputDecoration(
                      labelText: 'City/District',
                      prefixIcon: Icon(
                        Icons.location_city,
                        color: colorScheme.primary,
                      ),
                    ),
                    items: _citiesInSelectedState
                        .map(
                          (city) => DropdownMenuItem(
                            value: city,
                            child: Text(city.name),
                          ),
                        )
                        .toList(),
                    onChanged: (CityModel? newValue) =>
                        setState(() => _selectedCity = newValue),
                    validator: (value) =>
                        value == null ? 'Select a city' : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Address (Optional)',
                      prefixIcon: Icon(
                        Icons.add_location,
                        color: colorScheme.primary,
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latitudeController,
                          decoration: InputDecoration(
                            labelText: 'Latitude',
                            prefixIcon: Icon(
                              Icons.map_outlined,
                              color: colorScheme.primary,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              value!.isEmpty || double.tryParse(value) == null
                              ? 'Enter valid latitude'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextFormField(
                          controller: _longitudeController,
                          decoration: InputDecoration(
                            labelText: 'Longitude',
                            prefixIcon: Icon(
                              Icons.map_outlined,
                              color: colorScheme.primary,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              value!.isEmpty || double.tryParse(value) == null
                              ? 'Enter valid longitude'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Voltage Levels',
                      prefixIcon: Icon(
                        Icons.flash_on,
                        color: colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Wrap(
                      spacing: 8.0,
                      children: _voltageLevels.map((level) {
                        final isSelected = _selectedVoltageLevels.contains(
                          level,
                        );
                        return FilterChip(
                          label: Text(level),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedVoltageLevels.add(level);
                              } else {
                                _selectedVoltageLevels.remove(level);
                              }
                            });
                          },
                          selectedColor: colorScheme.secondary.withOpacity(0.3),
                          checkmarkColor: colorScheme.onSecondary,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: _selectedSubstationType,
                    decoration: InputDecoration(
                      labelText: 'Substation Type',
                      prefixIcon: Icon(
                        Icons.category,
                        color: colorScheme.primary,
                      ),
                    ),
                    items: _substationTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (String? newValue) =>
                        setState(() => _selectedSubstationType = newValue),
                  ),
                  const SizedBox(height: 15),
                  ListTile(
                    title: Text(
                      _selectedYearOfCommissioning == null
                          ? 'Select Year of Commissioning'
                          : 'Year of Commissioning: $_selectedYearOfCommissioning',
                    ),
                    leading: Icon(
                      Icons.calendar_today,
                      color: colorScheme.primary,
                    ),
                    trailing: const Icon(Icons.arrow_drop_down),
                    onTap: () async {
                      final int? year = await showDialog<int>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Select Year"),
                            content: SizedBox(
                              width: 300,
                              height: 300,
                              child: YearPicker(
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365 * 10),
                                ),
                                selectedDate: DateTime(
                                  _selectedYearOfCommissioning ??
                                      DateTime.now().year,
                                ),
                                onChanged: (DateTime dateTime) {
                                  Navigator.pop(context, dateTime.year);
                                },
                              ),
                            ),
                          );
                        },
                      );
                      if (year != null) {
                        setState(() {
                          _selectedYearOfCommissioning = year;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _capacityController,
                    decoration: InputDecoration(
                      labelText: 'Total Connected Capacity (MVA) (Optional)',
                      prefixIcon: Icon(
                        Icons.power_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      prefixIcon: Icon(Icons.notes, color: colorScheme.primary),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _saveSubstation,
                    icon: Icon(
                      _substationToEdit == null ? Icons.add : Icons.save,
                    ),
                    label: Text(
                      _substationToEdit == null
                          ? 'Add Substation'
                          : 'Update Substation',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  if (_substationToEdit != null)
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
              'Existing Substations',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _substations.isEmpty
                ? Center(
                    child: Text(
                      'No substations added yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _substations.length,
                    itemBuilder: (context, index) {
                      final substation = _substations[index];
                      final String areaName =
                          _allAreas
                              .firstWhereOrNull(
                                (a) => a.id == substation.areaId,
                              )
                              ?.name ??
                          'N/A';
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 3,
                        child: ListTile(
                          title: Text(
                            substation.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            '${substation.voltageLevels.join(', ')} | Area: $areaName | Comm. ${substation.yearOfCommissioning}',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (String result) {
                              if (result == 'edit') {
                                _editSubstation(substation);
                              } else if (result == 'delete') {
                                _deleteSubstation(substation.id);
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
