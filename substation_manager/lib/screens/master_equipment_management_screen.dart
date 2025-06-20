// lib/screens/master_equipment_management_screen.dart

import 'package:flutter/material.dart';
import 'package:substation_manager/models/master_equipment_template.dart';
import 'package:substation_manager/services/core_firestore_service.dart';
import 'package:substation_manager/utils/snackbar_utils.dart';
import 'package:uuid/uuid.dart'; // For generating IDs

// Define an enum for different views within the screen
enum MasterEquipmentViewMode {
  list, // Shows the list of existing templates
  form, // Shows the form to add/edit a template
}

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

  // Custom fields for the main equipment type
  List<Map<String, dynamic>> _equipmentCustomFields = [];

  // Lists to hold definitions of specific relay and energy meter instances
  // Each map represents an instance: {'name': String, 'fields': List<Map<String, dynamic>>}
  List<Map<String, dynamic>> _definedRelays = [];
  List<Map<String, dynamic>> _definedEnergyMeters = [];

  List<MasterEquipmentTemplate> _templates = [];
  bool _isLoading = true; // For initial data fetch
  MasterEquipmentTemplate?
  _templateToEdit; // Holds the template being edited (null for new)

  bool _isSaving = false; // Flag specifically for the save/update operation

  // State variable to control the current view mode
  MasterEquipmentViewMode _viewMode = MasterEquipmentViewMode.list;

  final CoreFirestoreService _coreFirestoreService = CoreFirestoreService();
  final Uuid _uuid = const Uuid(); // For generating unique IDs

  // Data types for custom fields (applicable to all custom fields)
  final List<String> _dataTypes = const [
    'text',
    'number',
    'dropdown',
    'boolean',
    'date',
    'time',
  ];

  // Categories for custom fields (e.g., for filtering/grouping in other parts of the app)
  final List<String> _fieldCategories = const [
    'Specification',
    'Daily Reading',
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

  /// Loads master equipment templates from Firestore.
  Future<void> _loadTemplates() async {
    if (!mounted) return; // Ensure the widget is still in the tree

    setState(() {
      _isLoading = true;
    });

    try {
      _coreFirestoreService.getMasterEquipmentTemplatesStream().listen(
        (templates) {
          if (mounted) {
            setState(() {
              _templates = templates;
              _isLoading = false; // Set loading to false once data is received
            });
          }
        },
        onError: (e) {
          if (mounted) {
            SnackBarUtils.showSnackBar(
              context,
              'Error loading master templates: ${e.toString()}',
              isError: true,
            );
          }
          debugPrint('Error loading master equipment templates: $e');
          if (mounted) {
            setState(() {
              _isLoading = false; // Set loading to false on error too
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Unexpected error loading master templates: ${e.toString()}',
          isError: true,
        );
      }
      debugPrint('Unexpected error in _loadTemplates setup: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Navigates to the form for editing an existing template.
  void _showFormForEdit(MasterEquipmentTemplate template) {
    setState(() {
      _viewMode = MasterEquipmentViewMode.form; // Switch to form view
      _templateToEdit = template;
      _equipmentTypeController.text = template.equipmentType;
      // Deep copy customFields from the template, including new 'hasUnits' property
      _equipmentCustomFields = List<Map<String, dynamic>>.from(
        template.equipmentCustomFields.map(
          (field) => Map<String, dynamic>.from(field)
            ..putIfAbsent(
              'hasUnits',
              () => (field['units'] as String?)?.isNotEmpty ?? false,
            ),
        ), // Initialize based on existing units
      );
      // Deep copy definedRelays and definedEnergyMeters
      _definedRelays = List<Map<String, dynamic>>.from(
        template.definedRelays.map(
          (relayDef) => {
            'name': relayDef['name'],
            'fields': List<Map<String, dynamic>>.from(
              relayDef['fields'].map(
                (f) => Map<String, dynamic>.from(f)
                  ..putIfAbsent(
                    'hasUnits',
                    () => (f['units'] as String?)?.isNotEmpty ?? false,
                  ),
              ),
            ), // Initialize based on existing units
          },
        ),
      );
      _definedEnergyMeters = List<Map<String, dynamic>>.from(
        template.definedEnergyMeters.map(
          (meterDef) => {
            'name': meterDef['name'],
            'fields': List<Map<String, dynamic>>.from(
              meterDef['fields'].map(
                (f) => Map<String, dynamic>.from(f)
                  ..putIfAbsent(
                    'hasUnits',
                    () => (f['units'] as String?)?.isNotEmpty ?? false,
                  ),
              ),
            ), // Initialize based on existing units
          },
        ),
      );
    });
  }

  /// Navigates to the form for adding a new template.
  void _showFormForNew() {
    setState(() {
      _viewMode = MasterEquipmentViewMode.form; // Switch to form view
      _clearForm(); // Clear the form for a new entry
    });
  }

  /// Navigates back to the list view and clears the form.
  void _showListView() {
    setState(() {
      _viewMode = MasterEquipmentViewMode.list; // Switch to list view
      _clearForm(); // Clear any form data when returning to list
    });
  }

  /// Clears all form fields and resets state related to template editing.
  void _clearForm() {
    setState(() {
      _templateToEdit = null;
      _equipmentTypeController.clear();
      _equipmentCustomFields = [];
      _definedRelays = []; // Clear defined relays
      _definedEnergyMeters = []; // Clear defined energy meters
      _formKey.currentState?.reset();
    });
  }

  /// Adds a new empty custom field to the specified list.
  void _addCustomField(List<Map<String, dynamic>> targetList) {
    setState(() {
      targetList.add({
        'name': '',
        'dataType': 'text',
        'isMandatory': false,
        'units': '', // Default empty unit
        'hasUnits': false, // New property for unit toggle
        'options': [],
        'category': 'Specification', // Default category
      });
    });
  }

  /// Removes a custom field at the given index from the specified list.
  void _removeCustomField(List<Map<String, dynamic>> targetList, int index) {
    setState(() {
      targetList.removeAt(index);
    });
  }

  /// Adds a new defined relay instance.
  void _addDefinedRelay() {
    setState(() {
      _definedRelays.add({
        'name': 'Relay ${_definedRelays.length + 1}',
        'fields': <Map<String, dynamic>>[], // Each relay has its own fields
      });
    });
  }

  /// Removes a defined relay instance.
  void _removeDefinedRelay(int index) {
    setState(() {
      _definedRelays.removeAt(index);
    });
  }

  /// Adds a new defined energy meter instance.
  void _addDefinedEnergyMeter() {
    setState(() {
      _definedEnergyMeters.add({
        'name': 'Meter ${_definedEnergyMeters.length + 1}',
        'fields': <Map<String, dynamic>>[], // Each meter has its own fields
      });
    });
  }

  /// Removes a defined energy meter instance.
  void _removeDefinedEnergyMeter(int index) {
    setState(() {
      _definedEnergyMeters.removeAt(index);
    });
  }

  /// Saves or updates a master equipment template.
  Future<void> _saveTemplate() async {
    if (!mounted) return; // Ensure the widget is still in the tree

    if (!_formKey.currentState!.validate()) {
      SnackBarUtils.showSnackBar(
        context,
        'Please correct the errors in the form.',
        isError: true,
      );
      return;
    }

    // Dismiss the keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true; // Use _isSaving flag for the save operation
    });

    try {
      // For new templates, generate a UUID. For existing, use the current ID.
      final String templateId = _templateToEdit?.id ?? _uuid.v4();

      final MasterEquipmentTemplate template = MasterEquipmentTemplate(
        id: templateId,
        equipmentType: _equipmentTypeController.text.trim(),
        equipmentCustomFields: _equipmentCustomFields
            .where((field) => (field['name'] as String).isNotEmpty)
            .map(
              (field) =>
                  Map<String, dynamic>.from(
                      field,
                    ) // Ensure deep copy and clean up before saving
                    ..remove('hasUnits'),
            ) // Remove temporary UI field
            .toList(),
        definedRelays: _definedRelays
            .where((relayDef) => (relayDef['name'] as String).isNotEmpty)
            .map(
              (relayDef) => {
                'name': relayDef['name'],
                // Ensure inner fields are also filtered for empty names and clean up 'hasUnits'
                'fields':
                    (relayDef['fields'] as List<dynamic>?)
                        ?.where((f) => (f['name'] as String).isNotEmpty)
                        .map(
                          (f) =>
                              Map<String, dynamic>.from(f)..remove('hasUnits'),
                        )
                        .toList() ??
                    [],
              },
            )
            .toList(),
        definedEnergyMeters: _definedEnergyMeters
            .where((meterDef) => (meterDef['name'] as String).isNotEmpty)
            .map(
              (meterDef) => {
                'name': meterDef['name'],
                // Ensure inner fields are also filtered for empty names and clean up 'hasUnits'
                'fields':
                    (meterDef['fields'] as List<dynamic>?)
                        ?.where((f) => (f['name'] as String).isNotEmpty)
                        .map(
                          (f) =>
                              Map<String, dynamic>.from(f)..remove('hasUnits'),
                        )
                        .toList() ??
                    [],
              },
            )
            .toList(),
      );

      if (_templateToEdit == null) {
        await _coreFirestoreService.addMasterEquipmentTemplate(template);
        if (mounted) {
          SnackBarUtils.showSnackBar(
            context,
            'Master Equipment Template added successfully!',
          );
        }
      } else {
        await _coreFirestoreService.updateMasterEquipmentTemplate(template);
        if (mounted) {
          SnackBarUtils.showSnackBar(
            context,
            'Master Equipment Template updated successfully!',
          );
        }
      }
      if (mounted) {
        _showListView(); // Go back to list view after saving
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Error saving template: ${e.toString()}',
          isError: true,
        );
      }
      debugPrint('Error saving master equipment template: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false; // Reset _isSaving flag
        });
      }
    }
  }

  /// Deletes a master equipment template after confirmation.
  Future<void> _deleteTemplate(String id) async {
    if (!mounted) return; // Ensure the widget is still in the tree

    final bool confirm =
        await showDialog<bool>(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false; // Default to false if dialog is dismissed

    if (confirm == true) {
      try {
        await _coreFirestoreService.deleteMasterEquipmentTemplate(id);
        if (mounted) {
          SnackBarUtils.showSnackBar(context, 'Template deleted successfully!');
        }
      } catch (e) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
            context,
            'Error deleting template: ${e.toString()}',
            isError: true,
          );
        }
        debugPrint('Error deleting master equipment template: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (_isLoading && _templates.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _viewMode == MasterEquipmentViewMode.list
              ? 'Master Equipment Management'
              : (_templateToEdit == null
                    ? 'Define New Equipment Type'
                    : 'Edit Equipment Type'),
        ),
        leading: _viewMode == MasterEquipmentViewMode.form
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _showListView,
              )
            : null,
      ),
      body: _viewMode == MasterEquipmentViewMode.list
          ? _buildListView(colorScheme)
          : _buildFormView(colorScheme),
      floatingActionButton: _viewMode == MasterEquipmentViewMode.list
          ? FloatingActionButton.extended(
              onPressed: _showFormForNew,
              label: const Text('Add New Type'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }

  /// Widget for the list view of master equipment templates.
  Widget _buildListView(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Text(
          'Existing Master Equipment Templates',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        _templates.isEmpty
            ? Center(
                child: Text(
                  'No templates defined yet. Tap "+" to add one.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
              )
            : Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const AlwaysScrollableScrollPhysics(),
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
                          '${template.equipmentCustomFields.length} equipment fields, '
                          '${template.definedRelays.length} defined relays, '
                          '${template.definedEnergyMeters.length} defined energy meters',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (String result) {
                            if (result == 'edit') {
                              _showFormForEdit(template);
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
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.delete,
                                      color: colorScheme.error,
                                    ),
                                    title: Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Equipment Custom Fields display
                                Text(
                                  'Equipment Fields:',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                if (template.equipmentCustomFields.isEmpty)
                                  const Text('  No equipment fields defined.'),
                                ...template.equipmentCustomFields.map(
                                  (field) => Text(
                                    ' - ${field['name']} (${field['dataType']}) ${field['isMandatory'] ? '(Mandatory)' : ''} [${field['category'] ?? 'N/A'}] ${(field['units'] as String?)?.isNotEmpty == true ? 'Units: ${field['units']}' : ''}',
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Defined Relays display
                                Text(
                                  'Defined Relays:',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                if (template.definedRelays.isEmpty)
                                  const Text('  No relays defined.'),
                                ...template.definedRelays.map(
                                  (relayDef) => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '  - ${relayDef['name']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if ((relayDef['fields'] as List).isEmpty)
                                        const Text(
                                          '    No custom fields for this relay.',
                                        ),
                                      ...((relayDef['fields'] as List<dynamic>))
                                          .map(
                                            (field) => Text(
                                              '    - ${field['name']} (${field['dataType']}) ${field['isMandatory'] ? '(Mandatory)' : ''} [${field['category'] ?? 'N/A'}] ${(field['units'] as String?)?.isNotEmpty == true ? 'Units: ${field['units']}' : ''}',
                                            ),
                                          ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Defined Energy Meters display
                                Text(
                                  'Defined Energy Meters:',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                if (template.definedEnergyMeters.isEmpty)
                                  const Text('  No energy meters defined.'),
                                ...template.definedEnergyMeters.map(
                                  (meterDef) => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '  - ${meterDef['name']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if ((meterDef['fields'] as List).isEmpty)
                                        const Text(
                                          '    No custom fields for this meter.',
                                        ),
                                      ...((meterDef['fields'] as List<dynamic>))
                                          .map(
                                            (field) => Text(
                                              '    - ${field['name']} (${field['dataType']}) ${field['isMandatory'] ? '(Mandatory)' : ''} [${field['category'] ?? 'N/A'}] ${(field['units'] as String?)?.isNotEmpty == true ? 'Units: ${field['units']}' : ''}',
                                            ),
                                          ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  /// Widget for the form view to add or edit a master equipment template.
  Widget _buildFormView(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _equipmentTypeController,
                      decoration: InputDecoration(
                        labelText: 'Equipment Type Name',
                        hintText: 'e.g., Power Transformer, Custom Breaker',
                        prefixIcon: Icon(
                          Icons.category,
                          color: colorScheme.primary,
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Equipment Type cannot be empty'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Section for Equipment Custom Fields
                    _buildCustomFieldsSection(
                      'Equipment Custom Fields',
                      _equipmentCustomFields,
                      colorScheme,
                      Icons.settings_input_component,
                    ),
                    const SizedBox(height: 20),

                    // Section for Defined Relays
                    Text(
                      'Defined Relay Instances',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _definedRelays.length,
                      itemBuilder: (context, index) {
                        return _buildDefinedRelayOrMeterCard(
                          'Relay', // Default name prefix
                          _definedRelays[index],
                          colorScheme,
                          onRemove: () => _removeDefinedRelay(index),
                        );
                      },
                    ),
                    ElevatedButton.icon(
                      onPressed: _addDefinedRelay,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Relay Instance'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: colorScheme.onSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section for Defined Energy Meters
                    Text(
                      'Defined Energy Meter Instances',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _definedEnergyMeters.length,
                      itemBuilder: (context, index) {
                        return _buildDefinedRelayOrMeterCard(
                          'Meter', // Default name prefix
                          _definedEnergyMeters[index],
                          colorScheme,
                          onRemove: () => _removeDefinedEnergyMeter(index),
                        );
                      },
                    ),
                    ElevatedButton.icon(
                      onPressed: _addDefinedEnergyMeter,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Energy Meter Instance'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: colorScheme.onSecondary,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Save/Update Button
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveTemplate,
                      icon: _isSaving
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
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget to build a section for adding/editing custom fields.
  /// This is for the main equipment custom fields.
  Widget _buildCustomFieldsSection(
    String title,
    List<Map<String, dynamic>> fieldsList,
    ColorScheme colorScheme,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: fieldsList.length,
          itemBuilder: (context, index) {
            final field = fieldsList[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: field['name'] as String,
                      decoration: InputDecoration(
                        labelText: 'Field Name',
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) => field['name'] = value,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Field name required'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: field['dataType'] as String,
                      decoration: InputDecoration(
                        labelText: 'Data Type',
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                      items: _dataTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(
                                type,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() {
                        field['dataType'] = value;
                        if (value != 'dropdown') {
                          field['options'] =
                              []; // Clear options if not dropdown
                        }
                      }),
                      isExpanded: true,
                    ),
                    const SizedBox(height: 10),
                    if (field['dataType'] == 'dropdown')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: TextFormField(
                          initialValue: (field['options'] as List<dynamic>?)
                              ?.join(','),
                          decoration: InputDecoration(
                            labelText: 'Options (comma-separated)',
                            hintText: 'e.g., Option1, Option2',
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (value) => field['options'] = value
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList(),
                        ),
                      ),
                    // New: Toggle for Units field visibility
                    CheckboxListTile(
                      title: const Text('Has Units?'),
                      value: field['hasUnits'] as bool,
                      onChanged: (value) => setState(() {
                        field['hasUnits'] = value!;
                        if (!value) {
                          field['units'] = ''; // Clear units if toggle is off
                        }
                      }),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                    if (field['hasUnits'] ==
                        true) // Conditionally display units field
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: TextFormField(
                          initialValue: field['units'] as String?,
                          decoration: InputDecoration(
                            labelText: 'Units (e.g., kV, Amps)',
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (value) => field['units'] = value,
                        ),
                      ),
                    DropdownButtonFormField<String>(
                      value: field['category'] as String? ?? 'Specification',
                      decoration: InputDecoration(
                        labelText: 'Category',
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                      items: _fieldCategories
                          .map(
                            (cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)),
                          )
                          .toList(),
                      onChanged: (value) => field['category'] = value,
                      isExpanded: true,
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      title: const Text('Mandatory'),
                      value: field['isMandatory'] as bool,
                      onChanged: (value) =>
                          setState(() => field['isMandatory'] = value!),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: colorScheme.error,
                        ),
                        onPressed: () => _removeCustomField(fieldsList, index),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        ElevatedButton.icon(
          onPressed: () => _addCustomField(fieldsList),
          icon: const Icon(Icons.add),
          label: Text('Add ${title.split(' ')[0]} Field'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.secondary,
            foregroundColor: colorScheme.onSecondary,
          ),
        ),
      ],
    );
  }

  /// Helper widget to build a card for a defined Relay or Energy Meter instance.
  /// It includes an editable name and a section for its custom fields.
  Widget _buildDefinedRelayOrMeterCard(
    String defaultNamePrefix, // e.g., "Relay" or "Meter"
    Map<String, dynamic> instanceDefinition,
    ColorScheme colorScheme, {
    required VoidCallback onRemove,
  }) {
    // Ensure 'fields' list exists in the instance definition map
    instanceDefinition.putIfAbsent('fields', () => <Map<String, dynamic>>[]);
    List<Map<String, dynamic>> instanceFields =
        instanceDefinition['fields'] as List<Map<String, dynamic>>;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: instanceDefinition['name'] as String,
                    decoration: InputDecoration(
                      labelText: '$defaultNamePrefix Name',
                      hintText:
                          'e.g., $defaultNamePrefix 1, Main $defaultNamePrefix',
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() {
                      instanceDefinition['name'] = value;
                    }),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Name cannot be empty'
                        : null,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: colorScheme.error),
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              'Custom Fields for ${instanceDefinition['name'] ?? defaultNamePrefix}',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Inner ListView for custom fields of THIS specific instance
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: instanceFields.length,
              itemBuilder: (context, index) {
                final field = instanceFields[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          initialValue: field['name'] as String,
                          decoration: InputDecoration(
                            labelText: 'Field Name',
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (value) => field['name'] = value,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Field name required'
                              : null,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: field['dataType'] as String,
                          decoration: InputDecoration(
                            labelText: 'Data Type',
                            isDense: true,
                            border: const OutlineInputBorder(),
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
                            if (value != 'dropdown') {
                              field['options'] = [];
                            }
                          }),
                          isExpanded: true,
                        ),
                        const SizedBox(height: 8),
                        if (field['dataType'] == 'dropdown')
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: TextFormField(
                              initialValue: (field['options'] as List<dynamic>?)
                                  ?.join(','),
                              decoration: InputDecoration(
                                labelText: 'Options (comma-separated)',
                                hintText: 'e.g., Option1, Option2',
                                isDense: true,
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (value) => field['options'] = value
                                  .split(',')
                                  .map((e) => e.trim())
                                  .where((e) => e.isNotEmpty)
                                  .toList(),
                            ),
                          ),
                        // New: Toggle for Units field visibility
                        CheckboxListTile(
                          title: const Text('Has Units?'),
                          value: field['hasUnits'] as bool,
                          onChanged: (value) => setState(() {
                            field['hasUnits'] = value!;
                            if (!value) {
                              field['units'] =
                                  ''; // Clear units if toggle is off
                            }
                          }),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                        if (field['hasUnits'] ==
                            true) // Conditionally display units field
                          TextFormField(
                            initialValue: field['units'] as String?,
                            decoration: InputDecoration(
                              labelText: 'Units (e.g., kV, Amps)',
                              isDense: true,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (value) => field['units'] = value,
                          ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value:
                              field['category'] as String? ?? 'Specification',
                          decoration: InputDecoration(
                            labelText: 'Category',
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                          items: _fieldCategories
                              .map(
                                (cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => field['category'] = value,
                          isExpanded: true,
                        ),
                        CheckboxListTile(
                          title: const Text('Mandatory'),
                          value: field['isMandatory'] as bool,
                          onChanged: (value) =>
                              setState(() => field['isMandatory'] = value!),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: Icon(
                              Icons.remove_circle_outline,
                              color: colorScheme.error,
                            ),
                            onPressed: () =>
                                _removeCustomField(instanceFields, index),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              onPressed: () => _addCustomField(instanceFields),
              icon: const Icon(Icons.add),
              label: Text(
                'Custom Field for ${instanceDefinition['name'] ?? defaultNamePrefix}',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.tertiary,
                foregroundColor: colorScheme.onTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
