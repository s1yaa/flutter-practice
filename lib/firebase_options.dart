import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
    
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDDujOxnQFcVIrKnsZQsjSnLvrdcrDqCo4',
    appId: '1:1066202951525:android:52fcf90f5cc7e4211a7b8c',
    messagingSenderId: '1066202951525',
    projectId: 'mentorshipapp-7cffc',
    storageBucket: 'mentorshipapp-7cffc.firebasestorage.app',
  );

}