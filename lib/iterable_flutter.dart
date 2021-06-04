import 'dart:async';

import 'package:flutter/services.dart';

class IterableFlutter {
  static const MethodChannel _channel = const MethodChannel('iterable_flutter');

  static Future register({required dynamic data}) async {
    await _channel.invokeMethod('register', {'deviceToken': data});
  }

  static Future initialize({required String apiKey, String? pushIntegrationName}) async {
    await _channel.invokeMethod(
      'initialize',
      {
        'apiKey': apiKey,
        'pushIntegrationName': pushIntegrationName,
      },
    );
  }

  static Future setUserIdentity({
    required String userId,
    required String userEmail,
    String? firstName,
  }) async {
    await _channel.invokeMethod(
      'setUserIdentity',
      {
        'userId': userId,
        'userEmail': userEmail,
        'firstName': firstName,
      },
    );
  }

  static Future track({
    required String eventName,
    required Map<String, dynamic> params,
  }) async {
    await _channel.invokeMethod(
      'track',
      {
        'eventName': eventName,
        'params': params,
      },
    );
  }

  static Future signOut() async {
    await _channel.invokeMethod('signOut');
  }

  static Future handleAndroidMessage({required Map<String, dynamic> message}) async {
    await _channel.invokeMethod(
      'handleAndroidMessage',
      {
        'message': message,
      },
    );
  }
}
