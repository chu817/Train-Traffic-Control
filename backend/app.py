from flask import Flask, request, jsonify, session
from flask_cors import CORS
from datetime import datetime
import json
import os

# --- Import scheduler/optimizer modules as before ---
from algorithms.scheduler import BasicScheduler
from algorithms.optimizer import TrainScheduleOptimizer
from algorithms.kpi_calculator import KPICalculator
from algorithms.event_handler import DisruptionHandler

app = Flask(__name__)
app.secret_key = "changethissecret"
CORS(app)

# --- Data file paths ---
TRAINFILE = "data/synthetic_trains.json"
STATIONFILE = "data/synthetic_stations.json"
EVENTFILE = "data/synthetic_events.json"

def load_json(filepath):
    if os.path.exists(filepath):
        with open(filepath, "r") as f:
            return json.load(f)
    return []

def format_response(success=True, message="", data=None, code=200):
    response = {
        "success": success,
        "message": message,
        "timestamp": datetime.now().isoformat(),
    }
    if data is not None:
        response["data"] = data
    return jsonify(response), code

# --- Load synthetic data ---
def load_trains():
    return load_json(TRAINFILE)

def load_stations_tracks():
    stations_tracks = load_json(STATIONFILE)
    return stations_tracks.get('stations', []), stations_tracks.get('tracks', [])

def load_events():
    return load_json(EVENTFILE)

kpi_calculator = KPICalculator()
current_schedule = None
baseline_schedule = None
disruption_handler = None

def map_schedule_to_traininfo(schedule):
    traininfo = []
    for train_id, entry in schedule.items():
        traininfo.append({
            "number": train_id,
            "name": entry.get("name", f"Train {train_id}"),
            "currentStation": entry.get("current_station", "N/A"),
            "nextStation": entry.get("next_station", "N/A"),
            "status": "DELAYED" if entry.get("delay_minutes", 0) > 0 else "ON_TIME",
            "scheduledArrival": entry.get("scheduled_arrival"),
            "actualArrival": entry.get("optimized_arrival") or entry.get("scheduled_arrival"),
            "passengerCount": entry.get("passenger_count", 1000),
            "isDelayed": bool(entry.get("delay_minutes", 0) > 0),
            "delayMinutes": int(entry.get("delay_minutes", 0)),
        })
    return traininfo

@app.route("/health", methods=["GET"])
def health():
    return format_response(True, "Server is running", {"version": "1.0.0", "status": "healthy", 
                                                      "uptime": datetime.now().isoformat()})

@app.route("/api/login", methods=["POST"])
def login():
    return format_response(True, "Login stubbed, implement later", {"session": "dummy"})

@app.route("/api/logout", methods=["POST", "GET"])
def logout():
    return format_response(True, "Logout stubbed, implement later", {})

@app.route("/api/session", methods=["GET"])
def check_session():
    return format_response(True, "Session exists (stubbed)", {"user": "testuser", "role": "Admin", "login_time": datetime.now().isoformat()})

@app.route("/api/trains", methods=["GET"])
def get_trains():
    global current_schedule
    if current_schedule:
        trains = map_schedule_to_traininfo(current_schedule)
    else:
        trains = load_trains()
    return format_response(True, "Trains data retrieved", trains)

@app.route("/api/trains/<train_id>", methods=["GET"])
def get_train_detail(train_id):
    global current_schedule
    if current_schedule:
        trains = map_schedule_to_traininfo(current_schedule)
    else:
        trains = load_trains()
    train = next((t for t in trains if t["train_id"] == train_id), None)
    if train:
        return format_response(True, f"Train {train_id} details", train)
    return format_response(False, f"Train {train_id} not found", code=404)

@app.route("/api/alerts", methods=["GET"])
def get_alerts():
    alerts = load_events()
    return format_response(True, "Alerts retrieved", alerts)

@app.route("/api/alerts/<alert_id>/acknowledge", methods=["POST"])
def acknowledge_alert(alert_id):
    # Should update alert status in state/db
    return format_response(True, f"Alert {alert_id} acknowledged", {"alertId": alert_id, "acknowledgedAt": datetime.now().isoformat()})

@app.route("/api/dashboardstats", methods=["GET"])
def dashboard_stats():
    # Compute stats from train schedule/KPI module
    stats = {
        "totalTrains": 0,
        "activeTrains": 0,
        "delayedTrains": 0,
        "onTimeTrains": 0,
        "criticalAlerts": 0,
        "averageDelay": 0,
        "onTimePerformance": 0
    }
    if current_schedule:
        kpis = kpi_calculator.calculate_kpis(current_schedule)
        stats["averageDelay"] = kpis.get("average_delay_minutes", 0)
        stats["onTimePerformance"] = kpis.get("punctuality_rate", 0)
        stats["delayedTrains"] = kpis.get("delayed_trains", 0)
        stats["onTimeTrains"] = kpis.get("on_time_trains", 0)
        stats["totalTrains"] = kpis.get("total_trains", 0)
    else:
        trains = load_trains()
        stats["totalTrains"] = len(trains)
        stats["onTimeTrains"] = sum(not t.get("isDelayed", False) for t in trains)
        stats["delayedTrains"] = sum(t.get("isDelayed", False) for t in trains)
    alerts = load_events()
    # stats["criticalAlerts"] = sum(1 for a in alerts if a.get("severity", "").upper() == "CRITICAL")
    # a is resolving to be a string, not a dict
    stats["criticalAlerts"] = sum(1 for a in alerts if isinstance(a, dict) and a.get("severity", "").upper() == "CRITICAL")
    
    return format_response(True, "Dashboard statistics", stats)

@app.route("/api/refresh", methods=["POST"])
def refresh_data():
    # Just reload data from file for MVP
    return format_response(True, "Data refreshed successfully", {"lastUpdated": datetime.now().isoformat()})

@app.route("/api/schedule/generate", methods=["POST"])
def generate_schedule():
    global current_schedule, baseline_schedule
    trains = load_trains()
    stations, tracks = load_stations_tracks()
    scheduler = BasicScheduler(trains, stations, tracks)
    baseline_schedule = scheduler.create_initial_schedule()
    try:
        optimizer = TrainScheduleOptimizer(trains, tracks, {s['code']: s for s in stations})
        optimized_schedule = optimizer.optimize_schedule()
        if optimized_schedule:
            current_schedule = optimized_schedule
        else:
            current_schedule = baseline_schedule
    except Exception as e:
        print(f"[ERROR] Optimization failed, falling back: {e}")
        current_schedule = baseline_schedule
    return format_response(True, "Schedule generated", map_schedule_to_traininfo(current_schedule))

@app.route("/api/schedule/current", methods=["GET"])
def get_current_schedule():
    global current_schedule
    if not current_schedule:
        return format_response(False, "No schedule generated yet - POST /api/schedule/generate", code=404)
    return format_response(True, "Current schedule", map_schedule_to_traininfo(current_schedule))

@app.route("/api/disruption", methods=["POST"])
def report_disruption():
    global current_schedule, disruption_handler
    event_data = request.json
    if not current_schedule:
        return format_response(False, "No schedule loaded", code=400)
    if not disruption_handler:
        trains = load_trains()
        stations, tracks = load_stations_tracks()
        scheduler = BasicScheduler(trains, stations, tracks)
        optimizer = TrainScheduleOptimizer(trains, tracks, {s['code']: s for s in stations})
        disruption_handler = DisruptionHandler(scheduler, optimizer)
    updated_schedule = disruption_handler.handle_disruption(event_data, current_schedule)
    current_schedule = updated_schedule
    return format_response(True, "Disruption handled", map_schedule_to_traininfo(current_schedule))

@app.route("/api/whatif", methods=["POST"])
def whatif_scenario():
    scenario = request.json
    if not current_schedule:
        return format_response(False, "No schedule loaded", code=400)
    simulation = current_schedule.copy()
    if scenario.get("type") == "delay":
        train_id = scenario.get("train_id")
        minutes = int(scenario.get("delay_minutes", 30))
        if train_id in simulation:
            train_entry = simulation[train_id]
            old_delay = train_entry.get("delay_minutes", 0)
            train_entry["delay_minutes"] = old_delay + minutes
    elif scenario.get("type") == "cancel":
        train_id = scenario.get("train_id")
        if train_id in simulation:
            train_entry = simulation[train_id]
            train_entry["status"] = "CANCELLED"
    return format_response(True, "What-if scenario simulated", map_schedule_to_traininfo(simulation))

@app.errorhandler(404)
def notfound(e):
    return format_response(False, "Endpoint not found", code=404)

@app.errorhandler(500)
def internalerror(e):
    return format_response(False, "Internal server error", code=500)

if __name__ == "__main__":
    print("[STARTUP] AI-Powered Train Scheduler Flask API starting...")
    app.run(debug=True, host="0.0.0.0", port=5000)
