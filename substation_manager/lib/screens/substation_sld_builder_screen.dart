// lib/screens/substation_sld_builder_screen.dart

import 'package:collection/collection.dart'; // Import this for firstWhereOrNull
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for SystemChrome
import 'package:provider/provider.dart';
import 'package:substation_manager/models/master_equipment_template.dart';
import 'package:substation_manager/models/equipment.dart';
import 'package:substation_manager/models/substation.dart';
import 'package:substation_manager/models/bay.dart';
import 'package:substation_manager/models/electrical_connection.dart';
import 'package:substation_manager/services/core_firestore_service.dart';
import 'package:substation_manager/services/equipment_firestore_service.dart';
import 'package:substation_manager/services/electrical_connection_firestore_service.dart';
import 'package:substation_manager/utils/snackbar_utils.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

// --- SLD Builder State Management ---
class SldState extends ChangeNotifier {
  final Map<String, Equipment> _placedEquipment = {};
  final Map<String, Bay> _placedBays = {};
  final List<ElectricalConnection> _connections = [];
  Equipment? _selectedEquipment; // Selected on canvas for properties
  ElectricalConnection? _selectedConnection;
  bool _isLoadingTemplates = false;
  List<MasterEquipmentTemplate> _availableTemplates = [];

  // For managing selection within the modal sheet (templates for adding, equipment for editing)
  MasterEquipmentTemplate? _selectedTemplateInModal;
  Equipment? _selectedEquipmentInModal;

  Map<String, Equipment> get placedEquipment => _placedEquipment;
  Map<String, Bay> get placedBays => _placedBays;
  List<ElectricalConnection> get connections => _connections;
  Equipment? get selectedEquipment => _selectedEquipment;
  ElectricalConnection? get selectedConnection => _selectedConnection;
  bool get isLoadingTemplates => _isLoadingTemplates;
  List<MasterEquipmentTemplate> get availableTemplates => _availableTemplates;
  MasterEquipmentTemplate? get selectedTemplateInModal =>
      _selectedTemplateInModal;
  Equipment? get selectedEquipmentInModal => _selectedEquipmentInModal;

  void addEquipment(Equipment equipment) {
    _placedEquipment[equipment.id] = equipment;
    notifyListeners();
  }

  void updateEquipmentPosition(String id, Offset newPosition) {
    if (_placedEquipment.containsKey(id)) {
      _placedEquipment[id] = _placedEquipment[id]!.copyWith(
        positionX: newPosition.dx,
        positionY: newPosition.dy,
      );
      notifyListeners();
    }
  }

  void removeEquipment(String id) {
    _placedEquipment.remove(id);
    notifyListeners();
  }

  void addBay(Bay bay) {
    _placedBays[bay.id] = bay;
    notifyListeners();
  }

  void updateBayPosition(String id, Offset newPosition) {
    if (_placedBays.containsKey(id)) {
      _placedBays[id] = _placedBays[id]!.copyWith(
        positionX: newPosition.dx,
        positionY: newPosition.dy,
      );
      notifyListeners();
    }
  }

  void addConnection(ElectricalConnection connection) {
    _connections.add(connection);
    notifyListeners();
  }

  void removeConnection(String id) {
    _connections.removeWhere((conn) => conn.id == id);
    notifyListeners();
  }

  void selectEquipment(Equipment? equipment) {
    _selectedEquipment = equipment;
    _selectedConnection = null;
    notifyListeners();
  }

  void selectConnection(ElectricalConnection? connection) {
    _selectedConnection = connection;
    _selectedEquipment = null;
    notifyListeners();
  }

  void setSelectedTemplateInModal(MasterEquipmentTemplate? template) {
    _selectedTemplateInModal = template;
    _selectedEquipmentInModal = null; // Clear equipment selection in modal
    notifyListeners();
  }

  void setSelectedEquipmentInModal(Equipment? equipment) {
    _selectedEquipmentInModal = equipment;
    _selectedTemplateInModal = null; // Clear template selection in modal
    notifyListeners();
  }

  void setAvailableTemplates(List<MasterEquipmentTemplate> templates) {
    _availableTemplates = templates;
    notifyListeners();
  }

  void setIsLoadingTemplates(bool loading) {
    _isLoadingTemplates = loading;
    notifyListeners();
  }

  void updateAllBays(List<Bay> bays) {
    _placedBays.clear();
    for (var bay in bays) {
      _placedBays[bay.id] = bay;
    }
    notifyListeners();
  }

  void updateAllEquipment(List<Equipment> equipment) {
    _placedEquipment.clear();
    for (var eq in equipment) {
      _placedEquipment[eq.id] = eq;
    }
    notifyListeners();
  }

  void updateAllConnections(List<ElectricalConnection> connections) {
    _connections.clear();
    _connections.addAll(connections);
    notifyListeners();
  }
}

class SldBuilderScreen extends StatefulWidget {
  final Substation substation;

  const SldBuilderScreen({super.key, required this.substation});

  @override
  State<SldBuilderScreen> createState() => _SldBuilderScreenState();
}

class _SldBuilderScreenState extends State<SldBuilderScreen> {
  final CoreFirestoreService _coreFirestoreService = CoreFirestoreService();
  final EquipmentFirestoreService _equipmentFirestoreService =
      EquipmentFirestoreService();
  final ElectricalConnectionFirestoreService _connectionFirestoreService =
      ElectricalConnectionFirestoreService();
  final Uuid _uuid = const Uuid();

  StreamSubscription? _masterTemplatesSubscription;
  StreamSubscription? _baysSubscription;
  StreamSubscription? _equipmentSubscription;
  StreamSubscription? _connectionsSubscription;

  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMasterEquipmentTemplates();
      _loadSldData();
    });
  }

  @override
  void dispose() {
    // Revert to portrait mode when leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _masterTemplatesSubscription?.cancel();
    _baysSubscription?.cancel();
    _equipmentSubscription?.cancel();
    _connectionsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMasterEquipmentTemplates() async {
    final sldState = context.read<SldState>();
    sldState.setIsLoadingTemplates(true);
    try {
      _masterTemplatesSubscription = _coreFirestoreService
          .getMasterEquipmentTemplatesStream()
          .listen(
            (templates) {
              if (mounted) {
                sldState.setAvailableTemplates(templates);
                sldState.setIsLoadingTemplates(false);
              }
            },
            onError: (e) {
              if (mounted) {
                SnackBarUtils.showSnackBar(
                  context,
                  'Error loading equipment templates: ${e.toString()}',
                  isError: true,
                );
                sldState.setIsLoadingTemplates(false);
              }
            },
          );
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Unexpected error loading templates: ${e.toString()}',
          isError: true,
        );
        sldState.setIsLoadingTemplates(false);
      }
    }
  }

  Future<void> _loadSldData() async {
    final sldState = context.read<SldState>();

    _baysSubscription = _coreFirestoreService
        .getBaysStream(substationId: widget.substation.id)
        .listen(
          (bays) {
            if (mounted) {
              sldState.updateAllBays(bays);
            }
          },
          onError: (e) {
            if (mounted) {
              SnackBarUtils.showSnackBar(
                context,
                'Error loading bays: ${e.toString()}',
                isError: true,
              );
            }
          },
        );

    _equipmentSubscription = _equipmentFirestoreService
        .getEquipmentForSubstationStream(widget.substation.id)
        .listen(
          (equipmentList) {
            if (mounted) {
              sldState.updateAllEquipment(equipmentList);
            }
          },
          onError: (e) {
            if (mounted) {
              SnackBarUtils.showSnackBar(
                context,
                'Error loading equipment: ${e.toString()}',
                isError: true,
              );
            }
          },
        );

    _connectionsSubscription = _connectionFirestoreService
        .getConnectionsStream(substationId: widget.substation.id)
        .listen(
          (connections) {
            if (mounted) {
              sldState.updateAllConnections(connections);
            }
          },
          onError: (e) {
            if (mounted) {
              SnackBarUtils.showSnackBar(
                context,
                'Error loading connections: ${e.toString()}',
                isError: true,
              );
            }
          },
        );
  }

  /// Handles dropping a MasterEquipmentTemplate onto the canvas.
  void _onEquipmentDropped(
    BuildContext context,
    Offset canvasLocalPosition,
    String templateId,
  ) async {
    final sldState = context.read<SldState>();
    final template = sldState.availableTemplates.firstWhere(
      (t) => t.id == templateId,
      orElse: () => throw Exception('Template not found'),
    );

    String? selectedBayId;

    if (sldState.placedBays.isEmpty) {
      try {
        final defaultBay = Bay(
          substationId: widget.substation.id,
          name: 'Default Bay',
          type: 'Generic',
          voltageLevel: widget.substation.voltageLevels.isNotEmpty
              ? widget.substation.voltageLevels.first
              : 'Unknown',
          sequenceNumber: 1,
          positionX: 50.0,
          positionY: 50.0,
        );
        await _coreFirestoreService.addBay(defaultBay);
        sldState.addBay(defaultBay);
        selectedBayId = defaultBay.id;
        if (mounted) {
          SnackBarUtils.showSnackBar(
            context,
            'No bays found. Created "Default Bay".',
          );
        }
      } catch (e) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
            context,
            'Failed to create default bay: ${e.toString()}',
            isError: true,
          );
        }
        print('Error creating default bay: $e');
        return;
      }
    } else {
      selectedBayId = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Assign Equipment to Bay'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sldState.placedBays.values.length,
                itemBuilder: (context, index) {
                  final bay = sldState.placedBays.values.elementAt(index);
                  return ListTile(
                    title: Text(bay.name),
                    onTap: () {
                      Navigator.pop(context, bay.id);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    }

    if (selectedBayId == null) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Equipment placement cancelled. No bay selected.',
          isError: true,
        );
      }
      return;
    }

    final newEquipment = Equipment(
      id: _uuid.v4(),
      substationId: widget.substation.id,
      bayId: selectedBayId,
      equipmentType: template.equipmentType,
      masterTemplateId: template.id,
      name: '${template.equipmentType} ${_uuid.v4().substring(0, 4)}',
      positionX: canvasLocalPosition.dx,
      positionY: canvasLocalPosition.dy,
      customFieldValues: {},
      relays: [],
      energyMeters: [],
    );

    try {
      await _equipmentFirestoreService.addEquipment(newEquipment);
      sldState.addEquipment(newEquipment);
      sldState.selectEquipment(newEquipment);
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Equipment "${newEquipment.name}" placed successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Failed to place equipment: ${e.toString()}',
          isError: true,
        );
      }
      print('Error adding equipment: $e');
    }
  }

  /// Handles dropping a Bay template onto the canvas.
  void _onBayDropped(
    BuildContext context,
    Offset canvasLocalPosition,
    String bayType,
  ) async {
    final sldState = context.read<SldState>();
    final newBay = Bay(
      substationId: widget.substation.id,
      name: '$bayType Bay ${_uuid.v4().substring(0, 4)}',
      type: bayType,
      voltageLevel: widget.substation.voltageLevels.isNotEmpty
          ? widget.substation.voltageLevels.first
          : 'Unknown',
      isIncoming: false,
      sequenceNumber: sldState.placedBays.length + 1,
      positionX: canvasLocalPosition.dx,
      positionY: canvasLocalPosition.dy,
    );

    try {
      await _coreFirestoreService.addBay(newBay);
      sldState.addBay(newBay);
      if (mounted) {
        SnackBarUtils.showSnackBar(context, 'New Bay Added: ${newBay.name}');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Failed to add bay: ${e.toString()}',
          isError: true,
        );
      }
      print('Error adding bay: $e');
    }
  }

  // --- DELETE LOGIC ---
  Future<void> _deleteSelectedItem(SldState sldState) async {
    if (sldState.selectedEquipment != null) {
      final selectedEq = sldState.selectedEquipment!;
      final bool confirm =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm Deletion'),
              content: Text(
                'Are you sure you want to delete "${selectedEq.name}"?',
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
          false;

      if (confirm) {
        try {
          await _equipmentFirestoreService.deleteEquipment(
            selectedEq.substationId,
            selectedEq.bayId,
            selectedEq.id,
          );
          sldState.removeEquipment(selectedEq.id);
          sldState.selectEquipment(null);
          if (mounted) {
            SnackBarUtils.showSnackBar(
              context,
              'Equipment deleted successfully!',
            );
          }
        } catch (e) {
          if (mounted) {
            SnackBarUtils.showSnackBar(
              context,
              'Failed to delete equipment: ${e.toString()}',
              isError: true,
            );
          }
          print('Error deleting equipment: $e');
        }
      }
    } else if (sldState.selectedConnection != null) {
      final selectedConn = sldState.selectedConnection!;
      final bool confirm =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm Deletion'),
              content: const Text(
                'Are you sure you want to delete this connection?',
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
          false;

      if (confirm) {
        try {
          await _connectionFirestoreService.deleteConnection(selectedConn.id);
          sldState.removeConnection(selectedConn.id);
          sldState.selectConnection(null);
          if (mounted) {
            SnackBarUtils.showSnackBar(
              context,
              'Connection deleted successfully!',
            );
          }
        } catch (e) {
          if (mounted) {
            SnackBarUtils.showSnackBar(
              context,
              'Failed to delete connection: ${e.toString()}',
              isError: true,
            );
          }
          print('Error deleting connection: $e');
        }
      }
    }
  }

  void _addConnectionInteraction(SldState sldState) {
    if (sldState.selectedEquipment != null) {
      SnackBarUtils.showSnackBar(
        context,
        'Select another equipment to connect to ${sldState.selectedEquipment!.name}!',
      );
      // TODO: Implement actual connection drawing logic
    } else {
      SnackBarUtils.showSnackBar(
        context,
        'Select the first equipment to connect.',
      );
    }
  }

  // --- Modal Bottom Sheet for ADDING Elements ---
  Future<void> _showAddElementModal(BuildContext context) async {
    final sldState = context.read<SldState>();
    sldState.setSelectedTemplateInModal(null);
    sldState.setSelectedEquipmentInModal(null);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: Consumer<SldState>(
            builder: (context, modalSldState, child) {
              final bool showTemplateProperties =
                  modalSldState.selectedTemplateInModal != null;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
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
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: showTemplateProperties
                          ? _buildPropertiesSection(
                              modalSldState,
                              Theme.of(context).colorScheme,
                            )
                          : _buildEquipmentTemplateSelectionSection(
                              modalSldState,
                              Theme.of(context).colorScheme,
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

  // --- Modal Bottom Sheet for EDITING Existing Equipment ---
  Future<void> _showEditPropertiesModal(
    BuildContext context,
    Equipment equipmentToEdit,
  ) async {
    final sldState = context.read<SldState>();
    sldState.setSelectedEquipmentInModal(equipmentToEdit);
    sldState.setSelectedTemplateInModal(null);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: Consumer<SldState>(
            builder: (context, modalSldState, child) {
              if (modalSldState.selectedEquipmentInModal == null) {
                return const Center(
                  child: Text('No equipment selected for editing.'),
                );
              }
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
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
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _buildPropertiesSection(
                        modalSldState,
                        Theme.of(context).colorScheme,
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

  // This section lists templates and 'Add New Bay' for adding new elements
  Widget _buildEquipmentTemplateSelectionSection(
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
                    ListTile(
                      leading: Icon(
                        Icons.architecture,
                        color: colorScheme.secondary,
                      ),
                      title: const Text('Add New Bay'),
                      onTap: () async {
                        Navigator.pop(context); // Close modal
                        _onBayDropped(
                          context,
                          const Offset(100, 100),
                          'Generic',
                        );
                      },
                    ),
                    const Divider(),
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
                    }),
                  ],
                ),
              ),
      ],
    );
  }

  // --- Dynamic Properties Section ---
  Widget _buildPropertiesSection(SldState sldState, ColorScheme colorScheme) {
    final Equipment? selectedEquipment = sldState.selectedEquipmentInModal;
    final MasterEquipmentTemplate? selectedTemplate =
        sldState.selectedTemplateInModal;

    if (selectedEquipment == null && selectedTemplate == null) {
      return const Center(child: Text('No item selected for properties.'));
    }

    final bool isEditingExistingEquipment = selectedEquipment != null;
    final String currentItemName = isEditingExistingEquipment
        ? selectedEquipment.name
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Properties: ${isEditingExistingEquipment ? 'Edit $currentItemName' : 'New $currentItemName'}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (newName) {
                  if (isEditingExistingEquipment) {
                    final updatedEquipment = selectedEquipment.copyWith(
                      name: newName,
                    );
                    _equipmentFirestoreService.updateEquipment(
                      updatedEquipment,
                    );
                    sldState.addEquipment(updatedEquipment);
                  }
                },
              ),
              const SizedBox(height: 15),

              ...customFieldDefinitions.map((fieldDef) {
                String fieldName = fieldDef['name'];
                String fieldType = fieldDef['type'];
                dynamic fieldValue = currentCustomFieldValues[fieldName];

                Widget inputWidget;
                switch (fieldType) {
                  case 'text':
                    inputWidget = TextFormField(
                      initialValue: fieldValue?.toString() ?? '',
                      decoration: InputDecoration(labelText: fieldName),
                      onChanged: (value) =>
                          currentCustomFieldValues[fieldName] = value,
                    );
                    break;
                  case 'number':
                    inputWidget = TextFormField(
                      initialValue: fieldValue?.toString() ?? '',
                      decoration: InputDecoration(labelText: fieldName),
                      keyboardType: TextInputType.number,
                      onChanged: (value) =>
                          currentCustomFieldValues[fieldName] = num.tryParse(
                            value,
                          ),
                    );
                    break;
                  case 'boolean':
                    inputWidget = CheckboxListTile(
                      title: Text(fieldName),
                      value: fieldValue is bool ? fieldValue : false,
                      onChanged: (value) =>
                          currentCustomFieldValues[fieldName] = value,
                    );
                    break;
                  default:
                    inputWidget = Text('Unsupported field type: $fieldType');
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: inputWidget,
                );
              }),

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
                    await _coreFirestoreService.updateMasterEquipmentTemplate(
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
                    final updatedEquipment = selectedEquipment.copyWith(
                      name: nameController.text.trim(),
                      customFieldValues: currentCustomFieldValues,
                    );
                    try {
                      await _equipmentFirestoreService.updateEquipment(
                        updatedEquipment,
                      );
                      if (mounted) {
                        SnackBarUtils.showSnackBar(
                          context,
                          'Properties saved successfully!',
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (mounted) {
                        SnackBarUtils.showSnackBar(
                          context,
                          'Failed to save properties: ${e.toString()}',
                          isError: true,
                        );
                      }
                    }
                  } else {
                    String? selectedBayId;
                    if (sldState.placedBays.isEmpty) {
                      try {
                        final defaultBay = Bay(
                          substationId: widget.substation.id,
                          name: 'Default Bay',
                          type: 'Generic',
                          voltageLevel:
                              widget.substation.voltageLevels.isNotEmpty
                              ? widget.substation.voltageLevels.first
                              : 'Unknown',
                          sequenceNumber: 1,
                          positionX: 50.0,
                          positionY: 50.0,
                        );
                        await _coreFirestoreService.addBay(defaultBay);
                        sldState.addBay(defaultBay);
                        selectedBayId = defaultBay.id;
                        if (mounted) {
                          SnackBarUtils.showSnackBar(
                            context,
                            'No bays found. Created "Default Bay".',
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          SnackBarUtils.showSnackBar(
                            context,
                            'Failed to create default bay: ${e.toString()}',
                            isError: true,
                          );
                        }
                        return;
                      }
                    } else {
                      selectedBayId = await showDialog<String>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Assign Equipment to Bay'),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: sldState.placedBays.values.length,
                                itemBuilder: (context, index) {
                                  final bay = sldState.placedBays.values
                                      .elementAt(index);
                                  return ListTile(
                                    title: Text(bay.name),
                                    onTap: () {
                                      Navigator.pop(context, bay.id);
                                    },
                                  );
                                },
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                            ],
                          );
                        },
                      );
                    }

                    if (selectedBayId == null) {
                      if (mounted) {
                        SnackBarUtils.showSnackBar(
                          context,
                          'Equipment placement cancelled. No bay selected.',
                          isError: true,
                        );
                      }
                      return;
                    }

                    final newEquipment = Equipment(
                      id: _uuid.v4(),
                      substationId: widget.substation.id,
                      bayId: selectedBayId,
                      equipmentType: selectedTemplate!.equipmentType,
                      masterTemplateId: selectedTemplate.id,
                      name: nameController.text.trim().isNotEmpty
                          ? nameController.text.trim()
                          : '${selectedTemplate.equipmentType} ${_uuid.v4().substring(0, 4)}',
                      positionX: 100.0,
                      positionY: 100.0,
                      customFieldValues: currentCustomFieldValues,
                      relays: [],
                      energyMeters: [],
                    );
                    try {
                      await _equipmentFirestoreService.addEquipment(
                        newEquipment,
                      );
                      sldState.addEquipment(newEquipment);
                      sldState.selectEquipment(newEquipment);
                      if (mounted) {
                        SnackBarUtils.showSnackBar(
                          context,
                          'Equipment "${newEquipment.name}" added successfully!',
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (mounted) {
                        SnackBarUtils.showSnackBar(
                          context,
                          'Failed to add equipment: ${e.toString()}',
                          isError: true,
                        );
                      }
                      print('Error adding equipment: $e');
                    }
                  }
                },
                child: Text(
                  isEditingExistingEquipment
                      ? 'Save Changes'
                      : 'Add Equipment to Canvas',
                ),
              ),
              if (isEditingExistingEquipment)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _deleteSelectedItem(sldState);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
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

  Future<Map<String, dynamic>?> _showAddCustomFieldDialog(
    BuildContext context,
  ) async {
    final formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController();
    String? selectedType;
    final List<String> fieldTypes = ['text', 'number', 'boolean'];

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Define New Custom Field'),
          content: Form(
            key: formKey,
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
                  onChanged: (value) => selectedType = value,
                  validator: (value) => value == null ? 'Select a type' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, {
                    'name': nameController.text.trim(),
                    'type': selectedType,
                  });
                }
              },
              child: const Text('Add Field'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final sldState = context.watch<SldState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('SLD Builder: ${widget.substation.name}'),
        actions: [
          if (sldState.selectedEquipment != null ||
              sldState.selectedConnection != null)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Delete Selected Item',
              onPressed: () => _deleteSelectedItem(sldState),
            ),
          if (sldState.selectedEquipment != null)
            IconButton(
              icon: const Icon(Icons.link),
              tooltip: 'Create Connection',
              onPressed: () => _addConnectionInteraction(sldState),
            ),
        ],
      ),
      body: Consumer<SldState>(
        builder: (context, sldState, child) {
          return Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTapUp: (details) {
                    sldState.selectEquipment(null);
                    sldState.selectConnection(null);
                  },
                  child: InteractiveViewer(
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(500),
                    minScale: 0.1,
                    maxScale: 4.0,
                    child: DragTarget<String>(
                      onAcceptWithDetails: (details) {
                        final RenderBox renderBox =
                            _canvasKey.currentContext?.findRenderObject()
                                as RenderBox;
                        final localOffset = renderBox.globalToLocal(
                          details.offset,
                        );

                        if (details.data == 'NEW_BAY') {
                          _onBayDropped(context, localOffset, 'Generic');
                        } else {
                          _onEquipmentDropped(
                            context,
                            localOffset,
                            details.data,
                          );
                        }
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          key: _canvasKey,
                          color: Colors.grey[200],
                          width: 3000.0,
                          height: 2000.0,
                          child: Stack(
                            children: [
                              ...sldState.placedBays.values.map((bay) {
                                return Positioned(
                                  left: bay.positionX,
                                  top: bay.positionY,
                                  child: GestureDetector(
                                    onTap: () {
                                      // Optional: Select bay on tap
                                    },
                                    onLongPress: () {
                                      // --- DEBUGGING ---
                                      // This SnackBar will appear if the long-press on a Bay is detected.
                                      SnackBarUtils.showSnackBar(
                                        context,
                                        'Long-press detected for Bay: ${bay.name}',
                                      );
                                      // You can later replace this with a call to an edit modal.
                                    },
                                    onPanUpdate: (details) {
                                      final Offset newPosition = Offset(
                                        bay.positionX! + details.delta.dx,
                                        bay.positionY! + details.delta.dy,
                                      );
                                      sldState.updateBayPosition(
                                        bay.id,
                                        newPosition,
                                      );
                                    },
                                    onPanEnd: (details) {
                                      final finalBay = context
                                          .read<SldState>()
                                          .placedBays[bay.id];
                                      if (finalBay != null) {
                                        _coreFirestoreService.updateBay(
                                          finalBay,
                                        );
                                      }
                                    },
                                    child: _buildBayRepresentation(
                                      bay,
                                      colorScheme,
                                    ),
                                  ),
                                );
                              }),

                              ...sldState.placedEquipment.values.map((
                                equipment,
                              ) {
                                return Positioned(
                                  left: equipment.positionX,
                                  top: equipment.positionY,
                                  child: GestureDetector(
                                    onTap: () {
                                      sldState.selectEquipment(equipment);
                                    },
                                    onLongPress: () {
                                      // --- DEBUGGING ---
                                      // This SnackBar will show if the long-press is detected.
                                      SnackBarUtils.showSnackBar(
                                        context,
                                        'Long-press detected for: ${equipment.name}',
                                      );
                                      // --- END DEBUGGING ---

                                      sldState.selectEquipment(equipment);
                                      _showEditPropertiesModal(
                                        context,
                                        equipment,
                                      );
                                    },
                                    onPanUpdate: (details) {
                                      final Offset newPosition = Offset(
                                        equipment.positionX! + details.delta.dx,
                                        equipment.positionY! + details.delta.dy,
                                      );
                                      sldState.updateEquipmentPosition(
                                        equipment.id,
                                        newPosition,
                                      );
                                    },
                                    onPanEnd: (details) {
                                      final finalEquipment = context
                                          .read<SldState>()
                                          .placedEquipment[equipment.id];
                                      if (finalEquipment != null) {
                                        _equipmentFirestoreService
                                            .updateEquipment(finalEquipment);
                                      }
                                    },
                                    child: _buildEquipmentIcon(
                                      equipment,
                                      colorScheme,
                                      isSelected:
                                          sldState.selectedEquipment?.id ==
                                          equipment.id,
                                    ),
                                  ),
                                );
                              }),

                              CustomPaint(
                                painter: ConnectionPainter(
                                  equipment: sldState.placedEquipment.values
                                      .toList(),
                                  connections: sldState.connections,
                                  onConnectionTap: (connection) {
                                    sldState.selectConnection(connection);
                                  },
                                  selectedConnection:
                                      sldState.selectedConnection,
                                  colorScheme: colorScheme,
                                ),
                                size: Size.infinite,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddElementModal(context),
        tooltip: 'Add New SLD Element',
        child: const Icon(Icons.add),
      ),
    );
  }

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

  Widget _buildEquipmentIcon(
    Equipment equipment,
    ColorScheme colorScheme, {
    bool isSelected = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.tertiary.withOpacity(0.7)
            : colorScheme.primary.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: colorScheme.onTertiary, width: 3)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIconForEquipmentType(equipment.equipmentType),
            color: isSelected ? colorScheme.onTertiary : colorScheme.onPrimary,
            size: 30,
          ),
          const SizedBox(height: 4),
          Text(
            equipment.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isSelected
                  ? colorScheme.onTertiary
                  : colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildBayRepresentation(Bay bay, ColorScheme colorScheme) {
    return Container(
      width: 150,
      height: 100,
      decoration: BoxDecoration(
        color: colorScheme.secondary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.secondary, width: 2),
      ),
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text(
          'Bay: ${bay.name}\n(${bay.voltageLevel})',
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onSurface),
        ),
      ),
    );
  }
}

class ConnectionPainter extends CustomPainter {
  final List<Equipment> equipment;
  final List<ElectricalConnection> connections;
  final Function(ElectricalConnection) onConnectionTap;
  final ElectricalConnection? selectedConnection;
  final ColorScheme colorScheme;

  ConnectionPainter({
    required this.equipment,
    required this.connections,
    required this.onConnectionTap,
    this.selectedConnection,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Map<String, Equipment> equipmentMap = {
      for (var eq in equipment) eq.id: eq,
    };

    for (var connection in connections) {
      final fromEq = equipmentMap[connection.fromEquipmentId];
      final toEq = equipmentMap[connection.toEquipmentId];

      if (fromEq != null &&
          toEq != null &&
          fromEq.positionX != null &&
          fromEq.positionY != null &&
          toEq.positionX != null &&
          toEq.positionY != null) {
        final Offset startPoint = Offset(
          fromEq.positionX! + 45,
          fromEq.positionY! + 45,
        );
        final Offset endPoint = Offset(
          toEq.positionX! + 45,
          toEq.positionY! + 45,
        );

        final Paint paint = Paint()
          ..color = (selectedConnection?.id == connection.id)
              ? colorScheme.tertiary
              : Colors.blue.shade700
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(startPoint, endPoint, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is ConnectionPainter) {
      return oldDelegate.equipment != equipment ||
          oldDelegate.connections != connections ||
          oldDelegate.selectedConnection != selectedConnection ||
          oldDelegate.colorScheme != colorScheme;
    }
    return true;
  }
}
