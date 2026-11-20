# MyShelf

MyShelf is a Flutter app for tracking books, movies, and TV series. Accounts use
Firebase Authentication, and each user's shelf is stored in their own Firestore
subcollection.

## Run

Use Flutter 3.47 or newer. Create a Firebase project, enable the Email/Password
sign-in provider and Firestore, then provide the Firebase web app's API key,
project ID, and sender ID together with the app ID for the platform you run:

```sh
flutter pub get
flutter run --dart-define=FIREBASE_API_KEY=<api-key> --dart-define=FIREBASE_PROJECT_ID=<project-id> --dart-define=FIREBASE_MESSAGING_SENDER_ID=<sender-id> --dart-define=FIREBASE_ANDROID_APP_ID=<android-app-id>
```

For iOS, use `FIREBASE_IOS_APP_ID`; for web, use `FIREBASE_WEB_APP_ID` and
optionally `FIREBASE_AUTH_DOMAIN`. The Firebase API key and app IDs are public
client configuration, not service-account credentials. Do not put service
account keys in the app.

Deploy [firestore.rules](firestore.rules) to the Firebase project before using
the app. Rules restrict each user's records to their authenticated UID at
`users/{uid}/media/{entryId}`. The app also requires authentication before
showing any shelf routes. Firestore is the source of truth for library items;
selected cover photos remain local to the device. Existing shelves in the old
SQLite database are not transferred automatically; export a backup before
switching an existing installation to Firebase.

With the Firebase CLI installed and linked to your project, deploy the rules:

```sh
firebase deploy --only firestore:rules
```

To run in Chrome, supply the web app ID and use a consistent local port:

```sh
flutter run -d chrome --web-port 8080 --dart-define=FIREBASE_API_KEY=<api-key> --dart-define=FIREBASE_PROJECT_ID=<project-id> --dart-define=FIREBASE_MESSAGING_SENDER_ID=<sender-id> --dart-define=FIREBASE_WEB_APP_ID=<web-app-id>
```

Firebase Authentication supports account creation, sign-in, password reset,
and sign-out. Shelf data is isolated by authenticated account.

## Features

- Home dashboard with activity counts, in-progress items, and recent additions/completions
- Create, edit, search, filter, sort, rate with stars, and delete books, movies,
  and series
- Get live title suggestions while typing and fill available metadata from
  Open Library, Wikipedia, and TVmaze (requires an internet connection)
- Page and episode progress tracking with completion dates
- Optimistic saves that update the shelf immediately and roll back if Firestore
  rejects a write
- Dark, light, and system appearance preferences
- JSON backup shared through the platform share sheet
- Firebase email/password authentication and per-account Firestore authorization

## Structure

- `lib/domain` — media types, statuses, and entry model
- `lib/data` — Firebase authentication, Firestore repository, and catalog service
- `lib/providers` — Riverpod state and preferences
- `lib/core` — theme tokens and shared widgets
- `lib/features` — dashboard, libraries, search, profile, and item flows

Run `flutter analyze` and `flutter test` to check the project.
