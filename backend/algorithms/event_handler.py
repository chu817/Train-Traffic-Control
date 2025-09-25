from datetime import datetime, timedelta
import json

class DisruptionHandler:
    def __init__(self, scheduler, optimizer):
        self.scheduler = scheduler
        self.optimizer = optimizer
        self.active_disruptions = {}
        
    def handle_disruption(self, event_data, current_schedule):
        """
        Process disruption event and trigger rescheduling
        """
        event_id = event_data['event_id']
        event_type = event_data['type']
        affected_trains = event_data.get('affected_trains', [])
        
        # Store active disruption
        self.active_disruptions[event_id] = {
            'event': event_data,
            'start_time': datetime.now(),
            'status': 'active'
        }
        
        # Determine response strategy based on event type
        if event_type == 'delay':
            return self.handle_train_delay(event_data, current_schedule)
        elif event_type == 'breakdown':
            return self.handle_train_breakdown(event_data, current_schedule)
        elif event_type == 'obstruction':
            return self.handle_track_obstruction(event_data, current_schedule)
        elif event_type == 'weather':
            return self.handle_weather_disruption(event_data, current_schedule)
        else:
            return self.handle_generic_disruption(event_data, current_schedule)
    
    def handle_train_delay(self, event, schedule):
        """
        Handle individual train delays
        """
        affected_trains = event.get('affected_trains', [])
        delay_minutes = event.get('expected_duration', 30)
        
        updated_schedule = schedule.copy()
        cascading_effects = []
        
        for train_id in affected_trains:
            if train_id in updated_schedule:
                train_schedule = updated_schedule[train_id]
                
                # Add delay to departure time
                original_dep = datetime.fromisoformat(train_schedule['optimized_departure'])
                new_dep = original_dep + timedelta(minutes=delay_minutes)
                
                updated_schedule[train_id]['optimized_departure'] = new_dep.isoformat()
                updated_schedule[train_id]['delay_minutes'] = train_schedule.get('delay_minutes', 0) + delay_minutes
                updated_schedule[train_id]['status'] = 'delayed'
                
                # Check for cascading conflicts
                cascading_effects.extend(self.check_cascading_conflicts(train_id, new_dep, updated_schedule))
        
        # Resolve cascading conflicts if any
        if cascading_effects:
            updated_schedule = self.resolve_cascading_conflicts(cascading_effects, updated_schedule)
        
        return updated_schedule
    
    def handle_track_obstruction(self, event, schedule):
        """
        Handle track blockages - need to reroute affected trains
        """
        affected_tracks = event.get('affected_tracks', [])
        duration = event.get('expected_duration', 60)  # minutes
        
        # Find trains using affected tracks
        affected_trains = []
        for train_id, train_schedule in schedule.items():
            assigned_tracks = train_schedule.get('assigned_tracks', [])
            for track_assignment in assigned_tracks:
                if track_assignment.get('track_id') in affected_tracks:
                    affected_trains.append(train_id)
                    break
        
        # Strategy: Delay trains until obstruction is cleared
        updated_schedule = schedule.copy()
        
        for train_id in affected_trains:
            if train_id in updated_schedule:
                train_schedule = updated_schedule[train_id]
                original_dep = datetime.fromisoformat(train_schedule['optimized_departure'])
                new_dep = original_dep + timedelta(minutes=duration)
                
                updated_schedule[train_id]['optimized_departure'] = new_dep.isoformat()
                updated_schedule[train_id]['delay_minutes'] = train_schedule.get('delay_minutes', 0) + duration
                updated_schedule[train_id]['status'] = 'delayed'
                updated_schedule[train_id]['reason'] = f'Track obstruction: {event["event_id"]}'
        
        return updated_schedule
    
    def handle_train_breakdown(self, event, schedule):
        """
        Handle train breakdowns - may need cancellation or replacement
        """
        affected_trains = event.get('affected_trains', [])
        severity = event.get('severity', 'medium')
        
        updated_schedule = schedule.copy()
        
        for train_id in affected_trains:
            if train_id in updated_schedule:
                if severity == 'critical':
                    # Cancel train
                    updated_schedule[train_id]['status'] = 'cancelled'
                    updated_schedule[train_id]['reason'] = f'Breakdown: {event["event_id"]}'
                else:
                    # Significant delay
                    delay_minutes = 120 if severity == 'high' else 60
                    train_schedule = updated_schedule[train_id]
                    original_dep = datetime.fromisoformat(train_schedule['optimized_departure'])
                    new_dep = original_dep + timedelta(minutes=delay_minutes)
                    
                    updated_schedule[train_id]['optimized_departure'] = new_dep.isoformat()
                    updated_schedule[train_id]['delay_minutes'] = train_schedule.get('delay_minutes', 0) + delay_minutes
                    updated_schedule[train_id]['status'] = 'delayed'
                    updated_schedule[train_id]['reason'] = f'Breakdown: {event["event_id"]}'
        
        return updated_schedule
    
    def check_cascading_conflicts(self, changed_train_id, new_departure_time, schedule):
        """
        Check if train delay causes conflicts with other trains
        """
        conflicts = []
        changed_train = schedule[changed_train_id]
        
        # Check track conflicts
        for other_train_id, other_train in schedule.items():
            if other_train_id == changed_train_id:
                continue
                
            # Simple conflict check - same track usage overlap
            # In reality, need more sophisticated track conflict detection
            if self.trains_have_track_conflict(changed_train, other_train):
                conflicts.append({
                    'type': 'track_conflict',
                    'train1': changed_train_id,
                    'train2': other_train_id,
                    'resolution_needed': 'delay_or_reroute'
                })
        
        return conflicts
    
    def resolve_cascading_conflicts(self, conflicts, schedule):
        """
        Resolve conflicts caused by initial disruption
        """
        updated_schedule = schedule.copy()
        
        for conflict in conflicts:
            if conflict['type'] == 'track_conflict':
                # Simple resolution: delay the lower priority train
                train1_id = conflict['train1']
                train2_id = conflict['train2']
                
                train1_priority = schedule[train1_id].get('priority', 5)
                train2_priority = schedule[train2_id].get('priority', 5)
                
                # Lower priority number = higher priority
                if train1_priority > train2_priority:
                    # Delay train1
                    self.delay_train(train1_id, 30, updated_schedule)
                else:
                    # Delay train2
                    self.delay_train(train2_id, 30, updated_schedule)
        
        return updated_schedule
    
    def delay_train(self, train_id, delay_minutes, schedule):
        """
        Helper to delay a specific train
        """
        if train_id in schedule:
            train_schedule = schedule[train_id]
            original_dep = datetime.fromisoformat(train_schedule['optimized_departure'])
            new_dep = original_dep + timedelta(minutes=delay_minutes)
            
            schedule[train_id]['optimized_departure'] = new_dep.isoformat()
            schedule[train_id]['delay_minutes'] = train_schedule.get('delay_minutes', 0) + delay_minutes
    
    def trains_have_track_conflict(self, train1, train2):
        """
        Simplified track conflict detection
        """
        # In reality, need to check actual track segments and timing
        return False  # Placeholder
    
    def handle_weather_disruption(self, event, schedule):
        """
        Handle weather-related disruptions
        """
        # Weather typically affects all trains in a region
        severity = event.get('severity', 'medium')
        
        if severity == 'low':
            delay = 15
        elif severity == 'medium':
            delay = 45
        else:  # high/critical
            delay = 90
        
        updated_schedule = schedule.copy()
        
        # Apply delay to all trains (simplified)
        for train_id, train_schedule in updated_schedule.items():
            original_dep = datetime.fromisoformat(train_schedule['optimized_departure'])
            new_dep = original_dep + timedelta(minutes=delay)
            
            updated_schedule[train_id]['optimized_departure'] = new_dep.isoformat()
            updated_schedule[train_id]['delay_minutes'] = train_schedule.get('delay_minutes', 0) + delay
            updated_schedule[train_id]['status'] = 'delayed'
            updated_schedule[train_id]['reason'] = f'Weather: {event["event_id"]}'
        
        return updated_schedule
    
    def handle_generic_disruption(self, event, schedule):
        """
        Generic disruption handler
        """
        return self.handle_train_delay(event, schedule)
    
    def get_active_disruptions(self):
        """
        Get list of currently active disruptions
        """
        return self.active_disruptions
    
    def resolve_disruption(self, event_id):
        """
        Mark disruption as resolved
        """
        if event_id in self.active_disruptions:
            self.active_disruptions[event_id]['status'] = 'resolved'
            self.active_disruptions[event_id]['end_time'] = datetime.now()