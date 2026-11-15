# MyShelf

MyShelf is an offline-first Flutter app for tracking books, movies, and TV series.

## Run

Use Flutter 3.47 or newer, then run on a connected device:

```sh
flutter pub get
flutter run
```

The project targets Android and iOS. SQLite keeps library items on-device. Remote cover URLs are optional; local photos can be selected from the device.

To run in Chrome, use a consistent local port so browser storage stays on the same origin:

```sh
flutter run -d chrome --web-port 8080
```

The web build stores its SQLite database in browser IndexedDB. Local cover photos are saved as data URLs in that database.

## Features

- Home dashboard with activity counts, in-progress items, and recent additions/completions
- Create, edit, search, filter, sort, rate, and delete books, movies, and series
- Page and episode progress tracking with completion dates
- Dark, light, and system appearance preferences
- JSON backup shared through the platform share sheet

## Structure

- `lib/domain` — media types, statuses, and entry model
- `lib/data` — SQLite database and repository
- `lib/providers` — Riverpod state and preferences
- `lib/core` — theme tokens and shared widgets
- `lib/features` — dashboard, libraries, search, profile, and item flows

Run `flutter analyze` and `flutter test` to check the project.
