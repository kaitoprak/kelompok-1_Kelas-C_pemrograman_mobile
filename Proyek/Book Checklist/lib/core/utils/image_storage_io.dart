import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> persistCover(
  Uint8List bytes,
  String filename, {
  String mimeType = 'image/jpeg',
}) async {
  final directory = await getApplicationDocumentsDirectory();
  final covers = Directory(p.join(directory.path, 'covers'));
  await covers.create(recursive: true);
  final destination = File(p.join(covers.path, filename));
  await destination.writeAsBytes(bytes, flush: true);
  return destination.path;
}
