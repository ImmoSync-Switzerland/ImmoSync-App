// Temporary manual restoration of firebase_options.dart after flutterfire RangeError left the file empty.
// Regenerate with `flutterfire configure` once the CLI issue is resolved to populate all platforms.
// Project: realvetic  (project_number: 26290219883)
// NOTE: Values for non-Android platforms are placeholders and must be replaced by running flutterfire.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux; // placeholder
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCy3ENvdGGtH7ZzNmGy46Ddkbvr9q_ipHE',
    appId: '1:26290219883:android:7da05a9075643b402efa2e',
    messagingSenderId: '26290219883',
    projectId: 'realvetic',
    storageBucket: 'realvetic.firebasestorage.app',
  );

  // ANDROID (from google-services.json)

  // WEB (placeholder – run flutterfire configure to populate correctly)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WEB_API_KEY',
    appId: 'REPLACE_WEB_APP_ID',
    messagingSenderId: '26290219883',
    projectId: 'realvetic',
    storageBucket: 'realvetic.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBRdLyzc1Um9gcnc5XydvI51Pn5C1SqsTA',
    appId: '1:26290219883:ios:95cf589439f22bc92efa2e',
    messagingSenderId: '26290219883',
    projectId: 'realvetic',
    storageBucket: 'realvetic.firebasestorage.app',
    iosBundleId: 'com.example.immolink',
  );

  // IOS (placeholder)

  // MACOS (placeholder)
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REPLACE_MACOS_API_KEY',
    appId: 'REPLACE_MACOS_APP_ID',
    messagingSenderId: '26290219883',
    projectId: 'realvetic',
    storageBucket: 'realvetic.firebasestorage.app',
    iosBundleId: 'com.example.immolink',
  );

  // WINDOWS (placeholder)
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'REPLACE_WINDOWS_API_KEY',
    appId: 'REPLACE_WINDOWS_APP_ID',
    messagingSenderId: '26290219883',
    projectId: 'realvetic',
    storageBucket: 'realvetic.firebasestorage.app',
  );

  // LINUX (placeholder)
  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'REPLACE_LINUX_API_KEY',
    appId: 'REPLACE_LINUX_APP_ID',
    messagingSenderId: '26290219883',
    projectId: 'realvetic',
    storageBucket: 'realvetic.firebasestorage.app',
  );
}
