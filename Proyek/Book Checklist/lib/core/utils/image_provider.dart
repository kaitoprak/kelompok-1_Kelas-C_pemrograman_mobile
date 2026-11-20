export 'image_provider_stub.dart'
    if (dart.library.io) 'image_provider_io.dart'
    if (dart.library.js_interop) 'image_provider_web.dart';
