import 'dart:convert';
import 'package:native_app_shell_mobile/src/web_view/web_view_container.dart';

class BridgeManager {
  static const String _OPERATION_REGISTER_DEVICE = 'REGISTER_DEVICE';

  static Future<String> executeRequest(Map data) async {
    String operations = data['payload']['type'];

    try {
      switch (operations) {
        case _OPERATION_REGISTER_DEVICE:
          {
            var result = await WebViewContainer.registerForPushNotifications();
            if (result == null) throw Exception('Cannot register device');
          }
      }
      return buildResponse(
        id: data['payload']['id']!,
        type: data['payload']['type'],
        response: {'foo': 123},
      );
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
