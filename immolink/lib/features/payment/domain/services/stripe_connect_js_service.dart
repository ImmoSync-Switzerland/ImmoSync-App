// Conditional export: re-export platform-specific implementation
export 'stripe_connect_js_service_stub.dart'
    if (dart.library.js_interop) 'stripe_connect_js_service_web.dart';
