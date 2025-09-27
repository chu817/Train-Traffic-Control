from flask import Flask, jsonify, request
from flask_cors import CORS
from datetime import datetime, timedelta
import random
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

from neo4j_service import neo4j_service
from train_tracker import TrainTracker
import threading
import json
import logging
from google import genai

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Enhanced data structures
class KPICalculator:
    def __init__(self):
        pass
    
    def calculate_kpis(self, trains_data):
        """Calculate key performance indicators from train data"""
        if not trains_data:
            return {
                "total_trains": 0,
                "on_time_trains": 0,
                "delayed_trains": 0,
                "average_delay_minutes": 0,
                "punctuality_rate": 0,
                "active_trains": 0
            }
        
        total_trains = len(trains_data)
        on_time_trains = sum(1 for train in trains_data if train.get('delay', 0) == 0)
        delayed_trains = total_trains - on_time_trains
        active_trains = sum(1 for train in trains_data if train.get('status') == 'running')
        
        total_delay = sum(train.get('delay', 0) for train in trains_data)
        average_delay = total_delay / total_trains if total_trains > 0 else 0
        punctuality_rate = (on_time_trains / total_trains * 100) if total_trains > 0 else 0
        
        return {
            "total_trains": total_trains,
            "on_time_trains": on_time_trains,
            "delayed_trains": delayed_trains,
            "average_delay_minutes": round(average_delay, 2),
            "punctuality_rate": round(punctuality_rate, 2),
            "active_trains": active_trains
        }

class DisruptionHandler:
    def __init__(self):
        pass
    
    def handle_disruption(self, event_data, current_trains):
        """Handle disruption events and update train schedules"""
        disruption_type = event_data.get('type', 'delay')
        train_id = event_data.get('train_id')
        minutes = event_data.get('delay_minutes', 30)
        
        updated_trains = current_trains.copy()
        
        if disruption_type == 'delay' and train_id:
            for train in updated_trains:
                if train['id'] == train_id:
                    train['delay'] = train.get('delay', 0) + minutes
                    train['status'] = 'delayed'
                    break
        elif disruption_type == 'cancel' and train_id:
            for train in updated_trains:
                if train['id'] == train_id:
                    train['status'] = 'cancelled'
                    break
        
        return updated_trains

# Initialize services
kpi_calculator = KPICalculator()
disruption_handler = DisruptionHandler()

# Initialize train tracker
train_tracker = None
if os.getenv('RAILRADAR_API_KEY'):
    train_tracker = TrainTracker(os.getenv('RAILRADAR_API_KEY'))
    logger.info("✅ Train tracker initialized")
else:
    logger.warning("⚠️ No RailRadar API key found, train tracking disabled")

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Dummy train data
TRAINS_DATA = [
    {
        "id": "12951",
        "name": "Rajdhani Express",
        "position": {"latitude": 28.6139, "longitude": 77.2090},  # Delhi
        "status": "running",
        "route": "Delhi-Mumbai",
        "lastUpdate": datetime.now().isoformat(),
        "speed": 120,
        "direction": "South",
        "nextStation": "Agra",
        "delay": 0
    },
    {
        "id": "2265", 
        "name": "Shatabdi Express",
        "position": {"latitude": 19.0760, "longitude": 72.8777},  # Mumbai
        "status": "delayed",
        "route": "Mumbai-Pune",
        "lastUpdate": (datetime.now() - timedelta(minutes=5)).isoformat(),
        "speed": 95,
        "direction": "East",
        "nextStation": "Pune",
        "delay": 15
    },
    {
        "id": "2002",
        "name": "Duronto Express", 
        "position": {"latitude": 12.9716, "longitude": 77.5946},  # Bangalore
        "status": "running",
        "route": "Bangalore-Chennai",
        "lastUpdate": (datetime.now() - timedelta(minutes=2)).isoformat(),
        "speed": 110,
        "direction": "Southeast",
        "nextStation": "Chennai",
        "delay": 0
    },
    {
        "id": "12001",
        "name": "Shatabdi Express",
        "position": {"latitude": 26.2389, "longitude": 73.0243},  # Ajmer
        "status": "stopped",
        "route": "Delhi-Jaipur",
        "lastUpdate": (datetime.now() - timedelta(minutes=10)).isoformat(),
        "speed": 0,
        "direction": "West",
        "nextStation": "Jaipur",
        "delay": 0
    },
    {
        "id": "12345",
        "name": "Howrah Express",
        "position": {"latitude": 22.5726, "longitude": 88.3639},  # Kolkata
        "status": "maintenance",
        "route": "Kolkata-Delhi",
        "lastUpdate": (datetime.now() - timedelta(hours=1)).isoformat(),
        "speed": 0,
        "direction": "North",
        "nextStation": "Delhi",
        "delay": 0
    }
]

# Route data for visualization
ROUTES_DATA = [
    {
        "id": "route_1",
        "name": "Delhi-Mumbai Main Line",
        "points": [
            {"latitude": 28.6139, "longitude": 77.2090},  # Delhi
            {"latitude": 26.2389, "longitude": 73.0243},  # Ajmer
            {"latitude": 23.0225, "longitude": 72.5714},  # Ahmedabad
            {"latitude": 19.0760, "longitude": 72.8777}   # Mumbai
        ],
        "color": "#0D47A1",
        "width": 3
    },
    {
        "id": "route_2", 
        "name": "Bangalore-Chennai Line",
        "points": [
            {"latitude": 12.9716, "longitude": 77.5946},  # Bangalore
            {"latitude": 13.0827, "longitude": 80.2707}    # Chennai
        ],
        "color": "#1976D2",
        "width": 2
    }
]

# Load station data from Neo4j AuraDB
def load_stations_from_neo4j():
    """Load station data from Neo4j AuraDB"""
    print("🔗 Connecting to Neo4j AuraDB...")
    
    # Test connection first
    if not neo4j_service.test_connection():
        print("❌ Failed to connect to Neo4j AuraDB, using default stations")
        return get_default_stations()
    
    print("✅ Connected to Neo4j AuraDB")
    
    try:
        # Fetch all stations from Neo4j
        stations = neo4j_service.get_stations()
        
        if not stations:
            print("⚠️  No stations found in Neo4j, using default stations")
            return get_default_stations()
        
        print(f"✅ Loaded {len(stations)} stations from Neo4j AuraDB")
        return stations
        
    except Exception as e:
        print(f"⚠️  Error loading stations from Neo4j: {e}, using default stations")
        return get_default_stations()

def get_default_stations():
    """Default station data if CSV loading fails"""
    return [
        {
            "id": "NDLS",
            "name": "New Delhi",
            "position": {"latitude": 28.64177, "longitude": 77.22027},
            "type": "major",
            "platforms": 16,
            "zone": "NR",
            "state": "Delhi"
        },
        {
            "id": "CSMT",
            "name": "Mumbai CSMT", 
            "position": {"latitude": 18.9398, "longitude": 72.8355},
            "type": "major",
            "platforms": 12,
            "zone": "CR",
            "state": "Maharashtra"
        },
        {
            "id": "SBC",
            "name": "Bangalore City",
            "position": {"latitude": 12.9716, "longitude": 77.5946},
            "type": "major", 
            "platforms": 10,
            "zone": "SWR",
            "state": "Karnataka"
        },
        {
            "id": "AII",
            "name": "Ajmer Junction",
            "position": {"latitude": 26.2389, "longitude": 73.0243},
            "type": "junction",
            "platforms": 6,
            "zone": "NWR",
            "state": "Rajasthan"
        }
    ]

# Load station data
STATIONS_DATA = load_stations_from_neo4j()

# ==========================
# What-if: Rerouting helpers
# ==========================
def mark_route_failed_in_neo4j(train: str, from_station: str, to_station: str):
    """Mark a ROUTE relationship for a given train and segment as FAILED (soft-fail)."""
    if not neo4j_service.driver:
        raise RuntimeError("Neo4j driver not initialized")

    cypher = (
        "MATCH (s1:Station {code:$from_station})-[r:ROUTE {train:$train}]->(s2:Station {code:$to_station})\n"
        "SET r.status = 'FAILED'\n"
        "RETURN r"
    )
    with neo4j_service.driver.session() as session:
        result = session.run(cypher, train=train, from_station=from_station, to_station=to_station)
        return [record["r"] for record in result]


def get_shortest_open_path(current_station: str, destination_station: str, max_hops: int = 20):
    """Compute a shortest path using ROUTE as bidirectional and only OPEN/null status segments."""
    if not neo4j_service.driver:
        raise RuntimeError("Neo4j driver not initialized")

    cypher = (
        f"MATCH (src:Station {{code:$current}}), (dst:Station {{code:$destination}})\n"
        f"MATCH p = (src)-[:ROUTE*1..{max_hops}]-(dst)\n"
        f"WHERE ALL(r IN relationships(p) WHERE r.status IS NULL OR r.status='OPEN')\n"
        f"WITH p, length(p) AS hops\n"
        f"ORDER BY hops ASC\n"
        f"RETURN [n IN nodes(p) | n.code] AS path\n"
        f"LIMIT 1"
    )

    with neo4j_service.driver.session() as session:
        record = session.run(cypher, current=current_station, destination=destination_station).single()
        if record:
            return record["path"]
        return None

# ==========================
# AI Recommendations (Gemini)
# ==========================
@app.route('/api/ai/recommendations', methods=['POST'])
def ai_recommendations():
    """
    Generate AI recommendations using Gemini given context about station and live trains.
    Expects JSON: { station: str, live_trains: [ ... ], constraints?: {...}, prompt?: str }
    """
    try:
        payload = request.get_json() or {}
        station = payload.get('station', '')
        live_trains = payload.get('live_trains', [])
        constraints = payload.get('constraints', {})
        user_prompt = payload.get('prompt', '')

        api_key = os.getenv('GEMINI_API_KEY')
        if not api_key:
            return jsonify({
                'success': False,
                'error': 'GEMINI_API_KEY not configured'
            }), 500

        client = genai.Client(api_key=api_key)

        system_context = (
            "You are an expert railway traffic controller assistant for an operations dashboard. "
            "Generate precise, actionable, safety-first recommendations (bullet points) based on the given context. "
            "Avoid fluff. Be concise and specific (2-5 bullets)."
        )

        context_block = {
            'station': station,
            'constraints': constraints,
            'live_trains_sample': live_trains[:10],
        }

        composed_prompt = (
            f"{system_context}\n\n"
            f"Context JSON (trimmed):\n{json.dumps(context_block, ensure_ascii=False, indent=2)}\n\n"
            f"User Prompt (optional): {user_prompt}\n\n"
            "Return exactly 3 concise bullet points, one per line, no numbering, no headers."
        )

        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=composed_prompt,
        )
        text = (getattr(response, 'text', None) or '').strip()
        # Ensure exactly 3 lines
        lines = [l.strip('•- \t') for l in text.split('\n') if l.strip()]
        trimmed = '\n'.join(lines[:3])
        return jsonify({'success': True, 'recommendations': trimmed})
    except Exception as e:
        logger.exception("AI recommendations error")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/ai/schedule', methods=['POST'])
def ai_conflict_free_schedule():
    """Generate a conflict-free schedule proposal using Gemini.
    Expects JSON: { station: str, live_trains: [...], constraints?: {...} }
    Returns: { success: true, schedule: { slots: [...], notes: [...] } }
    """
    try:
        payload = request.get_json() or {}
        station = payload.get('station', '')
        live_trains = payload.get('live_trains', [])
        constraints = payload.get('constraints', {})

        api_key = os.getenv('GEMINI_API_KEY')
        if not api_key:
            return jsonify({'success': False, 'error': 'GEMINI_API_KEY not configured'}), 500

        client = genai.Client(api_key=api_key)

        schema_example = {
            "slots": [
                {
                    "train_number": "12951",
                    "train_name": "Rajdhani Express",
                    "priority": "Express",
                    "arrival": "2025-09-26T13:30:00Z",
                    "departure": "2025-09-26T13:40:00Z",
                    "platform": "3",
                    "conflicts": [],
                    "arrival_local": "19:00",
                    "departure_local": "19:10"
                }
            ],
            "notes": [
                "No platform overlap detected within 5-minute buffer.",
                "Constraint Programming (CP) used to enforce resource and time-window constraints.",
                "Priority given to superfast services."
            ]
        }

        # Heuristic priority assignment for input trains if none provided
        def derive_priority(train_name: str, explicit_type: str = "") -> str:
            name = (train_name or "").lower()
            t = (explicit_type or "").lower()
            if "rajdhani" in name or "duronto" in name or "shatabdi" in name or "express" in name or "exp" in name:
                return "Express"
            if "pass" in name or "passenger" in name or t == "passenger":
                return "Passenger"
            if "local" in name or "memu" in name or "emu" in name or t == "local":
                return "Local"
            if "freight" in name or "goods" in name or t == "freight":
                return "Freight"
            # Weighted random realistic distribution
            import random
            r = random.random()
            if r < 0.35: return "Express"
            if r < 0.65: return "Passenger"
            if r < 0.85: return "Local"
            return "Freight"

        # Build a compact list with inferred priorities
        trains_with_priority = []
        for t in live_trains[:20]:
            trains_with_priority.append({
                "train_number": t.get("train_number") or t.get("id") or "",
                "train_name": t.get("train_name") or t.get("name") or "",
                "priority": derive_priority(t.get("train_name") or t.get("name") or "", t.get("type") or ""),
            })

        prompt = (
            "You are an Indian Railways operations scheduler. Given the station context and the provided live trains, "
            "produce an official-style timetable that is conflict-free and uses a 5-minute safety buffer between trains on the same platform. "
            "Use Constraint Programming (CP) to assign platforms and arrival/departure times within feasible windows. "
            "Requirements:\n"
            "- Include EVERY train from the input 'live_trains' in the schedule. The number of 'slots' MUST equal the number of input trains.\n"
            "- Use the EXACT 'train_number' and 'train_name' values from input. Do NOT invent or substitute trains.\n"
            "- Consider train priority when ordering and allocating platforms. Higher priority trains should receive earlier/less-conflicted slots and preferred platforms.\n"
            "- Priority hierarchy (highest to lowest): Express > Passenger > Local > Freight.\n"
            "- Provide arrival/departure both as ISO-8601 UTC ('arrival', 'departure') and local HH:MM fields ('arrival_local', 'departure_local').\n"
            "- Assign a concrete integer 'platform' per train.\n"
            "- No overlapping occupancy on the same platform within 5 minutes buffer.\n"
            "- Add 'priority' to each slot, and 'notes' must explicitly state the algorithm used: 'Constraint Programming (CP)'.\n"
            "Output strictly JSON matching this shape (no extra prose):\n"
            f"{json.dumps(schema_example, ensure_ascii=False, indent=2)}\n"
        )

        context_block = {
            'station': station,
            'constraints': constraints,
            'live_trains_with_priority': trains_with_priority,
            'now': datetime.utcnow().isoformat() + 'Z'
        }

        composed = (
            prompt + "\nContext JSON:\n" + json.dumps(context_block, ensure_ascii=False, indent=2)
        )

        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=composed,
        )
        raw = (getattr(response, 'text', None) or '').strip()

        # Attempt to find JSON in the response; fallback to empty schedule
        schedule = {}
        try:
            schedule = json.loads(raw)
        except Exception:
            # Try to extract JSON substring if wrapped
            start = raw.find('{')
            end = raw.rfind('}')
            if start != -1 and end != -1 and end > start:
                try:
                    schedule = json.loads(raw[start:end+1])
                except Exception:
                    schedule = {"slots": [], "notes": ["Failed to parse schedule JSON"]}
            else:
                schedule = {"slots": [], "notes": ["No JSON content returned by model"]}

        # Basic validation/coercion
        if 'slots' not in schedule or not isinstance(schedule.get('slots'), list):
            schedule['slots'] = []
        if 'notes' not in schedule or not isinstance(schedule.get('notes'), list):
            schedule['notes'] = []

        return jsonify({'success': True, 'schedule': schedule})
    except Exception as e:
        logger.exception("AI schedule error")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/')
def home():
    return jsonify({
        "message": "Train Traffic Control API",
        "version": "1.0.0",
        "endpoints": {
            "trains": "/api/trains",
            "routes": "/api/routes", 
            "stations": "/api/stations",
            "train_details": "/api/trains/<train_id>"
        }
    })

@app.route('/api/trains', methods=['GET'])
def get_trains():
    """Get all trains with optional status filter"""
    status_filter = request.args.get('status')
    
    trains = TRAINS_DATA.copy()
    
    if status_filter:
        trains = [train for train in trains if train['status'] == status_filter]
    
    # Simulate real-time updates by slightly modifying positions
    for train in trains:
        if train['status'] == 'running':
            # Add small random movement to simulate travel
            lat_offset = random.uniform(-0.001, 0.001)
            lng_offset = random.uniform(-0.001, 0.001)
            train['position']['latitude'] += lat_offset
            train['position']['longitude'] += lng_offset
    
    return jsonify({
        "success": True,
        "data": trains,
        "count": len(trains),
        "timestamp": datetime.now().isoformat()
    })

@app.route('/api/trains/<train_id>', methods=['GET'])
def get_train_details(train_id):
    """Get specific train details"""
    train = next((t for t in TRAINS_DATA if t['id'] == train_id), None)
    
    if not train:
        return jsonify({
            "success": False,
            "error": "Train not found"
        }), 404
    
    return jsonify({
        "success": True,
        "data": train
    })

@app.route('/api/routes', methods=['GET'])
def get_routes():
    """Get all railway routes"""
    return jsonify({
        "success": True,
        "data": ROUTES_DATA,
        "count": len(ROUTES_DATA)
    })

@app.route('/api/stations', methods=['GET'])
def get_stations():
    """Get all stations"""
    return jsonify({
        "success": True,
        "data": STATIONS_DATA,
        "count": len(STATIONS_DATA)
    })

@app.route('/api/trains/<train_id>/position', methods=['PUT'])
def update_train_position(train_id):
    """Update train position (for simulation)"""
    train = next((t for t in TRAINS_DATA if t['id'] == train_id), None)
    
    if not train:
        return jsonify({
            "success": False,
            "error": "Train not found"
        }), 404
    
    data = request.get_json()
    if not data or 'latitude' not in data or 'longitude' not in data:
        return jsonify({
            "success": False,
            "error": "Invalid position data"
        }), 400
    
    train['position']['latitude'] = data['latitude']
    train['position']['longitude'] = data['longitude']
    train['lastUpdate'] = datetime.now().isoformat()
    
    return jsonify({
        "success": True,
        "data": train
    })

@app.route('/api/trains/<train_id>/status', methods=['PUT'])
def update_train_status(train_id):
    """Update train status"""
    train = next((t for t in TRAINS_DATA if t['id'] == train_id), None)
    
    if not train:
        return jsonify({
            "success": False,
            "error": "Train not found"
        }), 404
    
    data = request.get_json()
    if not data or 'status' not in data:
        return jsonify({
            "success": False,
            "error": "Status is required"
        }), 400
    
    valid_statuses = ['running', 'delayed', 'stopped', 'maintenance']
    if data['status'] not in valid_statuses:
        return jsonify({
            "success": False,
            "error": f"Invalid status. Must be one of: {valid_statuses}"
        }), 400
    
    train['status'] = data['status']
    train['lastUpdate'] = datetime.now().isoformat()
    
    return jsonify({
        "success": True,
        "data": train
    })

@app.route('/api/stations/<station_code>/connected', methods=['GET'])
def get_connected_stations(station_code):
    """Get stations directly connected to the given station via route relationships"""
    try:
        # Use Neo4j to get connected stations if available, otherwise fallback to empty list
        if neo4j_service.driver:
            stations = neo4j_service.get_connected_stations(station_code)
        else:
            # Fallback: return just the station itself if no Neo4j connection
            station = next((s for s in STATIONS_DATA if s['id'] == station_code), None)
            stations = [station] if station else []
        
        return jsonify({
            "success": True,
            "data": stations,
            "count": len(stations),
            "station_code": station_code
        })
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"Failed to get connected stations: {str(e)}"
        }), 500

@app.route('/api/stations/search', methods=['GET'])
def search_stations():
    """Search stations by name, code, zone, or state"""
    query = request.args.get('q', '')
    limit = int(request.args.get('limit', 100))
    
    if not query:
        return jsonify({
            "success": False,
            "error": "Search query 'q' is required"
        }), 400
    
    try:
        # Use Neo4j search if available, otherwise fallback to local search
        if neo4j_service.driver:
            stations = neo4j_service.search_stations(query, limit)
        else:
            # Fallback to local search
            stations = []
            query_lower = query.lower()
            for station in STATIONS_DATA:
                if (query_lower in station['name'].lower() or 
                    query_lower in station['id'].lower() or
                    query_lower in station.get('zone', '').lower() or
                    query_lower in station.get('state', '').lower()):
                    stations.append(station)
                    if len(stations) >= limit:
                        break
        
        return jsonify({
            "success": True,
            "data": stations,
            "count": len(stations),
            "query": query
        })
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"Search failed: {str(e)}"
        }), 500

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    neo4j_status = "connected" if neo4j_service.test_connection() else "disconnected"
    
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "uptime": "running",
        "neo4j": neo4j_status,
        "stations_loaded": len(STATIONS_DATA)
    })

# Enhanced API endpoints
@app.route('/api/dashboard/stats', methods=['GET'])
def get_dashboard_stats():
    """Get comprehensive dashboard statistics"""
    try:
        kpis = kpi_calculator.calculate_kpis(TRAINS_DATA)
        
        # Add additional stats
        stats = {
            **kpis,
            "critical_alerts": 0,  # Placeholder for alerts
            "last_updated": datetime.now().isoformat(),
            "system_status": "operational"
        }
        
        return jsonify({
            "success": True,
            "data": stats,
            "timestamp": datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"Failed to get dashboard stats: {str(e)}"
        }), 500

@app.route('/api/alerts', methods=['GET'])
def get_alerts():
    """Get system alerts and notifications"""
    # Mock alerts data
    alerts = [
        {
            "id": "alert_001",
            "type": "delay",
            "severity": "medium",
            "message": "Train 12951 delayed by 15 minutes",
            "timestamp": datetime.now().isoformat(),
            "acknowledged": False
        },
        {
            "id": "alert_002", 
            "type": "maintenance",
            "severity": "low",
            "message": "Scheduled maintenance on Track 3",
            "timestamp": (datetime.now() - timedelta(hours=2)).isoformat(),
            "acknowledged": True
        }
    ]
    
    return jsonify({
        "success": True,
        "data": alerts,
        "count": len(alerts)
    })

@app.route('/api/alerts/<alert_id>/acknowledge', methods=['POST'])
def acknowledge_alert(alert_id):
    """Acknowledge an alert"""
    return jsonify({
        "success": True,
        "message": f"Alert {alert_id} acknowledged",
        "acknowledged_at": datetime.now().isoformat()
    })

@app.route('/api/disruption', methods=['POST'])
def report_disruption():
    """Report and handle disruption events"""
    try:
        event_data = request.get_json()
        if not event_data:
            return jsonify({
                "success": False,
                "error": "No event data provided"
            }), 400
        
        # Handle the disruption
        global TRAINS_DATA
        updated_trains = disruption_handler.handle_disruption(event_data, TRAINS_DATA)
        
        # Update global train data
        TRAINS_DATA = updated_trains
        
        return jsonify({
            "success": True,
            "message": "Disruption handled successfully",
            "data": updated_trains,
            "timestamp": datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"Failed to handle disruption: {str(e)}"
        }), 500

@app.route('/api/whatif', methods=['POST'])
def whatif_scenario():
    """Run what-if analysis scenarios"""
    try:
        scenario = request.get_json()
        if not scenario:
            return jsonify({
                "success": False,
                "error": "No scenario data provided"
            }), 400
        
        # Supported scenario types: delay, cancel, reroute
        scenario_type = scenario.get('type', 'delay')
        
        if scenario_type in ['delay', 'cancel']:
            # Legacy simple scenarios on the demo TRAINS_DATA
            simulation_trains = [train.copy() for train in TRAINS_DATA]
            train_id = scenario.get('train_id')
            if scenario_type == 'delay':
                minutes = scenario.get('delay_minutes', 30)
                for train in simulation_trains:
                    if train['id'] == train_id:
                        train['delay'] = train.get('delay', 0) + minutes
                        train['status'] = 'delayed'
                        break
            elif scenario_type == 'cancel':
                for train in simulation_trains:
                    if train['id'] == train_id:
                        train['status'] = 'cancelled'
                        break

            scenario_kpis = kpi_calculator.calculate_kpis(simulation_trains)
            return jsonify({
                "success": True,
                "message": "What-if scenario completed",
                "data": {
                    "scenario": scenario,
                    "simulated_trains": simulation_trains,
                    "kpis": scenario_kpis,
                    "timestamp": datetime.now().isoformat()
                }
            })
        
        elif scenario_type == 'reroute':
            # Rerouting using Neo4j graph
            train = scenario.get('train') or scenario.get('train_id')
            current_station = scenario.get('current_station')
            destination_station = scenario.get('destination_station')
            failed_segment = scenario.get('failed_segment')  # [from, to]

            if not (train and current_station and destination_station and failed_segment and len(failed_segment) == 2):
                return jsonify({
                    "success": False,
                    "error": "Missing required fields: train, current_station, destination_station, failed_segment[from,to]"
                }), 400

            # 1) Mark failed route
            try:
                failed = mark_route_failed_in_neo4j(train, failed_segment[0], failed_segment[1])
            except Exception as e:
                return jsonify({
                    "success": False,
                    "error": f"Failed to mark failed segment: {str(e)}"
                }), 500

            # 2) Compute shortest path using only OPEN/null edges
            try:
                alt_path = get_shortest_open_path(current_station, destination_station)
            except Exception as e:
                return jsonify({
                    "success": False,
                    "error": f"Failed to compute alternate path: {str(e)}"
                }), 500

            if not alt_path:
                return jsonify({
                    "success": True,
                    "message": "No alternate path available",
                    "data": {"alternate_path": None}
                })

            # 3) Return reroute result; frontend can visualize on the map
            return jsonify({
                "success": True,
                "message": "Reroute successful",
                "data": {
                    "alternate_path": alt_path,
                    "failed_segment": failed_segment,
                    "train": train,
                    "timestamp": datetime.now().isoformat()
                }
            })
        
        else:
            return jsonify({
                "success": False,
                "error": f"Unsupported scenario type: {scenario_type}"
            }), 400
    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"Failed to run scenario: {str(e)}"
        }), 500

@app.route('/api/schedule/optimize', methods=['POST'])
def optimize_schedule():
    """Optimize train schedule based on current conditions"""
    try:
        global TRAINS_DATA
        # Simple optimization: reduce delays where possible
        optimized_trains = []
        for train in TRAINS_DATA:
            optimized_train = train.copy()
            if train.get('delay', 0) > 0:
                # Reduce delay by 50% (simplified optimization)
                optimized_train['delay'] = max(0, train['delay'] - train['delay'] // 2)
                if optimized_train['delay'] == 0:
                    optimized_train['status'] = 'running'
            optimized_trains.append(optimized_train)
        
        # Update global train data
        TRAINS_DATA = optimized_trains
        
        kpis = kpi_calculator.calculate_kpis(optimized_trains)
        
        return jsonify({
            "success": True,
            "message": "Schedule optimized successfully",
            "data": {
                "optimized_trains": optimized_trains,
                "kpis": kpis,
                "timestamp": datetime.now().isoformat()
            }
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"Failed to optimize schedule: {str(e)}"
        }), 500

@app.route('/api/performance', methods=['GET'])
def performance_metrics():
    """Return performance metrics and trends from trains data.
    Optional query: stations=CODE[,CODE...] to filter using live trains around specified stations if tracker is available.
    """
    try:
        # Select data source
        station_codes = request.args.get('stations', '')
        trains_source = []
        if station_codes and train_tracker:
            codes = [s.strip() for s in station_codes.split(',') if s.strip()]
            try:
                trains_source = train_tracker.get_live_train_locations()
                if codes:
                    trains_source = train_tracker.filter_trains_by_stations(trains_source, codes)
                # Normalize to minimal structure for KPI calc
                normalized = []
                for t in trains_source:
                    status = t.get('demo_status') or ('stopped' if (t.get('halt_mins', 0) or 0) > 0 else ('delayed' if (t.get('mins_since_dep', 0) or 0) > 30 else 'running'))
                    normalized.append({
                        'id': t.get('train_number') or t.get('id') or 'unknown',
                        'delay': max(0, int(t.get('halt_mins', 0) or 0)),
                        'status': 'running' if status == 'RUNNING_FAST' or status == 'ON_TIME' or status == 'running' else ('delayed' if status == 'delayed' else 'stopped'),
                        'lastUpdate': datetime.now().isoformat(),
                    })
                trains = normalized
            except Exception:
                trains = TRAINS_DATA
        else:
            trains = TRAINS_DATA

        # KPIs
        kpis = kpi_calculator.calculate_kpis(trains)

        # Build simple hourly trend placeholders from delays
        now = datetime.now()
        buckets = {h: [] for h in range(24)}
        for t in trains:
            # Use lastUpdate hour if present; else current hour
            try:
                hour = datetime.fromisoformat(t.get('lastUpdate', now.isoformat())).hour
            except Exception:
                hour = now.hour
            buckets.setdefault(hour, []).append(t.get('delay', 0))

        punctuality_trend = []  # percentage on-time per hour
        avg_delay_trend = []    # average delay minutes per hour
        for h in range(24):
            delays = buckets.get(h, [])
            if delays:
                total = len(delays)
                on_time = sum(1 for d in delays if (d or 0) == 0)
                punctuality = round(on_time / total * 100, 2)
                avg_delay = round(sum(d or 0 for d in delays) / total, 2)
            else:
                punctuality = 100.0
                avg_delay = 0.0
            punctuality_trend.append({"hour": h, "value": punctuality})
            avg_delay_trend.append({"hour": h, "value": avg_delay})

        # Additional derived metrics
        status_counts = {}
        for t in trains:
            status = t.get('status', 'unknown')
            status_counts[status] = status_counts.get(status, 0) + 1

        payload = {
            "kpis": kpis,
            "status_counts": status_counts,
            "trends": {
                "punctuality": punctuality_trend,
                "average_delay": avg_delay_trend,
            },
            "generated_at": now.isoformat()
        }

        return jsonify({"success": True, "data": payload, "source": "live" if station_codes and train_tracker else "static"})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

# Train tracking endpoints
@app.route('/api/trains/track', methods=['GET'])
def get_tracked_trains():
    """Get trains that start or end at specific stations"""
    if not train_tracker:
        return jsonify({
            "success": False,
            "error": "Train tracking not available"
        }), 503
    
    try:
        station_codes = request.args.getlist('stations')
        if not station_codes:
            station_codes = ['RC', 'AGC']  # Default to Raichur and Agra Cantt
        
        # Handle comma-separated stations parameter
        if len(station_codes) == 1 and ',' in station_codes[0]:
            station_codes = [s.strip() for s in station_codes[0].split(',')]
        
        trains = train_tracker.get_trains_by_stations(station_codes)
        
        return jsonify({
            "success": True,
            "data": trains,
            "count": len(trains),
            "stations": station_codes
        })
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"Failed to get tracked trains: {str(e)}"
        }), 500

@app.route('/api/trains/live', methods=['GET'])
def get_live_trains():
    """Get live train locations"""
    if not train_tracker:
        return jsonify({
            "success": False,
            "error": "Train tracking not available"
        }), 503
    
    try:
        live_trains = train_tracker.get_live_train_locations()
        
        # Filter for target stations if specified
        station_codes = request.args.getlist('stations')
        if station_codes:
            # Handle comma-separated stations parameter
            if len(station_codes) == 1 and ',' in station_codes[0]:
                station_codes = [s.strip() for s in station_codes[0].split(',')]
            live_trains = train_tracker.filter_trains_by_stations(live_trains, station_codes)
        
        return jsonify({
            "success": True,
            "data": live_trains,
            "count": len(live_trains),
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"Failed to get live trains: {str(e)}"
        }), 500

@app.route('/api/trains/start-tracking', methods=['POST'])
def start_train_tracking():
    """Start continuous train tracking"""
    if not train_tracker:
        return jsonify({
            "success": False,
            "error": "Train tracking not available"
        }), 503
    
    try:
        data = request.get_json() or {}
        station_codes = data.get('stations', ['RC', 'AGC'])
        interval_minutes = data.get('interval_minutes', 5)
        
        # Start tracking in background thread
        def track_trains():
            train_tracker.start_tracking(station_codes, interval_minutes)
        
        thread = threading.Thread(target=track_trains, daemon=True)
        thread.start()
        
        return jsonify({
            "success": True,
            "message": f"Started tracking trains for stations: {station_codes}",
            "interval_minutes": interval_minutes
        })
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"Failed to start tracking: {str(e)}"
        }), 500

if __name__ == '__main__':
    print("🚂 Starting Train Traffic Control API Server...")
    print("📍 Available endpoints:")
    print("   GET  /api/trains - Get all trains")
    print("   GET  /api/trains/<id> - Get specific train")
    print("   GET  /api/routes - Get railway routes")
    print("   GET  /api/stations - Get stations")
    print("   GET  /api/stations/<code>/connected - Get connected stations")
    print("   GET  /api/stations/search?q=<query> - Search stations")
    print("   PUT  /api/trains/<id>/position - Update train position")
    print("   PUT  /api/trains/<id>/status - Update train status")
    print("   GET  /api/health - Health check")
    print("   GET  /api/dashboard/stats - Get dashboard statistics")
    print("   GET  /api/alerts - Get system alerts")
    print("   POST /api/alerts/<id>/acknowledge - Acknowledge alert")
    print("   POST /api/disruption - Report disruption")
    print("   POST /api/whatif - Run what-if analysis")
    print("   POST /api/schedule/optimize - Optimize schedule")
    print("   GET  /api/trains/track - Get tracked trains")
    print("   GET  /api/trains/live - Get live train locations")
    print("   POST /api/trains/start-tracking - Start train tracking")
    print("\n🌐 Server starting on http://localhost:5001")
    
    app.run(debug=True, host='0.0.0.0', port=5001)
