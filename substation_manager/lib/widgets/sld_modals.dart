// lib/widgets/sld_modals.dart

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:substation_manager/models/master_equipment_template.dart';
import 'package:substation_manager/models/equipment.dart';
import 'package:substation_manager/services/core_firestore_service.dart';
import 'package:substation_manager/services/equipment_firestore_service.dart';
import 'package:substation_manager/utils/snackbar_utils.dart';
import 'package:substation_manager/state/sld_state.dart';
import 'package:uuid/uuid.dart';

// --- Functions to show Modals ---

// Show Add Element Modal
Future<void> showAddElementModal(BuildContext context) async {
  final sldState = context.read<SldState>();
  sldState.setSelectedTemplateInModal(null);
  sldState.setSelectedEquipmentInModal(null);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (modalContext) {
      // Changed parameter name to modalContext to avoid conflict with inner build methods
      return SizedBox(
        height: MediaQuery.of(modalContext).size.height * 0.9,
        child: Consumer<SldState>(
          builder: (consumerContext, modalSldState, child) {
            // Changed parameter name to consumerContext
            final bool showTemplateProperties =
                modalSldState.selectedTemplateInModal != null;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(consumerContext).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 20,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        if (modalSldState.selectedTemplateInModal != null) {
                          modalSldState.setSelectedTemplateInModal(null);
                        } else {
                          Navigator.pop(consumerContext);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: showTemplateProperties
                        ? _buildPropertiesSection(
                            consumerContext, // Pass consumerContext
                            modalSldState,
                            Theme.of(consumerContext).colorScheme,
                          )
                        : _buildEquipmentTemplateSelectionSection(
                            consumerContext, // Pass consumerContext
                            modalSldState,
                            Theme.of(consumerContext).colorScheme,
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

// Show Edit Properties Modal
Future<void> showEditPropertiesModal(
  BuildContext context,
  Equipment equipmentToEdit,
) async {
  final sldState = context.read<SldState>();
  sldState.setSelectedEquipmentInModal(equipmentToEdit);
  sldState.setSelectedTemplateInModal(null);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (modalContext) {
      // Changed parameter name to modalContext
      return SizedBox(
        height: MediaQuery.of(modalContext).size.height * 0.9,
        child: Consumer<SldState>(
          builder: (consumerContext, modalSldState, child) {
            // Changed parameter name to consumerContext
            if (modalSldState.selectedEquipmentInModal == null) {
              return const Center(
                child: Text('No equipment selected for editing.'),
              );
            }
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(consumerContext).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 20,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pop(consumerContext);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _buildPropertiesSection(
                      consumerContext, // Pass consumerContext
                      modalSldState,
                      Theme.of(consumerContext).colorScheme,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

// Show Add Custom Field Dialog
Future<Map<String, dynamic>?> _showAddCustomFieldDialog(
  BuildContext context, // Now explicitly takes BuildContext
) async {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  String? selectedType;
  final List<String> fieldTypes = [
    'text',
    'number',
    'boolean',
    'dropdown',
    'date',
    'time',
  ];
  List<TextEditingController> optionControllers = [];
  bool isDropdown = false;

  return await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) {
      // Changed parameter name to dialogContext
      return StatefulBuilder(
        builder: (statefulContext, setDialogState) {
          // Changed parameter name to statefulContext
          return AlertDialog(
            title: const Text('Define New Custom Field'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Field Name'),
                    validator: (value) =>
                        value!.isEmpty ? 'Name cannot be empty' : null,
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Field Type'),
                    value: selectedType,
                    items: fieldTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedType = value;
                        isDropdown = (value == 'dropdown');
                        if (!isDropdown) {
                          optionControllers.clear();
                        } else if (optionControllers.isEmpty) {
                          optionControllers.add(TextEditingController());
                        }
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Select a type' : null,
                  ),
                  if (isDropdown) ...[
                    const SizedBox(height: 10),
                    Text('Dropdown Options:'),
                    ...optionControllers
                        .map(
                          (controller) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: TextFormField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: 'Option',
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    setDialogState(() {
                                      optionControllers.remove(controller);
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            optionControllers.add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Option'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final Map<String, dynamic> result = {
                      'name': nameController.text.trim(),
                      'dataType': selectedType,
                    };
                    if (isDropdown) {
                      result['options'] = optionControllers
                          .map((c) => c.text.trim())
                          .where((text) => text.isNotEmpty)
                          .toList();
                    }
                    Navigator.pop(dialogContext, result);
                  }
                },
                child: const Text('Add Field'),
              ),
            ],
          );
        },
      );
    },
  );
}

// --- Helper Widgets for Modals ---

Widget _buildEquipmentTemplateSelectionSection(
  BuildContext context, // Now explicitly takes BuildContext
  SldState sldState,
  ColorScheme colorScheme,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Select Element to Add',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      sldState.isLoadingTemplates
          ? const Center(child: CircularProgressIndicator())
          : Expanded(
              child: ListView(
                children: [
                  // Removed 'Add New Bay' option as per previous request to remove bay UI for now.
                  // ListTile(
                  //   leading: Icon(
                  //     Icons.architecture,
                  //     color: colorScheme.secondary,
                  //   ),
                  //   title: const Text('Add New Bay'),
                  //   onTap: () async {
                  //     Navigator.pop(context); // Close modal
                  //     _onBayDropped(
                  //       context,
                  //       const Offset(100, 100),
                  //       'Generic',
                  //     );
                  //   },
                  // ),
                  // const Divider(),
                  ...sldState.availableTemplates.map((template) {
                    return ListTile(
                      leading: Icon(
                        _getIconForEquipmentType(template.equipmentType),
                        color: colorScheme.primary,
                      ),
                      title: Text(template.equipmentType),
                      trailing: IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () {
                          sldState.setSelectedTemplateInModal(template);
                        },
                      ),
                      onTap: () {
                        sldState.setSelectedTemplateInModal(template);
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
    ],
  );
}

Widget _buildPropertiesSection(
  BuildContext context,
  SldState sldState,
  ColorScheme colorScheme,
) {
  final Equipment? selectedEquipment = sldState.selectedEquipmentInModal;
  final MasterEquipmentTemplate? selectedTemplate =
      sldState.selectedTemplateInModal;

  if (selectedEquipment == null && selectedTemplate == null) {
    return const Center(child: Text('No item selected for properties.'));
  }

  final bool isEditingExistingEquipment = selectedEquipment != null;
  final String currentItemName = isEditingExistingEquipment
      ? selectedEquipment!.name
      : selectedTemplate!.equipmentType;

  final MasterEquipmentTemplate? masterTemplateForFields =
      isEditingExistingEquipment
      ? sldState.availableTemplates.firstWhereOrNull(
          (t) => t.id == selectedEquipment.masterTemplateId,
        )
      : selectedTemplate;

  if (masterTemplateForFields == null) {
    return const Center(
      child: Text('Master template not found for selected item.'),
    );
  }

  final TextEditingController nameController = TextEditingController(
    text: currentItemName,
  );
  Map<String, dynamic> currentCustomFieldValues = isEditingExistingEquipment
      ? Map.from(selectedEquipment.customFieldValues)
      : {};

  List<Map<String, dynamic>> customFieldDefinitions = List.from(
    masterTemplateForFields.equipmentCustomFields ?? [],
  );

  nameController.addListener(() {
    if (isEditingExistingEquipment) {
      sldState.updateEquipment(
        selectedEquipment!.copyWith(name: nameController.text.trim()),
      );
    }
  });

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Properties: ${isEditingExistingEquipment ? 'Edit ${currentItemName}' : 'New ${currentItemName}'}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      Expanded(
        child: ListView(
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 15),

            ...customFieldDefinitions.map((fieldDef) {
              String fieldName = fieldDef['name'];
              String dataType = fieldDef['dataType'];
              dynamic fieldValue = currentCustomFieldValues[fieldName];

              void updateAndSaveLocal(dynamic newValue) {
                currentCustomFieldValues[fieldName] = newValue;
                if (isEditingExistingEquipment) {
                  sldState.updateEquipment(
                    selectedEquipment!.copyWith(
                      customFieldValues: currentCustomFieldValues,
                    ),
                  );
                }
              }

              Widget inputWidget;
              switch (dataType) {
                case 'text':
                  inputWidget = TextFormField(
                    initialValue: fieldValue?.toString() ?? '',
                    decoration: InputDecoration(labelText: fieldName),
                    onChanged: updateAndSaveLocal,
                  );
                  break;
                case 'number':
                  inputWidget = TextFormField(
                    initialValue: fieldValue?.toString() ?? '',
                    decoration: InputDecoration(labelText: fieldName),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        updateAndSaveLocal(num.tryParse(value)),
                  );
                  break;
                case 'boolean':
                  inputWidget = CheckboxListTile(
                    title: Text(fieldName),
                    value: fieldValue is bool ? fieldValue : false,
                    onChanged: updateAndSaveLocal,
                  );
                  break;
                case 'dropdown':
                  inputWidget = DropdownButtonFormField<String>(
                    value: fieldValue?.toString(),
                    decoration: InputDecoration(labelText: fieldName),
                    items: List<String>.from(fieldDef['options'] ?? []).map((
                      option,
                    ) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: updateAndSaveLocal,
                  );
                  break;
                case 'date':
                  inputWidget = TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: fieldValue != null
                          ? DateFormat(
                              'yyyy-MM-dd',
                            ).format(DateTime.parse(fieldValue))
                          : '',
                    ),
                    decoration: InputDecoration(
                      labelText: fieldName,
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.calendar_today,
                          color: colorScheme.primary,
                        ),
                        onPressed: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: fieldValue != null
                                ? DateTime.parse(fieldValue)
                                : DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            updateAndSaveLocal(pickedDate.toIso8601String());
                          }
                        },
                      ),
                    ),
                  );
                  break;
                case 'time':
                  inputWidget = TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: fieldValue != null
                          ? TimeOfDay.fromDateTime(
                              DateTime.parse(fieldValue),
                            ).format(context)
                          : '',
                    ),
                    decoration: InputDecoration(
                      labelText: fieldName,
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.access_time,
                          color: colorScheme.primary,
                        ),
                        onPressed: () async {
                          TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: fieldValue != null
                                ? TimeOfDay.fromDateTime(
                                    DateTime.parse(fieldValue),
                                  )
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
                            updateAndSaveLocal(dt.toIso8601String());
                          }
                        },
                      ),
                    ),
                  );
                  break;
                default:
                  inputWidget = Text('Unsupported data type: $dataType');
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: inputWidget,
              );
            }).toList(),

            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Custom Property Field to Template'),
              onPressed: () async {
                final newFieldDef = await _showAddCustomFieldDialog(context);
                if (newFieldDef != null) {
                  customFieldDefinitions.add(newFieldDef);
                  final updatedTemplate = masterTemplateForFields.copyWith(
                    equipmentCustomFields: customFieldDefinitions,
                  );
                  await CoreFirestoreService().updateMasterEquipmentTemplate(
                    updatedTemplate,
                  );
                  sldState.setSelectedTemplateInModal(updatedTemplate);
                }
              },
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                if (isEditingExistingEquipment) {
                  Navigator.pop(context);
                  if (context.mounted) {
                    SnackBarUtils.showSnackBar(
                      context,
                      'Properties updated locally. Remember to save your changes!',
                    );
                  }
                } else {
                  final newEquipment = Equipment(
                    id: const Uuid().v4(),
                    substationId: sldState.placedEquipment.isNotEmpty
                        ? sldState.placedEquipment.values.first.substationId
                        : 'unknown_substation', // Placeholder if no equipment exists yet
                    bayId: 'default_sld_bay',
                    equipmentType: selectedTemplate!.equipmentType,
                    masterTemplateId: selectedTemplate.id,
                    name: nameController.text.trim().isNotEmpty
                        ? nameController.text.trim()
                        : '${selectedTemplate.equipmentType} ${const Uuid().v4().substring(0, 4)}',
                    positionX: 100.0,
                    positionY: 100.0,
                    customFieldValues: currentCustomFieldValues,
                    relays: [],
                    energyMeters: [],
                  );
                  sldState.addEquipment(newEquipment);
                  sldState.selectEquipment(newEquipment);
                  if (context.mounted) {
                    SnackBarUtils.showSnackBar(
                      context,
                      'Equipment "${newEquipment.name}" added to canvas! Remember to save your changes.',
                    );
                    Navigator.pop(context);
                  }
                }
              },
              child: Text(
                isEditingExistingEquipment
                    ? 'Done Editing'
                    : 'Add Equipment to Canvas',
              ),
            ),
            if (isEditingExistingEquipment)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // This will trigger deletion logic in SldBuilderScreen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                  child: const Text('Delete Equipment'),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

// Helper for _buildEquipmentTemplateSelectionSection and _buildPropertiesSection to get icons
IconData _getIconForEquipmentType(String type) {
  switch (type.toLowerCase()) {
    case 'power transformer':
      return Icons.power;
    case 'circuit breaker':
      return Icons.flash_on;
    case 'isolator':
      return Icons.flip_to_front;
    case 'current transformer (ct)':
    case 'voltage transformer (vt/pt)':
      return Icons.bolt;
    case 'busbar':
      return Icons.horizontal_rule;
    case 'lightning arrester (la)':
      return Icons.shield;
    case 'wave trap':
      return Icons.waves;
    case 'shunt reactor':
      return Icons.device_thermostat;
    case 'capacitor bank':
      return Icons.battery_charging_full;
    case 'line':
      return Icons.linear_scale;
    case 'control panel':
      return Icons.settings_remote;
    case 'relay panel':
      return Icons.vpn_key;
    case 'battery bank':
      return Icons.battery_full;
    case 'ac/dc distribution board':
      return Icons.dashboard;
    case 'earthing system':
      return Icons.public;
    case 'energy meter':
      return Icons.electric_meter;
    case 'auxiliary transformer':
      return Icons.power_input;
    default:
      return Icons.category;
  }
}
