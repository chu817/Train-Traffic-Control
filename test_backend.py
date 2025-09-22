#!/usr/bin/env python3
"""
Test script for Indian Railways Control Center Flask Backend
Run this script to verify all endpoints are working correctly
"""

import requests
import json
import time

# Configuration
BASE_URL = "http://localhost:5000"
API_URL = f"{BASE_URL}/api"

class BackendTester:
    def __init__(self):
        self.session = requests.Session()
        self.test_results = []

    def log_test(self, test_name, success, message=""):
        """Log test result"""
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{status} {test_name}")
        if message:
            print(f"    {message}")
        self.test_results.append({"test": test_name, "success": success, "message": message})

    def test_health_check(self):
        """Test health endpoint"""
        try:
            response = self.session.get(f"{BASE_URL}/health")
            success = response.status_code == 200 and response.json().get('success')
            self.log_test("Health Check", success, f"Status: {response.status_code}")
            return success
        except Exception as e:
            self.log_test("Health Check", False, f"Error: {e}")
            return False

    def test_login(self):
        """Test login endpoint"""
        try:
            data = {"username": "demo", "password": "demo", "role": "Admin"}
            response = self.session.post(f"{API_URL}/login", json=data)
            success = response.status_code == 200 and response.json().get('success')
            self.log_test("Login", success, f"Status: {response.status_code}")
            return success
        except Exception as e:
            self.log_test("Login", False, f"Error: {e}")
            return False

    def test_session_check(self):
        """Test session check endpoint"""
        try:
            response = self.session.get(f"{API_URL}/session")
            success = response.status_code == 200 and response.json().get('success')
            self.log_test("Session Check", success, f"Status: {response.status_code}")
            return success
        except Exception as e:
            self.log_test("Session Check", False, f"Error: {e}")
            return False

    def test_get_trains(self):
        """Test get trains endpoint"""
        try:
            response = self.session.get(f"{API_URL}/trains")
            success = response.status_code == 200 and response.json().get('success')
            if success:
                trains = response.json().get('data', [])
                self.log_test("Get Trains", success, f"Found {len(trains)} trains")
            else:
                self.log_test("Get Trains", success, f"Status: {response.status_code}")
            return success
        except Exception as e:
            self.log_test("Get Trains", False, f"Error: {e}")
            return False

    def test_get_train_details(self):
        """Test get specific train details"""
        try:
            response = self.session.get(f"{API_URL}/trains/12002")
            success = response.status_code == 200 and response.json().get('success')
            self.log_test("Get Train Details", success, f"Status: {response.status_code}")
            return success
        except Exception as e:
            self.log_test("Get Train Details", False, f"Error: {e}")
            return False

    def test_get_alerts(self):
        """Test get alerts endpoint"""
        try:
            response = self.session.get(f"{API_URL}/alerts")
            success = response.status_code == 200 and response.json().get('success')
            if success:
                alerts = response.json().get('data', [])
                self.log_test("Get Alerts", success, f"Found {len(alerts)} alerts")
            else:
                self.log_test("Get Alerts", success, f"Status: {response.status_code}")
            return success
        except Exception as e:
            self.log_test("Get Alerts", False, f"Error: {e}")
            return False

    def test_dashboard_stats(self):
        """Test dashboard statistics endpoint"""
        try:
            response = self.session.get(f"{API_URL}/dashboard/stats")
            success = response.status_code == 200 and response.json().get('success')
            self.log_test("Dashboard Stats", success, f"Status: {response.status_code}")
            return success
        except Exception as e:
            self.log_test("Dashboard Stats", False, f"Error: {e}")
            return False

    def test_refresh_data(self):
        """Test data refresh endpoint"""
        try:
            response = self.session.post(f"{API_URL}/refresh")
            success = response.status_code == 200 and response.json().get('success')
            self.log_test("Refresh Data", success, f"Status: {response.status_code}")
            return success
        except Exception as e:
            self.log_test("Refresh Data", False, f"Error: {e}")
            return False

    def test_acknowledge_alert(self):
        """Test alert acknowledgment endpoint"""
        try:
            response = self.session.post(f"{API_URL}/alerts/alert_001/acknowledge")
            success = response.status_code == 200 and response.json().get('success')
            self.log_test("Acknowledge Alert", success, f"Status: {response.status_code}")
            return success
        except Exception as e:
            self.log_test("Acknowledge Alert", False, f"Error: {e}")
            return False

    def test_logout(self):
        """Test logout endpoint"""
        try:
            response = self.session.get(f"{API_URL}/logout")
            success = response.status_code == 200 and response.json().get('success')
            self.log_test("Logout", success, f"Status: {response.status_code}")
            return success
        except Exception as e:
            self.log_test("Logout", False, f"Error: {e}")
            return False

    def run_all_tests(self):
        """Run all tests in sequence"""
        print("🚂 Indian Railways Backend Test Suite")
        print("="*50)
        print(f"Testing backend at: {BASE_URL}")
        print("-"*50)

        # Test sequence (order matters for authentication)
        tests = [
            self.test_health_check,
            self.test_login,
            self.test_session_check,
            self.test_get_trains,
            self.test_get_train_details,
            self.test_get_alerts,
            self.test_dashboard_stats,
            self.test_refresh_data,
            self.test_acknowledge_alert,
            self.test_logout,
        ]

        passed = 0
        total = len(tests)

        for test in tests:
            if test():
                passed += 1
            time.sleep(0.1)  # Small delay between tests

        print("-"*50)
        print(f"📊 Test Results: {passed}/{total} tests passed")

        if passed == total:
            print("🎉 All tests passed! Backend is ready for Flutter integration.")
        else:
            print("⚠️  Some tests failed. Check the Flask server is running and try again.")

        return passed == total

def main():
    """Main test function"""
    try:
        tester = BackendTester()
        success = tester.run_all_tests()
        return 0 if success else 1
    except KeyboardInterrupt:
        print("\n❌ Tests interrupted by user")
        return 1
    except Exception as e:
        print(f"❌ Test suite failed: {e}")
        return 1

if __name__ == "__main__":
    exit(main())
