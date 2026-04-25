// ─────────────────────────────────────────────────────────────────────────────
// firebase_options.dart  —  AUTO-GENERATED
// Run `flutterfire configure` to regenerate with your real Firebase project.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ─── TODO: Replace placeholder values with your real Firebase config ───────
  // Run `flutterfire configure` in the project root:
  //   dart pub global activate flutterfire_cli
  //   flutterfire configure --project=your-firebase-project-id

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: '1:000000000000:web:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'your-project-id',
    authDomain: 'your-project-id.firebaseapp.com',
    storageBucket: 'your-project-id.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAR0ajuuR1KAY6Nn4kvkxKJ_KdbcZrIuKI',
    appId: '1:924919259462:android:a3b8add774d81b60d0c547',
    messagingSenderId: '924919259462',
    projectId: 'bahria-lost-found',
    storageBucket: 'bahria-lost-found.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'your-project-id',
    storageBucket: 'your-project-id.appspot.com',
    iosBundleId: 'pk.edu.bahria.lostfound',
  );
}
