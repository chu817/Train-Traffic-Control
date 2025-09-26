import json
from algorithms.scheduler import BasicScheduler
from algorithms.optimizer import TrainScheduleOptimizer
from algorithms.kpi_calculator import KPICalculator
from algorithms.event_handler import DisruptionHandler
from datetime import datetime

# Load data
print("Loading synthetic data...")
with open("data/synthetic_trains.json") as f:
    trains = json.load(f)

with open("data/synthetic_stations.json") as f:
    infra = json.load(f)
    stations = infra["stations"]
    tracks = infra["tracks"]

with open("data/synthetic_events.json") as f:
    events_data = json.load(f)

events = events_data.get('events', [])

print(f"Loaded: {len(trains)} trains, {len(stations)} stations, {len(tracks)} tracks, {len(events)} events")

# 1. FCFS Scheduling
print("\n=== FCFS (Priority + Multi-Route) Schedule ===")
fcfs_scheduler = BasicScheduler(trains, stations, tracks)
fcfs_schedule_dict = fcfs_scheduler.create_initial_schedule()

print("FCFS Results:")
for train_id, data in list(fcfs_schedule_dict.items())[:5]:  # Show first 5
    print(f"Train {train_id} | arrival: {data['final_arrival']} | delay: {data['total_delay']:.1f}m | segments: {len(data.get('segments', []))}")

fcfs_kpi = KPICalculator().calculate_kpis(fcfs_schedule_dict)
print(f"FCFS KPIs: Punctuality: {fcfs_kpi.get('punctuality_rate', 0):.1f}%, Avg Delay: {fcfs_kpi.get('average_delay_minutes', 0):.1f}m")

# 2. CP Optimizer Scheduling
print("\n=== CP Optimizer (Multi-Route Constraints) Schedule ===")
cp_optimizer = TrainScheduleOptimizer(trains, tracks, {s['code']: s for s in stations})
cp_schedule_dict = cp_optimizer.optimize_schedule()

if cp_schedule_dict:
    print("CP Optimizer Results:")
    for train_id, data in list(cp_schedule_dict.items())[:5]:  # Show first 5
        print(f"Train {train_id} | departure: {data['optimized_departure']} | delay: {data['delay_minutes']:.1f}m | segments: {len(data.get('segments', []))}")
    
    cp_kpi = KPICalculator().calculate_kpis(cp_schedule_dict)
    print(f"CP KPIs: Punctuality: {cp_kpi.get('punctuality_rate', 0):.1f}%, Avg Delay: {cp_kpi.get('average_delay_minutes', 0):.1f}m")
else:
    print("CP optimization failed, using FCFS schedule for comparison")
    cp_schedule_dict = fcfs_schedule_dict
    cp_kpi = fcfs_kpi

# 3. Compare FCFS vs CP KPIs
print("\n=== KPI Comparison ===")
comparison_metrics = ["punctuality_rate", "average_delay_minutes", "throughput_trains_per_hour"]
for key in comparison_metrics:
    fcfs_val = fcfs_kpi.get(key, 0)
    cp_val = cp_kpi.get(key, 0)
    improvement = ((cp_val - fcfs_val) / fcfs_val * 100) if fcfs_val > 0 else 0
    print(f"{key}: FCFS={fcfs_val:.2f} | CP={cp_val:.2f} | Improvement={improvement:+.1f}%")

# 4. Track Utilization Analysis
def analyze_track_conflicts(schedule, tracks):
    """Analyze track usage and potential conflicts"""
    track_usage = {}
    conflicts = 0
    
    for train_id, entry in schedule.items():
        segments = entry.get('segments', [])
        for segment in segments:
            track = segment.get('track', 'unknown')
            start_time = segment.get('start', '')
            end_time = segment.get('end', '')
            
            if track not in track_usage:
                track_usage[track] = []
            
            # Check for overlaps with existing usage
            for existing_start, existing_end, existing_train in track_usage[track]:
                if (start_time < existing_end and end_time > existing_start):
                    conflicts += 1
            
            track_usage[track].append((start_time, end_time, train_id))
    
    return conflicts, len(track_usage), sum(len(usage) for usage in track_usage.values())

fcfs_conflicts, fcfs_tracks_used, fcfs_total_segments = analyze_track_conflicts(fcfs_schedule_dict, tracks)
cp_conflicts, cp_tracks_used, cp_total_segments = analyze_track_conflicts(cp_schedule_dict, tracks)

print(f"\n=== Track Usage Analysis ===")
print(f"FCFS: {fcfs_conflicts} conflicts across {fcfs_tracks_used} tracks ({fcfs_total_segments} segments)")
print(f"CP: {cp_conflicts} conflicts across {cp_tracks_used} tracks ({cp_total_segments} segments)")
print(f"Conflict reduction: {fcfs_conflicts - cp_conflicts} ({((fcfs_conflicts - cp_conflicts) / max(fcfs_conflicts, 1) * 100):+.1f}%)")

# 5. Event/Disruption Test with Priority Handling
print(f"\n=== Disruption Event Test ===")
if events:
    test_event = events[0]
    print(f"Testing event: {test_event['description']}")
    print(f"Affected trains: {test_event['affected_trains']}")
    print(f"Expected duration: {test_event['expected_duration']} minutes")
    
    # Initialize disruption handler
    handler = DisruptionHandler(fcfs_scheduler, cp_optimizer)
    disrupted_schedule = handler.handle_disruption(test_event, cp_schedule_dict)
    
    print("\nAfter disruption handling:")
    affected_trains = test_event.get('affected_trains', [])
    for train_id in affected_trains:
        if train_id in disrupted_schedule:
            data = disrupted_schedule[train_id]
            status = data.get("status", "unknown")
            delay = data.get("delay_minutes", 0)
            reason = data.get("reason", "")
            print(f"Train {train_id}: status={status}, delay={delay:.1f}m, reason={reason}")
    
    # Calculate impact
    disrupted_kpi = KPICalculator().calculate_kpis(disrupted_schedule)
    print(f"\nPost-disruption KPIs: Punctuality: {disrupted_kpi.get('punctuality_rate', 0):.1f}%, Avg Delay: {disrupted_kpi.get('average_delay_minutes', 0):.1f}m")
    
    # Test multiple disruptions
    print(f"\n=== Multiple Disruption Test ===")
    multi_disrupted = disrupted_schedule
    for event in events[1:3]:  # Test next 2 events
        print(f"Applying: {event['description']}")
        multi_disrupted = handler.handle_disruption(event, multi_disrupted)
    
    multi_kpi = KPICalculator().calculate_kpis(multi_disrupted)
    print(f"After multiple disruptions: Punctuality: {multi_kpi.get('punctuality_rate', 0):.1f}%, Avg Delay: {multi_kpi.get('average_delay_minutes', 0):.1f}m")
    
else:
    print("No events found for testing")

# 6. Route Complexity Analysis
print(f"\n=== Route Complexity Analysis ===")
route_lengths = [len(train.get('route', [train['source'], train['destination']])) for train in trains]
avg_route_length = sum(route_lengths) / len(route_lengths)
max_route_length = max(route_lengths)
multi_station_trains = sum(1 for length in route_lengths if length > 2)

print(f"Average route length: {avg_route_length:.1f} stations")
print(f"Maximum route length: {max_route_length} stations")
print(f"Trains with intermediate stations: {multi_station_trains}/{len(trains)} ({multi_station_trains/len(trains)*100:.1f}%)")

# Show sample multi-station routes
print("\nSample multi-station routes:")
for train in trains[:3]:
    route = train.get('route', [train['source'], train['destination']])
    if len(route) > 2:
        print(f"Train {train['train_id']} ({train['name']}): {' -> '.join(route[:5])}{'...' if len(route) > 5 else ''}")

print(f"\n=== Test Completed Successfully ===")
print("Key improvements demonstrated:")
print("- Multi-station routing with intermediate stops")
print("- Multiple tracks between stations for conflict resolution")
print("- Priority-based disruption handling")
print("- Realistic train data with proper event correlation")
