// lib/screens/equipment_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:substation_manager/models/equipment.dart';
import 'package:substation_manager/models/master_equipment_template.dart';
import 'package:substation_manager/services/core_firestore_service.dart';
import 'package:substation_manager/services/equipment_firestore_service.dart'; // Using specific equipment service
import 'package:substation_manager/utils/snackbar_utils.dart';
import 'dart:convert'; // For jsonEncode/Decode if needed (already in model)

class EquipmentDetailScreen extends StatefulWidget {
  final Equipment equipment;

  const EquipmentDetailScreen({super.key, required this.equipment});

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true; // Overall loading state
  MasterEquipmentTemplate? _equipmentTemplate;

  final CoreFirestoreService _coreFirestoreService = CoreFirestoreService();
  final EquipmentFirestoreService _equipmentFirestoreService =
      EquipmentFirestoreService(); // Use specific service

  late TextEditingController _nameController;
  late TextEditingController _yearOfManufacturingController;
  late TextEditingController _yearOfCommissioningController;
  late TextEditingController _makeController;
  late TextEditingController _serialNumberController;
  late TextEditingController _ratedVoltageController;
  late TextEditingController _ratedCurrentController;
  String? _status;
  String? _phaseConfiguration;
  late TextEditingController _positionXController; // For editing position
  late TextEditingController _positionYController; // For editing position

  final Map<String, TextEditingController> _detailTextNumberControllers = {};
  final Map<String, bool> _detailBooleanValues = {};
  final Map<String, String?> _detailDropdownValues = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.equipment.name);
    _yearOfManufacturingController = TextEditingController(
      text: widget.equipment.yearOfManufacturing.toString(),
    );
    _yearOfCommissioningController = TextEditingController(
      text: widget.equipment.yearOfCommissioning.toString(),
    );
    _makeController = TextEditingController(text: widget.equipment.make);
    _serialNumberController = TextEditingController(
      text: widget.equipment.serialNumber,
    );
    _ratedVoltageController = TextEditingController(
      text: widget.equipment.ratedVoltage,
    );
    _ratedCurrentController = TextEditingController(
      text: widget.equipment.ratedCurrent,
    );
    _status = widget.equipment.status;
    _phaseConfiguration = widget.equipment.phaseConfiguration;
    _positionXController = TextEditingController(
      text: widget.equipment.positionX.toStringAsFixed(3),
    ); // Display with precision
    _positionYController = TextEditingController(
      text: widget.equipment.positionY.toStringAsFixed(3),
    );

    _loadEquipmentTemplate();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearOfManufacturingController.dispose();
    _yearOfCommissioningController.dispose();
    _makeController.dispose();
    _serialNumberController.dispose();
    _ratedVoltageController.dispose();
    _ratedCurrentController.dispose();
    _positionXController.dispose();
    _positionYController.dispose();
    _detailTextNumberControllers.forEach(
      (key, controller) => controller.dispose(),
    );
    super.dispose();
  }

  Future<void> _loadEquipmentTemplate() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final List<MasterEquipmentTemplate> templates =
          await _coreFirestoreService.getMasterEquipmentTemplatesOnce();
      _equipmentTemplate = templates.firstWhere(
        (template) => template.equipmentType == widget.equipment.equipmentType,
        orElse: () => throw Exception('No matching template found'),
      );

      _equipmentTemplate?.equipmentCustomFields.forEach((field) {
        final fieldName = field['name'] as String;
        final dataType = field['dataType'] as String;
        final currentValue = widget.equipment.details[fieldName];

        if (dataType == 'text' ||
            dataType == 'number' ||
            dataType == 'date' ||
            dataType == 'time') {
          _detailTextNumberControllers[fieldName] = TextEditingController(
            text: currentValue?.toString() ?? '',
          );
        } else if (dataType == 'boolean') {
          _detailBooleanValues[fieldName] = currentValue as bool? ?? false;
        } else if (dataType == 'dropdown') {
          _detailDropdownValues[fieldName] = currentValue as String?;
        }
      });
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Error loading equipment template: $e',
          isError: true,
        );
      }
      _equipmentTemplate = null;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveEquipmentDetails() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String newStatus = _status ?? 'Operational';
      String newPhaseConfiguration = _phaseConfiguration ?? 'Single Unit';

      Map<String, dynamic> updatedDetails = {};
      _equipmentTemplate?.equipmentCustomFields.forEach((field) {
        final fieldName = field['name'] as String;
        final dataType = field['dataType'] as String;

        if (dataType == 'text' || dataType == 'date' || dataType == 'time') {
          updatedDetails[fieldName] =
              _detailTextNumberControllers[fieldName]?.text;
        } else if (dataType == 'number') {
          updatedDetails[fieldName] = num.tryParse(
            _detailTextNumberControllers[fieldName]?.text ?? '',
          );
        } else if (dataType == 'boolean') {
          updatedDetails[fieldName] = _detailBooleanValues[fieldName];
        } else if (dataType == 'dropdown') {
          updatedDetails[fieldName] = _detailDropdownValues[fieldName];
        }
      });

      final updatedEquipment = widget.equipment.copyWith(
        name: _nameController.text.trim(),
        yearOfManufacturing:
            int.tryParse(_yearOfManufacturingController.text.trim()) ?? 0,
        yearOfCommissioning:
            int.tryParse(_yearOfCommissioningController.text.trim()) ?? 0,
        make: _makeController.text.trim(),
        serialNumber: _serialNumberController.text.trim().isEmpty
            ? null
            : _serialNumberController.text.trim(),
        ratedVoltage: _ratedVoltageController.text.trim(),
        ratedCurrent: _ratedCurrentController.text.trim().isEmpty
            ? null
            : _ratedCurrentController.text.trim(),
        status: newStatus,
        phaseConfiguration: newPhaseConfiguration,
        positionX: double.tryParse(_positionXController.text.trim()) ?? 0.0,
        positionY: double.tryParse(_positionYController.text.trim()) ?? 0.0,
        details: updatedDetails,
      );

      await _equipmentFirestoreService.updateEquipment(updatedEquipment);

      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Equipment details saved successfully!',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Error saving equipment details: $e',
          isError: true,
        );
      }
      print('Error saving equipment: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: colorScheme.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      isDense: true,
      labelStyle: TextStyle(
        color: colorScheme.primary.withOpacity(0.8),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('${widget.equipment.name} Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_equipmentTemplate == null) {
      return Scaffold(
        appBar: AppBar(title: Text('${widget.equipment.name} Details')),
        body: Center(
          child: Text(
            'No master template found for equipment type: ${widget.equipment.equipmentType}. Cannot display details.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: colorScheme.error),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('${widget.equipment.name} Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Equipment Specifications',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration(
                  'Equipment Name',
                  Icons.label,
                  colorScheme,
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Name cannot be empty' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _yearOfManufacturingController,
                decoration: _inputDecoration(
                  'Year of Manufacturing',
                  Icons.calendar_today,
                  colorScheme,
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty || int.tryParse(value) == null
                    ? 'Enter valid year'
                    : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _yearOfCommissioningController,
                decoration: _inputDecoration(
                  'Year of Commissioning',
                  Icons.event_available,
                  colorScheme,
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty || int.tryParse(value) == null
                    ? 'Enter valid year'
                    : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _makeController,
                decoration: _inputDecoration(
                  'Make',
                  Icons.business,
                  colorScheme,
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Make cannot be empty' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _serialNumberController,
                decoration: _inputDecoration(
                  'Serial Number',
                  Icons.qr_code,
                  colorScheme,
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _ratedVoltageController,
                decoration: _inputDecoration(
                  'Rated Voltage',
                  Icons.flash_on,
                  colorScheme,
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Rated Voltage cannot be empty' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _ratedCurrentController,
                decoration: _inputDecoration(
                  'Rated Current',
                  Icons.power,
                  colorScheme,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: _inputDecoration(
                  'Status',
                  Icons.info_outline,
                  colorScheme,
                ),
                items: ['Operational', 'Under Maintenance', 'Decommissioned']
                    .map(
                      (status) =>
                          DropdownMenuItem(value: status, child: Text(status)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _status = value),
                validator: (value) => value == null ? 'Select status' : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _phaseConfiguration,
                decoration: _inputDecoration(
                  'Phase Configuration',
                  Icons.settings_ethernet,
                  colorScheme,
                ),
                items: ['Single Unit', 'Three Units (R, Y, B)', 'Other']
                    .map(
                      (config) =>
                          DropdownMenuItem(value: config, child: Text(config)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _phaseConfiguration = value),
                validator: (value) =>
                    value == null ? 'Select phase configuration' : null,
              ),
              const SizedBox(height: 15),
              Text(
                'SLD Position (Relative 0.0-1.0)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _positionXController,
                      decoration: _inputDecoration(
                        'Position X',
                        Icons.horizontal_distribute,
                        colorScheme,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) =>
                          value!.isEmpty ||
                              double.tryParse(value) == null ||
                              double.parse(value) < 0 ||
                              double.parse(value) > 1
                          ? 'Enter 0.0-1.0'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: _positionYController,
                      decoration: _inputDecoration(
                        'Position Y',
                        Icons.vertical_distribute,
                        colorScheme,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) =>
                          value!.isEmpty ||
                              double.tryParse(value) == null ||
                              double.parse(value) < 0 ||
                              double.parse(value) > 1
                          ? 'Enter 0.0-1.0'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              Text(
                'Specific Details for ${widget.equipment.equipmentType}',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              ..._equipmentTemplate!.equipmentCustomFields.map((field) {
                final String fieldName = field['name'] as String;
                final String dataType = field['dataType'] as String;
                final bool isMandatory = field['isMandatory'] as bool;
                final String? units = field['units'] as String?;
                final List<String>? options =
                    (field['options'] as List<dynamic>?)?.cast<String>();

                switch (dataType) {
                  case 'text':
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: TextFormField(
                        controller: _detailTextNumberControllers[fieldName],
                        decoration: _inputDecoration(
                          '$fieldName ${units != null ? '($units)' : ''}',
                          Icons.text_fields,
                          colorScheme,
                        ),
                        validator: (value) => isMandatory && value!.isEmpty
                            ? '$fieldName is mandatory'
                            : null,
                      ),
                    );
                  case 'number':
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: TextFormField(
                        controller: _detailTextNumberControllers[fieldName],
                        decoration: _inputDecoration(
                          '$fieldName ${units != null ? '($units)' : ''}',
                          Icons.numbers,
                          colorScheme,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            isMandatory &&
                                (value!.isEmpty || num.tryParse(value) == null)
                            ? 'Enter valid $fieldName'
                            : null,
                      ),
                    );
                  case 'dropdown':
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: DropdownButtonFormField<String>(
                        value: _detailDropdownValues[fieldName],
                        decoration: _inputDecoration(
                          '$fieldName ${units != null ? '($units)' : ''}',
                          Icons.arrow_drop_down,
                          colorScheme,
                        ),
                        items: options!
                            .map(
                              (opt) => DropdownMenuItem(
                                value: opt,
                                child: Text(opt),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(
                          () => _detailDropdownValues[fieldName] = value,
                        ),
                        validator: (value) => isMandatory && value == null
                            ? 'Select $fieldName'
                            : null,
                      ),
                    );
                  case 'boolean':
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: CheckboxListTile(
                        title: Text(fieldName),
                        value: _detailBooleanValues[fieldName],
                        onChanged: (value) => setState(
                          () =>
                              _detailBooleanValues[fieldName] = value ?? false,
                        ),
                        activeColor: colorScheme.primary,
                      ),
                    );
                  case 'date':
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: InkWell(
                        onTap: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365 * 10),
                            ),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _detailTextNumberControllers[fieldName] =
                                  TextEditingController(
                                    text: pickedDate.toIso8601String().split(
                                      'T',
                                    )[0],
                                  );
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: _inputDecoration(
                            '$fieldName ${units != null ? '($units)' : ''}',
                            Icons.calendar_today,
                            colorScheme,
                          ),
                          child: Text(
                            _detailTextNumberControllers[fieldName]?.text ??
                                'Select Date',
                          ),
                        ),
                      ),
                    );
                  default:
                    return const SizedBox.shrink();
                }
              }),

              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveEquipmentDetails,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Saving...' : 'Save Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
