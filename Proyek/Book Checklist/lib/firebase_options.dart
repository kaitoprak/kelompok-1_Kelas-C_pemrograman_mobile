import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

abstract final class DefaultFirebaseOptions {
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
  );
  static const _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const _webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');

  static FirebaseOptions get currentPlatform {
    final appId = kIsWeb
        ? _webAppId
        : switch (defaultTargetPlatform) {
            TargetPlatform.android => _androidAppId,
            TargetPlatform.iOS => _iosAppId,
            _ => throw UnsupportedError(
              'Firebase is configured for Android, iOS, and web only.',
            ),
          };
    if (_apiKey.isEmpty ||
        _projectId.isEmpty ||
        _messagingSenderId.isEmpty ||
        appId.isEmpty) {
      throw StateError(
        'Firebase configuration is missing. Provide FIREBASE_API_KEY, '
        'FIREBASE_PROJECT_ID, FIREBASE_MESSAGING_SENDER_ID, and the '
        'FIREBASE_${kIsWeb ? 'WEB' : defaultTargetPlatform.name.toUpperCase()}_APP_ID '
        'dart-defines.',
      );
    }

    return FirebaseOptions(
      apiKey: _apiKey,
      appId: appId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      authDomain: kIsWeb && _authDomain.isNotEmpty ? _authDomain : null,
    );
  }
}
