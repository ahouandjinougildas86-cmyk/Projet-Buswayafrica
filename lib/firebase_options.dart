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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAVUrrUD0jve04s_WtxdSZoP0No5chkAJg',
    authDomain: 'busway-africa.firebaseapp.com',
    projectId: 'busway-africa',
    storageBucket: 'busway-africa.firebasestorage.app',
    messagingSenderId: '755401705537',
    appId: '1:755401705537:web:9d2753acaa6bad334a5ec0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAVUrrUD0jve04s_WtxdSZoP0No5chkAJg',
    authDomain: 'busway-africa.firebaseapp.com',
    projectId: 'busway-africa',
    storageBucket: 'busway-africa.firebasestorage.app',
    messagingSenderId: '755401705537',
    appId: '1:755401705537:android:9d83371cf37ae4a64a5ec0',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAVUrrUD0jve04s_WtxdSZoP0No5chkAJg',
    authDomain: 'busway-africa.firebaseapp.com',
    projectId: 'busway-africa',
    storageBucket: 'busway-africa.firebasestorage.app',
    messagingSenderId: '755401705537',
    appId: '1:755401705537:ios:6d4482b3e5474f3b4a5ec0',
  );
}
