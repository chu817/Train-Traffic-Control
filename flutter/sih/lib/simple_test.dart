import 'package:flutter/material.dart';
import 'services/train_api_service.dart';

void main() async {
  print('🧪 Testing station API...');
  try {
    final stations = await TrainApiService.getStations();
    print('✅ Successfully loaded ${stations.length} stations');
    if (stations.isNotEmpty) {
      print('📋 First station: ${stations.first.name} (${stations.first.id})');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
