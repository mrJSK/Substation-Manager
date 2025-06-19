// lib/screens/sld_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Ensure provider is in pubspec.yaml
import 'package:substation_manager/models/area.dart';
import 'package:substation_manager/models/substation.dart';
import 'package:substation_manager/models/bay.dart'; // Import Bay model
import 'package:substation_manager/services/core_firestore_service.dart';
import 'package:substation_manager/utils/snackbar_utils.dart';
import 'package:substation_manager/screens/substation_sld_builder_screen.dart';
// Make sure the file 'substation_sld_builder_screen.dart' exists and exports 'SubstationSldBuilderScreen'

class SldSelectionScreen extends StatefulWidget {
  const SldSelectionScreen({super.key});

  @override
  State<SldSelectionScreen> createState() => _SldSelectionScreenState();
}

class _SldSelectionScreenState extends State<SldSelectionScreen> {
  final CoreFirestoreService _coreFirestoreService = CoreFirestoreService();
  List<Area> _areas = [];
  List<Substation> _substations = [];
  List<Bay> _bays = []; // State to hold bays

  Area? _selectedArea;
  Substation? _selectedSubstation;
  Bay? _selectedBay; // State for selected bay

  bool _isLoadingAreas = true;
  bool _isLoadingSubstations = false;
  bool _isLoadingBays = false; // Loading state for bays

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    setState(() {
      _isLoadingAreas = true;
    });
    try {
      _coreFirestoreService.getAreasStream().listen((areas) {
        if (mounted) {
          setState(() {
            _areas = areas;
            _isLoadingAreas = false;
            // Clear selections if areas change
            _selectedArea = null;
            _substations = [];
            _selectedSubstation = null;
            _bays = [];
            _selectedBay = null;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Error loading areas: ${e.toString()}',
          isError: true,
        );
        setState(() {
          _isLoadingAreas = false;
        });
      }
    }
  }

  Future<void> _loadSubstations(String areaId) async {
    setState(() {
      _isLoadingSubstations = true;
      _substations = []; // Clear previous substations
      _selectedSubstation = null;
      _bays = []; // Clear bays when substation changes
      _selectedBay = null;
    });
    try {
      final fetchedSubstations = await _coreFirestoreService
          .getSubstationsByAreaIds([areaId]);
      if (mounted) {
        setState(() {
          _substations = fetchedSubstations;
          _isLoadingSubstations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Error loading substations: ${e.toString()}',
          isError: true,
        );
        setState(() {
          _isLoadingSubstations = false;
        });
      }
    }
  }

  Future<void> _loadBays(String substationId) async {
    setState(() {
      _isLoadingBays = true;
      _bays = []; // Clear previous bays
      _selectedBay = null;
    });
    try {
      final fetchedBays = await _coreFirestoreService.getBaysOnce(
        substationId: substationId,
      );
      if (mounted) {
        setState(() {
          _bays = fetchedBays;
          _isLoadingBays = false;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Error loading bays: ${e.toString()}',
          isError: true,
        );
        setState(() {
          _isLoadingBays = false;
        });
      }
    }
  }

  void _navigateToSldBuilder() {
    if (_selectedSubstation != null && _selectedBay != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubstationSldBuilderScreen(
            substation: _selectedSubstation!,
            bay: _selectedBay!,
          ),
        ),
      );
    } else {
      SnackBarUtils.showSnackBar(
        context,
        'Please select an Area, Substation, and Bay.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Select SLD Location')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Location for SLD',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    // Area Dropdown
                    _isLoadingAreas
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<Area>(
                            value: _selectedArea,
                            decoration: InputDecoration(
                              labelText: 'Select Area',
                              border: const OutlineInputBorder(),
                              prefixIcon: Icon(
                                Icons.location_city,
                                color: colorScheme.primary,
                              ),
                            ),
                            hint: const Text('Select an Area'),
                            items: _areas.map((area) {
                              return DropdownMenuItem(
                                value: area,
                                child: Text(area.name),
                              );
                            }).toList(),
                            onChanged: (Area? newValue) {
                              setState(() {
                                _selectedArea = newValue;
                                _selectedSubstation = null;
                                _substations = []; // Clear substations
                                _selectedBay = null;
                                _bays = []; // Clear bays
                              });
                              if (newValue != null) {
                                _loadSubstations(newValue.id);
                              }
                            },
                            validator: (value) =>
                                value == null ? 'Area is required' : null,
                          ),
                    const SizedBox(height: 16),

                    // Substation Dropdown
                    _isLoadingSubstations
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<Substation>(
                            value: _selectedSubstation,
                            decoration: InputDecoration(
                              labelText: 'Select Substation',
                              border: const OutlineInputBorder(),
                              prefixIcon: Icon(
                                Icons.electrical_services,
                                color: colorScheme.primary,
                              ),
                            ),
                            hint: const Text('Select a Substation'),
                            items: _substations.map((substation) {
                              return DropdownMenuItem(
                                value: substation,
                                child: Text(substation.name),
                              );
                            }).toList(),
                            onChanged: _selectedArea == null
                                ? null
                                : (Substation? newValue) {
                                    setState(() {
                                      _selectedSubstation = newValue;
                                      _selectedBay = null;
                                      _bays = []; // Clear bays
                                    });
                                    if (newValue != null) {
                                      _loadBays(newValue.id);
                                    }
                                  },
                            validator: (value) =>
                                value == null ? 'Substation is required' : null,
                            isExpanded: true,
                          ),
                    const SizedBox(height: 16),

                    // Bay Dropdown
                    _isLoadingBays
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<Bay>(
                            value: _selectedBay,
                            decoration: InputDecoration(
                              labelText: 'Select Bay',
                              border: const OutlineInputBorder(),
                              prefixIcon: Icon(
                                Icons.architecture,
                                color: colorScheme.primary,
                              ),
                            ),
                            hint: const Text('Select a Bay'),
                            items: _bays.map((bay) {
                              return DropdownMenuItem(
                                value: bay,
                                child: Text('${bay.name} (${bay.type})'),
                              );
                            }).toList(),
                            onChanged: _selectedSubstation == null
                                ? null
                                : (Bay? newValue) {
                                    setState(() {
                                      _selectedBay = newValue;
                                    });
                                  },
                            validator: (value) =>
                                value == null ? 'Bay is required' : null,
                            isExpanded: true,
                          ),
                  ],
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _navigateToSldBuilder,
              icon: const Icon(Icons.design_services),
              label: const Text('Open SLD Builder'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
