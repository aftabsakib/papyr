# BedBreaker — Design Document
**Date:** 2026-05-27  
**Status:** Approved

---

## What It Is

BedBreaker is a free, open source Flutter alarm clock that refuses to stop ringing until you physically travel to a GPS location and take a photo there. It forces you out of bed by making dismissal impossible from your bed.

---

## Platform

- Flutter (Android + iOS)
- Primary experience: Android (iOS has background execution limits — alarm fires via notification only, no foreground service)
- Distribution: Google Play Store + App Store + GitHub (open source, MIT license)
- Cost: $0 — no paid APIs, no backend, no cloud

---

## Screen Flow

| Screen | Purpose |
|---|---|
| Home | List of alarms, toggle on/off, streak + cheat count |
| Create Alarm | Set time, repeat days, label, mission type |
| Mission Setup | Distance from home (X meters) OR pin location on map |
| Ringing Screen | Fullscreen alarm — no snooze, shows mission instructions |
| Mission Active | Live GPS distance to target, camera unlocks when in range |
| Camera | Take photo to dismiss alarm |
| Stats | Streak, cheat history, completion rate |

---

## Core Logic

1. User creates alarm → sets time, repeat days, mission type
2. If "distance from home" → app saves current GPS as home at creation time
3. Alarm fires → fullscreen ringing screen, foreground service starts GPS tracking
4. App checks continuously: is user within target radius?
5. When in range → camera button unlocks
6. User takes photo → alarm dismissed, saved as "completed"
7. Force dismiss → logged as "cheat" with timestamp, penalty counter increments

### Edge Cases
- GPS unavailable (indoors, no signal) → show "waiting for GPS signal", keep ringing
- GPS accuracy > 50m → ignore reading, wait for better signal
- Minimum mission distance: 100 meters (prevent doorstep cheating)
- App killed by OS → foreground service restart via alarm manager

---

## Verification Method

**GPS + Photo (both required)**
- GPS confirms user is at the target location (within radius)
- Camera confirms physical presence (photo taken at that moment)
- No AI verification — photo is proof of action, not content-verified
- Photo saved to app's local storage (not camera roll, unless user opts in)

---

## Mission Types

1. **Distance from home** — set X meters, app saves home GPS at alarm creation. User must travel at least that far.
2. **Pinned location** — user drops a pin on map during alarm setup. Must physically reach that pin.

Map provider: OpenStreetMap via flutter_map (free, no API key).

---

## Bypass / Emergency Dismiss

- Force dismiss is always possible (no true lockout — respects user autonomy)
- Every force dismiss is logged: timestamp, which alarm, how early
- Stats screen shows total cheat count and cheat history
- No punishment beyond the log — accountability is social/personal

---

## Data Structure (Hive, local only)

**Alarm**
- id, label, time (HH:mm), repeatDays (List<bool> Mon–Sun)
- missionType: `distance` | `pin`
- homeLat, homeLng (saved at creation)
- targetLat, targetLng, radiusMeters
- isActive

**AlarmHistory**
- alarmId, firedAt (DateTime)
- status: `completed` | `cheated` | `missed`
- photoPath (nullable)
- secondsToComplete (nullable)

**Stats** (derived)
- currentStreak (consecutive completed days)
- totalCheats
- completionRate

---

## Tech Stack

| Need | Package | Cost |
|---|---|---|
| Alarm scheduling | flutter_local_notifications + android_alarm_manager_plus | Free |
| GPS tracking | geolocator | Free |
| Camera | camera | Free |
| Maps + pin | flutter_map + OpenStreetMap tiles | Free |
| Local database | hive + hive_flutter | Free |
| Foreground service | flutter_foreground_task | Free |
| Permissions | permission_handler | Free |

---

## UI Design Workflow

All screens designed in **Google Stitch** (free, 350 generations/month) before any Flutter UI code is written.
- Describe each screen in Stitch → export Flutter widget code → drop into `/widgets`
- Design system: Material 3, dark mode first, bold typography

---

## Permissions Required

| Permission | Why |
|---|---|
| Location (always on) | GPS tracking while alarm is active |
| Camera | Photo capture to dismiss alarm |
| Exact alarm (Android 12+) | Precise alarm firing |
| Notifications | Show alarm + foreground service notification |
| Battery optimization bypass | Keep foreground service alive |

Handled via onboarding flow on first launch.

---

## Folder Structure

```
bedbreaker/
├── lib/
│   ├── main.dart
│   ├── models/          # Alarm, AlarmHistory
│   ├── services/        # GPS, camera, alarm scheduler, foreground service
│   ├── screens/         # home, create_alarm, mission_setup, ringing, mission_active, camera, stats
│   ├── widgets/         # Stitch-exported UI components
│   └── storage/         # Hive adapters + DB logic
├── android/             # Foreground service + exact alarm config
├── ios/
├── docs/
│   └── plans/
├── LICENSE              # MIT
└── pubspec.yaml
```

---

## Open Source

- GitHub repository: public from day one
- License: MIT
- README includes: what it is, how to build, how to contribute
- No API keys in repo (none needed)

---

## Out of Scope (v1)

- User accounts / cloud sync
- Social features / leaderboard
- AI photo verification
- Google Places category search
- Subscription / monetization
