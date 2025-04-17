// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAdvjNjTBfZuebajMBaifmHLOpyOQ14YD0',
    appId: '1:295040825125:web:dc2992059ccfe8509acccc',
    messagingSenderId: '295040825125',
    projectId: 'fingerprintmis',
    authDomain: 'fingerprintmis.firebaseapp.com',
    storageBucket: 'fingerprintmis.firebasestorage.app',
    measurementId: 'G-TQ3ZNE6JZY',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBeITakbC9807lTM9jwWpYeN4MXigFcd8Y',
    appId: '1:295040825125:android:4c54f0ecb19161979acccc',
    messagingSenderId: '295040825125',
    projectId: 'fingerprintmis',
    storageBucket: 'fingerprintmis.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAzre787e5Hlddya3zpZuyz6uk4ouT4ShI',
    appId: '1:295040825125:ios:f5a64dd590c93c319acccc',
    messagingSenderId: '295040825125',
    projectId: 'fingerprintmis',
    storageBucket: 'fingerprintmis.firebasestorage.app',
    iosBundleId: 'com.example.fingerPrintMis',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAzre787e5Hlddya3zpZuyz6uk4ouT4ShI',
    appId: '1:295040825125:ios:f5a64dd590c93c319acccc',
    messagingSenderId: '295040825125',
    projectId: 'fingerprintmis',
    storageBucket: 'fingerprintmis.firebasestorage.app',
    iosBundleId: 'com.example.fingerPrintMis',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAdvjNjTBfZuebajMBaifmHLOpyOQ14YD0',
    appId: '1:295040825125:web:9041242ce2b26dd29acccc',
    messagingSenderId: '295040825125',
    projectId: 'fingerprintmis',
    authDomain: 'fingerprintmis.firebaseapp.com',
    storageBucket: 'fingerprintmis.firebasestorage.app',
    measurementId: 'G-R6YVX7W29C',
  );
}
