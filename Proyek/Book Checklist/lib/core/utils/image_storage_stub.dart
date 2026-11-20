import 'dart:convert';
import 'dart:typed_data';

Future<String> persistCover(
  Uint8List bytes,
  String filename, {
  String mimeType = 'image/jpeg',
}) async => 'data:$mimeType;base64,${base64Encode(bytes)}';
