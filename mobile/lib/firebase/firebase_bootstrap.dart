import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!Env.firebaseEnabled) return;
  await Firebase.initializeApp(options: Env.firebaseOptions!);
}

/// Initializes Firebase + FCM when [Env.firebaseEnabled].
class FirebaseBootstrap {
  static bool _initialized = false;

  static Future<bool> init() async {
    if (kIsWeb || !Env.firebaseEnabled) return false;
    if (_initialized) return true;

    final options = Env.firebaseOptions;
    if (options == null) return false;

    await Firebase.initializeApp(options: options);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _initialized = true;
    return true;
  }
}
