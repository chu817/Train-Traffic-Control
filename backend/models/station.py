class Station:
    def __init__(self, code, name, platforms, platform_length=500):
        self.code = code
        self.name = name
        self.total_platforms = platforms
        self.platform_length = platform_length
        self.occupied_platforms = {}  # {platform_id: train_id}
        self.is_terminus = False
        
    def get_available_platforms(self, time_slot):
        # Return list of available platform numbers
        available = []
        for i in range(1, self.total_platforms + 1):
            if i not in self.occupied_platforms:
                available.append(i)
        return available

class Track:
    def __init__(self, track_id, from_station, to_station, distance, max_speed):
        self.track_id = track_id
        self.from_station = from_station
        self.to_station = to_station
        self.distance_km = distance
        self.max_speed = max_speed
        self.direction = "BIDIRECTIONAL"  # UP/DOWN/BIDIRECTIONAL
        self.occupied_slots = []  # [(start_time, end_time, train_id)]
        self.maintenance_blocks = []
        
    def is_available(self, start_time, end_time):
        for slot_start, slot_end, train in self.occupied_slots:
            if not (end_time <= slot_start or start_time >= slot_end):
                return False
        return True