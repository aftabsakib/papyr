# Papyr

> A calm, paper-like reader for your PDF and EPUB library. 100% local.

Import your PDFs and ebooks, then read them on a page that feels like paper — warm cream, sepia, e-ink grey, or night. No accounts, no cloud, no tracking. Your books stay on your device.

---

## Features

- **Two formats** — PDF documents and reflowable EPUB ebooks
- **Paper themes** — Cream, Sepia, E-ink, and Night, switchable while reading
- **Reflowable reading** — adjustable font size, line spacing, and margins (EPUB)
- **Your library** — covers, reading progress, and resume-where-you-left-off
- **Bookmarks** and quick chapter/page navigation
- **100% local** — no backend, no accounts, no API keys

---

## Tech Stack

| What | How |
|---|---|
| Framework | Flutter (Android + iOS) |
| PDF rendering | pdfrx |
| EPUB reading | flutter_epub_viewer (reflowable, themeable) |
| EPUB metadata/covers | epubx |
| Importing books | file_picker |
| Local storage | Hive |
| Reading font | Source Serif 4 · Titles: Playfair Display · UI: Inter |

---

## Build & Run

```bash
git clone https://github.com/aftabsakib/papyr
cd papyr
flutter pub get
flutter run
```

No API keys. No accounts. Just clone and run.

Requires: Flutter 3.x, Android SDK, JDK 17+

---

## License

MIT — see [LICENSE](LICENSE)
