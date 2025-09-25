import json
from datetime import datetime, timedelta
import random

def generate_synthetic_trains():
    train_types = ["passenger", "express", "freight"]
    stations = ["MAS", "AJJ", "KPD", "PER", "TRL", "AVD", "PUT", "TO"]
    trains = []
    
    for i in range(30):
        train_id = f"1{str(i+1).zfill(4)}"
        train_type = random.choice(train_types)
        source = random.choice(stations)
        destination = random.choice([s for s in stations if s != source])
        
        # Generate schedule
        base_time = datetime(2025, 9, 26, 6, 0)  # 6 AM start
        dep_time = base_time + timedelta(minutes=random.randint(0, 1440))  # Within 24h
        journey_time = random.randint(120, 480)  # 2-8 hours
        arr_time = dep_time + timedelta(minutes=journey_time)
        
        priority = 1 if train_type == "passenger" else (2 if train_type == "express" else 3)
        
        train = {
            "train_id": train_id,
            "name": f"{train_type.title()} {train_id}",
            "type": train_type,
            "source": source,
            "destination": destination,
            "scheduled_departure": dep_time.isoformat(),
            "scheduled_arrival": arr_time.isoformat(),
            "priority": priority,
            "current_delay": random.randint(0, 30),  # Random initial delay
            "speed_kmh": random.randint(60, 120),
            "length_meters": random.randint(200, 500)
        }
        trains.append(train)
    
    return trains

def generate_synthetic_stations():
    stations_data = [
        {"code": "MAS", "name": "Chennai Central", "platforms": 12, "is_terminus": True},
        {"code": "AJJ", "name": "Arakkonam Junction", "platforms": 6, "is_terminus": False},
        {"code": "KPD", "name": "Katpadi Junction", "platforms": 8, "is_terminus": False},
        {"code": "PER", "name": "Perambur", "platforms": 4, "is_terminus": False},
        {"code": "TRL", "name": "Tiruvallur", "platforms": 4, "is_terminus": False},
        {"code": "AVD", "name": "Avadi", "platforms": 3, "is_terminus": False},
        {"code": "PUT", "name": "Pattabiram", "platforms": 3, "is_terminus": False},
        {"code": "TO", "name": "Tiruchchirappalli", "platforms": 10, "is_terminus": True}
    ]
    
    tracks = []
    for i in range(len(stations_data)-1):
        from_station = stations_data[i]["code"]
        to_station = stations_data[i+1]["code"]
        distance = random.randint(15, 80)
        
        # Create UP and DOWN tracks
        tracks.append({
            "track_id": f"{from_station}-{to_station}-UP",
            "from_station": from_station,
            "to_station": to_station,
            "distance_km": distance,
            "max_speed": random.randint(80, 130),
            "direction": "UP"
        })
        
        tracks.append({
            "track_id": f"{from_station}-{to_station}-DOWN", 
            "from_station": to_station,
            "to_station": from_station,
            "distance_km": distance,
            "max_speed": random.randint(80, 130),
            "direction": "DOWN"
        })
    
    return stations_data, tracks

# Generate and save data
if __name__ == "__main__":
    trains = generate_synthetic_trains()
    stations, tracks = generate_synthetic_stations()
    
    with open('synthetic_trains.json', 'w') as f:
        json.dump(trains, f, indent=2)
    
    with open('synthetic_stations.json', 'w') as f:
        json.dump({"stations": stations, "tracks": tracks}, f, indent=2)
    
    print(f"Generated {len(trains)} trains, {len(stations)} stations, {len(tracks)} tracks")