from datetime import datetime, timedelta
from enum import Enum

class TrainType(Enum):
    PASSENGER = 1
    EXPRESS = 2  
    FREIGHT = 3

class TrainStatus(Enum):
    SCHEDULED = "scheduled"
    RUNNING = "running"
    DELAYED = "delayed"
    CANCELLED = "cancelled"

class Train:
    def __init__(self, train_id, name, train_type, source, destination, 
                 scheduled_dep, scheduled_arr, priority=5):
        self.train_id = train_id
        self.name = name
        self.type = train_type
        self.source = source
        self.destination = destination
        self.scheduled_departure = scheduled_dep
        self.scheduled_arrival = scheduled_arr
        self.current_delay = 0  # minutes
        self.priority = priority  # 1=highest, 10=lowest
        self.status = TrainStatus.SCHEDULED
        self.current_location = source
        self.assigned_track = None
        self.assigned_platform = None
    
    def get_effective_departure(self):
        return self.scheduled_departure + timedelta(minutes=self.current_delay)
    
    def get_effective_arrival(self):
        return self.scheduled_arrival + timedelta(minutes=self.current_delay)