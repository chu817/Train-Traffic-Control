import 'package:flutter/material.dart';
import 'services/train_api_service.dart';

class DebugStationTest extends StatefulWidget {
  const DebugStationTest({super.key});

  @override
  State<DebugStationTest> createState() => _DebugStationTestState();
}

class _DebugStationTestState extends State<DebugStationTest> {
  List<StationData> stations = [];
  String status = 'Loading...';

  @override
  void initState() {
    super.initState();
    _testStations();
  }

  Future<void> _testStations() async {
    try {
      print('🧪 Testing station loading...');
      final result = await TrainApiService.getStations();
      setState(() {
        stations = result;
        status = 'Loaded ${result.length} stations';
      });
      print('✅ Test completed: ${result.length} stations');
    } catch (e) {
      setState(() {
        status = 'Error: $e';
      });
      print('❌ Test failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Station Debug Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $status', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            if (stations.isNotEmpty) ...[
              const Text('Sample Stations:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: stations.take(10).length,
                  itemBuilder: (context, index) {
                    final station = stations[index];
                    return Card(
                      child: ListTile(
                        title: Text(station.name),
                        subtitle: Text('Code: ${station.id}, Zone: ${station.zone}'),
                        trailing: Text('${station.position.latitude}, ${station.position.longitude}'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
