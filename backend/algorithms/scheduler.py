from datetime import datetime, timedelta
import heapq

class BasicScheduler:
    def __init__(self, trains, stations, tracks):
        self.trains = trains
        self.stations = {s['code']: s for s in stations}
        self.tracks = {t['track_id']: t for t in tracks}
        self.schedule = {}
        
    def create_initial_schedule(self):
        """
        FCFS scheduling with multi-station route support
        """
        # Sort trains by priority then by scheduled time
        sorted_trains = sorted(self.trains, key=lambda t: (t['priority'], t['scheduled_departure']))
        
        schedule = {}
        track_occupancy = {}  # track_id: [(start, end, train_id)]
        
        for train_data in sorted_trains:
            train_id = train_data['train_id']
            route = train_data.get('route', [train_data['source'], train_data['destination']])
            
            # Calculate journey through all stations in route
            current_time = datetime.fromisoformat(train_data['scheduled_departure'])
            segment_times = []
            total_delay = 0
            
            for i in range(len(route) - 1):
                from_station = route[i]
                to_station = route[i + 1]
                
                # Find available track for this segment
                segment_tracks = self.find_segment_tracks(from_station, to_station)
                if not segment_tracks:
                    continue
                
                # Choose best available track
                chosen_track = self.choose_best_track(segment_tracks, current_time, track_occupancy, train_data)
                
                # Calculate travel time
                track_info = self.tracks[chosen_track]
                distance = track_info['distance_km']
                speed = min(train_data.get('speed_kmh', 80), track_info['max_speed'])
                travel_time_hours = distance / speed
                travel_time_minutes = travel_time_hours * 60
                
                # Add station dwell time
                dwell_time = self.get_dwell_time(to_station, train_data, i == len(route) - 2)
                
                # Calculate segment end time
                segment_end = current_time + timedelta(minutes=travel_time_minutes + dwell_time)
                
                # Check for conflicts and add delay if needed
                conflict_delay = self.check_track_conflicts(chosen_track, current_time, segment_end, track_occupancy)
                if conflict_delay > 0:
                    current_time += timedelta(minutes=conflict_delay)
                    segment_end += timedelta(minutes=conflict_delay)
                    total_delay += conflict_delay
                
                # Record track occupancy
                if chosen_track not in track_occupancy:
                    track_occupancy[chosen_track] = []
                track_occupancy[chosen_track].append((current_time, segment_end, train_id))
                
                segment_times.append({
                    'from': from_station,
                    'to': to_station,
                    'track': chosen_track,
                    'start': current_time.isoformat(),
                    'end': segment_end.isoformat(),
                    'travel_time': travel_time_minutes
                })
                
                current_time = segment_end
            
            # Calculate final arrival (ensure not earlier than scheduled)
            scheduled_arrival = datetime.fromisoformat(train_data['scheduled_arrival'])
            final_arrival = max(current_time, scheduled_arrival)
            actual_delay = max(0, (final_arrival - scheduled_arrival).total_seconds() / 60)
            
            schedule[train_id] = {
                'train_id': train_id,
                'segments': segment_times,
                'final_arrival': final_arrival.isoformat(),
                'total_delay': actual_delay,
                'status': 'scheduled'
            }
        
        self.schedule = schedule
        return schedule
    
    def find_segment_tracks(self, from_station, to_station):
        """Find all available tracks between two stations"""
        tracks = []
        for track_id, track in self.tracks.items():
            if track['from_station'] == from_station and track['to_station'] == to_station:
                tracks.append(track_id)
        return tracks
    
    def choose_best_track(self, available_tracks, start_time, occupancy, train_data):
        """Choose the best track based on conflicts and train priority"""
        if not available_tracks:
            return None
        
        # Score tracks by conflicts and suitability
        best_track = None
        min_conflicts = float('inf')
        
        for track_id in available_tracks:
            conflicts = 0
            if track_id in occupancy:
                for occ_start, occ_end, _ in occupancy[track_id]:
                    # Simple overlap check
                    if start_time < occ_end and start_time + timedelta(hours=2) > occ_start:
                        conflicts += 1
            
            if conflicts < min_conflicts:
                min_conflicts = conflicts
                best_track = track_id
        
        return best_track or available_tracks[0]
    
    def check_track_conflicts(self, track_id, start_time, end_time, occupancy):
        """Check for conflicts and return additional delay needed"""
        if track_id not in occupancy:
            return 0
        
        max_delay = 0
        for occ_start, occ_end, _ in occupancy[track_id]:
            # If there's overlap, delay until track is free
            if start_time < occ_end and end_time > occ_start:
                required_delay = (occ_end - start_time).total_seconds() / 60 + 5  # 5 min buffer
                max_delay = max(max_delay, required_delay)
        
        return max_delay
    
    def get_dwell_time(self, station_code, train_data, is_destination):
        """Calculate station dwell time based on train type and station"""
        if is_destination:
            return 0  # No dwell time at final destination
        
        station = self.stations.get(station_code, {})
        
        # Base dwell time by train type
        if train_data['type'] == 'passenger':
            base_dwell = 2
        elif train_data['type'] == 'express':
            base_dwell = 1
        else:  # freight
            base_dwell = 5
        
        # Adjust for station importance
        if station.get('is_terminus', False):
            base_dwell += 3
        elif station.get('platforms', 2) > 6:
            base_dwell += 1
        
        return base_dwell
