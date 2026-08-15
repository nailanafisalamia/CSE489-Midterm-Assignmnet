================================================================================
  SMART LANDMARKS
  CSE 489 - Midterm Submission
  Student ID: 24241291
================================================================================


PROJECT OVERVIEW
----------------
Smart Landmarks is an Android app written in Flutter. It gives users a way
to discover, visit, and contribute to a shared database of geo-tagged points
of interest. Everything is built around a live API with offline fallback, so
the app stays useful even when the device has no connection.

The visual design takes a warm, earthy approach: parchment backgrounds, burnt
orange as the primary accent, and forest green for confirmation states. The map
uses custom painted teardrop pins. Landmark cards animate in from the side.
The add-landmark flow is broken into a three-step wizard to keep the form
from feeling overwhelming.


FEATURES IMPLEMENTED
--------------------
1. Map View
   - OpenStreetMap tiles via flutter_map, no paid API key needed
   - Teardrop pins drawn with a CustomPainter, colored by score tier:
       Red    : below 10
       Orange : 10 to 25
       Yellow : 25 to 50
       Green  : 50 and above
   - Tapping a pin opens a bottom sheet with landmark info and a visit button
   - Score legend strip fixed at the bottom of the map

2. Landmarks Screen
   - Scrollable list with slide-in card animations
   - Horizontal chip row to sort by score (high/low) or alphabetically
   - Minimum score filter via a slider
   - Live search bar in the app bar
   - Swipe left to delete; undo restores via the API

3. Visit Flow
   - GPS coordinates captured fresh at the moment of each visit
   - POST to visit_landmark returns a job_id immediately, not the result
   - WorkManager picks up the job_id and polls get_job_status in background
   - Visit shows as "pending" in history until the job resolves
   - If the device is offline at visit time, the request is queued locally
     and retried automatically once connectivity is restored

4. Add Landmark Wizard
   - Step 1: Enter a title
   - Step 2: Set coordinates (type them in or tap the map)
   - Step 3: Attach a photo from the gallery or camera
   - Progress bar at the top tracks which step the user is on
   - Submit sends the data as multipart/form-data with the image attached

5. Trip Log (Activity Screen)
   - All visits grouped by date
   - Each entry shows landmark name, status, and distance once resolved
   - Screen polls the local database every 5 seconds while any visit is
     still pending, so the status updates without a manual refresh

6. Offline Support
   - Landmarks fetched from API are written to SQLite via sqflite
   - On subsequent opens with no connection, cached data loads from DB
   - Pending visits persist across app restarts in a separate queue table
   - WorkManager drains the queue and submits visits when online again


API USAGE
---------
Base URL : https://labs.anontech.info/cse489/exm3/api.php
API Key  : 24241291 (sent as query param ?key=24241291 on every call)

Endpoint reference:

  get_landmarks      GET   Returns the full list of active landmarks
  visit_landmark     POST  JSON body with landmark_id, user_lat, user_lon.
                           Response is {job_id, status} only; poll for result
  get_job_status     GET   Pass ?job_id=... to check visit result
  create_landmark    POST  Multipart form with title, lat, lon, optional image
  delete_landmark    POST  Form body with id= to soft-delete a landmark
  restore_landmark   POST  Form body with id= to un-delete a landmark

A few things that caused bugs and are worth documenting:

  create_landmark requires multipart/form-data, not JSON. The server reads
  the image from $_FILES, which is only populated for multipart requests.
  Sending JSON causes the file to be silently dropped.

  visit_landmark requires JSON (Content-Type: application/json). The server
  reads the body via php://input rather than $_POST, so URL-encoded form data
  will not work even if the field names are correct.

  The visit response only contains a job_id. The actual distance calculation
  happens server-side and must be fetched separately via get_job_status.

  Image values in the landmark list are relative paths. They need the server
  base URL prepended before they can be used as image sources.


ARCHITECTURE USED
-----------------
The project uses Clean Architecture divided into four layers:

  Data layer
    - ApiService handles all HTTP communication
    - DatabaseHelper manages the sqflite database
    - DAOs (LandmarkDao, VisitDao) handle all DB reads and writes
    - Model classes convert between JSON, DB maps, and domain entities
    - LandmarkRepositoryImpl is the single source of truth; it writes API
      results to the DB and always serves the UI from the DB

  Domain layer
    - Abstract repository interfaces define what operations exist
    - Use cases encapsulate business rules independently of Flutter

  Presentation layer
    - Screens: MapScreen, LandmarksScreen, ActivityScreen, AddLandmarkScreen
    - Providers: LandmarkProvider and VisitProvider (ChangeNotifier)
    - MultiProvider at the root supplies both providers to the whole tree

  Workers
    - BackgroundWorkerManager configures WorkManager on startup
    - One periodic task polls pending job_ids and updates the DB
    - One periodic task drains the offline visit queue when online

Directory layout:

  lib/
    core/           - AppConstants, AppTheme, AppColors, error types
    data/
      local/        - database_helper.dart, dao/
      remote/       - api_service.dart
      models/       - landmark_model, visit_history_model, pending_visit_model
      repositories/ - landmark_repository_impl.dart
    domain/
      entities/     - landmark.dart, visit_history.dart
      repositories/ - landmark_repository.dart (abstract)
      usecases/     - individual use case classes
    presentation/
      screens/      - map/, landmarks/, activity/, add/
      widgets/      - landmark_card.dart
      providers/    - landmark_provider.dart, visit_provider.dart
    workers/        - background_workers.dart
    main.dart


CHALLENGES FACED
----------------
1. Visit result does not come back immediately
   When a user logs a visit, the API only confirms receipt. The actual
   distance calculation runs server-side and can take time. I had to build
   a full polling pipeline: WorkManager triggers the poll, writes the result
   to SQLite, and the UI reads the DB on a timer to pick up the change.

2. Cross-isolate communication with WorkManager
   WorkManager runs in its own Dart isolate. It cannot call setState or touch
   any provider directly. The approach that worked was treating the database
   as the message bus: the worker writes, the UI polls. Simple but effective.

3. Content-Type mismatch took too long to debug
   The visit endpoint rejected requests even with the correct field names until
   I realized it was reading php://input rather than $_POST. Switching from
   URL-encoded form data to JSON fixed it. The opposite applies to the create
   endpoint where the image must go through multipart.

4. latlong2 exports a conflicting type
   The latlong2 package exports Path<LatLng> into the global namespace. Inside
   a CustomPainter, this collides with Flutter's canvas Path type. The fix is
   to add "hide Path" to the latlong2 import.

5. Keeping the landmark list fresh after creation
   The create_landmark API response does not include a complete landmark object.
   Trying to parse it directly caused format errors. The working approach was
   to build a placeholder model from the input values, save it locally, then
   immediately force-refresh the full list from the API.


================================================================================
