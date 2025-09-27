"""
Neo4j AuraDB service for fetching railway station data
"""

import os
from typing import List, Dict, Optional
from neo4j import GraphDatabase
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class Neo4jService:
    def __init__(self):
        """Initialize Neo4j connection"""
        self.uri = os.getenv('NEO4J_URI', '')
        self.username = os.getenv('NEO4J_USERNAME', '')
        self.password = os.getenv('NEO4J_PASSWORD', '')
        self.database = os.getenv('NEO4J_DATABASE', 'neo4j')
        
        if not all([self.uri, self.username, self.password]):
            logger.warning("Neo4j credentials not found in environment variables")
            self.driver = None
        else:
            try:
                self.driver = GraphDatabase.driver(
                    self.uri, 
                    auth=(self.username, self.password)
                )
                logger.info("✅ Connected to Neo4j AuraDB")
            except Exception as e:
                logger.error(f"❌ Failed to connect to Neo4j: {e}")
                self.driver = None

    def close(self):
        """Close Neo4j connection"""
        if self.driver:
            self.driver.close()

    def test_connection(self) -> bool:
        """Test Neo4j connection"""
        if not self.driver:
            return False
        
        try:
            with self.driver.session(database=self.database) as session:
                result = session.run("RETURN 1 as test")
                return result.single() is not None
        except Exception as e:
            logger.error(f"Neo4j connection test failed: {e}")
            return False

    def get_stations(self, limit: Optional[int] = None) -> List[Dict]:
        """
        Fetch all railway stations from Neo4j
        
        Args:
            limit: Maximum number of stations to return (None for all)
            
        Returns:
            List of station dictionaries
        """
        if not self.driver:
            logger.error("Neo4j driver not initialized")
            return []
        
        try:
            with self.driver.session(database=self.database) as session:
                # Query to fetch stations - adjust based on your node structure
                query = """
                MATCH (s:Station)
                RETURN s.code as code,
                       s.name as name,
                       s.lat as latitude,
                       s.lng as longitude,
                       s.zone as zone,
                       s.state as state,
                       s.division as division,
                       s.type as type,
                       s.platforms as platforms
                ORDER BY s.name
                """
                
                if limit:
                    query += f" LIMIT {limit}"
                
                result = session.run(query)
                stations = []
                
                for record in result:
                    # Handle null coordinates with default India center
                    lat = record.get("latitude")
                    lng = record.get("longitude")
                    
                    if lat is None or lng is None:
                        # Use real coordinates for major stations, default for others
                        station_code = record.get("code", "")
                        
                        # Real coordinates for major stations
                        real_coords = {
                            "NDLS": (28.6448, 77.2167),  # New Delhi
                            "MTJ": (27.4924, 77.6739),   # Mathura Junction
                            "AGC": (27.1767, 78.0081),   # Agra Cantt
                            "NZM": (28.5849, 77.2197),   # Hazrat Nizamuddin
                            "MAS": (13.0827, 80.2707),   # Chennai Central
                            "CSTM": (18.9404, 72.8354),  # Mumbai CST
                            "HWH": (22.5851, 88.3468),   # Howrah
                            "SBC": (12.9716, 77.5946),   # Bangalore City
                            "ADI": (23.0225, 72.5714),   # Ahmedabad
                            "BCT": (19.0176, 72.8562),   # Mumbai Central
                        }
                        
                        if station_code in real_coords:
                            lat, lng = real_coords[station_code]
                        else:
                            # Use default India center coordinates for stations without coordinates
                            lat = 20.5937
                            lng = 78.9629
                    
                    station = {
                        "id": record.get("code", ""),
                        "name": record.get("name", ""),
                        "position": {
                            "latitude": lat,
                            "longitude": lng
                        },
                        "type": record.get("type", "minor"),
                        "platforms": record.get("platforms", 2),
                        "zone": record.get("zone", ""),
                        "state": record.get("state", ""),
                        "division": record.get("division", "")
                    }
                    stations.append(station)
                
                logger.info(f"✅ Fetched {len(stations)} stations from Neo4j")
                return stations
                
        except Exception as e:
            logger.error(f"Error fetching stations from Neo4j: {e}")
            return []

    def get_station_by_code(self, station_code: str) -> Optional[Dict]:
        """
        Fetch a specific station by its code
        
        Args:
            station_code: The station code to search for
            
        Returns:
            Station dictionary or None if not found
        """
        if not self.driver:
            return None
        
        try:
            with self.driver.session(database=self.database) as session:
                query = """
                MATCH (s:Station {code: $code})
                RETURN s.code as code,
                       s.name as name,
                       s.lat as latitude,
                       s.lng as longitude,
                       s.zone as zone,
                       s.state as state,
                       s.division as division,
                       s.type as type,
                       s.platforms as platforms
                """
                
                result = session.run(query, code=station_code)
                record = result.single()
                
                if record:
                    # Handle null coordinates with default India center
                    lat = record.get("latitude")
                    lng = record.get("longitude")
                    
                    if lat is None or lng is None:
                        # Use real coordinates for major stations, default for others
                        station_code = record.get("code", "")
                        
                        # Real coordinates for major stations
                        real_coords = {
                            "NDLS": (28.6448, 77.2167),  # New Delhi
                            "MTJ": (27.4924, 77.6739),   # Mathura Junction
                            "AGC": (27.1767, 78.0081),   # Agra Cantt
                            "NZM": (28.5849, 77.2197),   # Hazrat Nizamuddin
                            "MAS": (13.0827, 80.2707),   # Chennai Central
                            "CSTM": (18.9404, 72.8354),  # Mumbai CST
                            "HWH": (22.5851, 88.3468),   # Howrah
                            "SBC": (12.9716, 77.5946),   # Bangalore City
                            "ADI": (23.0225, 72.5714),   # Ahmedabad
                            "BCT": (19.0176, 72.8562),   # Mumbai Central
                        }
                        
                        if station_code in real_coords:
                            lat, lng = real_coords[station_code]
                        else:
                            # Use default India center coordinates for stations without coordinates
                            lat = 20.5937
                            lng = 78.9629
                    
                    return {
                        "id": record.get("code", ""),
                        "name": record.get("name", ""),
                        "position": {
                            "latitude": lat,
                            "longitude": lng
                        },
                        "type": record.get("type", "minor"),
                        "platforms": record.get("platforms", 2),
                        "zone": record.get("zone", ""),
                        "state": record.get("state", ""),
                        "division": record.get("division", "")
                    }
                return None
                
        except Exception as e:
            logger.error(f"Error fetching station {station_code} from Neo4j: {e}")
            return None

    def get_connected_stations(self, station_code: str) -> List[Dict]:
        """
        Get stations directly connected to the given station via route relationships
        
        Args:
            station_code: The station code to find connections for
            
        Returns:
            List of connected station dictionaries including the station itself
        """
        if not self.driver:
            logger.error("Neo4j driver not initialized")
            return []
        
        try:
            with self.driver.session(database=self.database) as session:
                # Query to find stations connected via route relationships
                query = """
                MATCH (s:Station {code: $station_code})
                OPTIONAL MATCH (s)-[r:ROUTE]-(connected:Station)
                WITH s, collect(DISTINCT connected) as connected_stations
                UNWIND [s] + connected_stations as station
                RETURN station.code as code,
                       station.name as name,
                       station.lat as latitude,
                       station.lng as longitude,
                       station.zone as zone,
                       station.state as state,
                       station.division as division,
                       station.type as type,
                       station.platforms as platforms
                ORDER BY station.name
                """
                
                result = session.run(query, station_code=station_code)
                stations = []
                
                for record in result:
                    # Handle null coordinates with default India center
                    lat = record.get("latitude")
                    lng = record.get("longitude")
                    
                    if lat is None or lng is None:
                        # Use real coordinates for major stations, default for others
                        station_code = record.get("code", "")
                        
                        # Real coordinates for major stations
                        real_coords = {
                            "NDLS": (28.6448, 77.2167),  # New Delhi
                            "MTJ": (27.4924, 77.6739),   # Mathura Junction
                            "AGC": (27.1767, 78.0081),   # Agra Cantt
                            "NZM": (28.5849, 77.2197),   # Hazrat Nizamuddin
                            "MAS": (13.0827, 80.2707),   # Chennai Central
                            "CSTM": (18.9404, 72.8354),  # Mumbai CST
                            "HWH": (22.5851, 88.3468),   # Howrah
                            "SBC": (12.9716, 77.5946),   # Bangalore City
                            "ADI": (23.0225, 72.5714),   # Ahmedabad
                            "BCT": (19.0176, 72.8562),   # Mumbai Central
                        }
                        
                        if station_code in real_coords:
                            lat, lng = real_coords[station_code]
                        else:
                            # Use default India center coordinates for stations without coordinates
                            lat = 20.5937
                            lng = 78.9629
                    
                    station = {
                        "id": record.get("code", ""),
                        "name": record.get("name", ""),
                        "position": {
                            "latitude": lat,
                            "longitude": lng
                        },
                        "type": record.get("type", "minor"),
                        "platforms": record.get("platforms", 2),
                        "zone": record.get("zone", ""),
                        "state": record.get("state", ""),
                        "division": record.get("division", "")
                    }
                    stations.append(station)
                
                logger.info(f"✅ Found {len(stations)} connected stations for {station_code}")
                return stations
                
        except Exception as e:
            logger.error(f"Error fetching connected stations for {station_code}: {e}")
            return []

    def search_stations(self, search_term: str, limit: int = 100) -> List[Dict]:
        """
        Search stations by name, code, or other fields
        
        Args:
            search_term: The search term
            limit: Maximum number of results
            
        Returns:
            List of matching station dictionaries
        """
        if not self.driver:
            return []
        
        try:
            with self.driver.session(database=self.database) as session:
                query = """
                MATCH (s:Station)
                WHERE toLower(s.name) CONTAINS toLower($search) 
                   OR toLower(s.code) CONTAINS toLower($search)
                   OR toLower(s.zone) CONTAINS toLower($search)
                   OR toLower(s.state) CONTAINS toLower($search)
                RETURN s.code as code,
                       s.name as name,
                       s.lat as latitude,
                       s.lng as longitude,
                       s.zone as zone,
                       s.state as state,
                       s.division as division,
                       s.type as type,
                       s.platforms as platforms
                ORDER BY s.name
                LIMIT $limit
                """
                
                result = session.run(query, search=search_term, limit=limit)
                stations = []
                
                for record in result:
                    # Handle null coordinates with default India center
                    lat = record.get("latitude")
                    lng = record.get("longitude")
                    
                    if lat is None or lng is None:
                        # Use real coordinates for major stations, default for others
                        station_code = record.get("code", "")
                        
                        # Real coordinates for major stations
                        real_coords = {
                            "NDLS": (28.6448, 77.2167),  # New Delhi
                            "MTJ": (27.4924, 77.6739),   # Mathura Junction
                            "AGC": (27.1767, 78.0081),   # Agra Cantt
                            "NZM": (28.5849, 77.2197),   # Hazrat Nizamuddin
                            "MAS": (13.0827, 80.2707),   # Chennai Central
                            "CSTM": (18.9404, 72.8354),  # Mumbai CST
                            "HWH": (22.5851, 88.3468),   # Howrah
                            "SBC": (12.9716, 77.5946),   # Bangalore City
                            "ADI": (23.0225, 72.5714),   # Ahmedabad
                            "BCT": (19.0176, 72.8562),   # Mumbai Central
                        }
                        
                        if station_code in real_coords:
                            lat, lng = real_coords[station_code]
                        else:
                            # Use default India center coordinates for stations without coordinates
                            lat = 20.5937
                            lng = 78.9629
                    
                    station = {
                        "id": record.get("code", ""),
                        "name": record.get("name", ""),
                        "position": {
                            "latitude": lat,
                            "longitude": lng
                        },
                        "type": record.get("type", "minor"),
                        "platforms": record.get("platforms", 2),
                        "zone": record.get("zone", ""),
                        "state": record.get("state", ""),
                        "division": record.get("division", "")
                    }
                    stations.append(station)
                
                logger.info(f"✅ Found {len(stations)} stations matching '{search_term}'")
                return stations
                
        except Exception as e:
            logger.error(f"Error searching stations in Neo4j: {e}")
            return []

# Global instance
neo4j_service = Neo4jService()
