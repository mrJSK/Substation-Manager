// lib/screens/equipment_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:substation_manager/models/equipment.dart';
import 'package:substation_manager/models/master_equipment_template.dart'; // Import MasterEquipmentTemplate
import 'package:substation_manager/services/equipment_firestore_service.dart';
import 'package:substation_manager/services/core_firestore_service.dart'; // Import CoreFirestoreService
import 'package:substation_manager/utils/snackbar_utils.dart';
import 'package:intl/intl.dart'; // For date formatting

class EquipmentDetailScreen extends StatefulWidget {
  final Equipment equipment;
  final String substationName; // Pass substation name for display
  final String bayName; // Pass bay name for display

  const EquipmentDetailScreen({
    super.key,
    required this.equipment,
    required this.substationName,
    required this.bayName,
  });

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _yearOfManufacturingController;
  late TextEditingController _yearOfCommissioningController;
  late TextEditingController _makeController;
  late TextEditingController _serialNumberController;
  late TextEditingController _ratedVoltageController;
  late TextEditingController _ratedCurrentController;
  late TextEditingController _phaseConfigurationController;
  late String _status;

  // New: To hold the custom field values for editing
  late Map<String, dynamic> _editableCustomFieldValues;
  late List<Map<String, dynamic>> _editableRelays;
  late List<Map<String, dynamic>> _editableEnergyMeters;

  MasterEquipmentTemplate? _masterTemplate; // To hold the fetched template

  bool _isLoadingTemplate = true;
  bool _isSaving = false;

  final EquipmentFirestoreService _equipmentFirestoreService =
      EquipmentFirestoreService();
  final CoreFirestoreService _coreFirestoreService = CoreFirestoreService();

  // Categories for custom fields (copied from master_equipment_management_screen)
  final List<String> _fieldCategories = const [
    'Specification',
    'Daily Reading',
    'Operational',
  ];

  // Data types for custom fields (copied from master_equipment_management_screen)
  final List<String> _dataTypes = const [
    'text',
    'number',
    'dropdown',
    'boolean',
    'date',
    'time',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.equipment.name);
    _yearOfManufacturingController = TextEditingController(
      text: widget.equipment.yearOfManufacturing?.toString() ?? '',
    );
    _yearOfCommissioningController = TextEditingController(
      text: widget.equipment.yearOfCommissioning?.toString() ?? '',
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
    _phaseConfigurationController = TextEditingController(
      text: widget.equipment.phaseConfiguration,
    );
    _status = widget.equipment.status ?? 'Active'; // Default status

    // Initialize editable custom field values from the equipment
    _editableCustomFieldValues = Map.from(widget.equipment.customFieldValues);
    _editableRelays = List<Map<String, dynamic>>.from(
      widget.equipment.relays.map((r) => Map<String, dynamic>.from(r)),
    );
    _editableEnergyMeters = List<Map<String, dynamic>>.from(
      widget.equipment.energyMeters.map((m) => Map<String, dynamic>.from(m)),
    );

    _loadMasterTemplate();
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
    _phaseConfigurationController.dispose();
    super.dispose();
  }

  Future<void> _loadMasterTemplate() async {
    setState(() {
      _isLoadingTemplate = true;
    });
    try {
      // Use getUserProfileOnce as this is a one-time fetch for the template
      // MasterEquipmentTemplates are stored at root level, not under user profiles
      // Corrected call: getMasterEquipmentTemplateStream for a single document
      _coreFirestoreService.getMasterEquipmentTemplatesStream().listen((
        templates,
      ) {
        if (mounted) {
          setState(() {
            _masterTemplate = templates.firstWhere(
              (template) => template.id == widget.equipment.masterTemplateId,
              orElse: () => throw Exception(
                'Master template not found for ID: ${widget.equipment.masterTemplateId}',
              ),
            );
            _isLoadingTemplate = false;

            // Ensure custom fields from template are initialized in editable values
            // This is a crucial part: populate _editableCustomFieldValues with keys from template fields
            // if they don't already exist from the equipment's saved values.
            for (var fieldDef in _masterTemplate!.equipmentCustomFields) {
              if (!_editableCustomFieldValues.containsKey(fieldDef['name'])) {
                _editableCustomFieldValues[fieldDef['name']] =
                    null; // Initialize with null or default value
              }
            }

            // Similarly for relays and energy meters: ensure instances exist and fields are initialized
            _initializeDefinedInstances();
          });
        }
      });
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Error loading master template: ${e.toString()}',
          isError: true,
        );
        setState(() {
          _isLoadingTemplate = false;
          _masterTemplate = null; // Set to null on error
        });
      }
      debugPrint('Error loading master template: $e');
    }
  }

  void _initializeDefinedInstances() {
    // Initialize defined relays based on master template
    if (_masterTemplate != null && _masterTemplate!.definedRelays.isNotEmpty) {
      for (var templateRelayDef in _masterTemplate!.definedRelays) {
        // Find if an instance of this relay already exists in _editableRelays
        bool found = false;
        for (var existingRelayInstance in _editableRelays) {
          if (existingRelayInstance['name'] == templateRelayDef['name']) {
            found = true;
            // Ensure all fields from template def exist in instance field_values
            Map<String, dynamic> instanceFieldValues =
                existingRelayInstance['field_values'] ?? {};
            for (var fieldDef
                in (templateRelayDef['fields'] as List<dynamic>)) {
              if (!instanceFieldValues.containsKey(fieldDef['name'])) {
                instanceFieldValues[fieldDef['name']] = null;
              }
            }
            existingRelayInstance['field_values'] = instanceFieldValues;
            break;
          }
        }
        if (!found) {
          // If not found, create a new instance based on the template definition
          _editableRelays.add({
            'name': templateRelayDef['name'],
            'field_values': _createInitialFieldValues(
              templateRelayDef['fields'],
            ),
          });
        }
      }
      // Remove any _editableRelays instances that are no longer in the template's definedRelays
      _editableRelays.retainWhere(
        (relayInstance) => _masterTemplate!.definedRelays.any(
          (templateDef) => templateDef['name'] == relayInstance['name'],
        ),
      );
    } else {
      _editableRelays = []; // No defined relays in template
    }

    // Initialize defined energy meters based on master template
    if (_masterTemplate != null &&
        _masterTemplate!.definedEnergyMeters.isNotEmpty) {
      for (var templateMeterDef in _masterTemplate!.definedEnergyMeters) {
        bool found = false;
        for (var existingMeterInstance in _editableEnergyMeters) {
          if (existingMeterInstance['name'] == templateMeterDef['name']) {
            found = true;
            Map<String, dynamic> instanceFieldValues =
                existingMeterInstance['field_values'] ?? {};
            for (var fieldDef
                in (templateMeterDef['fields'] as List<dynamic>)) {
              if (!instanceFieldValues.containsKey(fieldDef['name'])) {
                instanceFieldValues[fieldDef['name']] = null;
              }
            }
            existingMeterInstance['field_values'] = instanceFieldValues;
            break;
          }
        }
        if (!found) {
          _editableEnergyMeters.add({
            'name': templateMeterDef['name'],
            'field_values': _createInitialFieldValues(
              templateMeterDef['fields'],
            ),
          });
        }
      }
      _editableEnergyMeters.retainWhere(
        (meterInstance) => _masterTemplate!.definedEnergyMeters.any(
          (templateDef) => templateDef['name'] == meterInstance['name'],
        ),
      );
    } else {
      _editableEnergyMeters = []; // No defined energy meters in template
    }

    // Trigger UI refresh after initializing
    setState(() {});
  }

  Map<String, dynamic> _createInitialFieldValues(
    List<dynamic> fieldDefinitions,
  ) {
    Map<String, dynamic> values = {};
    for (var fieldDef in fieldDefinitions) {
      values[fieldDef['name']] = null; // Default to null
    }
    return values;
  }

  Future<void> _saveEquipment() async {
    if (!mounted) return;
    if (!_formKey.currentState!.validate()) {
      SnackBarUtils.showSnackBar(
        context,
        'Please correct the errors in the form.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedEquipment = widget.equipment.copyWith(
        name: _nameController.text.trim(),
        yearOfManufacturing: int.tryParse(
          _yearOfManufacturingController.text.trim(),
        ),
        yearOfCommissioning: int.tryParse(
          _yearOfCommissioningController.text.trim(),
        ),
        make: _makeController.text.trim(),
        serialNumber: _serialNumberController.text.trim(),
        ratedVoltage: _ratedVoltageController.text.trim(),
        ratedCurrent: _ratedCurrentController.text.trim(),
        status: _status,
        phaseConfiguration: _phaseConfigurationController.text.trim(),
        customFieldValues: _editableCustomFieldValues,
        relays: _editableRelays, // Save updated relays
        energyMeters: _editableEnergyMeters, // Save updated energy meters
      );

      await _equipmentFirestoreService.updateEquipment(updatedEquipment);

      if (mounted) {
        SnackBarUtils.showSnackBar(context, 'Equipment updated successfully!');
        Navigator.pop(context); // Go back after saving
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Error updating equipment: ${e.toString()}',
          isError: true,
        );
      }
      debugPrint('Error updating equipment: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (_isLoadingTemplate) {
      return Scaffold(
        appBar: AppBar(title: const Text('Equipment Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_masterTemplate == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Equipment Details')),
        body: Center(
          child: Text(
            'Error: Master Equipment Template not found for this equipment.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Equipment Details')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  _buildSectionHeader(
                    'Basic Information',
                    Icons.info,
                    colorScheme,
                  ),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Equipment Name',
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Name is required'
                        : null,
                  ),
                  TextFormField(
                    controller: _yearOfManufacturingController,
                    decoration: const InputDecoration(
                      labelText: 'Year of Manufacturing',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: _yearOfCommissioningController,
                    decoration: const InputDecoration(
                      labelText: 'Year of Commissioning',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: _makeController,
                    decoration: const InputDecoration(labelText: 'Make'),
                  ),
                  TextFormField(
                    controller: _serialNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Serial Number',
                    ),
                  ),
                  TextFormField(
                    controller: _ratedVoltageController,
                    decoration: const InputDecoration(
                      labelText: 'Rated Voltage',
                    ),
                  ),
                  TextFormField(
                    controller: _ratedCurrentController,
                    decoration: const InputDecoration(
                      labelText: 'Rated Current',
                    ),
                  ),
                  TextFormField(
                    controller: _phaseConfigurationController,
                    decoration: const InputDecoration(
                      labelText: 'Phase Configuration',
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: ['Active', 'Inactive', 'Under Maintenance']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _status = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Dynamically build custom fields based on the MasterEquipmentTemplate
                  _buildSectionHeader(
                    'Custom Fields',
                    Icons.settings_input_component,
                    colorScheme,
                  ),
                  ..._masterTemplate!.equipmentCustomFields.map((fieldDef) {
                    return _buildCustomFormField(
                      fieldDef,
                      _editableCustomFieldValues,
                      colorScheme,
                    );
                  }),
                  const SizedBox(height: 20),

                  // Dynamically build Relay Instances and their custom fields
                  if (_masterTemplate!.definedRelays.isNotEmpty) ...[
                    _buildSectionHeader(
                      'Relay Details',
                      Icons.power,
                      colorScheme,
                    ),
                    ..._editableRelays.map((relayInstance) {
                      final templateRelayDef = _masterTemplate!.definedRelays
                          .firstWhere(
                            (def) => def['name'] == relayInstance['name'],
                            orElse: () => {
                              'name': 'Unknown Relay',
                              'fields': [],
                            },
                          );
                      return _buildDefinedInstanceCard(
                        relayInstance,
                        templateRelayDef,
                        colorScheme,
                        'Relay',
                      );
                    }),
                    const SizedBox(height: 20),
                  ],

                  // Dynamically build Energy Meter Instances and their custom fields
                  if (_masterTemplate!.definedEnergyMeters.isNotEmpty) ...[
                    _buildSectionHeader(
                      'Energy Meter Details',
                      Icons.electric_meter,
                      colorScheme,
                    ),
                    ..._editableEnergyMeters.map((meterInstance) {
                      final templateMeterDef = _masterTemplate!
                          .definedEnergyMeters
                          .firstWhere(
                            (def) => def['name'] == meterInstance['name'],
                            orElse: () => {
                              'name': 'Unknown Meter',
                              'fields': [],
                            },
                          );
                      return _buildDefinedInstanceCard(
                        meterInstance,
                        templateMeterDef,
                        colorScheme,
                        'Meter',
                      );
                    }),
                    const SizedBox(height: 20),
                  ],

                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveEquipment,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  /// Builds a dynamic form field based on the field definition from MasterEquipmentTemplate.
  Widget _buildCustomFormField(
    Map<String, dynamic> fieldDef,
    Map<String, dynamic> valuesMap, // The map to store the values
    ColorScheme colorScheme,
  ) {
    final String fieldName = fieldDef['name'] as String;
    final String dataType = fieldDef['dataType'] as String;
    final bool isMandatory = fieldDef['isMandatory'] as bool;
    final String? units = fieldDef['units'] as String?;
    final List<String> options = List<String>.from(fieldDef['options'] ?? []);
    final String category = fieldDef['category'] as String? ?? 'Specification';

    // Get current value from the valuesMap
    dynamic currentValue = valuesMap[fieldName];

    // Validator function based on mandatory flag
    validator(value) {
      if (isMandatory && (value == null || value.trim().isEmpty)) {
        return '$fieldName is required';
      }
      // Add more specific validation based on dataType if needed
      return null;
    }

    // Helper to update the value in the valuesMap
    void updateValue(dynamic newValue) {
      setState(() {
        valuesMap[fieldName] = newValue;
      });
    }

    Widget fieldWidget;

    switch (dataType) {
      case 'text':
        fieldWidget = TextFormField(
          initialValue: currentValue?.toString() ?? '',
          decoration: InputDecoration(
            labelText:
                '$fieldName ${units != null && units.isNotEmpty ? '($units)' : ''}',
            border: const OutlineInputBorder(),
          ),
          onChanged: updateValue,
          validator: validator,
        );
        break;
      case 'number':
        fieldWidget = TextFormField(
          initialValue: currentValue?.toString() ?? '',
          decoration: InputDecoration(
            labelText:
                '$fieldName ${units != null && units.isNotEmpty ? '($units)' : ''}',
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (val) => updateValue(num.tryParse(val)), // Parse to num
          validator: (value) {
            if (isMandatory && (value == null || value.trim().isEmpty)) {
              return '$fieldName is required';
            }
            if (value != null &&
                value.isNotEmpty &&
                num.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        );
        break;
      case 'dropdown':
        fieldWidget = DropdownButtonFormField<String>(
          value: currentValue?.toString(),
          decoration: InputDecoration(
            labelText:
                '$fieldName ${units != null && units.isNotEmpty ? '($units)' : ''}',
            border: const OutlineInputBorder(),
          ),
          items: options.map((option) {
            return DropdownMenuItem(value: option, child: Text(option));
          }).toList(),
          onChanged: (newValue) => updateValue(newValue),
          validator: validator,
        );
        break;
      case 'boolean':
        fieldWidget = CheckboxListTile(
          title: Text(fieldName),
          value: currentValue as bool? ?? false,
          onChanged: (newValue) => updateValue(newValue),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        );
        break;
      case 'date':
        fieldWidget = TextFormField(
          controller: TextEditingController(
            text: currentValue != null
                ? DateFormat('yyyy-MM-dd').format(DateTime.parse(currentValue))
                : '',
          ),
          readOnly: true,
          decoration: InputDecoration(
            labelText: fieldName,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(Icons.calendar_today, color: colorScheme.primary),
              onPressed: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: currentValue != null
                      ? DateTime.parse(currentValue)
                      : DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  updateValue(
                    pickedDate.toIso8601String(),
                  ); // Store as ISO String
                }
              },
            ),
          ),
          validator: validator,
        );
        break;
      case 'time':
        fieldWidget = TextFormField(
          controller: TextEditingController(
            text: currentValue != null
                ? TimeOfDay.fromDateTime(
                    DateTime.parse(currentValue),
                  ).format(context)
                : '',
          ),
          readOnly: true,
          decoration: InputDecoration(
            labelText: fieldName,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(Icons.access_time, color: colorScheme.primary),
              onPressed: () async {
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: currentValue != null
                      ? TimeOfDay.fromDateTime(DateTime.parse(currentValue))
                      : TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  final now = DateTime.now();
                  final dt = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );
                  updateValue(dt.toIso8601String()); // Store as ISO String
                }
              },
            ),
          ),
          validator: validator,
        );
        break;
      default:
        fieldWidget = Text('Unsupported data type: $dataType for $fieldName');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: fieldWidget,
    );
  }

  /// Builds a card for a defined Relay or Energy Meter instance with its custom fields.
  Widget _buildDefinedInstanceCard(
    Map<String, dynamic> instanceData,
    Map<String, dynamic> templateDefinition,
    ColorScheme colorScheme,
    String instanceType, // e.g., 'Relay' or 'Meter'
  ) {
    // Get the name from instanceData, fallback to template definition or default
    final String instanceName =
        instanceData['name'] as String? ??
        templateDefinition['name'] as String? ??
        'Unnamed $instanceType';

    // Get the field definitions from the template
    final List<dynamic> fieldDefs =
        templateDefinition['fields'] as List<dynamic>? ?? [];

    // Get the editable field values for this specific instance
    Map<String, dynamic> instanceFieldValues =
        instanceData['field_values'] as Map<String, dynamic>? ?? {};

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              instanceName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: colorScheme.secondary),
            ),
            const Divider(),
            if (fieldDefs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'No custom fields defined for this $instanceType type.',
                ),
              ),
            ...fieldDefs.map((fieldDef) {
              return _buildCustomFormField(
                Map<String, dynamic>.from(fieldDef),
                instanceFieldValues,
                colorScheme,
              );
            }),
            // No add/remove buttons here, as instances are determined by template
            // and their fields are defined by the template.
          ],
        ),
      ),
    );
  }
}
