// lib/screens/substation_management_screen.dart

import 'dart:async'; // For Timer and StreamSubscription
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // For GPS coordinates
import 'package:substation_manager/models/substation.dart';
import 'package:substation_manager/models/area.dart'; // Import Area, StateModel, CityModel
import 'package:substation_manager/services/core_firestore_service.dart';
import 'package:substation_manager/utils/snackbar_utils.dart';
import 'package:uuid/uuid.dart'; // For generating IDs
import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'package:substation_manager/services/location_service.dart'; // For GPS
import 'package:substation_manager/services/permission_service.dart'; // For location permissions
import 'package:substation_manager/services/local_database_service.dart'; // For local cities DB

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
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();

  Area? _selectedArea;
  List<Area> _allAreas = [];

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

  List<Substation> _substations = [];
  bool _isLoading = true; // For initial screen data load ONLY
  Substation? _substationToEdit;

  // NEW: Flag specifically for the save/update operation
  bool _isSaving = false;

  // GPS related state and services
  Position? _currentPosition;
  bool _isFetchingLocation = false; // Separate flag for GPS fetching UI
  bool _isLocationAccurateEnough = false; // Tracks if accuracy is met
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _accuracyTimeoutTimer;
  static const int _maximumWaitSeconds = 30; // Max time to wait for accuracy
  static const double _requiredAccuracyForCapture =
      20.0; // Required accuracy in meters

  final CoreFirestoreService _coreFirestoreService = CoreFirestoreService();
  final LocationService _locationService = LocationService();
  final PermissionService _permissionService = PermissionService();
  final LocalDatabaseService _localDatabaseService = LocalDatabaseService();
  final Uuid _uuid = const Uuid();

  List<CityModel> _allCitiesFromDB =
      []; // Used for displaying city names in list tile

  @override
  void initState() {
    super.initState();
    // Schedule the initial data loading and GPS fetching to run AFTER the first frame has rendered.
    // This prevents a black screen before the loading indicator can even be painted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialDataAndGPS();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _notesController.dispose();
    _areaController.dispose();
    _positionStreamSubscription?.cancel(); // Cancel GPS stream
    _accuracyTimeoutTimer?.cancel(); // Cancel GPS timer
    super.dispose();
  }

  // Orchestrates all initial loading and GPS fetching for the screen
  Future<void> _loadInitialDataAndGPS() async {
    print('DEBUG: _loadInitialDataAndGPS started.');
    if (mounted) {
      SnackBarUtils.showSnackBar(
        context,
        'Initializing Substation Management data...',
        isError: false,
      );
    }

    setState(() {
      _isLoading = true; // Show full screen loader for initial setup
    });

    try {
      // 1. Load data from Firestore and local DB
      print('DEBUG: Fetching areas from Firestore...');
      _allAreas = await _coreFirestoreService.getAreasOnce();
      print('DEBUG: Loaded ${_allAreas.length} areas.');

      print('DEBUG: Fetching all cities from local DB...');
      _allCitiesFromDB = await _localDatabaseService.getAllCities();
      print('DEBUG: Loaded ${_allCitiesFromDB.length} cities.');

      // Listen to substation stream (this is continuous)
      print('DEBUG: Setting up substations stream...');
      _coreFirestoreService.getSubstationsStream().listen((substations) {
        if (mounted) {
          setState(() {
            _substations = substations;
            print(
              'DEBUG: Substation stream updated. Loaded ${_substations.length} substations.',
            );
            if (_substationToEdit != null) {
              final updatedSubstation = _substations.firstWhereOrNull(
                (s) => s.id == _substationToEdit!.id,
              );
              if (updatedSubstation != null) {
                _editSubstation(updatedSubstation);
              }
            }
          });
        }
      });
      print('DEBUG: Substation stream setup complete.');

      // 2. Fetch initial GPS coordinates (this will manage its own _isFetchingLocation state)
      print('DEBUG: Starting initial GPS location fetch...');
      await _getCurrentLocation(
        initialLoad: true,
      ); // Pass a flag for initial load
      print('DEBUG: Initial GPS location fetch completed.');
    } catch (e) {
      print('DEBUG ERROR: Error in _loadInitialDataAndGPS: ${e.toString()}');
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
          _isLoading =
              false; // Hide full screen loader ONLY after ALL initial tasks
          print('DEBUG: _isLoading set to false. UI should be ready.');
        });
      }
    }
  }

  void _editSubstation(Substation substation) {
    setState(() {
      _substationToEdit = substation;
      _nameController.text = substation.name;
      _addressController.text = substation.address ?? '';
      _latitudeController.text = substation.latitude.toString();
      _longitudeController.text = substation.longitude.toString();
      _notesController.text = substation.notes ?? '';

      _selectedArea = _allAreas.firstWhereOrNull(
        (area) => area.id == substation.areaId,
      );
      _areaController.text = _selectedArea?.name ?? '';

      _selectedSubstationType = substation.type;
      _selectedVoltageLevels.clear();
      _selectedVoltageLevels.addAll(substation.voltageLevels);
      _selectedYearOfCommissioning = substation.yearOfCommissioning;
    });
  }

  void _clearForm() {
    setState(() {
      _substationToEdit = null;
      _nameController.clear();
      _addressController.clear();
      _latitudeController.clear();
      _longitudeController.clear();
      _notesController.clear();
      _selectedArea = null;
      _areaController.clear();
      _selectedSubstationType = null;
      _selectedVoltageLevels.clear();
      _selectedYearOfCommissioning = null;
      _formKey.currentState?.reset();

      // Reset GPS state and restart fetching for new entry
      _currentPosition = null;
      _isLocationAccurateEnough = false;
      _isFetchingLocation = false; // Ensure this is reset
      _positionStreamSubscription?.cancel();
      _accuracyTimeoutTimer?.cancel();
      _getCurrentLocation(); // Restart GPS fetching
    });
  }

  Future<void> _saveSubstation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedArea == null) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Please select an Area.',
          isError: true,
        );
      }
      return;
    }
    if (_selectedArea!.cities.isEmpty) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Selected Area has no cities. Please choose an area with associated cities.',
          isError: true,
        );
      }
      return;
    }
    // Validate GPS accuracy before saving
    if (_currentPosition == null || !_isLocationAccurateEnough) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'GPS accuracy (${_currentPosition?.accuracy.toStringAsFixed(1) ?? 'N/A'}m) is less than required (${_requiredAccuracyForCapture.toStringAsFixed(1)}m). Please wait or ensure better GPS signal.',
          isError: true,
        );
      }
      return;
    }

    setState(() {
      _isSaving = true; // NEW: Use _isSaving for the form submission button
    });

    try {
      final String substationId = _substationToEdit?.id ?? _uuid.v4();

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
        stateId: _selectedArea!.state.id,
        cityId: _selectedArea!.cities.first.id,
        type: _selectedSubstationType,
        yearOfCommissioning: _selectedYearOfCommissioning!,
        totalConnectedCapacityMVA:
            null, // Set to null as it's now dynamically derived
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (_substationToEdit == null) {
        await _coreFirestoreService.addSubstation(substation);
        if (mounted) {
          SnackBarUtils.showSnackBar(context, 'Substation added successfully!');
        }
      } else {
        await _coreFirestoreService.updateSubstation(substation);
        if (mounted) {
          SnackBarUtils.showSnackBar(
            context,
            'Substation updated successfully!',
          );
        }
      }
      _clearForm();
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Error saving substation: ${e.toString()}',
          isError: true,
        );
      }
      print('Error saving substation: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false; // NEW: Reset _isSaving flag
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
        if (mounted) {
          SnackBarUtils.showSnackBar(
            context,
            'Substation deleted successfully!',
          );
        }
        _clearForm();
      } catch (e) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
            context,
            'Error deleting substation: $e',
            isError: true,
          );
        }
        print('Error deleting substation: $e');
      }
    }
  }

  Future<void> _selectArea() async {
    final Area? result = await showModalBottomSheet<Area>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _AreaSingleSelectModal(
          availableAreas: _allAreas,
          initialSelectedArea: _selectedArea,
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedArea = result;
        _areaController.text = result.name;
      });
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Selected Area: ${result.name}',
          isError: false,
        );
      }
    }
  }

  // Refactored GPS fetching to use stream with timeout and accuracy check
  Future<void> _getCurrentLocation({bool initialLoad = false}) async {
    print('DEBUG: _getCurrentLocation called. initialLoad: $initialLoad');
    if (_isFetchingLocation && !initialLoad) {
      print('DEBUG: Already fetching location. Skipping call.');
      return; // Prevent multiple concurrent fetches unless it's initial load
    }

    setState(() {
      _isFetchingLocation = true; // Flag for GPS specific loading UI
      _isLocationAccurateEnough = false; // Reset accuracy status
      _currentPosition = null; // Clear previous position
      _latitudeController.clear(); // Clear UI fields
      _longitudeController.clear(); // Clear UI fields
      print('DEBUG: _isFetchingLocation set to true.');
    });

    print('DEBUG: Requesting location permissions...');
    final hasPermission = await _permissionService.requestLocationPermission(
      context,
    );
    if (!hasPermission) {
      print('DEBUG: Location permission denied.');
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Location permission denied.',
          isError: true,
        );
      }
      setState(() {
        _isFetchingLocation = false;
        print(
          'DEBUG: _isFetchingLocation set to false after permission denial.',
        );
      });
      return;
    }

    // Cancel any previous stream or timer before starting a new one
    print('DEBUG: Cancelling previous GPS stream/timer...');
    _positionStreamSubscription?.cancel();
    _accuracyTimeoutTimer?.cancel();
    print('DEBUG: Previous GPS stream/timer cancelled.');

    try {
      if (mounted && !initialLoad) {
        // Only show snackbar if not initial load
        SnackBarUtils.showSnackBar(context, 'Starting location stream...');
        print('DEBUG: Showing "Starting location stream" snackbar.');
      }

      print('DEBUG: Calling Geolocator.getPositionStream...');
      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.best, // Request best accuracy
              distanceFilter: 0, // Get updates as frequently as possible
            ),
          ).listen(
            (Position position) {
              if (mounted) {
                print(
                  'DEBUG: Received position update: ${position.accuracy.toStringAsFixed(2)}m',
                );
                setState(() {
                  _currentPosition = position;
                  _latitudeController.text = position.latitude.toStringAsFixed(
                    6,
                  );
                  _longitudeController.text = position.longitude
                      .toStringAsFixed(6);

                  // Check if required accuracy is met
                  if (position.accuracy <= _requiredAccuracyForCapture) {
                    _isLocationAccurateEnough = true;
                    _isFetchingLocation = false; // Stop fetching
                    _accuracyTimeoutTimer?.cancel(); // Stop timer
                    _positionStreamSubscription?.cancel(); // Stop stream
                    print(
                      'DEBUG: Accuracy met (${position.accuracy.toStringAsFixed(2)}m). Stopping stream.',
                    );
                    if (mounted) {
                      SnackBarUtils.showSnackBar(
                        context,
                        'Required accuracy (${position.accuracy.toStringAsFixed(2)}m) achieved!',
                        isError: false,
                      );
                    }
                  }
                });
              }
            },
            onError: (e) {
              print('DEBUG ERROR: Geolocator stream error: $e');
              if (mounted) {
                SnackBarUtils.showSnackBar(
                  context,
                  'Error getting location stream: ${e.toString()}',
                  isError: true,
                );
                setState(() {
                  _isFetchingLocation = false;
                  _isLocationAccurateEnough = false;
                });
              }
              _positionStreamSubscription?.cancel();
              _accuracyTimeoutTimer?.cancel();
            },
          );

      // Set a timeout for accuracy
      print(
        'DEBUG: Starting accuracy timeout timer for $_maximumWaitSeconds seconds...',
      );
      _accuracyTimeoutTimer = Timer(const Duration(seconds: _maximumWaitSeconds), () {
        print('DEBUG: Accuracy timeout timer fired.');
        if (mounted) {
          setState(() {
            _isLocationAccurateEnough =
                (_currentPosition != null &&
                _currentPosition!.accuracy <= _requiredAccuracyForCapture);
            _isFetchingLocation = false; // Stop fetching regardless of accuracy

            _positionStreamSubscription
                ?.cancel(); // Ensure stream is cancelled on timeout
          });

          if (!_isLocationAccurateEnough && mounted) {
            String accuracyMessage = _currentPosition != null
                ? 'Current accuracy is ${_currentPosition!.accuracy.toStringAsFixed(2)}m, which is above the required ${_requiredAccuracyForCapture.toStringAsFixed(1)}m. Move to an open area.'
                : 'Could not get any location within $_maximumWaitSeconds seconds. Please try again.';
            SnackBarUtils.showSnackBar(
              context,
              'Timeout reached. $accuracyMessage',
              isError: true,
            );
            print('DEBUG: Timeout: Accuracy not met. SnackBar shown.');
          } else if (mounted && _currentPosition != null) {
            SnackBarUtils.showSnackBar(
              context,
              'Location acquired with best available accuracy: ${_currentPosition!.accuracy.toStringAsFixed(2)}m.',
              isError: false,
            );
            print(
              'DEBUG: Timeout: Accuracy met (or best available). SnackBar shown.',
            );
          }
        }
      });
    } catch (e) {
      print(
        'DEBUG ERROR: An unexpected error occurred while starting location: $e',
      );
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'An unexpected error occurred while starting location: ${e.toString()}',
          isError: true,
        );
        setState(() {
          _isFetchingLocation = false;
          _isLocationAccurateEnough = false;
        });
      }
      _positionStreamSubscription?.cancel();
      _accuracyTimeoutTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Determine accuracy status text for display
    String accuracyStatusText;
    Color accuracyStatusColor;
    if (_isFetchingLocation) {
      accuracyStatusText =
          'Fetching... Current: ${_currentPosition?.accuracy.toStringAsFixed(2) ?? 'N/A'}m';
      accuracyStatusColor = colorScheme.onSurface.withOpacity(0.6);
    } else if (_currentPosition == null) {
      accuracyStatusText = 'No location obtained.';
      accuracyStatusColor = colorScheme.error;
    } else if (_currentPosition!.accuracy <= _requiredAccuracyForCapture) {
      accuracyStatusText =
          'Achieved: ${_currentPosition!.accuracy.toStringAsFixed(2)}m (Required < ${_requiredAccuracyForCapture.toStringAsFixed(1)}m)';
      accuracyStatusColor = colorScheme.secondary;
    } else {
      accuracyStatusText =
          'Current: ${_currentPosition!.accuracy.toStringAsFixed(2)}m (Required < ${_requiredAccuracyForCapture.toStringAsFixed(1)}m)';
      accuracyStatusColor = colorScheme.tertiary;
    }

    if (_isLoading) {
      // This covers the initial data load and the save operations
      print(
        'DEBUG: Building screen. _isLoading is true, showing full screen spinner.',
      );
      return const Center(child: CircularProgressIndicator());
    }
    print('DEBUG: Building screen. _isLoading is false, showing form.');

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

                  // Area Selection (TextFormField that acts like a button)
                  TextFormField(
                    controller: _areaController,
                    readOnly: true,
                    onTap: _selectArea,
                    decoration: InputDecoration(
                      labelText: 'Assigned Area',
                      prefixIcon: Icon(Icons.map, color: colorScheme.primary),
                      suffixIcon: Icon(
                        Icons.arrow_drop_down,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    validator: (value) =>
                        _selectedArea == null ? 'Please select an area' : null,
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
                  // Get Current Location Button with in-button spinner and text
                  ElevatedButton.icon(
                    onPressed: _isFetchingLocation
                        ? null
                        : _getCurrentLocation, // Disable when fetching
                    icon:
                        _isFetchingLocation // Conditionally show spinner or icon
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Icon(Icons.gps_fixed, color: colorScheme.onPrimary),
                    label: Text(
                      _isFetchingLocation
                          ? 'Fetching Location...'
                          : 'Get Current Location', // Change text based on state
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // GPS Coordinates Display Card
                  Card(
                    elevation: 2,
                    color: colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current GPS Coordinates:',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(color: colorScheme.primary),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Lat: ${_currentPosition?.latitude.toStringAsFixed(6) ?? 'N/A'}\n'
                            'Lon: ${_currentPosition?.longitude.toStringAsFixed(6) ?? 'N/A'}',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: colorScheme.onSurface),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            accuracyStatusText,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: accuracyStatusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (_accuracyTimeoutTimer != null &&
                              _accuracyTimeoutTimer!.isActive)
                            Text(
                              'Timeout in ${_maximumWaitSeconds - (_accuracyTimeoutTimer?.tick ?? 0)}s',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.tertiary,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                        ],
                      ),
                    ),
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
                    decoration: InputDecoration(
                      labelText:
                          'Total Connected Capacity (MVA) (Auto-calculated)',
                      prefixIcon: Icon(
                        Icons.power_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: false, // Make it non-editable
                    controller: TextEditingController(
                      text: "Auto-calculated from Transformers",
                    ), // Display fixed text
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
                    // Button logic for Save/Update operation
                    onPressed: _isSaving || _isLoading
                        ? null
                        : _saveSubstation, // Disable if saving or initial loading
                    icon:
                        _isSaving // Show spinner if saving
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Icon(
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
                      final String cityName =
                          _allCitiesFromDB
                              .firstWhereOrNull(
                                (c) => c.id == substation.cityId,
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
                            '${substation.voltageLevels.join(', ')} | Area: $areaName | City: $cityName | Comm. ${substation.yearOfCommissioning}',
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

// Area Single-Select Modal
class _AreaSingleSelectModal extends StatefulWidget {
  final List<Area> availableAreas;
  final Area? initialSelectedArea;

  const _AreaSingleSelectModal({
    required this.availableAreas,
    this.initialSelectedArea,
  });

  @override
  _AreaSingleSelectModalState createState() => _AreaSingleSelectModalState();
}

class _AreaSingleSelectModalState extends State<_AreaSingleSelectModal> {
  final TextEditingController _searchController = TextEditingController();
  List<Area> _filteredAreas = [];
  Area? _currentSelectedArea;

  @override
  void initState() {
    super.initState();
    _currentSelectedArea = widget.initialSelectedArea;
    _filteredAreas = List.from(widget.availableAreas);
    _searchController.addListener(_filterAreas);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterAreas);
    _searchController.dispose();
    super.dispose();
  }

  void _filterAreas() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAreas = widget.availableAreas.where((area) {
        return area.name.toLowerCase().contains(query);
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
          Text('Select Area', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Area',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _filteredAreas.isEmpty
                ? const Center(child: Text('No areas found.'))
                : ListView.builder(
                    itemCount: _filteredAreas.length,
                    itemBuilder: (context, index) {
                      final area = _filteredAreas[index];
                      return RadioListTile<Area>(
                        title: Text('${area.name} (${area.areaPurpose})'),
                        value: area,
                        groupValue: _currentSelectedArea,
                        onChanged: (Area? selected) {
                          setState(() {
                            _currentSelectedArea = selected;
                          });
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, _currentSelectedArea);
            },
            child: const Text('Confirm Selection'),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
