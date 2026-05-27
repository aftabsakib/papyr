# BedBreaker

> An alarm clock that only stops when you get up and go somewhere.

Set a mission — walk 500m from home, or travel to a pinned location. When you arrive, take a photo. That's the only way to stop it.

No snooze. No excuses. Break the bed.

---

## How it works

1. **Set an alarm** — pick a time and a mission (distance from home, or a map pin)
2. **Alarm fires** — fullscreen ring, no snooze button
3. **Start mission** — walk to your target location
4. **Take a photo** — camera unlocks when GPS confirms you're there
5. **Alarm dismissed** — your streak goes up

Force-dismiss is always available, but every time you do it gets logged as a cheat.

---

## Features

- GPS-verified alarm dismissal
- Two mission types: distance from home or map-pinned target
- Photo proof required at destination
- Cheat counter — bypasses are logged, not blocked
- Streak tracking + completion rate
- 100% free — no backend, no accounts, no API keys

---

## Tech Stack

| What | How |
|---|---|
| Framework | Flutter (Android + iOS) |
| Maps | OpenStreetMap via flutter_map |
| GPS | geolocator |
| Local storage | Hive |
| Font | Space Grotesk (Google Fonts) |
| UI design | Material 3 dark mode |

---

## Build & Run

```bash
git clone https://github.com/aftabsakib/bedbreaker
cd bedbreaker
flutter pub get
flutter run
```

No API keys needed. No accounts. Just clone and run.

Requires: Flutter 3.x, Android SDK, JDK 17+

---

## Contributing

Issues and PRs are welcome. Open an issue first for larger changes.

---

## License

MIT — see [LICENSE](LICENSE)
