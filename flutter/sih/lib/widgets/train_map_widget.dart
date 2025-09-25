import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TrainMapWidget extends StatefulWidget {
  final double? initialZoom;
  final LatLng? initialCenter;
  final List<TrainMarker>? trainMarkers;
  final List<LatLng>? routePoints;
  final Function(LatLng)? onTap;
  final Function(LatLng)? onLongPress;

  const TrainMapWidget({
    super.key,
    this.initialZoom = 6.0,
    this.initialCenter,
    this.trainMarkers,
    this.routePoints,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<TrainMapWidget> createState() => _TrainMapWidgetState();
}

class _TrainMapWidgetState extends State<TrainMapWidget> {
  late MapController _mapController;
  LatLng _center = const LatLng(20.5937, 78.9629); // Default to India center
  double _zoom = 6.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initialCenter != null) {
      _center = widget.initialCenter!;
    }
    if (widget.initialZoom != null) {
      _zoom = widget.initialZoom!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: _zoom,
        minZoom: 3.0,
        maxZoom: 18.0,
        onTap: (tapPosition, point) {
          widget.onTap?.call(point);
        },
        onLongPress: (tapPosition, point) {
          widget.onLongPress?.call(point);
        },
      ),
      children: [
        // OpenStreetMap tiles
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.sih',
          maxZoom: 18,
        ),
        
        // Route lines (if provided)
        if (widget.routePoints != null && widget.routePoints!.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.routePoints!,
                color: const Color(0xFF0D47A1),
                strokeWidth: 3.0,
              ),
            ],
          ),
        
        // Train markers (if provided)
        if (widget.trainMarkers != null && widget.trainMarkers!.isNotEmpty)
          MarkerLayer(
            markers: widget.trainMarkers!.map((train) {
              return Marker(
                point: train.position,
                width: 30,
                height: 30,
                child: _buildTrainMarker(train),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildTrainMarker(TrainMarker train) {
    return Container(
      decoration: BoxDecoration(
        color: train.status == TrainStatus.running 
            ? Colors.green 
            : train.status == TrainStatus.delayed 
                ? Colors.orange 
                : Colors.red,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.train,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  // Public methods to control the map
  void moveToLocation(LatLng location, {double? zoom}) {
    _mapController.move(location, zoom ?? _zoom);
  }

  void fitBounds(LatLngBounds bounds) {
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds));
  }

  void addTrainMarker(TrainMarker train) {
    setState(() {
      widget.trainMarkers?.add(train);
    });
  }

  void removeTrainMarker(String trainId) {
    setState(() {
      widget.trainMarkers?.removeWhere((train) => train.id == trainId);
    });
  }
}

// Data models for train markers
class TrainMarker {
  final String id;
  final String name;
  final LatLng position;
  final TrainStatus status;
  final String? route;
  final DateTime? lastUpdate;

  const TrainMarker({
    required this.id,
    required this.name,
    required this.position,
    required this.status,
    this.route,
    this.lastUpdate,
  });
}

enum TrainStatus {
  running,
  delayed,
  stopped,
  maintenance,
}

