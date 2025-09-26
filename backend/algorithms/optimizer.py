from ortools.sat.python import cp_model
from datetime import datetime, timedelta

class TrainScheduleOptimizer:
    def __init__(self, trains, tracks, stations):
        self.trains = trains
        self.tracks = {t['track_id']: t for t in tracks}
        self.stations = stations
        self.model = cp_model.CpModel()
        
    def optimize_schedule(self):
        """
        CP-SAT solver with multi-station route optimization
        """
        train_vars = {}
        segment_vars = {}  # For route segments
        horizon = 48 * 60  # 48 hours in minutes
        
        print(f"[Optimizer] Starting optimization for {len(self.trains)} trains")
        
        # Create variables for each train's departure time
        for train in self.trains:
            train_id = train['train_id']
            earliest_dep = self.time_to_minutes(train['scheduled_departure'])
            
            train_vars[train_id] = self.model.NewIntVar(
                max(0, earliest_dep - 60),
                horizon,
                f'dep_{train_id}'
            )
            
            # Create segment variables for multi-station routes
            route = train.get('route', [train['source'], train['destination']])
            segment_vars[train_id] = []
            
            for i in range(len(route) - 1):
                from_station = route[i]
                to_station = route[i + 1]
                
                segment_start = self.model.NewIntVar(0, horizon, f'seg_{train_id}_{i}_start')
                travel_time = self.calculate_segment_travel_time(from_station, to_station, train)
                segment_end = self.model.NewIntVar(0, horizon, f'seg_{train_id}_{i}_end')
                
                # Constraint: segment_end = segment_start + travel_time
                self.model.Add(segment_end == segment_start + travel_time)
                
                segment_vars[train_id].append({
                    'start': segment_start,
                    'end': segment_end,
                    'from': from_station,
                    'to': to_station,
                    'travel_time': travel_time
                })
        
        print("[Optimizer] Created variables and segments")
        
        # Add track conflict constraints
        self.add_multi_route_track_constraints(segment_vars)
        
        # Add platform constraints
        self.add_platform_constraints(train_vars)
        
        # Add objective
        self.add_delay_objective(train_vars)
        
        print("[Optimizer] Added constraints, starting solve...")
        
        # Solve
        solver = cp_model.CpSolver()
        solver.parameters.max_time_in_seconds = 60.0
        
        status = solver.Solve(self.model)
        
        if status == cp_model.OPTIMAL or status == cp_model.FEASIBLE:
            # print(f"[Optimizer] Solution found with objective value: {solver.Objective().Value()}")
            print(f"[Optimizer] Solution found.")
            return self.extract_multi_route_solution(solver, train_vars, segment_vars)
        else:
            print("[Optimizer] No feasible solution found")
            return None
    
    def add_multi_route_track_constraints(self, segment_vars):
        """Add non-overlapping constraints for track segments"""
        print("[Optimizer] Adding track conflict constraints")
        
        # Group segments by track
        track_segments = {}
        
        for train_id, segments in segment_vars.items():
            for seg_idx, segment in enumerate(segments):
                from_station = segment['from']
                to_station = segment['to']
                
                # Find tracks for this segment
                possible_tracks = [track_id for track_id, track in self.tracks.items()
                                 if track['from_station'] == from_station and track['to_station'] == to_station]
                
                for track_id in possible_tracks:
                    if track_id not in track_segments:
                        track_segments[track_id] = []
                    
                    # Create interval for this segment on this track
                    interval = self.model.NewIntervalVar(
                        segment['start'],
                        segment['travel_time'],
                        segment['end'],
                        f'interval_{train_id}_{seg_idx}_{track_id}'
                    )
                    track_segments[track_id].append(interval)
        
        # Add no-overlap constraints for each track
        for track_id, intervals in track_segments.items():
            if len(intervals) > 1:
                self.model.AddNoOverlap(intervals)
                print(f"[Optimizer] Added no-overlap constraint for track {track_id} with {len(intervals)} segments")
    
    def add_platform_constraints(self, train_vars):
        """Add platform capacity constraints at stations"""
        for station_code, station_data in self.stations.items():
            station_trains = [t for t in self.trains 
                            if station_code in t.get('route', [t['source'], t['destination']])]
            
            if len(station_trains) > station_data.get('platforms', 2):
                intervals = []
                for train in station_trains:
                    dwell_time = 5  # Fixed dwell time for optimization
                    start_var = train_vars[train['train_id']]
                    
                    interval = self.model.NewIntervalVar(
                        start_var, 
                        dwell_time,
                        start_var + dwell_time,
                        f'platform_{train["train_id"]}_{station_code}'
                    )
                    intervals.append(interval)
                
                # Platform capacity constraint (simplified)
                # In reality, this would be more complex
                if len(intervals) > station_data.get('platforms', 2):
                    self.model.AddNoOverlap(intervals[:station_data.get('platforms', 2)])
    
    def add_delay_objective(self, train_vars):
        """Minimize total weighted delay"""
        delay_vars = []
        
        for train in self.trains:
            train_id = train['train_id']
            scheduled_dep = self.time_to_minutes(train['scheduled_departure'])
            
            delay_var = self.model.NewIntVar(0, 1440, f'delay_{train_id}')
            self.model.Add(delay_var >= train_vars[train_id] - scheduled_dep)
            self.model.Add(delay_var >= 0)
            
            # Weight by inverse priority (lower number = higher priority = higher weight)
            weight = 10 - train.get('priority', 5)
            delay_vars.append(delay_var * weight)
        
        self.model.Minimize(sum(delay_vars))
    
    def calculate_segment_travel_time(self, from_station, to_station, train):
        """Calculate travel time for a route segment"""
        # Find the track for this segment
        for track_id, track in self.tracks.items():
            if track['from_station'] == from_station and track['to_station'] == to_station:
                distance = track['distance_km']
                max_track_speed = track['max_speed']
                train_speed = train.get('speed_kmh', 80)
                effective_speed = min(train_speed, max_track_speed)
                
                travel_time_hours = distance / effective_speed
                return int(travel_time_hours * 60)  # Convert to minutes
        
        # Default if track not found
        return 60
    
    def extract_multi_route_solution(self, solver, train_vars, segment_vars):
        """Extract solution with multi-route information"""
        solution = {}
        
        for train in self.trains:
            train_id = train['train_id']
            optimized_dep_minutes = solver.Value(train_vars[train_id])
            optimized_dep_time = self.minutes_to_datetime(optimized_dep_minutes)
            
            original_dep = datetime.fromisoformat(train['scheduled_departure'])
            delay = max(0, (optimized_dep_time - original_dep).total_seconds() / 60)
            
            # Extract segment information
            segments = []
            if train_id in segment_vars:
                for seg in segment_vars[train_id]:
                    segments.append({
                        'from': seg['from'],
                        'to': seg['to'],
                        'start': self.minutes_to_datetime(solver.Value(seg['start'])).isoformat(),
                        'end': self.minutes_to_datetime(solver.Value(seg['end'])).isoformat(),
                        'travel_time': seg['travel_time']
                    })
            
            solution[train_id] = {
                'train_id': train_id,
                'name': train.get('name', f"Train {train_id}"),
                'original_departure': train['scheduled_departure'],
                'optimized_departure': optimized_dep_time.isoformat(),
                'delay_minutes': delay,
                'segments': segments,
                'status': 'scheduled',
                'current_station': train['source'],
                'next_station': train.get('route', [train['destination']])[1] if len(train.get('route', [])) > 1 else train['destination']
            }
        
        return solution
    
    def time_to_minutes(self, time_str):
        """Convert ISO time string to minutes from base date"""
        dt = datetime.fromisoformat(time_str.replace('+1', '').replace('+2', ''))
        base_date = datetime(2025, 9, 26)
        delta = dt - base_date
        return int(delta.total_seconds() / 60)
    
    def minutes_to_datetime(self, minutes):
        """Convert minutes to datetime"""
        base_date = datetime(2025, 9, 26)
        return base_date + timedelta(minutes=minutes)
