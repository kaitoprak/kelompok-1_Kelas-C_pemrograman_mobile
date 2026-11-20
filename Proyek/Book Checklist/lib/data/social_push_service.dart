import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class SocialPushService {
  SocialPushService(this._messaging, this._firestore);

  static const _webVapidKey = String.fromEnvironment('FIREBASE_VAPID_KEY');

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  StreamSubscription<String>? _tokenSubscription;

  Future<void> enableForUser(String uid) async {
    if (kIsWeb && _webVapidKey.isEmpty) {
      throw StateError(
        'Web push requires FIREBASE_VAPID_KEY from Firebase project settings.',
      );
    }

    final settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      throw StateError('Notification permission was denied.');
    }
    // The Admin SDK's multicast sender needs the FCM token, not the new FID.
    // ignore: deprecated_member_use
    final token = await _messaging.getToken(
      vapidKey: kIsWeb ? _webVapidKey : null,
      serviceWorkerScriptPath: kIsWeb ? 'firebase-messaging-sw.js' : null,
    );
    if (token == null || token.isEmpty) {
      throw StateError('Firebase Messaging did not return a device token.');
    }
    await _saveToken(uid, token);

    // ignore: deprecated_member_use
    _tokenSubscription ??= _messaging.onTokenRefresh.listen((
      updatedToken,
    ) async {
      try {
        await _saveToken(uid, updatedToken);
      } catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'social push registration',
            context: ErrorDescription('while saving a refreshed FCM token'),
          ),
        );
      }
    });
  }

  Future<void> disableForUser(String uid) async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    if (kIsWeb && _webVapidKey.isEmpty) return;
    final tokenCollection = _tokenCollection(uid);
    // Read the current app instance's token so signing out here does not
    // disable notifications on the user's other devices.
    // ignore: deprecated_member_use
    final token = await _messaging.getToken(
      vapidKey: kIsWeb ? _webVapidKey : null,
      serviceWorkerScriptPath: kIsWeb ? 'firebase-messaging-sw.js' : null,
    );
    if (token != null && token.isNotEmpty) {
      final tokens = await tokenCollection
          .where('token', isEqualTo: token)
          .get();
      if (tokens.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final token in tokens.docs) {
          batch.delete(token.reference);
        }
        await batch.commit();
      }
      await _messaging.unregister();
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    final tokenCollection = _tokenCollection(uid);
    final existing = await tokenCollection
        .where('token', isEqualTo: token)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;
    await tokenCollection.add({
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  CollectionReference<Map<String, dynamic>> _tokenCollection(String uid) =>
      _firestore.collection('users').doc(uid).collection('fcm_tokens');
}
