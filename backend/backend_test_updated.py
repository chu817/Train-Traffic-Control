import requests
import json

BASE = "http://localhost:5000/api"

def test_health():
    resp = requests.get("http://localhost:5000/health")
    print("Health:", resp.status_code, resp.json())

def test_login():
    resp = requests.post(f"{BASE}/login", json={"username": "demo", "password": "demo", "role": "Admin"})
    print("Login:", resp.status_code, resp.json())

def test_session():
    resp = requests.get(f"{BASE}/session")
    print("Session:", resp.status_code, resp.json())

def test_trains():
    resp = requests.get(f"{BASE}/trains")
    print("Trains:", resp.status_code, len(resp.json().get('data', [])))
    if resp.json().get("data"):
        train_id = resp.json()["data"][0]["train_id"]
        test_train_detail(train_id)

def test_train_detail(train_id):
    resp = requests.get(f"{BASE}/trains/{train_id}")
    print(f"Train {train_id} details:", resp.status_code, resp.json())

def test_alerts():
    resp = requests.get(f"{BASE}/alerts")
    print("Alerts:", resp.status_code, resp.json())

def test_dashboard():
    resp = requests.get(f"{BASE}/dashboardstats")
    print("Dashboard Stats:", resp.status_code, resp.json())

def test_refresh():
    resp = requests.post(f"{BASE}/refresh")
    print("Refresh:", resp.status_code, resp.json())

def test_acknowledge_alert(alert_id="alert001"):
    resp = requests.post(f"{BASE}/alerts/{alert_id}/acknowledge")
    print("Acknowledge Alert:", resp.status_code, resp.json())

def test_generate_schedule():
    resp = requests.post(f"{BASE}/schedule/generate")
    print("Generate Schedule:", resp.status_code, resp.json())
    return resp.json().get("data", [])

def test_get_schedule():
    resp = requests.get(f"{BASE}/schedule/current")
    print("Current Schedule:", resp.status_code, resp.json())

def main():
    print("== Testing Backend ==")
    test_acknowledge_alert()
    test_dashboard()
    test_health()
    test_trains()
    test_login()
    test_session()
    test_alerts()
    test_refresh()
    test_generate_schedule()
    test_get_schedule()

if __name__ == "__main__":
    main()
