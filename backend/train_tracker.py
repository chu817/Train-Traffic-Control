"""
Train tracking system using RailRadar API
Fetches trains and their live locations for animation
"""

import requests
import json
import time
import os
from datetime import datetime, timedelta
from typing import List, Dict, Optional
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class TrainTracker:
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.base_url = "https://railradar.in/api/v1"
        self.headers = {
            'x-api-key': api_key,
            'Content-Type': 'application/json'
        }
        self.trains_data = []
        self.live_trains = []
        self._demo_trains: List[Dict] = []

    @staticmethod
    def _quadratic_bezier(a: float, c: float, b: float, t: float) -> float:
        """
        Quadratic Bezier interpolation for a single component.
        """
        return (1 - t) * (1 - t) * a + 2 * (1 - t) * t * c + t * t * b

    def _curved_position(self, start: Dict, end: Dict, progress: float, curve_phase: float, curve_scale: float) -> Dict[str, float]:
        """
        Compute a non-linear (curved) position between start and end using a quadratic Bezier.
        The control point is offset perpendicular to the start->end vector and varies per-train.
        """
        import math

        lat1, lng1 = start['lat'], start['lng']
        lat2, lng2 = end['lat'], end['lng']

        # Vector from start to end
        dv_lat = lat2 - lat1
        dv_lng = lng2 - lng1
        # Perpendicular vector (not normalized)
        perp_lat = -dv_lng
        perp_lng = dv_lat
        # Normalize perpendicular
        mag = math.sqrt(perp_lat * perp_lat + perp_lng * perp_lng) or 1.0
        perp_lat /= mag
        perp_lng /= mag

        # Midpoint
        mid_lat = (lat1 + lat2) / 2.0
        mid_lng = (lng1 + lng2) / 2.0

        # Unique amplitude per train based on supplied phase
        amplitude = curve_scale * (0.5 + 0.5 * math.sin(curve_phase))

        control_lat = mid_lat + perp_lat * amplitude
        control_lng = mid_lng + perp_lng * amplitude

        cur_lat = self._quadratic_bezier(lat1, control_lat, lat2, progress)
        cur_lng = self._quadratic_bezier(lng1, control_lng, lng2, progress)

        return { 'lat': cur_lat, 'lng': cur_lng }

    @staticmethod
    def _cubic_bezier(a: float, c1: float, c2: float, b: float, t: float) -> float:
        """
        Cubic Bezier interpolation for a single component.
        """
        u = 1 - t
        return (
            u*u*u * a +
            3*u*u*t * c1 +
            3*u*t*t * c2 +
            t*t*t * b
        )

    def _curved_position_cubic(self, start: Dict, end: Dict, progress: float, phase: float, scale1: float, scale2: float, along1: float, along2: float) -> Dict[str, float]:
        """
        Compute a non-linear (curved) position using a cubic Bezier with two control points.
        Control points are placed at fractional distances along the segment and offset perpendicularly
        with different magnitudes to ensure diverse shapes.
        """
        import math

        lat1, lng1 = start['lat'], start['lng']
        lat2, lng2 = end['lat'], end['lng']

        # Direction vector
        dv_lat = lat2 - lat1
        dv_lng = lng2 - lng1
        # Tangent unit vector
        tan_lat = dv_lat
        tan_lng = dv_lng
        tmag = math.sqrt(tan_lat * tan_lat + tan_lng * tan_lng) or 1.0
        tan_lat /= tmag
        tan_lng /= tmag
        # Perpendicular unit vector
        perp_lat = -tan_lng
        perp_lng = tan_lat

        # First control point (at along1 fraction of the path) with tangential skew
        t_skew1 = 0.15 * math.cos(phase * 0.7)
        c1_lat = lat1 + dv_lat * along1 + perp_lat * scale1 * math.sin(phase) + tan_lat * t_skew1
        c1_lng = lng1 + dv_lng * along1 + perp_lng * scale1 * math.cos(phase) + tan_lng * t_skew1

        # Second control point (at along2 fraction of the path) with opposite tangential skew
        t_skew2 = -0.18 * math.sin(phase * 0.9)
        c2_lat = lat1 + dv_lat * along2 + perp_lat * scale2 * math.cos(phase * 1.3) + tan_lat * t_skew2
        c2_lng = lng1 + dv_lng * along2 + perp_lng * scale2 * math.sin(phase * 1.3) + tan_lng * t_skew2

        cur_lat = self._cubic_bezier(lat1, c1_lat, c2_lat, lat2, progress)
        cur_lng = self._cubic_bezier(lng1, c1_lng, c2_lng, lng2, progress)

        return { 'lat': cur_lat, 'lng': cur_lng }
        
    def get_trains_by_stations(self, station_codes: List[str], limit: int = 100) -> List[Dict]:
        """
        Get trains that start or end at specific stations
        """
        all_trains = []
        
        for station_code in station_codes:
            try:
                # Search for trains starting from this station
                url = f"{self.base_url}/trains/list"
                params = {
                    'page': 1,
                    'limit': limit,
                    'search': station_code
                }
                
                response = requests.get(url, headers=self.headers, params=params)
                
                if response.status_code == 200:
                    data = response.json()
                    # The API returns data in a nested structure
                    if 'data' in data and 'trains' in data['data']:
                        trains = data['data']['trains']
                    else:
                        trains = data.get('trains', [])
                    
                    # Filter trains that start or end at this station
                    station_trains = [
                        train for train in trains 
                        if (train.get('source_station_code') == station_code or 
                            train.get('destination_station_code') == station_code)
                    ]
                    
                    all_trains.extend(station_trains)
                    logger.info(f"Found {len(station_trains)} trains for station {station_code}")
                else:
                    logger.error(f"Error fetching trains for {station_code}: {response.status_code}")
                    
            except Exception as e:
                logger.error(f"Error processing station {station_code}: {e}")
                
        # Remove duplicates based on train_number
        unique_trains = {}
        for train in all_trains:
            train_num = train.get('train_number')
            if train_num and train_num not in unique_trains:
                unique_trains[train_num] = train
                
        return list(unique_trains.values())
    
    def get_live_train_locations(self) -> List[Dict]:
        """
        Get live train locations from RailRadar API with demo speed modifications
        """
        # Always return a constant set of trains; only positions update smoothly
        if not self._demo_trains:
            logger.info("Initializing constant live trains set")
            self._demo_trains = self._create_demo_train_data(seed=42)
        return self._update_positions(self._demo_trains)
        
        # Commented out real API for demo
        # try:
        #     url = f"{self.base_url}/trains/live-map"
        #     response = requests.get(url, headers=self.headers)
        #     
        #     if response.status_code == 200:
        #         data = response.json()
        #         # The API returns data in a nested structure
        #         if 'data' in data and isinstance(data['data'], list):
        #             trains = data['data']
        #         elif isinstance(data, list):
        #             trains = data
        #         else:
        #             trains = []
        #         
        #         # If no real data, create demo data
        #         if not trains:
        #             trains = self._create_demo_train_data()
        #         
        #         # Apply demo speed modifications
        #         return self._apply_demo_speed_modifications(trains)
        #     else:
        #         logger.error(f"Error fetching live train data: {response.status_code}")
        #         # Return demo data if API fails
        #         return self._apply_demo_speed_modifications(self._create_demo_train_data())
        #         
        # except Exception as e:
        #     logger.error(f"Error fetching live train locations: {e}")
        #     # Return demo data if API fails
        #     return self._apply_demo_speed_modifications(self._create_demo_train_data())
    
    def _create_demo_train_data(self, seed: Optional[int] = None) -> List[Dict]:
        """
        Create a constant demo train dataset; details never change
        """
        import random
        import time
        import math
        
        if seed is not None:
            random.seed(seed)

        # Station coordinates
        stations = {
            'RC': {'name': 'Raichur Jn', 'lat': 16.2079, 'lng': 77.3553},
            'AGC': {'name': 'Agra Cantt', 'lat': 27.1767, 'lng': 77.9890},
            'MTJ': {'name': 'Mathura Jn', 'lat': 27.4924, 'lng': 77.6739},
            'GZB': {'name': 'Ghaziabad', 'lat': 28.6692, 'lng': 77.4538},
            'NDLS': {'name': 'New Delhi', 'lat': 28.6139, 'lng': 77.2090},
        }
        
        # Define routes between stations
        # Diverse, non-overlapping path set so trains don't all share the same segment
        routes = [
            {'from': 'RC', 'to': 'MTJ', 'duration': 8},
            {'from': 'AGC', 'to': 'MTJ', 'duration': 3},
            {'from': 'GZB', 'to': 'NDLS', 'duration': 1},
            {'from': 'MTJ', 'to': 'RC', 'duration': 8},
            {'from': 'NDLS', 'to': 'GZB', 'duration': 1},
            {'from': 'MTJ', 'to': 'AGC', 'duration': 3},
        ]
        
        demo_trains = []
        current_time = time.time()
        
        for i, route in enumerate(routes):
            # Create 2 trains per route for variety
            for j in range(2):
                # Create a simple synthetic train id without DEMO prefix
                train_id = f"{route['from']}{route['to']}{i+1}{j+1}"
                
                # Calculate current position along the route
                progress = (current_time + i * 3600 + j * 1800) % (route['duration'] * 3600) / (route['duration'] * 3600)
                
                # Get start and end coordinates
                start_station = stations[route['from']]
                end_station = stations[route['to']]
                
                # Calculate current position (cubic curved interpolation) with unique parameters per-train
                phase = (i * 2.13 + j * 1.17)
                curve = self._curved_position_cubic(
                    start_station,
                    end_station,
                    progress,
                    phase,
                    scale1=0.8 + 0.2 * (i % 3),
                    scale2=0.6 + 0.25 * (j % 3),
                    along1=0.3 + 0.1 * (i % 2),
                    along2=0.7 - 0.1 * (j % 2),
                )
                current_lat = curve['lat']
                current_lng = curve['lng']
                
                # No per-refresh randomness; only deterministic position from time
                
                # Determine current station based on progress
                if progress < 0.1:
                    current_station = route['from']
                    current_station_name = start_station['name']
                elif progress > 0.9:
                    current_station = route['to']
                    current_station_name = end_station['name']
                else:
                    # Train is between stations
                    current_station = f"{route['from']}-{route['to']}"
                    current_station_name = f"En route {start_station['name']} to {end_station['name']}"
                
                # Calculate journey progress
                journey_progress = int(progress * 100)
                
                train_data = {
                    'train_number': train_id,
                    'train_name': f'{route["from"]}-{route["to"]} Express',
                    'type': random.choice(['Express', 'Superfast', 'Mail', 'Passenger']),
                    'days_ago': 0,
                    'mins_since_dep': random.randint(5, 30),
                    'current_station': current_station,
                    'current_station_name': current_station_name,
                    'current_lat': current_lat,
                    'current_lng': current_lng,
                    'departure_minutes': random.randint(10, 60),
                    'current_day': 0,
                    'halt_mins': random.randint(0, 2) if progress > 0.9 else 0,
                    'route_from': route['from'],
                    'route_to': route['to'],
                    'journey_progress': journey_progress,
                    'speed_kmph': random.randint(60, 120),
                    # Stable per-train color from a palette
                    'color_hex': [
                        '#0D47A1', '#1976D2', '#42A5F5', '#00897B', '#2E7D32', '#C62828', '#AD1457', '#6A1B9A', '#283593', '#0277BD',
                        '#00695C', '#558B2F', '#EF6C00', '#4E342E', '#37474F', '#7B1FA2', '#0097A7', '#1B5E20', '#D84315', '#5D4037'
                    ][(i * 3 + j * 5) % 20]
                }
                
                demo_trains.append(train_data)
        
        logger.info(f"Created {len(demo_trains)} constant trains for live map")
        return demo_trains
    
    def _update_positions(self, trains: List[Dict]) -> List[Dict]:
        """
        Update only position and journey progress deterministically; keep all other details constant
        """
        import time
        import math

        current_time = time.time()

        stations = {
            'RC': {'lat': 16.2079, 'lng': 77.3553},
            'AGC': {'lat': 27.1767, 'lng': 77.9890},
            'MTJ': {'lat': 27.4924, 'lng': 77.6739},
            'GZB': {'lat': 28.6692, 'lng': 77.4538},
            'NDLS': {'lat': 28.6139, 'lng': 77.2090},
        }

        updated: List[Dict] = []
        for idx, train in enumerate(trains):
            t = train.copy()
            # Deterministic, per-train speed factors and offsets to avoid sync
            base_speed = 6.0 + (idx % 9)  # 6..14 different speeds
            offset = (idx * 13) % 100
            accelerated_progress = (current_time * base_speed + offset) % 100
            t['journey_progress'] = int(accelerated_progress)

            start_station = stations.get(train['route_from'])
            end_station = stations.get(train['route_to'])
            if start_station and end_station:
                p = accelerated_progress / 100.0
                # Use cubic curved path per train with unique parameters
                phase = (idx * 0.91 + 1.37)
                curve = self._curved_position_cubic(
                    start_station,
                    end_station,
                    p,
                    phase,
                    scale1=0.7 + 0.2 * ((idx % 4) - 1),
                    scale2=0.6 + 0.25 * (((idx + 1) % 4) - 1),
                    along1=0.25 + 0.15 * ((idx % 3) / 2),
                    along2=0.65 - 0.15 * (((idx + 1) % 3) / 2),
                )
                t['current_lat'] = curve['lat']
                t['current_lng'] = curve['lng']

                if p < 0.1:
                    t['current_station'] = train['route_from']
                    t['current_station_name'] = f"Departing from {train['route_from']}"
                elif p > 0.9:
                    t['current_station'] = train['route_to']
                    t['current_station_name'] = f"Arriving at {train['route_to']}"
                else:
                    t['current_station'] = f"{train['route_from']}-{train['route_to']}"
                    t['current_station_name'] = f"En route {train['route_from']} to {train['route_to']}"

            # Status logic varies by position and per-train phase
            phase_mod = (idx * 0.37) % 1.0
            if 0.88 < p < 0.95 or 0.05 < p < 0.12:
                t['halt_mins'] = 1
                t['demo_status'] = 'BRIEF_HALT'
                t['speed_kmph'] = 0
            elif (0.3 < p < 0.35 and phase_mod > 0.5) or (0.62 < p < 0.67 and phase_mod < 0.5):
                t['halt_mins'] = 0
                t['demo_status'] = 'ON_TIME'
                t['speed_kmph'] = min(max(train.get('speed_kmph', 80), 60), 120)
            else:
                t['halt_mins'] = 0
                t['demo_status'] = 'RUNNING_FAST'
                # Slightly higher speed for fast
                t['speed_kmph'] = min(160, max(70, train.get('speed_kmph', 90) + ((idx % 3) * 5)))

            # Depart minutes increases slowly but bounded
            t['mins_since_dep'] = min(45, max(5, train.get('mins_since_dep', 15)))

            updated.append(t)

        return updated
    
    def filter_trains_by_stations(self, live_trains: List[Dict], target_stations: List[str]) -> List[Dict]:
        """
        Return a constant subset of trains whose planned routes include the target stations
        """
        target = {s.upper() for s in target_stations}
        route_matched: List[Dict] = []
        
        for train in live_trains:
            route_from = str(train.get('route_from', '')).upper()
            route_to = str(train.get('route_to', '')).upper()
            if route_from in target or route_to in target:
                route_matched.append(train)

        # Keep the order stable and return
        return route_matched
    
    def save_trains_data(self, filename: str = "trains_data.json"):
        """
        Save trains data to file
        """
        data = {
            'timestamp': datetime.now().isoformat(),
            'trains': self.trains_data,
            'live_trains': self.live_trains
        }
        
        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)
            
        logger.info(f"Saved trains data to {filename}")
    
    def start_tracking(self, station_codes: List[str], interval_minutes: int = 5):
        """
        Start continuous tracking of trains
        """
        logger.info(f"Starting train tracking for stations: {station_codes}")
        
        # Get initial train list
        self.trains_data = self.get_trains_by_stations(station_codes)
        logger.info(f"Found {len(self.trains_data)} trains")
        
        # Start tracking loop
        while True:
            try:
                # Get live train locations
                live_trains = self.get_live_train_locations()
                
                # Filter for our target stations
                filtered_trains = self.filter_trains_by_stations(live_trains, station_codes)
                self.live_trains = filtered_trains
                
                logger.info(f"Tracking {len(filtered_trains)} live trains")
                
                # Save data
                self.save_trains_data()
                
                # Wait for next interval
                time.sleep(interval_minutes * 60)
                
            except KeyboardInterrupt:
                logger.info("Stopping train tracking...")
                break
            except Exception as e:
                logger.error(f"Error in tracking loop: {e}")
                time.sleep(60)  # Wait 1 minute before retrying

def main():
    # Get API key from environment
    api_key = os.getenv('RAILRADAR_API_KEY')
    
    if not api_key:
        logger.error("No API key provided. Set RAILRADAR_API_KEY environment variable.")
        return
    
    # Initialize tracker
    tracker = TrainTracker(api_key)
    
    # Target stations
    target_stations = ['RC', 'AGC']  # Raichur Jn and Agra Cantt codes
    
    # Start tracking
    try:
        tracker.start_tracking(target_stations)
    except KeyboardInterrupt:
        logger.info("Tracking stopped by user")
    except Exception as e:
        logger.error(f"Error in main: {e}")

if __name__ == "__main__":
    main()
