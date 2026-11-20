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

Deploy the Firestore rules and indexes before using the app. Personal shelves
remain restricted to their owner at `users/{uid}/media/{entryId}`. Community
profiles never store email addresses; posts from private accounts are limited
to approved followers. Existing shelves in the old SQLite database are not
transferred automatically; export a backup before switching an existing
installation to Firebase.

With the Firebase CLI installed, first confirm the selected project is the
intended Firebase project. Deploy the rules and indexes:

```sh
firebase use <project-id>
firebase deploy --only firestore:rules,firestore:indexes
```

### Community and notifications

The Community tab supports text posts, media-linked posts, ratings, comments,
username search, public/private profiles, follow requests, and an in-app
notification inbox. A mutual means both accounts have an approved follow
relationship. Mutual followers are notified about shared posts, ratings, and
comments; users also receive follow, request, and comment notifications.

Cloud Functions create notifications and deliver push messages using FCM. They
are not deployed automatically. Functions deployment requires a Firebase
project with the Blaze billing plan enabled:

```sh
cd functions
npm install
npm run build
cd ..
firebase deploy --only functions
```

Push delivery is opt-in from the Notifications screen. For Android, enable
Firebase Cloud Messaging for the Firebase app and allow notification
permission. For iOS, configure an APNs authentication key in Firebase Console
and enable Push Notifications for the Runner target in Xcode.

For Chrome, configure the web push certificate in Firebase Console under
**Project settings > Cloud Messaging > Web Push certificates**. Copy the
Firebase web app's public configuration into
[`web/firebase-messaging-config.js`](web/firebase-messaging-config.js), then
provide its VAPID public key when running the app:

```sh
flutter run -d chrome --web-port 8080 --dart-define=FIREBASE_API_KEY=<api-key> --dart-define=FIREBASE_PROJECT_ID=<project-id> --dart-define=FIREBASE_MESSAGING_SENDER_ID=<sender-id> --dart-define=FIREBASE_WEB_APP_ID=<web-app-id> --dart-define=FIREBASE_VAPID_KEY=<vapid-public-key>
```

The web app must be served from HTTPS or localhost for browser notifications.
The API key, app ID, project ID, sender ID, and VAPID public key are public
client configuration; never put service-account credentials in the app or web
worker. Push delivery also depends on deploying the Functions after enabling
the required Firebase billing plan.

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
- Community feed with public/private profiles, follow approvals, media posts,
  ratings, comments, and in-app/push notifications

## Structure

- `lib/domain` — media types, statuses, and social models
- `lib/data` — Firebase authentication, Firestore repositories, and catalog service
- `lib/providers` — Riverpod state and preferences
- `lib/core` — theme tokens and shared widgets
- `lib/features` — dashboard, libraries, community, notifications, and item flows
- `functions` — trusted notification creation and FCM delivery triggers

Run `flutter analyze` and `flutter test` to check the project.
