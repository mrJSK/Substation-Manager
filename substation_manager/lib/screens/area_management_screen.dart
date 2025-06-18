// lib/screens/area_management_screen.dart
// Placeholder for Area Management Screen

import 'package:flutter/material.dart';
import 'package:substation_manager/models/area.dart'; // Area, StateModel, CityModel
import 'package:substation_manager/services/core_firestore_service.dart';
import 'package:substation_manager/utils/snackbar_utils.dart';
import 'package:uuid/uuid.dart'; // For generating IDs

class AreaManagementScreen extends StatefulWidget {
  const AreaManagementScreen({super.key});

  @override
  State<AreaManagementScreen> createState() => _AreaManagementScreenState();
}

class _AreaManagementScreenState extends State<AreaManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _areaNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  StateModel? _selectedState;
  List<CityModel> _allStates = []; // For dropdown of states
  List<CityModel> _allCities = []; // For cities in selected state
  final Set<double> _selectedCityIds = {}; // Selected cities by ID

  List<Area> _areas = [];
  bool _isLoading = true;
  Area? _areaToEdit;

  final CoreFirestoreService _coreFirestoreService = CoreFirestoreService();
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _areaNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Fetch all states and cities (these would typically be pre-populated from SQL data into Firestore)
      // For now, let's assume core_firestore_service can fetch them from some config collection or they are hardcoded.
      // In a real app, you'd load these from LocalDatabaseService after pre-population.
      // For this placeholder, we'll use dummy lists if not available from Firestore.

      // Placeholder for fetching States and Cities (if you populate them to Firestore)
      // For now, create dummy ones if you haven't put them in Firestore yet
      _allStates = []; // Assuming you'll have a service to get these
      _allCities = []; // Assuming you'll have a service to get these

      // Or, fetch from LocalDatabaseService if pre-populated there:
      // final localDb = LocalDatabaseService();
      // final fetchedStates = await localDb.getAllStates();
      // final fetchedCities = await localDb.getAllCities();
      // _allStates = fetchedStates.map((s) => CityModel(id: s.id, name: s.name, stateId: s.id)).toList(); // Convert to CityModel for simplicity in list
      // _allCities = fetchedCities;

      _coreFirestoreService.getAreasStream().listen((areas) {
        if (mounted) {
          setState(() {
            _areas = areas;
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
      print('Error loading area management data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _editArea(Area area) {
    setState(() {
      _areaToEdit = area;
      _areaNameController.text = area.name;
      _descriptionController.text = area.description ?? '';
      _selectedState = area.state;
      _selectedCityIds.clear();
      _selectedCityIds.addAll(area.cities.map((city) => city.id));
      _filterCitiesForState(
        _selectedState,
      ); // Filter cities dropdown based on selected state
    });
  }

  void _clearForm() {
    setState(() {
      _areaToEdit = null;
      _areaNameController.clear();
      _descriptionController.clear();
      _selectedState = null;
      _selectedCityIds.clear();
      _allCities = []; // Clear cities too
      _formKey.currentState?.reset();
    });
  }

  Future<void> _saveArea() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedState == null) {
      if (mounted)
        SnackBarUtils.showSnackBar(
          context,
          'Please select a state.',
          isError: true,
        );
      return;
    }

    setState(() {
      _isLoading = true; // Use loading state for saving
    });

    try {
      final List<CityModel> selectedCities = _selectedCityIds
          .map((id) => _allCities.firstWhere((city) => city.id == id))
          .toList();

      final Area area = Area(
        id: _areaToEdit?.id ?? _uuid.v4(),
        name: _areaNameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        state: _selectedState!,
        cities: selectedCities,
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
          'Error saving area: $e',
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

  void _filterCitiesForState(StateModel? state) {
    setState(() {
      if (state == null) {
        _allCities = []; // Clear cities if no state selected
      } else {
        // In a real scenario, you'd fetch cities from local DB or pre-filtered lists
        // For this placeholder, let's assume _allCities has all cities and filter them
        _allCities = []; // This should come from your full list of cities
        // Example: If you hardcode states/cities for testing
        // _allCities = allIndianCities.where((city) => city.stateId == state.id).toList();
      }
      _selectedCityIds.clear(); // Clear selected cities on state change
    });
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
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      prefixIcon: Icon(
                        Icons.description,
                        color: colorScheme.primary,
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 15),
                  // State Selection
                  DropdownButtonFormField<StateModel>(
                    value: _selectedState,
                    decoration: InputDecoration(
                      labelText: 'State',
                      prefixIcon: Icon(
                        Icons.location_on,
                        color: colorScheme.primary,
                      ),
                    ),
                    items:
                        [
                              // Placeholder: In real app, load from LocalDatabaseService.getAllStates()
                              StateModel(
                                id: 34,
                                name: 'Uttar Pradesh',
                              ), // Dummy State for testing
                              StateModel(id: 29, name: 'Rajasthan'),
                              // ... add more as per your SQL data
                            ]
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
                  // City Multi-Select (if cities are populated)
                  if (_allCities.isNotEmpty ||
                      _selectedCityIds
                          .isNotEmpty) // Show only if cities exist or selected
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Cities:',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          children: _allCities.map((city) {
                            final isSelected = _selectedCityIds.contains(
                              city.id,
                            );
                            return FilterChip(
                              label: Text(city.name),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedCityIds.add(city.id);
                                  } else {
                                    _selectedCityIds.remove(city.id);
                                  }
                                });
                              },
                              selectedColor: colorScheme.secondary.withOpacity(
                                0.3,
                              ),
                              checkmarkColor: colorScheme.onSecondary,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 15),
                      ],
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
                      // To display city names, you would need to fetch them from your master list of cities
                      String cityNames = area.cities
                          .map((c) => c.name)
                          .join(', ');
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 3,
                        child: ListTile(
                          title: Text(
                            area.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            '${area.state.name} ${cityNames.isNotEmpty ? '(${cityNames})' : ''}',
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
