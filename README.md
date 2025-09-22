# Indian Railways Control Center - Flask Backend

A flexible Flask backend designed to integrate with the Flutter frontend for the Indian Railways Control Center MVP.

## 🎯 Overview

This backend provides all the necessary API endpoints that your Flutter frontend expects, with flexible placeholder functions that can be easily extended for future integration with real databases and external APIs.

## 🚀 Quick Start

### Prerequisites
- Python 3.7+
- pip

### Installation
1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Run the server:
```bash
python flask_backend.py
```

The server will start on `http://localhost:5000`

## 📱 Frontend Integration

### Base URL
```
http://localhost:5000/api
```

### Authentication
The backend uses session-based authentication. Login first, then all subsequent requests will be authenticated automatically.

**Demo Credentials:**
- Username: `demo`
- Password: `demo`
- Role: Any role (Admin, Station Master, etc.)

## 🔌 API Endpoints

### Authentication
- `POST /api/login` - User login
- `GET /api/logout` - User logout  
- `GET /api/session` - Check session status

### Train Data
- `GET /api/trains` - Get all trains
- `GET /api/trains/<train_number>` - Get specific train
- `POST /api/refresh` - Refresh train data

### Alerts
- `GET /api/alerts` - Get critical alerts
- `POST /api/alerts/<alert_id>/acknowledge` - Acknowledge alert

### Dashboard
- `GET /api/dashboard/stats` - Get dashboard statistics

### Utility
- `GET /health` - Health check

## 📊 Data Structure

### Train Object (matches Flutter TrainInfo class)
```json
{
  "number": "12002",
  "name": "Shatabdi Express", 
  "current": "New Delhi",
  "next": "Kanpur Central",
  "eta": "14:30",
  "passengers": 1200,
  "isDelayed": false,
  "delayTime": ""
}
```

### Response Format
All endpoints return standardized responses:
```json
{
  "success": true,
  "message": "Operation successful",
  "timestamp": "2025-09-22T19:32:00",
  "data": { ... }
}
```

## 🔧 MVP Features

### ✅ Implemented
- Session-based authentication
- Hardcoded demo credentials
- File-based data storage
- All Flutter-required endpoints
- CORS enabled
- Error handling
- Flexible data structure

### 📋 Placeholder Functions (Ready for Extension)
- `get_sample_trains()` - Replace with database query
- `get_sample_alerts()` - Replace with monitoring system
- `get_sample_stats()` - Replace with real calculations
- `integrate_external_railway_api()` - For external API integration
- `setup_real_time_monitoring()` - For WebSocket/SSE
- `initialize_database_connection()` - For database setup

## 🛠️ Future Integration Points

### Database Integration
Replace file-based storage:
```python
# Current: save_data(data)
# Future: db.session.commit()
```

### External APIs
Use placeholder function:
```python
def integrate_external_railway_api():
    # Add your external API integration here
    response = requests.get('https://api.railway.gov.in/trains')
    return response.json()
```

### Real-time Features
Extend monitoring function:
```python
def setup_real_time_monitoring():
    # Add WebSocket or SSE implementation
    socketio = SocketIO(app)
    return socketio
```

## 📁 Project Structure

```
backend/
├── flask_backend.py      # Main Flask application
├── requirements.txt      # Python dependencies
├── railway_data.json     # Data storage (auto-generated)
└── README.md            # This file
```

## 🔒 Security Notes

- **Demo Mode**: Uses hardcoded credentials (`demo`/`demo`)
- **Session Secret**: Change `app.secret_key` in production
- **CORS**: Enabled for development, configure for production
- **File Storage**: Not suitable for production scale

## 🚀 Production Considerations

For production deployment, consider:
1. **Database**: PostgreSQL/MySQL instead of file storage
2. **Authentication**: JWT tokens or OAuth
3. **Environment Variables**: Use python-dotenv
4. **WSGI Server**: Gunicorn instead of development server
5. **Security**: Proper HTTPS and security headers

## 🤝 Flutter Integration Examples

### Login Request
```dart
final response = await http.post(
  Uri.parse('http://localhost:5000/api/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'username': 'demo',
    'password': 'demo', 
    'role': 'Admin'
  }),
);
```

### Get Trains
```dart
final response = await http.get(
  Uri.parse('http://localhost:5000/api/trains'),
);
final trains = jsonDecode(response.body)['data'];
```

## 📞 Support

This backend is specifically designed to support your Flutter frontend with:
- ✅ All expected API endpoints
- ✅ Matching data structures  
- ✅ Session-based auth
- ✅ Flexible architecture for future expansion

The placeholder functions are ready for your specific integration requirements!
