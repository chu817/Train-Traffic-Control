from datetime import datetime, timedelta
from models.train import Train, TrainType
import heapq

class BasicScheduler:
    def __init__(self, trains, stations, tracks):
        self.trains = trains
        self.stations = {s['code']: s for s in stations}
        self.tracks = {t['track_id']: t for t in tracks}
        self.schedule = {}
        
    def create_initial_schedule(self):
        # Sort trains by priority then by scheduled time
        sorted_trains = sorted(self.trains, key=lambda t: (t['priority'], t['scheduled_departure']))
        
        schedule = {}
        track_occupancy = {}  # track_id: [(start, end, train_id)]
        
        for train_data in sorted_trains:
            train_id = train_data['train_id']
            
            # Find route from source to destination
            route_tracks = self.find_route_tracks(train_data['source'], train_data['destination'])
            
            if not route_tracks:
                continue
                
            # Calculate travel times and assign tracks
            current_time = datetime.fromisoformat(train_data['scheduled_departure'])
            assigned_tracks = []
            conflict = False
            
            for track_id in route_tracks:
                track = self.tracks[track_id]
                travel_time = (track['distance_km'] / train_data.get('speed_kmh', 80)) * 60  # minutes
                end_time = current_time + timedelta(minutes=travel_time)
                
                # Check track availability
                if track_id not in track_occupancy:
                    track_occupancy[track_id] = []
                
                # Simple conflict check - ensure 15 min buffer
                buffer = timedelta(minutes=15)
                available = True
                
                for start, end, _ in track_occupancy[track_id]:
                    if not (end_time + buffer <= start or current_time - buffer >= end):
                        available = False
                        break
                
                if not available:
                    # Try to delay train
                    delay_needed = 30  # minutes
                    current_time += timedelta(minutes=delay_needed)
                    end_time = current_time + timedelta(minutes=travel_time)
                
                track_occupancy[track_id].append((current_time, end_time, train_id))
                assigned_tracks.append({
                    'track_id': track_id,
                    'start_time': current_time.isoformat(),
                    'end_time': end_time.isoformat()
                })
                
                current_time = end_time
            
            schedule[train_id] = {
                'train_id': train_id,
                'assigned_tracks': assigned_tracks,
                'final_arrival': current_time.isoformat(),
                'total_delay': (current_time - datetime.fromisoformat(train_data['scheduled_arrival'])).total_seconds() / 60
            }
        
        self.schedule = schedule
        return schedule
    
    def find_route_tracks(self, source, destination):
        # Simple direct route finding
        # In real implementation, use graph algorithms
        up_track = f"{source}-{destination}-UP"
        down_track = f"{destination}-{source}-DOWN"
        
        if up_track in self.tracks:
            return [up_track]
        elif down_track in self.tracks:
            return [down_track]
        else:
            # Find intermediate route (simplified)
            for track_id, track in self.tracks.items():
                if track['from_station'] == source:
                    return [track_id]  # Single hop for now
        
        return []