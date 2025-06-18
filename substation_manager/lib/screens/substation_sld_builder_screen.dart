// lib/screens/substation_sld_builder_screen.dart

import 'package:flutter/material.dart';
import 'package:substation_manager/models/substation.dart';
import 'package:substation_manager/models/equipment.dart';
import 'package:substation_manager/models/electrical_connection.dart';
import 'package:substation_manager/services/equipment_firestore_service.dart';
import 'package:substation_manager/services/electrical_connection_firestore_service.dart';
import 'package:substation_manager/utils/snackbar_utils.dart';
import 'package:substation_manager/screens/equipment_detail_screen.dart'; // To navigate to equipment detail
// For min function
import 'dart:async'; // For StreamSubscription
// For Image drawing
import 'package:vector_math/vector_math_64.dart' as vmath; // For Vector3

// Helper to draw equipment symbols (Simplified for now)
class EquipmentPainter extends CustomPainter {
  final List<Equipment> equipment;
  final List<ElectricalConnection> connections;
  final Function(String equipmentId) onEquipmentTap;
  final double scaleFactor; // Scale factor for drawing

  // Keep track of drawn equipment boundaries for hit-testing
  final Map<String, Rect> _equipmentBounds = {};

  EquipmentPainter({
    required this.equipment,
    required this.connections,
    required this.onEquipmentTap,
    this.scaleFactor = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _equipmentBounds.clear(); // Clear old bounds

    final double equipmentSize =
        50.0 / scaleFactor; // Size of equipment symbol relative to zoom
    final double strokeWidth =
        2.0 / scaleFactor; // Stroke width relative to zoom
    final double fontSize = 10.0 / scaleFactor; // Font size relative to zoom

    // Draw Connections First (so equipment can overlay them)
    final Paint connectionPaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (var conn in connections) {
      final Equipment? fromEq = equipment.firstWhereOrNull(
        (eq) => eq.id == conn.fromEquipmentId,
      );
      final Equipment? toEq = equipment.firstWhereOrNull(
        (eq) => eq.id == conn.toEquipmentId,
      );

      if (fromEq != null && toEq != null) {
        // Calculate absolute pixel coordinates for equipment centers
        final Offset fromCenter = Offset(
          fromEq.positionX * size.width,
          fromEq.positionY * size.height,
        );
        final Offset toCenter = Offset(
          toEq.positionX * size.width,
          toEq.positionY * size.height,
        );

        if (conn.points.isEmpty) {
          // Draw straight line if no intermediate points
          canvas.drawLine(fromCenter, toCenter, connectionPaint);
        } else {
          // Draw path if intermediate points are provided
          final Path path = Path();
          path.moveTo(fromCenter.dx, fromCenter.dy);
          for (var p in conn.points) {
            path.lineTo(p['x']! * size.width, p['y']! * size.height);
          }
          path.lineTo(toCenter.dx, toCenter.dy);
          canvas.drawPath(path, connectionPaint);
        }
      }
    }

    // Draw Equipment Symbols
    final Paint equipmentFillPaint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.fill;
    final Paint equipmentBorderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (var eq in equipment) {
      final double x = eq.positionX * size.width;
      final double y = eq.positionY * size.height;

      // Draw simplified symbol based on equipmentType
      Rect bounds;
      switch (eq.equipmentType) {
        case 'Circuit Breaker':
          // Draw a square for CB
          bounds = Rect.fromCenter(
            center: Offset(x, y),
            width: equipmentSize,
            height: equipmentSize,
          );
          canvas.drawRect(bounds, equipmentFillPaint);
          canvas.drawRect(bounds, equipmentBorderPaint);
          break;
        case 'Power Transformer':
          // Draw a rectangle for Transformer
          bounds = Rect.fromCenter(
            center: Offset(x, y),
            width: equipmentSize * 1.5,
            height: equipmentSize,
          );
          canvas.drawRect(bounds, equipmentFillPaint);
          canvas.drawRect(bounds, equipmentBorderPaint);
          break;
        case 'Busbar':
          // Draw a horizontal line for Busbar (or thick rectangle)
          bounds = Rect.fromCenter(
            center: Offset(x, y),
            width: equipmentSize * 2,
            height: equipmentSize * 0.3,
          );
          canvas.drawRect(bounds, equipmentFillPaint);
          canvas.drawRect(bounds, equipmentBorderPaint);
          break;
        case 'Current Transformer (CT)':
        case 'Voltage Transformer (VT/PT)':
          // Draw a circle for CT/VT
          bounds = Rect.fromCircle(
            center: Offset(x, y),
            radius: equipmentSize * 0.4,
          );
          canvas.drawCircle(
            Offset(x, y),
            equipmentSize * 0.4,
            equipmentFillPaint,
          );
          canvas.drawCircle(
            Offset(x, y),
            equipmentSize * 0.4,
            equipmentBorderPaint,
          );
          break;
        default:
          // Default to a small circle/dot for other equipment
          bounds = Rect.fromCircle(
            center: Offset(x, y),
            radius: equipmentSize * 0.2,
          );
          canvas.drawCircle(
            Offset(x, y),
            equipmentSize * 0.2,
            equipmentFillPaint,
          );
          canvas.drawCircle(
            Offset(x, y),
            equipmentSize * 0.2,
            equipmentBorderPaint,
          );
      }

      // Store bounds for hit-testing
      _equipmentBounds[eq.id] = bounds;

      // Draw equipment name text
      textPainter.text = TextSpan(
        text: eq.name,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  // Custom hit-testing logic: determines which equipment was tapped
  String? equipmentHitTest(Offset position) {
    for (var entry in _equipmentBounds.entries) {
      if (entry.value.contains(position)) {
        return entry.key; // Return equipment ID if tapped
      }
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Repaint if equipment or connections list changes or scaleFactor changes
    if (oldDelegate is EquipmentPainter &&
        (oldDelegate.equipment != equipment ||
            oldDelegate.connections != connections ||
            oldDelegate.scaleFactor != scaleFactor)) {
      return true;
    }
    return false;
  }
}

// Extension to allow firstWhereOrNull
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}

class SubstationSLDBuilderScreen extends StatefulWidget {
  final Substation
  substation; // The substation whose SLD we are building/viewing

  const SubstationSLDBuilderScreen({super.key, required this.substation});

  @override
  State<SubstationSLDBuilderScreen> createState() =>
      _SubstationSLDBuilderScreenState();
}

class _SubstationSLDBuilderScreenState
    extends State<SubstationSLDBuilderScreen> {
  final EquipmentFirestoreService _equipmentService =
      EquipmentFirestoreService();
  final ElectricalConnectionFirestoreService _connectionService =
      ElectricalConnectionFirestoreService();

  List<Equipment> _equipment = [];
  List<ElectricalConnection> _connections = [];
  bool _isLoading = true;
  String? _tappedEquipmentId; // Track which equipment was tapped

  // GlobalKey for CustomPaint so we can access its painter for hit-testing
  final GlobalKey _paintKey = GlobalKey();
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _loadSldData();
    _transformationController.addListener(_onScaleChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onScaleChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onScaleChanged() {
    // Trigger a repaint of the CustomPaint when scale changes to adjust symbol sizes
    setState(() {});
  }

  Future<void> _loadSldData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final fetchedEquipment = await _equipmentService.getEquipmentOnce(
        substationId: widget.substation.id,
      );
      final fetchedConnections = await _connectionService.getConnectionsOnce(
        substationId: widget.substation.id,
      );

      setState(() {
        _equipment = fetchedEquipment;
        _connections = fetchedConnections;
      });
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Error loading SLD data: $e',
          isError: true,
        );
      }
      print('Error loading SLD data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleTapDown(TapDownDetails details) {
    final RenderBox renderBox =
        _paintKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    // Get the inverse matrix from the InteractiveViewer's controller
    final Matrix4 inverseMatrix = _transformationController.value.clone()
      ..invert();

    // Transform the local tap position (relative to the widget) back to the painter's coordinate system
    // This accounts for panning and zooming applied by InteractiveViewer
    final vmath.Vector3 transformedVector = inverseMatrix.transform3(
      vmath.Vector3(localPosition.dx, localPosition.dy, 0),
    );
    final Offset transformedPosition = Offset(
      transformedVector.x,
      transformedVector.y,
    );

    // Pass the untransformed position to the CustomPainter for hit-testing
    final EquipmentPainter painter = EquipmentPainter(
      equipment: _equipment,
      connections: _connections,
      onEquipmentTap: _onEquipmentTapped,
      scaleFactor: _transformationController.value.getMaxScaleOnAxis(),
    );
    final String? tappedId = painter.equipmentHitTest(transformedPosition);

    setState(() {
      _tappedEquipmentId = tappedId;
    });

    if (tappedId != null) {
      _onEquipmentTapped(tappedId);
    }
  }

  Future<void> _onEquipmentTapped(String equipmentId) async {
    final tappedEquipment = _equipment.firstWhereOrNull(
      (eq) => eq.id == equipmentId,
    );
    if (tappedEquipment != null && mounted) {
      SnackBarUtils.showSnackBar(
        context,
        'Tapped on: ${tappedEquipment.name} (${tappedEquipment.equipmentType})',
      );
      // Navigate to EquipmentDetailScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              EquipmentDetailScreen(equipment: tappedEquipment),
        ),
      );
    }
  }

  // Placeholder for adding new equipment
  void _addEquipment() {
    if (mounted) {
      SnackBarUtils.showSnackBar(
        context,
        'Add Equipment functionality coming soon!',
      );
      // TODO: Implement a dialog or new screen to add equipment,
      // and allow placing it on the canvas (e.g., tap on canvas).
    }
  }

  // Placeholder for adding new connection
  void _addConnection() {
    if (mounted) {
      SnackBarUtils.showSnackBar(
        context,
        'Add Connection functionality coming soon!',
      );
      // TODO: Implement logic to select two equipment and create a connection.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('${widget.substation.name} SLD Builder')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Define a fixed canvas size for drawing consistency regardless of screen size
    // The InteractiveViewer will handle scaling/panning of this canvas.
    final Size sldCanvasSize = Size(1600, 1000); // Example large canvas size

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.substation.name} SLD Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box),
            onPressed: _addEquipment,
            tooltip: 'Add Equipment',
          ),
          IconButton(
            icon: const Icon(Icons.add_link),
            onPressed: _addConnection,
            tooltip: 'Add Connection',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(80.0), // Margin for panning
            minScale: 0.1,
            maxScale: 4.0,
            onInteractionEnd: (details) {
              setState(() {
                // Trigger repaint to update scaleFactor for text/equipment size
              });
            },
            child: GestureDetector(
              key: _paintKey, // Key for hit-testing
              onTapDown: _handleTapDown,
              child: CustomPaint(
                size: sldCanvasSize, // The intrinsic size of our drawing canvas
                painter: EquipmentPainter(
                  equipment: _equipment,
                  connections: _connections,
                  onEquipmentTap: _onEquipmentTapped,
                  scaleFactor: _transformationController.value
                      .getMaxScaleOnAxis(),
                ),
                child: Container(
                  // Optional: background for the drawing canvas
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
