# MyMedBuddy

A Flutter app for medication management, health logging, and compliance tracking.

---

## **Features Implemented**

- **User Onboarding:**  
  - Collects user details (name, age, condition, medication reminders) and stores them with SharedPreferences.
  - Skips onboarding on relaunch if data exists.

- **Multi-Screen Navigation:**  
  - Home, Medication Schedule, Health Logs, Appointments, Profile.
  - Uses both named routes (for Profile) and `Navigator.push` (for others).

- **UI Design & Layouts:**  
  - Responsive dashboard with cards for:  
    - Next Medication (shows next untaken dose for today)
    - Missed Doses (for today)
    - Medication Compliance Streaks
    - Weekly Appointments
  - Uses ListView, Card, Column, Row, etc.

- **State Management:**  
  - App-wide state with Provider (`AppState` in `/providers`).
  - Riverpod used for async health tip fetching (`health_tip_provider` in `/providers`).

- **Async Programming + API:**  
  - Fetches real-time health tips/medication info from a public API.
  - Shows loading spinner and error message as needed.

- **Shared Preferences:**  
  - Persists user preferences (dark mode, reminders, daily log reminder settings).
  - Persists medication taken state and compliance streaks.

- **Health Logs:**  
  - Users can add, view, and delete free-form health logs.
  - Export health logs as PDF.

- **Dark Mode:**  
  - Toggle in Profile, persists preference.

---

## **Project Structure**

```
lib/
  main.dart                # App entry point
  /screens                 # All main screens (Home, Schedule, Logs, Appointments, Profile, Onboarding)
  /providers               # AppState (Provider) and health_tip_provider (Riverpod)
  /services                # (Ready for API/persistence helpers)
  /widgets                 # (Ready for custom widgets)
```

---

## **Packages Used**

- `provider` (app-wide state)
- `flutter_riverpod` (health tip provider)
- `shared_preferences` (persistent storage)
- `pdf`, `path_provider`, `share_plus` (PDF export)
- `intl` (date/time formatting)

---

## **How to Run**

1. Install Flutter and dependencies:
   ```sh
   flutter pub get
   ```
2. Run the app:
   ```sh
   flutter run
   ```

---

## **Notes**

- All notification code has been removed for stability.
- No custom widgets or service helpers are present, but folders are ready for future use.


---

## **GitHub**

[https://github.com/oforias/MyMedBuddy](https://github.com/oforias/MyMedBuddy)
