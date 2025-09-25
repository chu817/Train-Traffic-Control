from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_socketio import SocketIO, emit
import json
from datetime import datetime, timedelta

# Import our custom modules
from algorithms.scheduler import BasicScheduler
from algorithms.optimizer import TrainScheduleOptimizer
from algorithms.kpi_calculator import KPICalculator
from algorithms.event_handler import DisruptionHandler

app = Flask(__name__)
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*")

# Global variables for data storage
trains_data = []
stations_data = []
tracks_data = []
current_schedule = {}
baseline_schedule = {}
kpi_calculator = KPICalculator()
disruption_handler = None

def load_synthetic_data():
    global trains_data, stations_data, tracks_data
    
    # Load trains
    with open('data/synthetic_trains.json', 'r') as f:
        trains_data = json.load(f)
    
    # Load stations and tracks
    with open('data/synthetic_stations.json', 'r') as f:
        infrastructure = json.load(f)
        stations_data = infrastructure['stations']
        tracks_data = infrastructure['tracks']
    
    print(f"Loaded {len(trains_data)} trains, {len(stations_data)} stations, {len(tracks_data)} tracks")

@app.route('/api/trains', methods=['GET'])
def get_trains():
    return jsonify(trains_data)

@app.route('/api/stations', methods=['GET'])
def get_stations():
    return jsonify(stations_data)

@app.route('/api/tracks', methods=['GET'])
def get_tracks():
    return jsonify(tracks_data)

@app.route('/api/schedule/generate', methods=['POST'])
def generate_schedule():
    global current_schedule, baseline_schedule
    
    try:
        # Use basic scheduler for quick results
        scheduler = BasicScheduler(trains_data, stations_data, tracks_data)
        baseline_schedule = scheduler.create_initial_schedule()
        
        # Try optimization if time permits
        try:
            optimizer = TrainScheduleOptimizer(trains_data, tracks_data, {s['code']: s for s in stations_data})
            optimized_schedule = optimizer.optimize_schedule()
            
            if optimized_schedule:
                current_schedule = optimized_schedule
                print("Using optimized schedule")
            else:
                current_schedule = baseline_schedule
                print("Using basic schedule")
                
        except Exception as e:
            print(f"Optimization failed, using basic schedule: {e}")
            current_schedule = baseline_schedule
        
        # Calculate KPIs
        kpis = kpi_calculator.calculate_kpis(current_schedule)
        
        # Emit real-time update
        socketio.emit('schedule_updated', {
            'schedule': current_schedule,
            'kpis': kpis,
            'timestamp': datetime.now().isoformat()
        })
        
        return jsonify({
            'success': True,
            'schedule': current_schedule,
            'kpis': kpis,
            'total_trains': len(current_schedule)
        })
        
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/schedule/current', methods=['GET'])
def get_current_schedule():
    kpis = kpi_calculator.calculate_kpis(current_schedule) if current_schedule else {}
    
    return jsonify({
        'schedule': current_schedule,
        'kpis': kpis,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/disruption', methods=['POST'])
def handle_disruption():
    global current_schedule, disruption_handler
    
    try:
        event_data = request.json
        
        if not disruption_handler:
            scheduler = BasicScheduler(trains_data, stations_data, tracks_data)
            optimizer = TrainScheduleOptimizer(trains_data, tracks_data, {s['code']: s for s in stations_data})
            disruption_handler = DisruptionHandler(scheduler, optimizer)
        
        # Process disruption
        updated_schedule = disruption_handler.handle_disruption(event_data, current_schedule)
        current_schedule = updated_schedule
        
        # Calculate new KPIs
        kpis = kpi_calculator.calculate_kpis(current_schedule)
        
        # Emit real-time update
        socketio.emit('disruption_handled', {
            'event': event_data,
            'updated_schedule': current_schedule,
            'kpis': kpis,
            'timestamp': datetime.now().isoformat()
        })
        
        return jsonify({
            'success': True,
            'event_processed': event_data['event_id'],
            'affected_trains': len(event_data.get('affected_trains', [])),
            'updated_schedule': current_schedule,
            'kpis': kpis
        })
        
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/whatif', methods=['POST'])
def whatif_simulation():
    """
    Run what-if scenarios without affecting current schedule
    """
    try:
        scenario_data = request.json
        
        # Create a copy of current schedule for simulation
        simulation_schedule = current_schedule.copy()
        
        # Apply scenario changes
        scenario_type = scenario_data.get('type', 'delay')
        
        if scenario_type == 'delay':
            # Simulate train delay
            train_id = scenario_data['train_id']
            delay_minutes = scenario_data['delay_minutes']
            
            if train_id in simulation_schedule:
                train_schedule = simulation_schedule[train_id]
                original_dep = datetime.fromisoformat(train_schedule['optimized_departure'])
                new_dep = original_dep + timedelta(minutes=delay_minutes)
                
                simulation_schedule[train_id]['optimized_departure'] = new_dep.isoformat()
                simulation_schedule[train_id]['delay_minutes'] = train_schedule.get('delay_minutes', 0) + delay_minutes
        
        elif scenario_type == 'cancel':
            # Simulate train cancellation
            train_id = scenario_data['train_id']
            if train_id in simulation_schedule:
                simulation_schedule[train_id]['status'] = 'cancelled'
        
        # Calculate KPIs for simulation
        simulation_kpis = kpi_calculator.calculate_kpis(simulation_schedule)
        original_kpis = kpi_calculator.calculate_kpis(current_schedule)
        
        # Compare with current schedule
        improvements = kpi_calculator.calculate_improvement_metrics(original_kpis, simulation_kpis)
        
        return jsonify({
            'success': True,
            'scenario': scenario_data,
            'simulated_schedule': simulation_schedule,
            'original_kpis': original_kpis,
            'simulated_kpis': simulation_kpis,
            'impact_analysis': improvements
        })
        
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/kpis', methods=['GET'])
def get_kpis():
    """
    Get current KPIs and performance metrics
    """
    kpis = kpi_calculator.calculate_kpis(current_schedule) if current_schedule else {}
    
    # Add baseline comparison if available
    if baseline_schedule:
        baseline_kpis = kpi_calculator.calculate_kpis(baseline_schedule)
        improvements = kpi_calculator.calculate_improvement_metrics(baseline_kpis, kpis)
        kpis['improvements'] = improvements
        kpis['baseline_comparison'] = baseline_kpis
    
    return jsonify(kpis)

@app.route('/api/disruptions/active', methods=['GET'])
def get_active_disruptions():
    """
    Get list of active disruptions
    """
    if disruption_handler:
        disruptions = disruption_handler.get_active_disruptions()
        return jsonify(disruptions)
    else:
        return jsonify({})

# WebSocket events for real-time updates
@socketio.on('connect')
def handle_connect():
    print('Client connected')
    emit('connected', {'data': 'Connected to train control system'})

@socketio.on('disconnect')
def handle_disconnect():
    print('Client disconnected')

@socketio.on('request_live_update')
def handle_live_update_request():
    kpis = kpi_calculator.calculate_kpis(current_schedule) if current_schedule else {}
    
    emit('live_update', {
        'schedule': current_schedule,
        'kpis': kpis,
        'timestamp': datetime.now().isoformat()
    })

if __name__ == '__main__':
    print("Loading synthetic data...")
    load_synthetic_data()
    
    print("Starting Flask app...")
    socketio.run(app, debug=True, host='0.0.0.0', port=5000)