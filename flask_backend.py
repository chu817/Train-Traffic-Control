# app.py - Main Flask Application for Indian Railways Control Center
from flask import Flask, request, jsonify, session
from flask_cors import CORS
from datetime import datetime, timedelta
import json
import os
from functools import wraps

app = Flask(__name__)
app.secret_key = 'indian_railways_mvp_secret_key_2025'  # Change this in production
CORS(app)  # Enable CORS for Flutter frontend

# Configuration
app.config['SESSION_PERMANENT'] = False
app.config['SESSION_TYPE'] = 'filesystem'

# Data storage (file-based for MVP)
DATA_FILE = 'railway_data.json'

# =============================================
# UTILITY FUNCTIONS
# =============================================

def load_data():
    """Load data from JSON file - flexible for future database integration"""
    if os.path.exists(DATA_FILE):
        try:
            with open(DATA_FILE, 'r') as f:
                return json.load(f)
        except:
            return get_default_data()
    return get_default_data()

def save_data(data):
    """Save data to JSON file - flexible for future database integration"""
    try:
        with open(DATA_FILE, 'w') as f:
            json.dump(data, f, indent=2)
        return True
    except:
        return False

def get_default_data():
    """Default data structure - easily expandable"""
    return {
        "users": {
            "admin": {
                "username": "demo",
                "password": "demo",
                "role": "Admin"
            }
        },
        "trains": [],
        "alerts": [],
        "stations": [],
        "settings": {
            "last_updated": datetime.now().isoformat()
        }
    }

def login_required(f):
    """Decorator to check if user is logged in"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            return jsonify({'error': 'Authentication required', 'code': 401}), 401
        return f(*args, **kwargs)
    return decorated_function

def format_response(success=True, message="", data=None, code=200):
    """Standardized response format"""
    response = {
        'success': success,
        'message': message,
        'timestamp': datetime.now().isoformat()
    }
    if data is not None:
        response['data'] = data
    return jsonify(response), code

# =============================================
# AUTHENTICATION ENDPOINTS
# =============================================

@app.route('/api/login', methods=['POST'])
def login():
    """
    Handle user login - matches Flutter login screen expectations
    Expected payload: {"username": "demo", "password": "demo", "role": "Admin"}
    """
    try:
        data = request.get_json()
        if not data:
            return format_response(False, "No data provided", code=400)

        username = data.get('username', '').strip()
        password = data.get('password', '').strip()
        role = data.get('role', '').strip()

        # Validate input
        if not username or not password:
            return format_response(False, "Username and password required", code=400)

        # For MVP: hardcoded credentials validation
        if username == 'demo' and password == 'demo':
            session['user_id'] = username
            session['role'] = role if role else 'Admin'
            session['login_time'] = datetime.now().isoformat()

            return format_response(True, "Login successful", {
                'username': username,
                'role': session['role'],
                'session_id': session.get('user_id')
            })
        else:
            return format_response(False, "Invalid credentials", code=401)

    except Exception as e:
        return format_response(False, f"Login error: {str(e)}", code=500)

@app.route('/api/logout', methods=['GET', 'POST'])
@login_required
def logout():
    """Handle user logout"""
    try:
        session.clear()
        return format_response(True, "Logout successful")
    except Exception as e:
        return format_response(False, f"Logout error: {str(e)}", code=500)

@app.route('/api/session', methods=['GET'])
def check_session():
    """Check if user session is valid"""
    if 'user_id' in session:
        return format_response(True, "Session valid", {
            'username': session.get('user_id'),
            'role': session.get('role'),
            'login_time': session.get('login_time')
        })
    return format_response(False, "No active session", code=401)

# =============================================
# TRAIN DATA ENDPOINTS
# =============================================

@app.route('/api/trains', methods=['GET'])
@login_required
def get_trains():
    """
    Get all train information - matches TrainInfo class structure
    Returns: List of train objects with all required fields
    """
    try:
        # Placeholder: In future, this will fetch from database
        trains_data = get_sample_trains()  # This will be replaced with actual data source

        return format_response(True, "Trains data retrieved", trains_data)

    except Exception as e:
        return format_response(False, f"Error fetching trains: {str(e)}", code=500)

@app.route('/api/trains/<train_number>', methods=['GET'])
@login_required
def get_train_details(train_number):
    """
    Get specific train details by train number
    """
    try:
        # Placeholder: In future, this will query database by train_number
        trains_data = get_sample_trains()
        train = next((t for t in trains_data if t['number'] == train_number), None)

        if train:
            return format_response(True, f"Train {train_number} details", train)
        else:
            return format_response(False, f"Train {train_number} not found", code=404)

    except Exception as e:
        return format_response(False, f"Error fetching train details: {str(e)}", code=500)

@app.route('/api/refresh', methods=['POST'])
@login_required
def refresh_data():
    """
    Trigger data refresh - placeholder for future real-time data integration
    """
    try:
        # Placeholder: In future, this will trigger actual data refresh from external APIs
        data = load_data()
        data['settings']['last_updated'] = datetime.now().isoformat()
        save_data(data)

        return format_response(True, "Data refreshed successfully", {
            'last_updated': data['settings']['last_updated']
        })

    except Exception as e:
        return format_response(False, f"Error refreshing data: {str(e)}", code=500)

# =============================================
# ALERTS ENDPOINTS
# =============================================

@app.route('/api/alerts', methods=['GET'])
@login_required
def get_alerts():
    """
    Get critical alerts - matches dashboard alert expectations
    """
    try:
        # Placeholder: In future, this will fetch real alerts from monitoring system
        alerts_data = get_sample_alerts()

        return format_response(True, "Alerts retrieved", alerts_data)

    except Exception as e:
        return format_response(False, f"Error fetching alerts: {str(e)}", code=500)

@app.route('/api/alerts/<alert_id>/acknowledge', methods=['POST'])
@login_required
def acknowledge_alert(alert_id):
    """
    Acknowledge a specific alert
    """
    try:
        # Placeholder: In future, this will update alert status in database
        return format_response(True, f"Alert {alert_id} acknowledged", {
            'alert_id': alert_id,
            'acknowledged_by': session.get('user_id'),
            'acknowledged_at': datetime.now().isoformat()
        })

    except Exception as e:
        return format_response(False, f"Error acknowledging alert: {str(e)}", code=500)

# =============================================
# DASHBOARD STATISTICS ENDPOINTS
# =============================================

@app.route('/api/dashboard/stats', methods=['GET'])
@login_required
def get_dashboard_stats():
    """
    Get dashboard statistics - matches dashboard summary section
    """
    try:
        # Placeholder: In future, this will calculate real statistics from database
        stats_data = get_sample_stats()

        return format_response(True, "Dashboard statistics", stats_data)

    except Exception as e:
        return format_response(False, f"Error fetching statistics: {str(e)}", code=500)

# =============================================
# PLACEHOLDER FUNCTIONS FOR FUTURE INTEGRATION
# =============================================

def get_sample_trains():
    """
    Placeholder function - returns sample train data matching Flutter TrainInfo structure
    TODO: Replace with actual database query or external API call
    """
    return [
        {
            "number": "12002",
            "name": "Shatabdi Express",
            "current": "New Delhi",
            "next": "Kanpur Central",
            "eta": "14:30",
            "passengers": 1200,
            "isDelayed": False,
            "delayTime": ""
        },
        {
            "number": "12951",
            "name": "Mumbai Rajdhani",
            "current": "Vadodara", 
            "next": "Surat",
            "eta": "16:45",
            "passengers": 1800,
            "isDelayed": True,
            "delayTime": "25 min"
        },
        {
            "number": "22691",
            "name": "Rajdhani Express",
            "current": "Gwalior",
            "next": "Jhansi", 
            "eta": "18:20",
            "passengers": 1500,
            "isDelayed": False,
            "delayTime": ""
        },
        {
            "number": "12425", 
            "name": "Jammu Express",
            "current": "Ambala",
            "next": "Jammu Tawi",
            "eta": "21:15",
            "passengers": 1100,
            "isDelayed": True,
            "delayTime": "39 min"
        }
    ]

def get_sample_alerts():
    """
    Placeholder function - returns sample alerts
    TODO: Replace with actual monitoring system integration
    """
    return [
        {
            "id": "alert_001",
            "type": "critical",
            "message": "Signal failure at Junction A - Track 3",
            "timestamp": datetime.now().isoformat(),
            "acknowledged": False
        }
    ]

def get_sample_stats():
    """
    Placeholder function - returns sample dashboard statistics
    TODO: Replace with actual data calculations
    """
    return {
        "on_time": 2,
        "delayed": 2, 
        "total_passengers": 5600,
        "avg_delay": "16 min",
        "active_trains": 4,
        "total_routes": 12
    }

def integrate_external_railway_api():
    """
    Placeholder function for future external API integration
    TODO: Implement actual railway data API integration
    """
    # This function will be used to fetch real train data from external APIs
    # For now, it returns None to indicate no external integration
    return None

def setup_real_time_monitoring():
    """
    Placeholder function for future real-time monitoring setup
    TODO: Implement WebSocket or SSE for real-time updates
    """
    # This function will set up real-time monitoring capabilities
    # For now, it's just a placeholder
    pass

def initialize_database_connection():
    """
    Placeholder function for future database setup
    TODO: Initialize actual database connection (PostgreSQL/MySQL/MongoDB)
    """
    # This function will initialize database connections
    # For now, we're using file-based storage
    pass

# =============================================
# ERROR HANDLERS
# =============================================

@app.errorhandler(404)
def not_found(error):
    return format_response(False, "Endpoint not found", code=404)

@app.errorhandler(500)
def internal_error(error):
    return format_response(False, "Internal server error", code=500)

# =============================================
# HEALTH CHECK ENDPOINT
# =============================================

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return format_response(True, "Server is running", {
        'version': '1.0.0',
        'status': 'healthy',
        'uptime': datetime.now().isoformat()
    })

# =============================================
# MAIN APPLICATION
# =============================================

if __name__ == '__main__':
    # Initialize data file if it doesn't exist
    if not os.path.exists(DATA_FILE):
        save_data(get_default_data())

    print("🚂 Indian Railways Control Center Backend Starting...")
    print("📱 Ready for Flutter frontend integration")
    print("🔧 MVP Mode: Using file-based storage and hardcoded credentials")
    print("🌐 CORS enabled for cross-origin requests")
    print("="*50)

    app.run(debug=True, host='0.0.0.0', port=5000)
