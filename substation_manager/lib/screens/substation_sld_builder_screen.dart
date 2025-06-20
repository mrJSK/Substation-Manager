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
        .getConnectionsStream(widget.substation.id)
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

    final newEquipment = Equipment(
      id: _uuid.v4(),
      substationId: widget.substation.id,
      bayId: 'default_sld_bay',
      equipmentType: template.equipmentType,
      masterTemplateId: template.id,
      name: '${template.equipmentType} ${_uuid.v4().substring(0, 4)}',
      positionX: canvasLocalPosition.dx,
      positionY: canvasLocalPosition.dy,
      customFieldValues: {},
      relays: [],
      energyMeters: [],
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
    }
  }

  void _addConnectionInteraction(SldState sldState) {
    if (sldState.selectedEquipment == null &&
        sldState.connectionStartEquipment == null) {
      SnackBarUtils.showSnackBar(
        context,
        'Select the first equipment to connect.',
      );
    } else if (sldState.selectedEquipment != null &&
        sldState.connectionStartEquipment == null) {
      sldState.setConnectionStartEquipment(sldState.selectedEquipment);
      SnackBarUtils.showSnackBar(
        context,
        'Selected ${sldState.selectedEquipment!.name}. Now tap another equipment to complete the connection.',
      );
    } else if (sldState.connectionStartEquipment != null) {
      sldState.setConnectionStartEquipment(null);
      SnackBarUtils.showSnackBar(context, 'Connection mode cancelled.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final sldState = context.watch<SldState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('SLD Builder: ${widget.substation.name}'),
        actions: [
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
          if (sldState.selectedEquipment != null ||
              sldState.selectedConnection != null ||
              sldState.connectionStartEquipment != null)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Delete Selected Item',
              onPressed: () => _deleteSelectedItem(sldState),
            ),
          IconButton(
            icon: Icon(
              Icons.link,
              color: sldState.connectionStartEquipment != null
                  ? Theme.of(context).colorScheme.tertiary
                  : null,
            ),
            tooltip: sldState.connectionStartEquipment != null
                ? 'Cancel Connection Mode'
                : 'Create Connection',
            onPressed: () => _addConnectionInteraction(sldState),
          ),
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
      body: Consumer<SldState>(
        builder: (context, sldState, child) {
          return Row(
            children: [
              Expanded(
                child: InteractiveViewer(
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(500),
                  minScale: 0.1,
                  maxScale: 4.0,
                  panEnabled: sldState.isCanvasPanEnabled,
                  child: DragTarget<String>(
                    onAcceptWithDetails: (details) {
                      final RenderBox renderBox =
                          _canvasKey.currentContext?.findRenderObject()
                              as RenderBox;
                      final localOffset = renderBox.globalToLocal(
                        details.offset,
                      );
                      _onEquipmentDropped(context, localOffset, details.data);
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        key: _canvasKey,
                        color: Colors.grey[200],
                        width: 3000.0,
                        height: 2000.0,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: () {
                                  if (!sldState.isDragging) {
                                    sldState.selectEquipment(null);
                                    sldState.selectConnection(null);
                                    sldState.setConnectionStartEquipment(null);
                                  }
                                  sldState.setIsDragging(false);
                                },
                                behavior: HitTestBehavior.translucent,
                              ),
                            ),
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
                                    sldState.selectEquipment(eq);
                                    showDialog(
                                      context: context,
                                      builder: (dialogContext) {
                                        return AlertDialog(
                                          title: Text(eq.name),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ListTile(
                                                leading: const Icon(Icons.edit),
                                                title: const Text(
                                                  'Edit Properties',
                                                ),
                                                onTap: () {
                                                  Navigator.pop(dialogContext);
                                                  showEditPropertiesModal(
                                                    context,
                                                    eq,
                                                  );
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(Icons.link),
                                                title: const Text(
                                                  'Create Connection',
                                                ),
                                                onTap: () {
                                                  Navigator.pop(dialogContext);
                                                  sldState
                                                      .setConnectionStartEquipment(
                                                        eq,
                                                      );
                                                  SnackBarUtils.showSnackBar(
                                                    context,
                                                    'Selected ${eq.name}. Now tap another equipment to complete the connection.',
                                                  );
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                title: const Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                                onTap: () {
                                                  Navigator.pop(dialogContext);
                                                  _deleteSelectedItem(sldState);
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              );
                            }),

                            // Render Connections
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
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddElementModal(
          context,
          sldState.availableTemplates,
        ), // Pass available templates
        tooltip: 'Add New SLD Element',
        child: const Icon(Icons.add),
      ),
    );
  }
}
