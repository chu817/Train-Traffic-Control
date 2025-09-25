from ortools.linear_solver import pywraplp
from ortools.sat.python import cp_model
from datetime import datetime, timedelta

class TrainScheduleOptimizer:
    def __init__(self, trains, tracks, stations):
        self.trains = trains
        self.tracks = tracks
        self.stations = stations
        self.model = cp_model.CpModel()
        
    def optimize_schedule(self):
        """
        Use CP-SAT solver for train scheduling optimization
        """
        train_vars = {}
        # Time horizon: 24 hours in minutes
        horizon = 24 * 60
        
        for train in self.trains:
            train_id = train['train_id']
            earliest_dep = self.time_to_minutes(train['scheduled_departure'])
            train_vars[train_id] = self.model.NewIntVar(
                max(0, earliest_dep - 60),  # Can depart 1 hour early
                horizon,  # Latest by end of day
                f'dep_{train_id}'
            )
        
        self.add_track_conflict_constraints(train_vars)
        self.add_platform_conflict_constraints(train_vars)
        self.add_delay_minimization_objective(train_vars)
        
        solver = cp_model.CpSolver()
        solver.parameters.max_time_in_seconds = 30.0  # 30 second limit
        
        status = solver.Solve(self.model)
        
        if status == cp_model.OPTIMAL or status == cp_model.FEASIBLE:
            return self.extract_solution(solver, train_vars)
        else:
            return None
    
    def add_track_conflict_constraints(self, train_vars):
        track_usage = {}
        for train in self.trains:
            route_tracks = self.get_train_tracks(train)
            for track_id in route_tracks:
                if track_id not in track_usage:
                    track_usage[track_id] = []
                track_usage[track_id].append(train['train_id'])
        
        for track_id, train_list in track_usage.items():
            if len(train_list) > 1:
                intervals = []
                for train_id in train_list:
                    travel_time = int(self.get_travel_time(train_id, track_id))
                    start_var = train_vars[train_id]
                    # Use only constant duration in interval definition
                    interval = self.model.NewIntervalVar(start_var, travel_time, start_var + travel_time, 
                                                         f'interval_{train_id}_{track_id}')
                    intervals.append(interval)
                self.model.AddNoOverlap(intervals)
    
    def add_platform_conflict_constraints(self, train_vars):
        for station_code, station_data in self.stations.items():
            station_trains = [t for t in self.trains if t['source'] == station_code or t['destination'] == station_code]
            if len(station_trains) > station_data['platforms']:
                intervals = []
                for train in station_trains:
                    platform_time = int(10 if station_code in [train['source'], train['destination']] else 2)
                    start_var = train_vars[train['train_id']]
                    interval = self.model.NewIntervalVar(start_var, platform_time, start_var + platform_time, 
                                                         f'platform_{train["train_id"]}_{station_code}')
                    intervals.append(interval)
                # self.model.AddNoOverlap(intervals)  # Uncomment to enforce stricter platform overlap
    
    def add_delay_minimization_objective(self, train_vars):
        delay_vars = []
        for train in self.trains:
            train_id = train['train_id']
            scheduled_dep = self.time_to_minutes(train['scheduled_departure'])
            delay_var = self.model.NewIntVar(0, 1440, f'delay_{train_id}')
            self.model.Add(delay_var >= train_vars[train_id] - scheduled_dep)
            self.model.Add(delay_var >= 0)
            weight = 10 - train['priority']  # Passenger=9, Express=8, Freight=7
            delay_vars.append(delay_var * weight)
        self.model.Minimize(sum(delay_vars))
    
    def extract_solution(self, solver, train_vars):
        solution = {}
        for train in self.trains:
            train_id = train['train_id']
            optimized_dep_minutes = solver.Value(train_vars[train_id])
            optimized_dep_time = self.minutes_to_datetime(optimized_dep_minutes)
            original_dep = datetime.fromisoformat(train['scheduled_departure'])
            delay = (optimized_dep_time - original_dep).total_seconds() / 60
            solution[train_id] = {
                'train_id': train_id,
                'original_departure': train['scheduled_departure'],
                'optimized_departure': optimized_dep_time.isoformat(),
                'delay_minutes': max(0, delay),
                'assigned_tracks': self.get_train_tracks(train),
                'status': 'scheduled'
            }
        return solution

    def time_to_minutes(self, time_str):
        dt = datetime.fromisoformat(time_str)
        return dt.hour * 60 + dt.minute
    
    def minutes_to_datetime(self, minutes):
        base_date = datetime(2025, 9, 26)
        return base_date + timedelta(minutes=minutes)
    
    def get_train_tracks(self, train):
        return [f"{train['source']}-{train['destination']}-UP"]
    
    def get_travel_time(self, train_id, track_id):
        return 60  # 1 hour default
