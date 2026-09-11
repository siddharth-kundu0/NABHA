import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Generated for project: nabha-a073b (NABHA)
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
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB16sRBi4p8F1QLbXaGNoYyUPUhhcmNMLg',
    appId: '1:62012617182:web:54e446b17cbf19c32e2d4f',
    messagingSenderId: '62012617182',
    projectId: 'nabha-a073b',
    authDomain: 'nabha-a073b.firebaseapp.com',
    databaseURL: 'https://nabha-a073b-default-rtdb.firebaseio.com',
    storageBucket: 'nabha-a073b.firebasestorage.app',
    measurementId: 'G-ETC0100X4L',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB16sRBi4p8F1QLbXaGNoYyUPUhhcmNMLg',
    appId: '1:62012617182:web:54e446b17cbf19c32e2d4f',
    messagingSenderId: '62012617182',
    projectId: 'nabha-a073b',
    databaseURL: 'https://nabha-a073b-default-rtdb.firebaseio.com',
    storageBucket: 'nabha-a073b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB16sRBi4p8F1QLbXaGNoYyUPUhhcmNMLg',
    appId: '1:62012617182:web:54e446b17cbf19c32e2d4f',
    messagingSenderId: '62012617182',
    projectId: 'nabha-a073b',
    databaseURL: 'https://nabha-a073b-default-rtdb.firebaseio.com',
    storageBucket: 'nabha-a073b.firebasestorage.app',
    iosBundleId: 'com.example.ruralcare',
  );
}
