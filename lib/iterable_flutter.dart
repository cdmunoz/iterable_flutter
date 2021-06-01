import 'dart:async';

import 'package:flutter/services.dart';

class IterableFlutter {
  static const MethodChannel _channel = const MethodChannel('iterable_flutter');

  static Future register({required dynamic data}) async {
    await _channel.invokeMethod('register', {'deviceToken': data});
  }

  static Future initialize({required String apiKey}) async {
    await _channel.invokeMethod(
      'initialize',
      {
        'apiKey': apiKey,
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

  static Future canHandle({required dynamic url}) async {
    await _channel.invokeMethod(
      'canHandle',
      {
        'url': url,
      },
    );
  }
}