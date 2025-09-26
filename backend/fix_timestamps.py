import re, json
# import datetime
from datetime import datetime, timedelta

with open("data/synthetic_trains.json") as f:
    trains = json.load(f)

for t in trains:
    for k in ["scheduled_departure", "scheduled_arrival"]:
        s = t[k]
        if "+" in s and not ":" in s.split("+")[1]:  # matches +1, +2 etc, not tz
            base, plus = s.split("+")
            try:
                days = int(plus)
                dt = datetime.fromisoformat(base) + timedelta(days=days)
                t[k] = dt.strftime("%Y-%m-%dT%H:%M:%S")
            except:
                t[k] = base

with open("data/synthetic_trains.json", "w") as f:
    json.dump(trains, f, indent=2)
