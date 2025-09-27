#!/usr/bin/env python3
"""
Test script for train tracking functionality
"""

import os
from dotenv import load_dotenv
from train_tracker import TrainTracker

# Load environment variables
load_dotenv()

def test_train_tracking():
    api_key = os.getenv('RAILRADAR_API_KEY')
    print(f"API Key: {api_key[:10]}..." if api_key else "No API key found")
    
    if not api_key:
        print("❌ No API key found")
        return
    
    tracker = TrainTracker(api_key)
    
    # Test getting trains by stations
    print("\n🚂 Testing train search for RC and AGC...")
    trains = tracker.get_trains_by_stations(['RC', 'AGC'])
    print(f"Found {len(trains)} trains")
    
    for train in trains[:3]:  # Show first 3 trains
        print(f"  - {train['train_name']} ({train['train_number']})")
        print(f"    From: {train['source_station_code']} To: {train['destination_station_code']}")
    
    # Test getting live trains
    print("\n🚂 Testing live train data...")
    live_trains = tracker.get_live_train_locations()
    print(f"Found {len(live_trains)} live trains")
    
    for train in live_trains[:3]:  # Show first 3 trains
        print(f"  - {train['train_name']} ({train['train_number']})")
        print(f"    At: {train['current_station_name']} ({train['current_lat']}, {train['current_lng']})")
        print(f"    Status: {'HALT' if train['halt_mins'] > 0 else 'RUNNING'}")

if __name__ == "__main__":
    test_train_tracking()
