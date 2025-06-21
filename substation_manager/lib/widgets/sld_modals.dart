// lib/widgets/sld_modals.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:substation_manager/models/master_equipment_template.dart';
import 'package:substation_manager/models/equipment.dart';
import 'package:substation_manager/state/sld_state.dart';

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
                    // This modal only selects the template. The dropping on canvas
                    // handles adding the actual equipment instance.
                    // The main screen needs to pick up sldState.selectedTemplateInModal
                    // and use it when an item is dropped.
                    // For direct placement without drag-and-drop:
                    // final newEquipment = Equipment(
                    //   id: const Uuid().v4(),
                    //   substationId: 'some_substation_id', // You need to pass this or get from context
                    //   bayId: 'default_bay_id', // You need to pass this or get from context
                    //   equipmentType: sldState.selectedTemplateInModal!.equipmentType,
                    //   masterTemplateId: sldState.selectedTemplateInModal!.id,
                    //   name: '${sldState.selectedTemplateInModal!.equipmentType} ${const Uuid().v4().substring(0, 4)}',
                    //   positionX: 50.0, // Default position, user will drag
                    //   positionY: 50.0,
                    //   customFieldValues: {},
                    //   relays: [],
                    //   energyMeters: [],
                    // );
                    // sldState.addEquipment(newEquipment);
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
  // You would add controllers for custom fields, relays, etc. here
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text('Edit ${equipment.equipmentType} Properties'),
        content: Form(
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
                // Add more fields here for custom properties, relays, meters, etc.
                // You'll need to fetch the MasterEquipmentTemplate for this equipment
                // to know what custom fields to display.
                // Example:
                // FutureBuilder<MasterEquipmentTemplate?>(
                //   future: sldState.getTemplateForEquipment(equipment), // You'd need to add this method to SldState
                //   builder: (context, snapshot) {
                //     if (snapshot.connectionState == ConnectionState.waiting) {
                //       return const CircularProgressIndicator();
                //     }
                //     if (snapshot.hasData && snapshot.data != null) {
                //       return Column(
                //         children: snapshot.data!.equipmentCustomFields.map((field) {
                //           // Render text fields, dropdowns based on field type
                //           return TextFormField(
                //             decoration: InputDecoration(labelText: field['name']),
                //             initialValue: equipment.customFieldValues[field['name']]?.toString() ?? '',
                //             onChanged: (value) {
                //               // Update local state, then push to sldState on save
                //             },
                //           );
                //         }).toList(),
                //       );
                //     }
                //     return const Text('No custom fields defined.');
                //   },
                // ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final updatedEquipment = equipment.copyWith(
                  name: nameController.text,
                  // Merge updated custom field values here
                );
                sldState.updateEquipment(updatedEquipment);
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
