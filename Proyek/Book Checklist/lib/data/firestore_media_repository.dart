import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/media_entry.dart';

class FirestoreMediaRepository {
  FirestoreMediaRepository(this._firestore, this._firebaseAuth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  CollectionReference<Map<String, dynamic>> _entriesForCurrentUser() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('Sign in before accessing your shelf.');
    }
    return _firestore.collection('users').doc(user.uid).collection('media');
  }

  Future<List<MediaEntry>> getAll() async {
    final snapshot = await _entriesForCurrentUser()
        .orderBy('updated_at', descending: true)
        .get();
    return snapshot.docs
        .map((document) => _fromDocument(document.id, document.data()))
        .toList(growable: false);
  }

  Future<MediaEntry?> getById(String id) async {
    final document = await _entriesForCurrentUser().doc(id).get();
    final data = document.data();
    return data == null ? null : _fromDocument(document.id, data);
  }

  Future<MediaEntry> save(MediaEntry entry) async {
    final collection = _entriesForCurrentUser();
    final document = entry.id == null
        ? collection.doc()
        : collection.doc(entry.id);
    final data = entry.toMap()..remove('id');
    await document.set(data);
    return entry.copyWith(id: document.id);
  }

  Future<void> delete(String id) async {
    await _entriesForCurrentUser().doc(id).delete();
  }

  MediaEntry _fromDocument(String id, Map<String, dynamic> data) {
    return MediaEntry.fromMap({
      ...data,
      'id': id,
      'started_at': _milliseconds(data['started_at']),
      'completed_at': _milliseconds(data['completed_at']),
      'created_at': _milliseconds(data['created_at']),
      'updated_at': _milliseconds(data['updated_at']),
    });
  }

  int? _milliseconds(Object? value) => switch (value) {
    Timestamp timestamp => timestamp.millisecondsSinceEpoch,
    DateTime date => date.millisecondsSinceEpoch,
    int milliseconds => milliseconds,
    _ => null,
  };
}
