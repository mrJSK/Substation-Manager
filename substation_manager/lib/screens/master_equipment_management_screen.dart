// lib/screens/master_equipment_management_screen.dart
// Placeholder for Master Equipment Management Screen

import 'package:flutter/material.dart';
import 'package:substation_manager/models/master_equipment_template.dart';
import 'package:substation_manager/services/core_firestore_service.dart';
import 'package:substation_manager/utils/snackbar_utils.dart';
import 'package:uuid/uuid.dart'; // For generating IDs
import 'package:substation_manager/data/master_equipment_definitions.dart'; // Import for masterEquipmentDefinitions

class MasterEquipmentManagementScreen extends StatefulWidget {
  const MasterEquipmentManagementScreen({super.key});

  @override
  State<MasterEquipmentManagementScreen> createState() =>
      _MasterEquipmentManagementScreenState();
}

class _MasterEquipmentManagementScreenState
    extends State<MasterEquipmentManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _equipmentTypeController =
      TextEditingController();

  List<Map<String, dynamic>> _customFields =
      []; // Fields for the current template being edited
  List<String> _associatedRelays = [];

  List<MasterEquipmentTemplate> _templates = [];
  bool _isLoading = true;
  MasterEquipmentTemplate? _templateToEdit;

  final CoreFirestoreService _coreFirestoreService = CoreFirestoreService();
  final Uuid _uuid = const Uuid();

  // List of pre-defined equipment types for dropdown (matching master_equipment_definitions.dart keys)
  final List<String> _predefinedEquipmentTypes = [
    'Power Transformer',
    'Circuit Breaker',
    'Isolator',
    'Current Transformer (CT)',
    'Voltage Transformer (VT/PT)',
    'Busbar',
    'Lightning Arrester (LA)',
    'Wave Trap',
    'Shunt Reactor',
    'Capacitor Bank',
    'Line',
    'Control Panel',
    'Relay Panel',
    'Battery Bank',
    'AC/DC Distribution Board',
    'Earthing System',
    'Energy Meter',
    'Auxiliary Transformer',
  ];

  // Data types for custom fields
  final List<String> _dataTypes = [
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
    _loadTemplates();
  }

  @override
  void dispose() {
    _equipmentTypeController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _coreFirestoreService.getMasterEquipmentTemplatesStream().listen((
        templates,
      ) {
        if (mounted) {
          setState(() {
            _templates = templates;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Error loading master templates: $e',
          isError: true,
        );
      }
      print('Error loading master equipment templates: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _editTemplate(MasterEquipmentTemplate template) {
    setState(() {
      _templateToEdit = template;
      _equipmentTypeController.text = template.equipmentType;
      _customFields = List.from(template.customFields);
      _associatedRelays = List.from(template.associatedRelays);
    });
  }

  void _clearForm() {
    setState(() {
      _templateToEdit = null;
      _equipmentTypeController.clear();
      _customFields = [];
      _associatedRelays = [];
      _formKey.currentState?.reset();
    });
  }

  void _addCustomField() {
    setState(() {
      _customFields.add({
        'name': '',
        'dataType': 'text',
        'isMandatory': false,
        'units': '',
        'options': [],
        'category': 'Specification', // Default category
      });
    });
  }

  void _removeCustomField(int index) {
    setState(() {
      _customFields.removeAt(index);
    });
  }

  void _addAssociatedRelay() {
    setState(() {
      _associatedRelays.add('');
    });
  }

  void _removeAssociatedRelay(int index) {
    setState(() {
      _associatedRelays.removeAt(index);
    });
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true; // Use loading state for saving
    });

    try {
      final String templateId =
          _templateToEdit?.id ??
          _equipmentTypeController.text.trim(); // Use equipmentType as ID
      final MasterEquipmentTemplate template = MasterEquipmentTemplate(
        id: templateId,
        equipmentType: _equipmentTypeController.text.trim(),
        customFields: _customFields,
        associatedRelays: _associatedRelays.where((r) => r.isNotEmpty).toList(),
      );

      if (_templateToEdit == null) {
        await _coreFirestoreService.addMasterEquipmentTemplate(template);
        if (mounted)
          SnackBarUtils.showSnackBar(
            context,
            'Master Equipment Template added successfully!',
          );
      } else {
        await _coreFirestoreService.updateMasterEquipmentTemplate(template);
        if (mounted)
          SnackBarUtils.showSnackBar(
            context,
            'Master Equipment Template updated successfully!',
          );
      }
      _clearForm();
    } catch (e) {
      if (mounted)
        SnackBarUtils.showSnackBar(
          context,
          'Error saving template: $e',
          isError: true,
        );
      print('Error saving master equipment template: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteTemplate(String id) async {
    final bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text(
              'Are you sure you want to delete this master equipment template? This cannot be undone.',
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
        await _coreFirestoreService.deleteMasterEquipmentTemplate(id);
        if (mounted)
          SnackBarUtils.showSnackBar(context, 'Template deleted successfully!');
      } catch (e) {
        if (mounted)
          SnackBarUtils.showSnackBar(
            context,
            'Error deleting template: $e',
            isError: true,
          );
        print('Error deleting master equipment template: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Master Equipment Management')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _templateToEdit == null
                  ? 'Define New Equipment Type'
                  : 'Edit Equipment Type',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _equipmentTypeController.text.isEmpty
                        ? null
                        : _equipmentTypeController.text,
                    decoration: InputDecoration(
                      labelText: 'Equipment Type',
                      prefixIcon: Icon(
                        Icons.category,
                        color: colorScheme.primary,
                      ),
                    ),
                    items: _predefinedEquipmentTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _equipmentTypeController.text = newValue ?? '';
                        // Optionally pre-populate custom fields from master_equipment_definitions.dart
                        _customFields = List.from(
                          masterEquipmentDefinitions[newValue] ?? [],
                        );
                      });
                    },
                    validator: (value) => value!.isEmpty
                        ? 'Equipment Type cannot be empty'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Custom Fields (Specifications & Readings)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _customFields.length,
                    itemBuilder: (context, index) {
                      final field = _customFields[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: field['name'] as String,
                                      decoration: const InputDecoration(
                                        labelText: 'Field Name',
                                      ),
                                      onChanged: (value) =>
                                          field['name'] = value,
                                      validator: (value) => value!.isEmpty
                                          ? 'Field name required'
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: field['dataType'] as String,
                                      decoration: const InputDecoration(
                                        labelText: 'Data Type',
                                      ),
                                      items: _dataTypes
                                          .map(
                                            (type) => DropdownMenuItem(
                                              value: type,
                                              child: Text(type),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) => setState(() {
                                        field['dataType'] = value;
                                        if (value != 'dropdown')
                                          field['options'] =
                                              []; // Clear options if not dropdown
                                      }),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _removeCustomField(index),
                                  ),
                                ],
                              ),
                              if (field['dataType'] == 'dropdown')
                                TextFormField(
                                  initialValue:
                                      (field['options'] as List<dynamic>?)
                                          ?.join(','),
                                  decoration: const InputDecoration(
                                    labelText: 'Options (comma-separated)',
                                  ),
                                  onChanged: (value) => field['options'] = value
                                      .split(',')
                                      .map((e) => e.trim())
                                      .toList(),
                                ),
                              TextFormField(
                                initialValue: field['units'] as String?,
                                decoration: const InputDecoration(
                                  labelText: 'Units (e.g., kV, Amps)',
                                ),
                                onChanged: (value) => field['units'] = value,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value:
                                          field['category'] as String? ??
                                          'Specification',
                                      decoration: const InputDecoration(
                                        labelText: 'Category',
                                      ),
                                      items:
                                          [
                                                'Specification',
                                                'Daily Reading',
                                                'Operational',
                                              ]
                                              .map(
                                                (cat) => DropdownMenuItem(
                                                  value: cat,
                                                  child: Text(cat),
                                                ),
                                              )
                                              .toList(),
                                      onChanged: (value) =>
                                          field['category'] = value,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: CheckboxListTile(
                                      title: const Text('Mandatory'),
                                      value: field['isMandatory'] as bool,
                                      onChanged: (value) => setState(
                                        () => field['isMandatory'] = value!,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  ElevatedButton.icon(
                    onPressed: _addCustomField,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Custom Field'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Associated Relays (for information)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _associatedRelays.length,
                    itemBuilder: (context, index) {
                      return Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _associatedRelays[index],
                              decoration: InputDecoration(
                                labelText: 'Relay Model ${index + 1}',
                              ),
                              onChanged: (value) =>
                                  _associatedRelays[index] = value,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _removeAssociatedRelay(index),
                          ),
                        ],
                      );
                    },
                  ),
                  ElevatedButton.icon(
                    onPressed: _addAssociatedRelay,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Associated Relay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          onPressed: _saveTemplate,
                          icon: Icon(
                            _templateToEdit == null ? Icons.add : Icons.save,
                          ),
                          label: Text(
                            _templateToEdit == null
                                ? 'Add Template'
                                : 'Update Template',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                  if (_templateToEdit != null)
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
              'Existing Master Equipment Templates',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _templates.isEmpty
                ? Center(
                    child: Text(
                      'No templates defined yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _templates.length,
                    itemBuilder: (context, index) {
                      final template = _templates[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 3,
                        child: ExpansionTile(
                          title: Text(
                            template.equipmentType,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            '${template.customFields.length} custom fields, ${template.associatedRelays.length} relays',
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Defined Fields:',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  ...template.customFields
                                      .map(
                                        (field) => Text(
                                          ' - ${field['name']} (${field['dataType']}) ${field['isMandatory'] ? '(Mandatory)' : ''}',
                                        ),
                                      )
                                      .toList(),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Associated Relays:',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  ...template.associatedRelays
                                      .map((relay) => Text(' - $relay'))
                                      .toList(),
                                ],
                              ),
                            ),
                          ],
                          trailing: PopupMenuButton<String>(
                            onSelected: (String result) {
                              if (result == 'edit') {
                                _editTemplate(template);
                              } else if (result == 'delete') {
                                _deleteTemplate(template.id);
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
