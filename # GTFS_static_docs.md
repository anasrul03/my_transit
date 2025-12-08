# GTFS Static — Malaysia's Official Open API

## GTFS Static API Endpoint

```
GET https://api.data.gov.my/gtfs-static/<agency>
```

---

## What Does GTFS Static Do?

The GTFS Static API provides access to standardized **public transportation schedules** and **geographical information**, following the General Transit Feed Specification (GTFS).

More info: [https://developers.google.com/transit/gtfs](https://developers.google.com/transit/gtfs)

---

## Source of GTFS Static Data

Static feeds are provided by major Malaysian public transport operators:

### • [KTMB](https://www.ktmb.com.my/)

National railway operator.

### • [Prasarana](https://myrapid.com.my/)

Manages LRT, MRT, Monorail, Rapid Bus services.

### • [BAS.MY](https://bas.my/)

Stage bus services across multiple states:
Kangar, Alor Setar, Kota Bharu, Kuala Terengganu, Ipoh, Seremban, Melaka, Johor Bahru, Kuching.

---

## Frequency of Data Update

* **KTMB**: Daily at **00:01:00**
* **Prasarana**: As required
* **BAS.MY**: As required

**Recommended:** Refresh static data daily at **4:00 AM**, before nationwide service begins.

---

## Request Query & Response Format

GTFS Static data is delivered as a **ZIP file** containing GTFS text files.

---

# Agency-Specific Endpoints

## KTMB

```
GET https://api.data.gov.my/gtfs-static/ktmb
```

## Prasarana

```
GET https://api.data.gov.my/gtfs-static/prasarana?category=<category>
```

### Valid `category` values:

* rapid-bus-penang
* rapid-bus-kuantan
* rapid-bus-mrtfeeder
* rapid-rail-kl
* rapid-bus-kl

### Note on rapid-bus-kl dataset:

~2% of trips were removed from `stop_times.txt` due to operational inconsistencies. Problematic trips list:
[https://openapi-malaysia-transport.s3.ap-southeast-1.amazonaws.com/prasarana/problematic_trips.csv](https://openapi-malaysia-transport.s3.ap-southeast-1.amazonaws.com/prasarana/problematic_trips.csv)

---

## BAS.MY Endpoints

### Kangar

```
GET https://api.data.gov.my/gtfs-static/mybas-kangar
```

### Alor Setar

```
GET https://api.data.gov.my/gtfs-static/mybas-alor-setar
```

### Kota Bharu

```
GET https://api.data.gov.my/gtfs-static/mybas-kota-bharu
```

### Kuala Terengganu

```
GET https://api.data.gov.my/gtfs-static/mybas-kuala-terengganu
```

### Ipoh

```
GET https://api.data.gov.my/gtfs-static/mybas-ipoh
```

### Seremban

(2 operators → query both for full coverage)

```
GET https://api.data.gov.my/gtfs-static/mybas-seremban-a
GET https://api.data.gov.my/gtfs-static/mybas-seremban-b
```

### Melaka

```
GET https://api.data.gov.my/gtfs-static/mybas-melaka
```

### Johor Bahru

```
GET https://api.data.gov.my/gtfs-static/mybas-johor
```

### Kuching

```
GET https://api.data.gov.my/gtfs-static/mybas-kuching
```

---

# Understanding the Data

When you extract the ZIP file, you will find the GTFS text files.

### Core GTFS Files

| GTFS File      | Description                                |
| -------------- | ------------------------------------------ |
| agency.txt     | Transit agency details                     |
| stops.txt      | Stop locations and metadata                |
| routes.txt     | Route definitions                          |
| trips.txt      | Trips associated with routes               |
| stop_times.txt | Scheduled stop-by-stop timings             |
| calendar.txt   | Service availability for days of operation |

Optional files may include:

* `frequencies.txt`
* `shapes.txt`
* Others depending on agency

Full GTFS Schedule Reference:
[https://gtfs.org/schedule/reference/](https://gtfs.org/schedule/reference/)

---

*Last updated on December 5, 2025.*
