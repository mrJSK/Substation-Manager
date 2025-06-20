// substation_manager/lib/screens/sld_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:substation_manager/models/area.dart';
import 'package:substation_manager/models/substation.dart';
import 'package:substation_manager/models/bay.dart'; // Keep import for model usage if needed elsewhere
import 'package:substation_manager/services/core_firestore_service.dart';
import 'package:substation_manager/utils/snackbar_utils.dart';
import 'package:substation_manager/screens/substation_sld_builder_screen.dart';
import 'package:substation_manager/state/sld_state.dart'; // <-- Add this import (adjust path if needed)

class SldSelectionScreen extends StatefulWidget {
  const SldSelectionScreen({super.key});

  @override
  State<SldSelectionScreen> createState() => _SldSelectionScreenState();
}

class _SldSelectionScreenState extends State<SldSelectionScreen> {
  final CoreFirestoreService _coreFirestoreService = CoreFirestoreService();
  List<Area> _areas = [];
  List<Substation> _substations = [];
  List<Bay> _bays =
      []; // Keep to load bays for the selected substation in memory if needed by builder screen logic

  Area? _selectedArea;
  Substation? _selectedSubstation;

  bool _isLoadingAreas = true;
  bool _isLoadingSubstations = false;
  bool _isLoadingBays = false; // Still needed if you fetch all bays for info

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  @override
  void dispose() {
    // No controllers or stream subscriptions directly here needing disposal
    super.dispose();
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
            _selectedArea = null;
            _substations = [];
            _selectedSubstation = null;
            _bays = [];
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
      _substations = [];
      _selectedSubstation = null;
      _bays = [];
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
      _bays = [];
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
    if (_selectedSubstation != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              // REMOVED: ChangeNotifierProvider wrapper here.
              // SldBuilderScreen will now use the SldState provided by main.dart.
              SldBuilderScreen(substation: _selectedSubstation!),
        ),
      );
    } else {
      SnackBarUtils.showSnackBar(
        context,
        'Please select an Area and Substation.',
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
                                _substations = [];
                                _bays = [];
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
                                      _bays = [];
                                    });
                                    if (newValue != null) {
                                      _loadBays(newValue.id);
                                    }
                                  },
                            validator: (value) =>
                                value == null ? 'Substation is required' : null,
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
