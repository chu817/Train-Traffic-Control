#!/usr/bin/env python3
"""
Script to analyze route relationships in Neo4j database
Finds stations with maximum route connections
"""

import os
from neo4j import GraphDatabase
from dotenv import load_dotenv
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s:%(name)s:%(message)s')
logger = logging.getLogger(__name__)

def analyze_route_connections():
    """Analyze route connections in Neo4j database"""
    
    # Load environment variables
    load_dotenv()
    
    uri = os.getenv("NEO4J_URI")
    username = os.getenv("NEO4J_USERNAME")
    password = os.getenv("NEO4J_PASSWORD")
    database = os.getenv("NEO4J_DATABASE", "neo4j")
    
    if not all([uri, username, password]):
        logger.error("Neo4j credentials not found in environment variables")
        return
    
    try:
        # Connect to Neo4j
        driver = GraphDatabase.driver(uri, auth=(username, password))
        driver.verify_connectivity()
        logger.info("✅ Connected to Neo4j AuraDB")
        
        with driver.session(database=database) as session:
            # Query to find stations with route connections
            query = """
            MATCH (s:Station)
            OPTIONAL MATCH (s)-[r:ROUTE]-(connected:Station)
            WITH s, count(DISTINCT connected) as connection_count
            WHERE connection_count > 0
            RETURN s.code as station_code, 
                   s.name as station_name, 
                   connection_count
            ORDER BY connection_count DESC
            LIMIT 20
            """
            
            result = session.run(query)
            stations = []
            
            for record in result:
                station = {
                    "code": record.get("station_code", ""),
                    "name": record.get("station_name", ""),
                    "connections": record.get("connection_count", 0)
                }
                stations.append(station)
            
            logger.info(f"📊 Found {len(stations)} stations with route connections")
            
            if stations:
                print("\n🏆 TOP 20 STATIONS BY ROUTE CONNECTIONS:")
                print("=" * 80)
                for i, station in enumerate(stations, 1):
                    print(f"{i:2d}. {station['code']:8s} | {station['name']:30s} | {station['connections']:3d} connections")
                
                # Find the station with maximum connections
                max_station = max(stations, key=lambda x: x['connections'])
                print(f"\n🥇 STATION WITH MAXIMUM ROUTES:")
                print(f"   Code: {max_station['code']}")
                print(f"   Name: {max_station['name']}")
                print(f"   Connections: {max_station['connections']}")
                
                # Get detailed connections for the top station
                print(f"\n🔗 DETAILED CONNECTIONS FOR {max_station['code']}:")
                detail_query = """
                MATCH (s:Station {code: $station_code})
                OPTIONAL MATCH (s)-[r:ROUTE]-(connected:Station)
                RETURN connected.code as connected_code,
                       connected.name as connected_name
                ORDER BY connected.name
                """
                
                detail_result = session.run(detail_query, station_code=max_station['code'])
                connected_stations = []
                
                for record in detail_result:
                    if record.get("connected_code"):
                        connected_stations.append({
                            "code": record.get("connected_code"),
                            "name": record.get("connected_name")
                        })
                
                for station in connected_stations:
                    print(f"   → {station['code']:8s} | {station['name']}")
                
            else:
                print("❌ No stations with route connections found")
                
            # Check total number of route relationships
            count_query = "MATCH ()-[r:ROUTE]-() RETURN count(r) as total_routes"
            count_result = session.run(count_query)
            total_routes = count_result.single()["total_routes"]
            print(f"\n📈 TOTAL ROUTE RELATIONSHIPS IN DATABASE: {total_routes}")
            
    except Exception as e:
        logger.error(f"Error analyzing routes: {e}")
    finally:
        if 'driver' in locals():
            driver.close()
            logger.info("Neo4j driver closed")

if __name__ == "__main__":
    analyze_route_connections()
