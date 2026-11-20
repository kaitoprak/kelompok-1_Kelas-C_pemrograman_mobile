export 'image_storage_stub.dart'
    if (dart.library.io) 'image_storage_io.dart'
    if (dart.library.js_interop) 'image_storage_web.dart';
