import 'dart:convert';

import 'package:flutter/widgets.dart';

ImageProvider<Object>? localImageProvider(String source) {
  if (!source.startsWith('data:')) return null;
  final separator = source.indexOf(',');
  if (separator < 0) return null;
  try {
    return MemoryImage(base64Decode(source.substring(separator + 1)));
  } on FormatException {
    return null;
  }
}
