import 'dart:convert';
import 'package:native_app_shell_mobile/src/bridge/bridge_ui_builder_functions.dart';

import '../web_view/web_view_container.dart';
import 'package:backendless_sdk/backendless_sdk.dart';

class BridgeManager {
  static const String _OPERATION_REGISTER_DEVICE = 'REGISTER_DEVICE';
  static const String _SOCIAL_LOGIN = 'SOCIAL_LOGIN';

  static Future<String> executeRequest(Map data) async {
    String operations = data['payload']['type'];

    try {
      var result;
      switch (operations) {
        case _OPERATION_REGISTER_DEVICE:
          {
            result =
                await BridgeUIBuilderFunctions.registerForPushNotifications();
            if (result == null) throw Exception('Cannot register device');
            return buildResponse(
              id: data['payload']['id']!,
              type: data['payload']['type'],
              userToken: data['payload']['userToken'],
              response: {
                'deviceToken': (result as DeviceRegistrationResult).deviceToken
              },
            );
          }
        case _SOCIAL_LOGIN:
          {
            result = await BridgeUIBuilderFunctions.socialLogin(
                'linkedin', data['_context']);
            return buildResponse(
              id: data['payload']['id'],
              type: data['payload']['type'],
              userToken: null,
              response: {
                result,
              },
            );
          }
          break;
      }
      throw Exception('Flutter error in bridge logic. Unknown operation type.');
    } catch (ex) {
      return buildResponse(
        id: data['payload']['id']!,
        type: data['payload']['type'],
        userToken: data['payload']['userToken'],
        error: data['payload']['error'] != null
            ? data['payload']['error']
            : ex.toString(),
      );
    }
  }

  static String buildResponse(
      {required String id,
      required String type,
      required String? userToken,
      dynamic response,
      String? error}) {
    Map? result = {
      'event': 'RESPONSE',
      'payload': <String?, dynamic>{
        'type': type,
        'id': id,
        'userToken': userToken
      }
    };

    if (response != null)
      result['payload']['result'] = response.toString();
    else
      result['payload']['error'] = error;

    try {
      return json.encode(result);
    } catch (ex) {
      throw new Exception(ex);
    }
  }
}
