// lib/screens/substation_sld_builder_screen.dart

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:substation_manager/models/master_equipment_template.dart';
import 'package:substation_manager/models/equipment.dart';
import 'package:substation_manager/models/substation.dart';
import 'package:substation_manager/models/electrical_connection.dart';
import 'package:substation_manager/services/core_firestore_service.dart';
import 'package:substation_manager/services/equipment_firestore_service.dart';
import 'package:substation_manager/services/electrical_connection_firestore_service.dart';
import 'package:substation_manager/utils/snackbar_utils.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:substation_manager/state/sld_state.dart';
import 'package:substation_manager/widgets/sld_equipment_node.dart';
import 'package:substation_manager/widgets/sld_connection_painter.dart';
import 'package:substation_manager/widgets/sld_modals.dart';
import 'package:substation_manager/utils/grid_utils.dart';
import 'package:substation_manager/widgets/sld_grid_painter.dart';

class SldBuilderScreen extends StatefulWidget {
  final Substation substation;

  const SldBuilderScreen({super.key, required this.substation});

  @override
  State<SldBuilderScreen> createState() => _SldBuilderScreenState();
}

class _SldBuilderScreenState extends State<SldBuilderScreen> {
  final EquipmentFirestoreService _equipmentFirestoreService =
      EquipmentFirestoreService();
  final ElectricalConnectionFirestoreService _connectionFirestoreService =
      ElectricalConnectionFirestoreService();
  final Uuid _uuid = const Uuid();

  StreamSubscription? _masterTemplatesSubscription;
  StreamSubscription? _equipmentSubscription;
  StreamSubscription? _connectionsSubscription;

  final GlobalKey _canvasKey = GlobalKey();
  bool _isSavingSld = false;

  // Define the fixed canvas size
  static const double _canvasWidth = 3000.0;
  static const double _canvasHeight = 2000.0;

  @override
  void initState() {
    super.initState();
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _masterTemplatesSubscription?.cancel();
    _equipmentSubscription?.cancel();
    _connectionsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMasterEquipmentTemplates() async {
    final sldState = context.read<SldState>();
    sldState.setIsLoadingTemplates(true);
    try {
      _masterTemplatesSubscription = CoreFirestoreService()
          .getMasterEquipmentTemplatesStream()
          .listen(
            (templates) {
              if (mounted) {
                print(
                  'DEBUG: SldBuilderScreen - Received ${templates.length} templates from Firestore stream.',
                );
                for (var template in templates) {
                  print(
                    'DEBUG: Template ID: ${template.id}, Type: ${template.equipmentType}',
                  );
                }
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

    _equipmentSubscription = EquipmentFirestoreService()
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
        .getConnectionsStream(
          substationId: widget.substation.id,
        ) // Pass substationId
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

  // Helper to get the correct size for the Draggable feedback and DragTarget acceptance
  // This must match the internal logic in _SldEquipmentNodeState._getEquipmentSize
  Size _getEquipmentNodeSize(String equipmentType) {
    switch (equipmentType) {
      case 'Busbar':
        return const Size(120, 15);
      case 'Current Transformer':
      case 'Potential Transformer':
        return const Size(80, 60);
      default:
        return const Size(60, 60);
    }
  }

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

    // Adjust position to center the dropped component and then snap to grid
    final nodeSize = _getEquipmentNodeSize(template.equipmentType);
    final adjustedPositionX = canvasLocalPosition.dx - nodeSize.width / 2;
    final adjustedPositionY =
        canvasLocalPosition.dy -
        (nodeSize.height * 1.5) / 2; // Adjust for label height

    final snappedPosition = snapToGrid(
      Offset(adjustedPositionX, adjustedPositionY),
    );

    final newEquipment = Equipment(
      id: _uuid.v4(),
      substationId: widget.substation.id,
      bayId: 'default_sld_bay', // Or prompt user for bay if relevant
      equipmentType: template.equipmentType,
      masterTemplateId: template.id,
      name: '${template.equipmentType} ${_uuid.v4().substring(0, 4)}',
      positionX: snappedPosition.dx, // Use snapped position
      positionY: snappedPosition.dy, // Use snapped position
      customFieldValues: {},
      relays: [],
      energyMeters: [],
      symbolKey:
          template.symbolKey, // NEW: Pass the symbolKey from the template
    );

    sldState.addEquipment(newEquipment);
    sldState.selectEquipment(newEquipment);
    if (mounted) {
      SnackBarUtils.showSnackBar(
        context,
        'Equipment "${newEquipment.name}" placed. Remember to save your changes!',
      );
    }
  }

  void _deleteSelectedItem(SldState sldState) async {
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
          final connectionsToRemove = sldState.connections
              .where(
                (conn) =>
                    conn.fromEquipmentId == selectedEq.id ||
                    conn.toEquipmentId == selectedEq.id,
              )
              .toList();

          for (final conn in connectionsToRemove) {
            sldState.removeConnection(conn.id);
          }

          sldState.removeEquipment(selectedEq.id);
          sldState.selectEquipment(null);

          if (mounted) {
            SnackBarUtils.showSnackBar(
              context,
              'Equipment deleted locally. Remember to save your changes!',
            );
          }
        } catch (e) {
          if (mounted) {
            SnackBarUtils.showSnackBar(
              context,
              'Failed to delete equipment locally: ${e.toString()}',
              isError: true,
            );
          }
          print('Error deleting equipment locally: $e');
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
        sldState.removeConnection(selectedConn.id);
        sldState.selectConnection(null);
        if (mounted) {
          SnackBarUtils.showSnackBar(
            context,
            'Connection deleted locally. Remember to save your changes!',
          );
        }
      }
    } else {
      SnackBarUtils.showSnackBar(context, 'No item selected to delete.');
    }
  }

  void _showAddElementModalDialog(
    BuildContext dialogContext,
    SldState sldState,
  ) {
    showAddElementModal(dialogContext, sldState.availableTemplates);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    // Watch SldState for changes to rebuild UI
    final sldState = context.watch<SldState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('SLD Builder: ${widget.substation.name}'),
        actions: [
          // Clear All button
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear All SLD Elements',
            onPressed: () async {
              final bool confirm =
                  await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Clear All'),
                      content: const Text(
                        'Are you sure you want to delete ALL equipment and connections from this SLD? This action will remove them locally. You must save to permanently delete them from the server.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                          child: const Text('Delete All'),
                        ),
                      ],
                    ),
                  ) ??
                  false;

              if (confirm) {
                sldState.clearAllSldElements();
                SnackBarUtils.showSnackBar(
                  context,
                  'All elements cleared locally. Remember to save your changes to permanently delete them!',
                );
              }
            },
          ),
          // Save button
          Consumer<SldState>(
            builder: (context, sldState, child) {
              print(
                'DEBUG: SAVE button builder. hasPendingChanges: ${sldState.hasPendingChanges}, _isSavingSld: $_isSavingSld',
              );
              return TextButton(
                onPressed: sldState.hasPendingChanges && !_isSavingSld
                    ? () async {
                        setState(() {
                          _isSavingSld = true;
                        });
                        print(
                          'DEBUG: SAVE button pressed. _isSavingSld set to true.',
                        );
                        try {
                          await sldState.saveSldChanges(widget.substation);
                          if (mounted) {
                            SnackBarUtils.showSnackBar(
                              context,
                              'SLD changes saved successfully!',
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            SnackBarUtils.showSnackBar(
                              context,
                              'Failed to save SLD changes: ${e.toString()}',
                              isError: true,
                            );
                          }
                          print('ERROR: Save failed in UI: $e');
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isSavingSld = false;
                            });
                            print(
                              'DEBUG: _isSavingSld set to false in finally block.',
                            );
                          }
                        }
                      }
                    : null,
                child: _isSavingSld
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'SAVE',
                        style: TextStyle(
                          color: sldState.hasPendingChanges && !_isSavingSld
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
              );
            },
          ),
          // Delete Selected Item button
          if (sldState.selectedEquipment != null ||
              sldState.selectedConnection !=
                  null) // Only show if something is selected
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Delete Selected Item',
              onPressed: () => _deleteSelectedItem(sldState),
            ),
          // Edit Properties button (only for equipment)
          if (sldState.selectedEquipment != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Properties',
              onPressed: () {
                if (sldState.selectedEquipment != null) {
                  showEditPropertiesModal(context, sldState.selectedEquipment!);
                }
              },
            ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar for equipment templates
          Container(
            width: 150,
            color: colorScheme.surfaceVariant.withOpacity(
              0.3,
            ), // Lighter background
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Templates',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const Divider(),
                if (sldState.isLoadingTemplates)
                  const Center(child: CircularProgressIndicator())
                else if (sldState.availableTemplates.isEmpty)
                  const Text(
                    'No templates loaded.',
                    style: TextStyle(fontSize: 12),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: sldState.availableTemplates.length,
                      itemBuilder: (context, index) {
                        final template = sldState.availableTemplates[index];
                        // Get the size for this template type
                        final templateNodeSize = _getEquipmentNodeSize(
                          template.equipmentType,
                        );
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Draggable<String>(
                            // Draggable provides the data
                            data: template.id, // Pass template ID when dragging
                            feedback: Material(
                              elevation: 12, // More prominent feedback
                              borderRadius: BorderRadius.circular(
                                templateNodeSize.height / 4,
                              ),
                              child: Container(
                                width: templateNodeSize.width,
                                height: templateNodeSize.height * 1.5,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(
                                    0.8,
                                  ), // Feedback color
                                  borderRadius: BorderRadius.circular(
                                    templateNodeSize.height / 4,
                                  ),
                                ),
                                child: SldEquipmentNode(
                                  // Re-use the node for feedback visual
                                  equipment: Equipment(
                                    // Create a dummy equipment for visual
                                    id: 'feedback',
                                    substationId: '',
                                    bayId: '',
                                    equipmentType: template.equipmentType,
                                    masterTemplateId: template.id,
                                    name: template.equipmentType,
                                    positionX: 0,
                                    positionY: 0,
                                    symbolKey: template
                                        .symbolKey, // Pass symbolKey for feedback
                                  ),
                                  colorScheme: colorScheme,
                                  onDoubleTap:
                                      (eq) {}, // No interaction for feedback
                                  onLongPress:
                                      (eq) {}, // No interaction for feedback
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              // Make original item slightly transparent when dragging
                              opacity: 0.5,
                              child: SldEquipmentNode(
                                equipment: Equipment(
                                  id: template.id,
                                  substationId: '',
                                  bayId: '',
                                  equipmentType: template.equipmentType,
                                  masterTemplateId: template.id,
                                  name: template.equipmentType,
                                  positionX: 0,
                                  positionY: 0,
                                  symbolKey: template
                                      .symbolKey, // Pass symbolKey for childWhenDragging
                                ),
                                colorScheme: colorScheme,
                                onDoubleTap: (eq) {},
                                onLongPress: (eq) {},
                              ),
                            ),
                            child: Card(
                              elevation: 2,
                              margin:
                                  EdgeInsets.zero, // Remove default card margin
                              child: SldEquipmentNode(
                                equipment: Equipment(
                                  id: template.id,
                                  substationId: '',
                                  bayId: '',
                                  equipmentType: template.equipmentType,
                                  masterTemplateId: template.id,
                                  name: template.equipmentType,
                                  positionX: 0,
                                  positionY: 0,
                                  symbolKey: template
                                      .symbolKey, // Pass symbolKey for actual child
                                ),
                                colorScheme: colorScheme,
                                onDoubleTap:
                                    (eq) {}, // No double tap action in palette
                                onLongPress:
                                    (eq) {}, // No long press action in palette
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          // Main canvas area
          Expanded(
            child: InteractiveViewer(
              constrained: false,
              boundaryMargin: const EdgeInsets.all(500),
              minScale: 0.1,
              maxScale: 4.0,
              panEnabled: !sldState.isDragging, // Disable pan when dragging
              child: DragTarget<String>(
                onAcceptWithDetails: (details) {
                  final RenderBox renderBox =
                      _canvasKey.currentContext?.findRenderObject()
                          as RenderBox;
                  final localOffset = renderBox.globalToLocal(details.offset);
                  _onEquipmentDropped(context, localOffset, details.data);
                },
                builder: (context, candidateData, rejectedData) {
                  return GestureDetector(
                    onTap: () {
                      if (!sldState.isDragging) {
                        sldState.selectEquipment(null);
                        sldState.selectConnection(null);
                        sldState.setConnectionStartEquipment(null);
                      }
                    },
                    child: Container(
                      key: _canvasKey,
                      color: Colors.grey[200],
                      width: _canvasWidth, // Use constant width
                      height: _canvasHeight, // Use constant height
                      child: Stack(
                        children: [
                          // Render Grid
                          CustomPaint(
                            painter: SldGridPainter(
                              canvasWidth: _canvasWidth,
                              canvasHeight: _canvasHeight,
                              gridColor: colorScheme.onSurface,
                              gridSize:
                                  20.0, // Provide a suitable grid size value
                            ),
                            size: Size.infinite,
                          ),

                          // Render Connections (background layer)
                          CustomPaint(
                            painter: ConnectionPainter(
                              equipment: sldState.placedEquipment.values
                                  .toList(),
                              connections: sldState.connections,
                              onConnectionTap: (connection) {
                                sldState.selectConnection(connection);
                              },
                              selectedConnection: sldState.selectedConnection,
                              colorScheme: colorScheme,
                              gridSize:
                                  20.0, // Provide the required gridSize argument
                            ),
                            size: Size.infinite, // Fill the stack
                          ),

                          // Render Equipment Nodes (foreground layer)
                          ...sldState.placedEquipment.values.map((equipment) {
                            return Positioned(
                              left: equipment.positionX,
                              top: equipment.positionY,
                              child: SldEquipmentNode(
                                equipment: equipment,
                                colorScheme: colorScheme,
                                onDoubleTap: (eq) {
                                  sldState.selectEquipment(eq);
                                  showEditPropertiesModal(context, eq);
                                },
                                onLongPress: (eq) {
                                  // This long press now initiates a connection if not already in connection mode
                                  if (sldState.connectionStartEquipment ==
                                      null) {
                                    sldState.setConnectionStartEquipment(eq);
                                    SnackBarUtils.showSnackBar(
                                      context,
                                      'Selected ${eq.name} to start connection. Now tap another equipment to complete.',
                                    );
                                  } else if (sldState
                                          .connectionStartEquipment
                                          ?.id ==
                                      eq.id) {
                                    // Tapping the same equipment again cancels connection mode
                                    sldState.setConnectionStartEquipment(null);
                                    SnackBarUtils.showSnackBar(
                                      context,
                                      'Connection mode cancelled.',
                                    );
                                  } else {
                                    // Complete connection if already in connection mode and different equipment
                                    final newConnection = ElectricalConnection(
                                      substationId: widget.substation.id,
                                      fromEquipmentId:
                                          sldState.connectionStartEquipment!.id,
                                      toEquipmentId: eq.id,
                                    );
                                    sldState.addConnection(newConnection);
                                    sldState.setConnectionStartEquipment(null);
                                    SnackBarUtils.showSnackBar(
                                      context,
                                      'Connected ${sldState.connectionStartEquipment!.name} to ${eq.name}.',
                                    );
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddElementModalDialog(context, sldState),
        tooltip: 'Add New SLD Element',
        child: const Icon(Icons.add),
      ),
    );
  }
}
