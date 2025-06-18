// lib/screens/sld_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:substation_manager/models/area.dart';
import 'package:substation_manager/models/substation.dart';
import 'package:substation_manager/services/core_firestore_service.dart';
import 'package:substation_manager/utils/snackbar_utils.dart';
import 'package:substation_manager/screens/substation_sld_builder_screen.dart';
// For firstWhereOrNull

class SldSelectionScreen extends StatefulWidget {
  const SldSelectionScreen({super.key});

  @override
  State<SldSelectionScreen> createState() => _SldSelectionScreenState();
}

class _SldSelectionScreenState extends State<SldSelectionScreen> {
  final CoreFirestoreService _coreFirestoreService = CoreFirestoreService();
  List<Area> _allAreas = [];
  List<Substation> _allSubstations = [];
  List<Substation> _filteredSubstations = [];

  Area? _selectedArea;
  Substation? _selectedSubstation;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSelectionData();
  }

  Future<void> _loadSelectionData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _allAreas = await _coreFirestoreService.getAreasOnce();
      _allSubstations = await _coreFirestoreService.getSubstationsOnce();
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Error loading data: ${e.toString()}',
          isError: true,
        );
      }
      print('Error loading selection data for SLD: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onAreaSelected(Area? area) {
    setState(() {
      _selectedArea = area;
      _selectedSubstation = null; // Reset substation when area changes
      _filteredSubstations = _allSubstations
          .where((sub) => sub.areaId == _selectedArea?.id)
          .toList();
    });
  }

  void _onSubstationSelected(Substation? substation) {
    setState(() {
      _selectedSubstation = substation;
    });
  }

  void _navigateToSldBuilder() {
    if (_selectedSubstation == null) {
      SnackBarUtils.showSnackBar(
        context,
        'Please select a Substation first.',
        isError: true,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SubstationSLDBuilderScreen(substation: _selectedSubstation!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select SLD')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Select Substation for SLD')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose Area and Substation for SLD Builder',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Area Dropdown
            DropdownButtonFormField<Area>(
              value: _selectedArea,
              decoration: InputDecoration(
                labelText: 'Select Area',
                prefixIcon: Icon(Icons.map, color: colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _allAreas.map((area) {
                return DropdownMenuItem<Area>(
                  value: area,
                  child: Text(area.name),
                );
              }).toList(),
              onChanged: _onAreaSelected,
              validator: (value) =>
                  value == null ? 'Please select an area' : null,
            ),
            const SizedBox(height: 20),

            // Substation Dropdown (conditionally enabled)
            DropdownButtonFormField<Substation>(
              value: _selectedSubstation,
              decoration: InputDecoration(
                labelText: 'Select Substation',
                prefixIcon: Icon(Icons.factory, color: colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _filteredSubstations.map((substation) {
                return DropdownMenuItem<Substation>(
                  value: substation,
                  child: Text(substation.name),
                );
              }).toList(),
              onChanged: _selectedArea == null
                  ? null
                  : _onSubstationSelected, // Disable if no area selected
              validator: (value) =>
                  value == null ? 'Please select a substation' : null,
              hint: _selectedArea == null
                  ? const Text('Select an Area first')
                  : (_filteredSubstations.isEmpty
                        ? const Text('No substations in this area')
                        : const Text('Select Substation')),
            ),
            const SizedBox(height: 40),

            ElevatedButton.icon(
              onPressed: _selectedSubstation == null
                  ? null
                  : _navigateToSldBuilder,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Proceed to SLD Builder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
