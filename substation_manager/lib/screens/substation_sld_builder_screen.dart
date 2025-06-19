// lib/screens/substation_sld_builder_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Using provider for state management if you prefer, or replace with setState/ValueNotifier
import 'package:substation_manager/models/master_equipment_template.dart';
import 'package:substation_manager/models/equipment.dart'; // To store placed equipment instances
import 'package:substation_manager/models/substation.dart'; // To get substation context
import 'package:substation_manager/models/bay.dart'; // To get bay context
import 'package:substation_manager/services/core_firestore_service.dart';
import 'package:substation_manager/services/equipment_firestore_service.dart';
import 'package:substation_manager/utils/snackbar_utils.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs

// --- SLD Builder State Management (simple for now) ---
// In a real app, you might use Provider, Riverpod, BLoC for more complex state.
class SldState extends ChangeNotifier {
  final List<Equipment> _placedEquipment = [];
  Equipment? _selectedEquipment;
  bool _isLoadingTemplates = false;
  List<MasterEquipmentTemplate> _availableTemplates = [];

  List<Equipment> get placedEquipment => _placedEquipment;
  Equipment? get selectedEquipment => _selectedEquipment;
  bool get isLoadingTemplates => _isLoadingTemplates;
  List<MasterEquipmentTemplate> get availableTemplates => _availableTemplates;

  void addEquipment(Equipment equipment) {
    _placedEquipment.add(equipment);
    notifyListeners();
  }

  void updateEquipmentPosition(String id, Offset newPosition) {
    final index = _placedEquipment.indexWhere((eq) => eq.id == id);
    if (index != -1) {
      _placedEquipment[index] = _placedEquipment[index].copyWith(
        positionX: newPosition.dx,
        positionY: newPosition.dy,
      );
      notifyListeners();
    }
  }

  void selectEquipment(Equipment? equipment) {
    _selectedEquipment = equipment;
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

  // You'd add methods for connections, deleting, etc.
}

class SldBuilderScreen extends StatefulWidget {
  final Substation substation;
  final Bay bay; // Assuming SLD is built per bay

  const SldBuilderScreen({
    super.key,
    required this.substation,
    required this.bay,
  });

  @override
  State<SldBuilderScreen> createState() => _SldBuilderScreenState();
}

class _SldBuilderScreenState extends State<SldBuilderScreen> {
  final CoreFirestoreService _coreFirestoreService = CoreFirestoreService();
  final EquipmentFirestoreService _equipmentFirestoreService =
      EquipmentFirestoreService();
  final Uuid _uuid = const Uuid();

  // Offset to adjust for scaling/panning if implemented later
  final Offset _canvasOffset = Offset.zero;
  final double _canvasScale = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load templates and existing equipment after the first frame
      _loadMasterEquipmentTemplates();
      _loadPlacedEquipment();
    });
  }

  Future<void> _loadMasterEquipmentTemplates() async {
    final sldState = Provider.of<SldState>(context, listen: false);
    sldState.setIsLoadingTemplates(true);
    try {
      _coreFirestoreService.getMasterEquipmentTemplatesStream().listen(
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

  Future<void> _loadPlacedEquipment() async {
    final sldState = Provider.of<SldState>(context, listen: false);
    try {
      // Listen to equipment changes for this bay
      _equipmentFirestoreService
          .getEquipmentForBayStream(widget.substation.id, widget.bay.id)
          .listen((equipmentList) {
            if (mounted) {
              // Clear and re-add to reflect current state
              sldState.placedEquipment.clear();
              for (var eq in equipmentList) {
                sldState.addEquipment(eq);
              }
              sldState.selectEquipment(null); // Deselect any old selection
            }
          });
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Error loading placed equipment: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  /// Handles dropping a MasterEquipmentTemplate onto the canvas.
  void _onEquipmentDropped(
    BuildContext context,
    Offset canvasLocalPosition,
    String templateId,
  ) {
    final sldState = Provider.of<SldState>(context, listen: false);
    final template = sldState.availableTemplates.firstWhere(
      (t) => t.id == templateId,
      orElse: () => throw Exception('Template not found'),
    );

    final newEquipment = Equipment(
      id: _uuid.v4(),
      substationId: widget.substation.id,
      bayId: widget.bay.id,
      equipmentType: template.equipmentType,
      masterTemplateId: template.id,
      name:
          '${template.equipmentType} ${_uuid.v4().substring(0, 4)}', // Default name
      positionX: canvasLocalPosition.dx,
      positionY: canvasLocalPosition.dy,
      // Initialize custom field values from template defaults (if any)
      customFieldValues: {}, // Will be populated in properties panel
      relays: [], // Will be populated based on definedRelays from template
      energyMeters:
          [], // Will be populated based on definedEnergyMeters from template
    );

    sldState.addEquipment(newEquipment);
    _equipmentFirestoreService.addEquipment(newEquipment); // Save to Firestore
    sldState.selectEquipment(newEquipment); // Select the newly added equipment
  }

  /// Builds the tool palette on the left side.
  Widget _buildToolPalette(SldState sldState, ColorScheme colorScheme) {
    return Container(
      width: 200,
      color: colorScheme.surface,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Equipment Palette',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          sldState.isLoadingTemplates
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: ListView.builder(
                    itemCount: sldState.availableTemplates.length,
                    itemBuilder: (context, index) {
                      final template = sldState.availableTemplates[index];
                      // Use Draggable to make equipment types draggable
                      return Draggable<String>(
                        data: template.id, // Pass template ID when dragged
                        feedback: Material(
                          elevation: 4.0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              template.equipmentType,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: colorScheme.onPrimary),
                            ),
                          ),
                        ),
                        childWhenDragging: Card(
                          color: colorScheme.surfaceContainerHighest
                              .withOpacity(0.5),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(child: Text(template.equipmentType)),
                          ),
                        ),
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Icon(
                              Icons.electrical_services,
                              color: colorScheme.primary,
                            ),
                            title: Text(template.equipmentType),
                            onTap: () {
                              // Optional: Add to canvas via tap
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  /// Builds the properties panel on the right side.
  Widget _buildPropertiesPanel(SldState sldState, ColorScheme colorScheme) {
    return Container(
      width: 250,
      color: colorScheme.surface,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Properties',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (sldState.selectedEquipment == null)
            Expanded(
              child: Center(
                child: Text(
                  'Select an equipment on the canvas to view/edit properties.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID: ${sldState.selectedEquipment!.id}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Type: ${sldState.selectedEquipment!.equipmentType}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    // TODO: Dynamically build form fields based on masterTemplateId
                    // For now, allow editing of name
                    TextFormField(
                      initialValue: sldState.selectedEquipment!.name,
                      decoration: const InputDecoration(labelText: 'Name'),
                      onChanged: (newName) {
                        final updatedEquipment = sldState.selectedEquipment!
                            .copyWith(name: newName);
                        // Update in state and Firestore
                        final index = sldState.placedEquipment.indexWhere(
                          (eq) => eq.id == updatedEquipment.id,
                        );
                        if (index != -1) {
                          sldState.placedEquipment[index] = updatedEquipment;
                          // Notify only this specific equipment change if using more granular state
                          // For simplicity, we'll re-save the whole object.
                          _equipmentFirestoreService.updateEquipment(
                            updatedEquipment,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Implement delete logic
                        final bool confirm =
                            await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirm Deletion'),
                                content: Text(
                                  'Are you sure you want to delete "${sldState.selectedEquipment!.name}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.error,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;

                        if (confirm == true) {
                          final selectedEq = sldState.selectedEquipment!;
                          await _equipmentFirestoreService.deleteEquipment(
                            selectedEq.substationId,
                            selectedEq.bayId,
                            selectedEq.id,
                          );
                          // Removing from local state will be handled by the stream listener
                          sldState.selectEquipment(
                            null,
                          ); // Deselect after delete
                          if (mounted) {
                            SnackBarUtils.showSnackBar(
                              context,
                              'Equipment deleted successfully!',
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete Equipment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SLD Builder: ${widget.substation.name} - ${widget.bay.name}',
        ),
      ),
      body: MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => SldState())],
        child: Consumer<SldState>(
          builder: (context, sldState, child) {
            return Row(
              children: [
                // Left Panel: Tool Palette
                _buildToolPalette(sldState, colorScheme),

                // Center Panel: Canvas Area
                Expanded(
                  child: GestureDetector(
                    onTapUp: (details) {
                      // Deselect equipment if clicking on empty canvas
                      sldState.selectEquipment(null);
                    },
                    child: DragTarget<String>(
                      onAcceptWithDetails: (details) {
                        // Calculate position relative to the canvas
                        final RenderBox renderBox =
                            context.findRenderObject() as RenderBox;
                        final localOffset = renderBox.globalToLocal(
                          details.offset,
                        );
                        // Pass position to handler
                        _onEquipmentDropped(context, localOffset, details.data);
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          color: Colors.grey[200],
                          child: Stack(
                            children: [
                              // Existing placed equipment
                              ...sldState.placedEquipment.map((equipment) {
                                return Positioned(
                                  left: equipment.positionX,
                                  top: equipment.positionY,
                                  child: GestureDetector(
                                    onTap: () {
                                      sldState.selectEquipment(equipment);
                                    },
                                    // Make equipment draggable on canvas
                                    child: Draggable(
                                      feedback: Material(
                                        elevation: 4.0,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary
                                                .withOpacity(0.7),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            equipment.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: colorScheme.onPrimary,
                                                ),
                                          ),
                                        ),
                                      ),
                                      onDragEnd: (details) {
                                        // Update position and save to Firestore
                                        sldState.updateEquipmentPosition(
                                          equipment.id,
                                          details.offset,
                                        );
                                        _equipmentFirestoreService
                                            .updateEquipment(
                                              equipment.copyWith(
                                                positionX: details.offset.dx,
                                                positionY: details.offset.dy,
                                              ),
                                            );
                                      },
                                      child: _buildEquipmentIcon(
                                        equipment,
                                        colorScheme,
                                        isSelected:
                                            sldState.selectedEquipment?.id ==
                                            equipment.id,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                              // TODO: Add CustomPaint for drawing connections here later
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Right Panel: Properties Panel
                _buildPropertiesPanel(sldState, colorScheme),
              ],
            );
          },
        ),
      ),
    );
  }

  // Helper to build equipment icon on canvas
  Widget _buildEquipmentIcon(
    Equipment equipment,
    ColorScheme colorScheme, {
    bool isSelected = false,
  }) {
    // A simple visual representation for now
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

  // Simple icon mapping (you can expand this or use a better system)
  IconData _getIconForEquipmentType(String type) {
    switch (type.toLowerCase()) {
      case 'power transformer':
        return Icons.power;
      case 'circuit breaker':
        return Icons.flash_on;
      case 'isolator':
        return Icons.flip_to_front; // Placeholder
      case 'current transformer (ct)':
      case 'voltage transformer (vt/pt)':
        return Icons.bolt;
      case 'busbar':
        return Icons.horizontal_rule; // Placeholder
      case 'lightning arrester (la)':
        return Icons.shield; // Placeholder
      case 'wave trap':
        return Icons.waves; // Placeholder
      case 'shunt reactor':
        return Icons.device_thermostat; // Placeholder
      case 'capacitor bank':
        return Icons.battery_charging_full; // Placeholder
      case 'line':
        return Icons.linear_scale; // Placeholder
      case 'control panel':
        return Icons.settings_remote;
      case 'relay panel':
        return Icons.vpn_key;
      case 'battery bank':
        return Icons.battery_full;
      case 'ac/dc distribution board':
        return Icons.dashboard;
      case 'earthing system':
        return Icons.public; // Placeholder
      case 'energy meter':
        return Icons.electric_meter;
      case 'auxiliary transformer':
        return Icons.power_input;
      default:
        return Icons.category;
    }
  }
}
