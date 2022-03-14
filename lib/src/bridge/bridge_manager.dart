import 'dart:convert';
import '../web_view/web_view_container.dart';
import 'package:backendless_sdk/backendless_sdk.dart';

class BridgeManager {
  static const String _OPERATION_REGISTER_DEVICE = 'REGISTER_DEVICE';

  static Future<String> executeRequest(Map data) async {
    String operations = data['payload']['type'];

    try {
      var result;
      switch (operations) {
        case _OPERATION_REGISTER_DEVICE:
          {
            result = await WebViewContainer.registerForPushNotifications();
            if (result == null) throw Exception('Cannot register device');
            return buildResponse(
              id: data['payload']['id']!,
              type: data['payload']['type'],
              response: {
                'deviceToken': (result as DeviceRegistrationResult).deviceToken
              },
            );
          }
      }
      throw Exception('Flutter error in bridge logic');
    } catch (ex) {
      return buildResponse(
        id: data['payload']['id']!,
        type: data['payload']['type'],
        error: data['payload']['error'] != null
            ? data['payload']['error']
            : ex.toString(),
      );
    }
  }

  static String buildResponse(
      {required String id,
      required String type,
      dynamic response,
      String? error}) {
    Map? result = {
      'event': 'RESPONSE',
      'payload': <String?, dynamic>{'type': type, 'id': id}
    };

    if (response != null)
      result['payload']['result'] = response;
    else
      result['payload']['error'] = error;

    try {
      return json.encode(result);
    } catch (ex) {
      throw new Exception(ex);
    }
  }
}
