#!/usr/bin/env python3
"""
Test Neo4j AuraDB connection
"""

import os
from neo4j import GraphDatabase

def test_neo4j_connection():
    """Test connection to Neo4j AuraDB"""
    
    # Load environment variables
    from dotenv import load_dotenv
    load_dotenv()
    
    # Configuration
    uri = os.getenv('NEO4J_URI', 'neo4j+s://fe5c9d1d.databases.neo4j.io')
    username = os.getenv('NEO4J_USERNAME', 'neo4j')
    password = os.getenv('NEO4J_PASSWORD', '')
    database = os.getenv('NEO4J_DATABASE', 'neo4j')
    
    print(f"🔗 Testing connection to: {uri}")
    print(f"👤 Username: {username}")
    print(f"🗄️  Database: {database}")
    print()
    
    try:
        # Create driver
        driver = GraphDatabase.driver(uri, auth=(username, password))
        
        # Test connection
        with driver.session(database=database) as session:
            result = session.run("RETURN 1 as test")
            test_value = result.single()
            
            if test_value:
                print("✅ Connection successful!")
                print(f"📊 Test query result: {test_value['test']}")
                
                # Test if we can see any nodes
                result = session.run("MATCH (n) RETURN count(n) as node_count")
                node_count = result.single()
                print(f"📈 Total nodes in database: {node_count['node_count']}")
                
                # Check for Station nodes specifically
                result = session.run("MATCH (s:Station) RETURN count(s) as station_count")
                station_count = result.single()
                print(f"🚉 Station nodes: {station_count['station_count']}")
                
                # Show sample station properties if any exist
                if station_count['station_count'] > 0:
                    result = session.run("MATCH (s:Station) RETURN s LIMIT 3")
                    print("\n📋 Sample station properties:")
                    for record in result:
                        station = record['s']
                        print(f"   {dict(station)}")
                
                return True
            else:
                print("❌ Connection test failed - no result returned")
                return False
                
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        return False
    finally:
        if 'driver' in locals():
            driver.close()

if __name__ == "__main__":
    print("🧪 Neo4j AuraDB Connection Test")
    print("=" * 40)
    
    success = test_neo4j_connection()
    
    if success:
        print("\n🎉 Ready to use Neo4j with your Flutter app!")
    else:
        print("\n💡 Please check your credentials and try again.")
