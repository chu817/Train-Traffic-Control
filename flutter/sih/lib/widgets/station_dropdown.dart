import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/train_api_service.dart';

class StationDropdown extends StatefulWidget {
  final String? initialStation;
  final ValueChanged<String> onChanged;

  const StationDropdown({super.key, this.initialStation, required this.onChanged});

  @override
  State<StationDropdown> createState() => _StationDropdownState();
}

class _StationDropdownState extends State<StationDropdown> {
  final TextEditingController _controller = TextEditingController();
  String? _selected;
  List<StationData> _stations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialStation;
    if (_selected != null) _controller.text = _selected!;
    _loadStations();
  }

  Future<void> _loadStations() async {
    try {
      print('🔍 Loading stations from API...');
      final stations = await TrainApiService.getStations();
      print('✅ Loaded ${stations.length} stations from API');
      setState(() {
        _stations = stations;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading stations: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: 'Station',
          prefixIcon: Icon(Icons.train, color: Colors.grey[600]),
          suffixIcon: const SizedBox(
            width: 20,
            height: 20,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        enabled: false,
      );
    }

    if (_error != null) {
      return TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: 'Station (Error loading)',
          prefixIcon: Icon(Icons.error, color: Colors.red[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.red[300]!),
          ),
          filled: true,
          fillColor: Colors.red[50],
        ),
        enabled: false,
      );
    }

    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _selected ?? ''),
      optionsBuilder: (TextEditingValue value) {
        final q = value.text.trim();
        if (q.isEmpty) {
          // Show first 20 stations when no search query to improve performance
          return _stations.take(20).map((s) => s.name).toList();
        }
        
        // Enhanced search - search in name, zone, and state
        final results = _stations.where((s) {
          final searchText = '${s.name} ${s.zone} ${s.state}'.toLowerCase();
          return searchText.contains(q.toLowerCase());
        }).toList();
        
        // Sort results: exact matches first, then starts with, then contains
        results.sort((a, b) {
          final aName = a.name.toLowerCase();
          final bName = b.name.toLowerCase();
          final query = q.toLowerCase();
          
          if (aName == query && bName != query) return -1;
          if (aName != query && bName == query) return 1;
          if (aName.startsWith(query) && !bName.startsWith(query)) return -1;
          if (!aName.startsWith(query) && bName.startsWith(query)) return 1;
          return aName.compareTo(bName);
        });
        
        // Limit results to 100 for performance
        return results.take(100).map((s) => s.name).toList();
      },
      displayStringForOption: (s) => s,
      onSelected: (s) {
        setState(() {
          _selected = s;
          _controller.text = s;
        });
        widget.onChanged(s);
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        // Keep controller in sync with initial value
        if ((_selected ?? '').isNotEmpty && textEditingController.text.isEmpty) {
          textEditingController.text = _selected!;
        }
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Station',
            prefixIcon: Icon(Icons.train, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final opts = options.toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 400, 
                minWidth: 400,
                maxWidth: 500,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with search info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${opts.length} stations found',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        if (opts.length > 10)
                          Text(
                            'Scroll to see more',
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Scrollable list
                  Flexible(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: opts.length,
                      itemBuilder: (context, index) {
                        final stationName = opts[index];
                        final station = _stations.firstWhere(
                          (s) => s.name == stationName,
                          orElse: () => StationData(
                            id: '',
                            name: stationName,
                            position: const LatLng(0, 0),
                            type: '',
                            platforms: 0,
                          ),
                        );
                        
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[200]!,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              station.type == 'major' ? Icons.train : Icons.location_on,
                              color: station.type == 'major' ? Colors.blue : Colors.orange,
                              size: 20,
                            ),
                            title: Text(
                              station.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: station.zone.isNotEmpty 
                                ? Text(
                                    '${station.zone} • ${station.state}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  )
                                : null,
                            trailing: station.type == 'major' 
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'MAJOR',
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : null,
                            onTap: () => onSelected(stationName),
                            hoverColor: Colors.blue[50],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


