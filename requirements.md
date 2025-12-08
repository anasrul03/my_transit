# 📱 **MyJejak – Enhanced Flutter Development Prompt (Android-first)**

### **Tech Stack: Flutter • Dart • Riverpod • GoRouter • Supabase • Mapbox**

---

## 🚀 **Objective**

Build **MyJejak**, a high-performance Flutter Android app with:

* **Main theme:** Dark mode
* **Primary color:** **Telemagenta (#CF3476)**
* **Navigation:** `GoRouter`
* **State management:** `Riverpod`
* **Architecture:** Clean Architecture + SOLID + DRY
* **Testing:** 100% Unit test coverage for core logic + widget tests for UI
* **Mapping:** Mapbox
* **GTFS realtime + static integration**
* **Supabase authentication**
* **Fast development, minimal bugs**

---

## 🛰 **GTFS APIs**

* **GTFS Realtime:**
  [https://developer.data.gov.my/realtime-api/gtfs-realtime](https://developer.data.gov.my/realtime-api/gtfs-realtime)
* **GTFS Static:**
  [https://developer.data.gov.my/realtime-api/gtfs-static](https://developer.data.gov.my/realtime-api/gtfs-static)

Use static GTFS shapes to **interpolate vehicle positions every 0.1s**, while realtime API refreshes every **30 seconds**.

---

## 🎨 **App Requirements**

### ▶️ **Theme**

* Implement global dark theme with telemagenta accent.
* Ensure consistent typography, spacing, and components using custom theme extension.

---

## 🗺 **Main Layout**

The app contains:

* **Top navbar** with 4 tabs:

  1. Routes
  2. Favourites
  3. Schedules
  4. Suggestions
* Tapping a tab opens a **sidebar drawer** containing relevant functions.
* **Main screen:** Mapbox map displaying realtime vehicles.
* **Left sidebar (persistent)**:

  * Filters
  * “Turn on my location” toggle
  * Search bar (vehicle name or ID)
  * Operator filter

    * Default: **MRT Feeder**
    * No multi-select allowed
* Clicking a vehicle opens a **bottom-right popup** showing:

  * Current vehicle ID
  * Route name
  * Speed
  * Next destination (from GTFS static stop_times.txt)
  * If user location active → compute distance & ETA using interpolation
  * Highlight its full route using GTFS static shapes
  * Button: **View Schedule** → opens “Schedules” tab
  * Button: **Favourite** (only for logged-in users)

---

## 🚍 **GTFS Realtime Behaviour**

* Pull realtime feed every **30 seconds** from API.
* Use GTFS static shapes to **interpolate the vehicle position at 0.1 second intervals**:

  * Move smoothly along polyline
  * Update direction & speed based on realtime `speed` field
* Use Riverpod state providers for:

  * Realtime vehicle store
  * Static shapes store
  * Map filters
  * User session
* Follow SRP: Keep GTFS parsing logic in separate repository layer.

---

## 🗂 **Tabs Breakdown**

### **1. Routes Tab**

* User inputs **Start** and **End** search fields.
* Search uses **GTFS static stops** (stop names).
* Show:

  * Transit routes (GTFS)
  * Driving
  * Biking
  * Walking
* Use **Google Maps Routes API (free tier)** for multimodal options.
* Clicking a transport on the map shows:

  * Route details
  * Full schedule button
  * Add to favourites

---

### **2. Favourites Tab** *(only for logged-in users)*

* Store favourite vehicles & routes in Supabase table
* Display:

  * Vehicle number / route
  * Current status
  * Next arrival
* Clicking an item focuses the map on the vehicle.

---

### **3. Schedules Tab**

* Fetch schedules using GTFS static:

  * trips.txt
  * stop_times.txt
* User can search bus/train name and view:

  * Full daily schedule
  * Upcoming times
  * Operator info
* “View Schedule” from vehicle popup deep-links here via GoRouter.

---

### **4. Suggestions Tab**

* Allow users to submit route suggestions or UX feedback.
* Store suggestions in Supabase.

---

## 🔎 **Left Sidebar Search**

* Search by vehicle name / ID
* Clicking result:

  * Focus camera on map
  * Open vehicle popup

Use debounced search provider in Riverpod.

---

## 🔐 **Authentication (Supabase)**

* On app open → show login/signup screen.
* Provide “Continue as Guest”.

**Guest mode restrictions:**

* No favourites tab
* No storing of recent searches
* Limited suggestions feature

**Logged-in mode:**

* Persist favourites
* Persist recent searches
* Store user profile
* All interactions tied to Supabase user ID

Use Supabase Row Level Security (RLS).

---

## 🧱 **Architecture Requirements**

Use **Clean Architecture** separated into:

1. `domain/`

   * entities
   * repositories (abstract interfaces)
   * usecases
2. `data/`

   * API services (GTFS, Supabase)
   * DTOs
   * Repository implementations
3. `presentation/`

   * Flutter UI
   * Riverpod providers
   * Views + Controllers
4. `router/`

   * GoRouter routes
   * Deep linking for schedule screens

### **SOLID Principles Mandatory**

* Single Responsibility: Separate logic for realtime parsing, static parsing, mapping, and auth.
* Open/Closed: Providers should be extendable without modification.
* Interface Segregation: Repositories must be minimal & feature-specific.
* Dependency Inversion: Upper layers depend only on abstractions.

### **DRY Principle Mandatory**

* Reuse shapes parsing, debouncing logic, and UI components.
* Shared widgets for cards, map popups, lists.

---

## 🧪 **Testing Requirements**

Include test coverage for:

* GTFS realtime parser (unit test)
* Static shape interpolation (unit test)
* Route selection search (unit test)
* Supabase auth repository mock tests
* Vehicle popup data formatting tests
* Riverpod providers → unit tests
* Widget tests for:

  * Map view
  * Sidebar filters
  * Vehicle popup
  * Schedule list

Use `mocktail` and dependency injection.

---

## ⚙️ **Performance Requirements**

* Smooth map animation (60 FPS)
* Vehicle interpolation should not block UI thread
* Use isolates for heavy parsing
* Cache static GTFS files locally
* Efficient Riverpod state updates:

  * Avoid rebuilding whole map
  * Use granular state providers
* Realtime updates should be diff-patched, not replaced.

---

## 🗺 **Mapbox Integration Requirements**

* Dark map style
* Custom vehicle markers for type & operator
* Polyline rendering for shapes
* Animate camera during search
* Popup UI with schedule & favourite button
* Operator filtering logic in map layer level (not UI rebuild)

---

## 📡 **Networking Requirements**

* Realtime API pull every 30s
* Static GTFS download on first launch or app update
* Cache using `flutter_cache_manager`
* Handle offline mode gracefully

---

## 🔔 **Notifications (Optional Enhancement)**

* User can receive alerts when favourite bus is approaching user's location.
* Use background fetch + Supabase Realtime or scheduled polling.

---

## 🏁 **Final Deliverables**

* Full Flutter project (Android)
* Clean Architecture directory structure
* Mapbox integrated screens
* GTFS realtime + static implemented
* Supabase auth integrated
* Unit tests + widget tests
* Dark telemagenta theme
* Fully functional tabs & features
* CI pipeline for tests
* Production-ready release build
