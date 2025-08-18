// Platform-aware wrapper that exports real `dart:html`-like APIs on web
// and a stub on other platforms.

export 'web_wrapper_stub.dart'
    if (dart.library.html) 'dart:html';
