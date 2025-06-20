// lib/widgets/sld_modals.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:substation_manager/models/master_equipment_template.dart';
import 'package:substation_manager/models/equipment.dart';
import 'package:substation_manager/state/sld_state.dart';
import 'package:uuid/uuid.dart';

// Modal to add a new SLD element from available templates
void showAddElementModal(
  BuildContext context,
  List<MasterEquipmentTemplate> availableTemplates,
) {
  final sldState = context.read<SldState>();
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Add New SLD Element'),
        content: SizedBox(
          width:
              MediaQuery.of(dialogContext).size.width * 0.4, // Responsive width
          height:
              MediaQuery.of(dialogContext).size.height *
              0.6, // Responsive height
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sldState.isLoadingTemplates)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                )
              else if (availableTemplates.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'No equipment templates available. Please add templates in the Master Data section.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: availableTemplates.length,
                    itemBuilder: (context, index) {
                      final template = availableTemplates[index];
                      final isSelected =
                          sldState.selectedTemplateInModal?.id == template.id;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        elevation: isSelected ? 8 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ListTile(
                          title: Text(template.equipmentType),
                          subtitle: Text('ID: ${template.id}'),
                          onTap: () {
                            sldState.setSelectedTemplateInModal(template);
                          },
                          selected: isSelected,
                          selectedTileColor: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              sldState.setSelectedTemplateInModal(null); // Clear selection
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: sldState.selectedTemplateInModal != null
                ? () {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Selected "${sldState.selectedTemplateInModal!.equipmentType}". Now drag it onto the canvas.',
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    sldState.setSelectedTemplateInModal(
                      null,
                    ); // Clear after use
                  }
                : null,
            child: const Text('Select'),
          ),
        ],
      );
    },
  );
}

// Modal to edit properties of an existing equipment
void showEditPropertiesModal(BuildContext context, Equipment equipment) {
  final sldState = context.read<SldState>();
  final TextEditingController nameController = TextEditingController(
    text: equipment.name,
  );
  final Map<String, TextEditingController> customFieldControllers = {};
  final Map<String, dynamic> tempCustomFieldValues = Map.from(
    equipment.customFieldValues,
  ); // Mutable copy

  // Initialize controllers for existing custom field values
  equipment.customFieldValues.forEach((key, value) {
    customFieldControllers[key] = TextEditingController(
      text: value?.toString() ?? '',
    );
  });

  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text('Edit ${equipment.equipmentType} Properties'),
        content: FutureBuilder<MasterEquipmentTemplate?>(
          future: Future.value(
            sldState.getTemplateForEquipment(equipment),
          ), // Use Future.value for immediate future
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Error loading template: ${snapshot.error}');
            }
            final MasterEquipmentTemplate? template = snapshot.data;

            return Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Equipment Name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Name cannot be empty';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (template != null &&
                        template.equipmentCustomFields.isNotEmpty) ...[
                      Text(
                        'Custom Fields',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ...template.equipmentCustomFields.map((field) {
                        final fieldName = field['name'] as String;
                        // Ensure controller exists for this field
                        if (!customFieldControllers.containsKey(fieldName)) {
                          customFieldControllers[fieldName] =
                              TextEditingController(
                                text:
                                    tempCustomFieldValues[fieldName]
                                        ?.toString() ??
                                    '',
                              );
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: TextFormField(
                            controller: customFieldControllers[fieldName],
                            decoration: InputDecoration(
                              labelText: fieldName,
                              hintText: 'Enter ${fieldName}',
                            ),
                            keyboardType: _getKeyboardType(
                              field['type'] as String?,
                            ),
                            onChanged: (value) {
                              // Update the temporary map
                              tempCustomFieldValues[fieldName] = value;
                            },
                          ),
                        );
                      }).toList(),
                    ] else if (template != null &&
                        template.equipmentCustomFields.isEmpty)
                      const Text(
                        'No custom fields defined for this equipment type.',
                      ),
                    if (template == null)
                      const Text('Equipment template not found.'),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Dispose controllers to prevent memory leaks
              nameController.dispose();
              customFieldControllers.values.forEach(
                (controller) => controller.dispose(),
              );
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final updatedEquipment = equipment.copyWith(
                  name: nameController.text,
                  customFieldValues:
                      tempCustomFieldValues, // Use the updated map
                );
                sldState.updateEquipment(updatedEquipment);
                // Dispose controllers
                nameController.dispose();
                customFieldControllers.values.forEach(
                  (controller) => controller.dispose(),
                );
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Equipment properties updated locally.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

// Helper function to determine keyboard type based on field type
TextInputType _getKeyboardType(String? fieldType) {
  switch (fieldType?.toLowerCase()) {
    case 'number':
    case 'int':
    case 'double':
      return TextInputType.number;
    case 'email':
      return TextInputType.emailAddress;
    case 'phone':
      return TextInputType.phone;
    case 'url':
      return TextInputType.url;
    default:
      return TextInputType.text;
  }
}
