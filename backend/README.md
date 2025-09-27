# Backend - Train Traffic Control

## Setup

1. Create a Python 3.9+ environment.
2. Install dependencies:

```
pip install -r requirements.txt
```

3. Create `.env` in `backend/` with:

```
NEO4J_URI="neo4j+s://<your-db-id>.databases.neo4j.io"
NEO4J_USERNAME="neo4j"
NEO4J_PASSWORD="<password>"
NEO4J_DATABASE="neo4j"
RAILRADAR_API_KEY="<railradar-api-key>"
GEMINI_API_KEY="<gemini-api-key>"
```

4. Run server:

```
python3 app.py
```

Server runs at `http://localhost:5001`.

### AI Recommendations
- Endpoint: `POST /api/ai/recommendations`
- Body: `{ station: string, live_trains: [...], constraints?: {}, prompt?: string }`
- Requires `GEMINI_API_KEY` in `.env`.

## API Endpoints

### Trains
- `GET /api/trains` - Get all trains
- `GET /api/trains?status=running` - Filter by status
- `GET /api/trains/<train_id>` - Get specific train
- `PUT /api/trains/<train_id>/position` - Update train position
- `PUT /api/trains/<train_id>/status` - Update train status

### Routes & Stations
- `GET /api/routes` - Get railway routes
- `GET /api/stations` - Get all stations

### System
- `GET /api/health` - Health check
- `GET /` - API info

## Sample Data

The API includes dummy data for:
- **5 Trains** with different statuses (running, delayed, stopped, maintenance)
- **2 Railway Routes** with GPS coordinates
- **4 Major Stations** across India

## Data Format

### Train Object
```json
{
  "id": "12951",
  "name": "Rajdhani Express", 
  "position": {"latitude": 28.6139, "longitude": 77.2090},
  "status": "running",
  "route": "Delhi-Mumbai",
  "lastUpdate": "2024-01-15T10:30:00",
  "speed": 120,
  "direction": "South",
  "nextStation": "Agra",
  "delay": 0
}
```

### Route Object
```json
{
  "id": "route_1",
  "name": "Delhi-Mumbai Main Line",
  "points": [
    {"latitude": 28.6139, "longitude": 77.2090},
    {"latitude": 19.0760, "longitude": 72.8777}
  ],
  "color": "#0D47A1",
  "width": 3
}
```

## CORS Enabled

The API has CORS enabled to allow requests from the Flutter frontend running on different ports.
