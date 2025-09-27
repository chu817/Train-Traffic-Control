#!/bin/bash

echo "🚂 Starting Train Traffic Control Backend Server..."
echo "📍 Installing dependencies..."

# Install dependencies
python3 -m pip install -r requirements.txt

echo "🌐 Starting Flask server on http://localhost:5001"
echo "📋 Available endpoints:"
echo "   GET  /api/trains - Get all trains"
echo "   GET  /api/trains/<id> - Get specific train"
echo "   GET  /api/routes - Get railway routes"
echo "   GET  /api/stations - Get stations"
echo "   PUT  /api/trains/<id>/position - Update train position"
echo "   PUT  /api/trains/<id>/status - Update train status"
echo "   GET  /api/health - Health check"
echo ""
echo "🧪 Run 'python3 test_api.py' to test all endpoints"
echo ""

# Start the server
python3 app.py
