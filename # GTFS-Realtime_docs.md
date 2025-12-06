# GTFS Realtime — Malaysia's Official Open API

## GTFS Realtime API Endpoint

```
GET https://api.data.gov.my/gtfs-realtime/<feed>/<agency>
```

---

## What Does GTFS Realtime Do?

GTFS Realtime is an extension of the [GTFS Static API](https://developer.data.gov.my/realtime-api/gtfs-static) that enables transport operators to share:

* Live **vehicle positions**
* (Upcoming in 2026) **Service alerts & trip updates**

More details: [https://gtfs.org/realtime/](https://gtfs.org/realtime/)

**Note:** Validation errors in the Vehicle Position section are generated using the [GTFS Realtime Validator](https://github.com/MobilityData/gtfs-realtime-validator).

---

## Source of GTFS Realtime Data

The API aggregates live data from Malaysian transport agencies:

### • [KTMB](https://www.ktmb.com.my/)

National train services operator.

### • [Prasarana](https://myrapid.com.my/)

Operates LRT, MRT, Monorail, and Rapid Bus networks.

### • [BAS.MY](https://bas.my/)

Stage buses across Malaysia. Supported regions include:
Kangar, Alor Setar, Kota Bharu, Kuala Terengganu, Ipoh, Seremban, Melaka, Johor Bahru, Kuching.

---

## Request Query & Response Format

GTFS Realtime uses the standard **GTFS Realtime protobuf (.proto)** format.

Reference: [https://gtfs.org/realtime/proto/](https://gtfs.org/realtime/proto/)

---

## Vehicle Position Endpoint

```
GET https://api.data.gov.my/gtfs-realtime/vehicle-position/<agency>
```

### Notes on Validation Errors

Frequent GTFS errors like **E028** may occur due to temporary erroneous GPS data placing vehicles outside the expected service area.

---

## Frequency of Updates

All Vehicle Position feeds are updated **every 30 seconds**.

---

# Agency-Specific Endpoints

## KTMB

```
GET https://api.data.gov.my/gtfs-realtime/vehicle-position/ktmb
```

## Prasarana

```
GET https://api.data.gov.my/gtfs-realtime/vehicle-position/prasarana?category=<category>
```

### Valid `category` values:

* rapid-bus-kl
* rapid-bus-mrtfeeder
* rapid-bus-kuantan
* rapid-bus-penang

> *rapid-rail-kl currently has no stable realtime feed*

### Known Issues (rapid-bus-kuantan & rapid-bus-penang)

* **E003** — Trip ID not found in static data
* **E004** — Route ID not found in static data

Caused by legacy operational systems unable to track routes/trips properly.

### Special Case: rapid-bus-penang Trip ID Matching

Realtime Trip ID example:
`30000001_1000000855_053000_02`

Corresponds to static trip IDs such as:

* `weekend_30000001_1000000855_053000_02`
* `weekday_30000001_1000000855_053000_02`
* `23102302_30000001_1000000855_053000_02`

---

## BAS.MY Endpoints

### Kangar

```
GET https://api.data.gov.my/gtfs-realtime/vehicle-position/mybas-kangar
```

### Alor Setar

```
GET https://api.data.gov.my/gtfs-realtime/vehicle-position/mybas-alor-setar
```

### Kota Bharu

```
GET https://api.data.gov.my/gtfs-realtime/vehicle-position/mybas-kota-bharu
```

### Kuala Terengganu

```
GET https://api.data.gov.my/gtfs-realtime/vehicle-position/mybas-kuala-terengganu
```

### Ipoh

```
GET https://api.data.gov.my/gtfs-realtime/vehicle-position/mybas-ipoh
```

### Seremban

(2 operators → 2 endpoints)

```
GET https://api.data.gov.my/gtfs-realtime/vehicle-position/mybas-seremban-a
GET https://api.data.gov.my/gtfs-realtime/vehicle-position/mybas-seremban-b
```

### Melaka

```
GET https://api.data.gov.my/gtfs-realtime/vehicle-position/mybas-melaka
```

### Johor Bahru

```
GET https://api.data.gov.my/gtfs-realtime/vehicle-position/mybas-johor
```

### Kuching

```
GET https://api.data.gov.my/gtfs-realtime/vehicle-position/mybas-kuching
```

---

# Understanding the Data

Use official language bindings:
[https://gtfs.org/realtime/language-bindings/](https://gtfs.org/realtime/language-bindings/)

### Example: Python Code to Parse RapidKL Bus Feed

```python
# pip install gtfs-realtime-bindings pandas requests

from google.transit import gtfs_realtime_pb2
from google.protobuf.json_format import MessageToDict
import pandas as pd
from requests import get

URL = 'https://api.data.gov.my/gtfs-realtime/vehicle-position/prasarana?category=rapid-bus-kl'

feed = gtfs_realtime_pb2.FeedMessage()
response = get(URL)
feed.ParseFromString(response.content)

vehicle_positions = [MessageToDict(entity.vehicle) for entity in feed.entity]

print(f'Total vehicles: {len(vehicle_positions)}')
df = pd.json_normalize(vehicle_positions)
print(df)
```

---

*Last updated on December 5, 2025.*
