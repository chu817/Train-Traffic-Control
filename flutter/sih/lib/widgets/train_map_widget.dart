import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TrainMapWidget extends StatefulWidget {
  final double? initialZoom;
  final LatLng? initialCenter;
  final List<TrainMarker>? trainMarkers;
  final List<LatLng>? routePoints;
  final List<StationMarker>? stationMarkers;
  final LatLngBounds? bounds;
  final bool autoFitBounds;
  final Function(LatLng)? onTap;
  final Function(LatLng)? onLongPress;
  final List<Polyline>? extraPolylines;
  final List<Marker>? customMarkers;

  const TrainMapWidget({
    super.key,
    this.initialZoom = 6.0,
    this.initialCenter,
    this.trainMarkers,
    this.routePoints,
    this.stationMarkers,
    this.bounds,
    this.autoFitBounds = false,
    this.onTap,
    this.onLongPress,
    this.extraPolylines,
    this.customMarkers,
  });

  @override
  State<TrainMapWidget> createState() => _TrainMapWidgetState();
}

class _TrainMapWidgetState extends State<TrainMapWidget> {
  late MapController _mapController;
  LatLng _center = const LatLng(20.5937, 78.9629); // Default to India center
  double _zoom = 6.0;
  StationMarker? _hoveredStation;
  TrainMarker? _hoveredTrain;

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
  void didUpdateWidget(TrainMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Auto-fit bounds when bounds change
    if (widget.autoFitBounds && widget.bounds != null && widget.bounds != oldWidget.bounds) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fitBounds(widget.bounds!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
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

        // Extra polylines (alternates, failed segments, etc.)
        if (widget.extraPolylines != null && widget.extraPolylines!.isNotEmpty)
          PolylineLayer(polylines: widget.extraPolylines!),
        
        // Station markers (if provided)
        if (widget.stationMarkers != null && widget.stationMarkers!.isNotEmpty)
          MarkerLayer(
            markers: widget.stationMarkers!.map((station) {
              return Marker(
                point: station.position,
                width: 20,
                height: 20,
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hoveredStation = station),
                  onExit: (_) => setState(() => _hoveredStation = null),
                  child: _buildStationMarker(station),
                ),
              );
            }).toList(),
          ),
        
        // Train markers (if provided)
        if (widget.trainMarkers != null && widget.trainMarkers!.isNotEmpty)
          MarkerLayer(
            markers: widget.trainMarkers!.map((train) {
              return Marker(
                point: train.position,
                width: 30,
                height: 30,
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hoveredTrain = train),
                  onExit: (_) => setState(() => _hoveredTrain = null),
                  child: _buildTrainMarker(train),
                ),
              );
            }).toList(),
          ),

        // Custom markers (overlays like X on failed segment)
        if (widget.customMarkers != null && widget.customMarkers!.isNotEmpty)
          MarkerLayer(markers: widget.customMarkers!),
      ],
        ),
        
        // Station tooltip overlay
        if (_hoveredStation != null)
          Positioned(
            top: 20,
            left: 20,
            child: _buildStationTooltip(_hoveredStation!),
          ),
        
        // Train tooltip overlay
        if (_hoveredTrain != null)
          Positioned(
            top: 20,
            right: 20,
            child: _buildTrainTooltip(_hoveredTrain!),
          ),
      ],
    );
  }

  Widget _buildStationMarker(StationMarker station) {
    Color color;
    IconData icon;
    
    if (station.isUserStation) {
      // User's selected station - make it prominent
      color = const Color(0xFF0D47A1);
      icon = Icons.location_city;
    } else if (station.type == 'major') {
      // Major station
      color = const Color(0xFF1976D2);
      icon = Icons.train;
    } else {
      // Minor station
      color = const Color(0xFF42A5F5);
      icon = Icons.place;
    }

    return Container(
      decoration: BoxDecoration(
        color: color,
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
        icon,
        color: Colors.white,
        size: station.isUserStation ? 14 : 12,
      ),
    );
  }

  Widget _buildTrainMarker(TrainMarker train) {
    Color color;
    IconData icon;
    double size;
    
    switch (train.status) {
      case TrainStatus.running:
        color = const Color(0xFF4CAF50); // Green for running
        icon = Icons.train;
        size = 20;
        break;
      case TrainStatus.delayed:
        color = const Color(0xFFFF9800); // Orange for delayed
        icon = Icons.schedule;
        size = 18;
        break;
      case TrainStatus.stopped:
        color = const Color(0xFFF44336); // Red for stopped
        icon = Icons.stop;
        size = 18;
        break;
      case TrainStatus.maintenance:
        color = const Color(0xFF9E9E9E); // Grey for maintenance
        icon = Icons.build;
        size = 16;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: train.color ?? color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: (train.color ?? color).withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: train.status == TrainStatus.running 
        ? TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.2),
            duration: const Duration(milliseconds: 1000),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: size,
                ),
              );
            },
            onEnd: () {
              // Restart animation
              setState(() {});
            },
          )
        : Icon(
            icon,
            color: Colors.white,
            size: size,
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
  Widget _buildTrainTooltip(TrainMarker train) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _getTrainStatusColor(train.status),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getTrainStatusIcon(train.status),
                color: _getTrainStatusColor(train.status),
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  train.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Train Number: ${train.id}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            'Status: ${_getTrainStatusText(train.status)}',
            style: TextStyle(
              fontSize: 14,
              color: _getTrainStatusColor(train.status),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (train.route != null)
            Text(
              'Route: ${train.route}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          if (train.lastUpdate != null)
            Text(
              'Last Update: ${_formatTime(train.lastUpdate!)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  Color _getTrainStatusColor(TrainStatus status) {
    switch (status) {
      case TrainStatus.running:
        return const Color(0xFF4CAF50);
      case TrainStatus.delayed:
        return const Color(0xFFFF9800);
      case TrainStatus.stopped:
        return const Color(0xFFF44336);
      case TrainStatus.maintenance:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _getTrainStatusIcon(TrainStatus status) {
    switch (status) {
      case TrainStatus.running:
        return Icons.train;
      case TrainStatus.delayed:
        return Icons.schedule;
      case TrainStatus.stopped:
        return Icons.stop;
      case TrainStatus.maintenance:
        return Icons.build;
    }
  }

  String _getTrainStatusText(TrainStatus status) {
    switch (status) {
      case TrainStatus.running:
        return 'Running';
      case TrainStatus.delayed:
        return 'Delayed';
      case TrainStatus.stopped:
        return 'Stopped';
      case TrainStatus.maintenance:
        return 'Maintenance';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStationTooltip(StationMarker station) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      border: Border.all(
        color: station.isUserStation ? const Color(0xFF0D47A1) : 
               station.type == 'major' ? const Color(0xFF1976D2) : const Color(0xFF42A5F5),
        width: 2,
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              station.isUserStation ? Icons.location_city :
              station.type == 'major' ? Icons.train : Icons.place,
              color: station.isUserStation ? const Color(0xFF0D47A1) : 
                     station.type == 'major' ? const Color(0xFF1976D2) : const Color(0xFF42A5F5),
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                station.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Station Code: ${station.id}',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Text(
          'Type: ${station.type.toUpperCase()}',
          style: TextStyle(
            fontSize: 14,
            color: station.type == 'major' ? const Color(0xFF1976D2) : const Color(0xFF42A5F5),
            fontWeight: FontWeight.w500,
          ),
        ),
        if (station.isUserStation)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'YOUR STATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
          ),
      ],
    ),
  );
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
  final Color? color;

  const TrainMarker({
    required this.id,
    required this.name,
    required this.position,
    required this.status,
    this.route,
    this.lastUpdate,
    this.color,
  });
}

enum TrainStatus {
  running,
  delayed,
  stopped,
  maintenance,
}

class StationMarker {
  final String id;
  final String name;
  final LatLng position;
  final String type;
  final bool isUserStation;

  StationMarker({
    required this.id,
    required this.name,
    required this.position,
    required this.type,
    this.isUserStation = false,
  });
}

