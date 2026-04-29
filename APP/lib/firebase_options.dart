import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'FirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_WEB_API_KEY',
      defaultValue: 'TODO_FIREBASE_WEB_API_KEY',
    ),
    appId: String.fromEnvironment(
      'FIREBASE_WEB_APP_ID',
      defaultValue: 'TODO_FIREBASE_WEB_APP_ID',
    ),
    messagingSenderId: '354206024941',
    projectId: 'alcoholimetro',
    authDomain: 'alcoholimetro.firebaseapp.com',
    storageBucket: 'alcoholimetro.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_ANDROID_API_KEY',
      defaultValue: 'TODO_FIREBASE_ANDROID_API_KEY',
    ),
    appId: String.fromEnvironment(
      'FIREBASE_ANDROID_APP_ID',
      defaultValue: 'TODO_FIREBASE_ANDROID_APP_ID',
    ),
    messagingSenderId: '354206024941',
    projectId: 'alcoholimetro',
    storageBucket: 'alcoholimetro.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_IOS_API_KEY',
      defaultValue: 'TODO_FIREBASE_IOS_API_KEY',
    ),
    appId: String.fromEnvironment(
      'FIREBASE_IOS_APP_ID',
      defaultValue: 'TODO_FIREBASE_IOS_APP_ID',
    ),
    messagingSenderId: '354206024941',
    projectId: 'alcoholimetro',
    storageBucket: 'alcoholimetro.appspot.com',
    iosBundleId: 'com.alcoholimetro.app', // TODO verify iOS bundle id
  );
}
