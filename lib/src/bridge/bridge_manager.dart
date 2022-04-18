import 'dart:convert';
import 'package:native_app_shell_mobile/src/bridge/bridge_ui_builder_functions.dart';
import 'package:native_app_shell_mobile/src/utils/request_container.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../web_view/web_view_container.dart';
import 'package:backendless_sdk/backendless_sdk.dart';

class BridgeManager {
  static const String _OPERATION_REGISTER_DEVICE = 'REGISTER_DEVICE';
  static const String _SOCIAL_LOGIN = 'SOCIAL_LOGIN';

  static Future<String> executeRequest(Map data) async {
    final requestContainer = RequestContainer(
        data['payload']['id'], data['payload']['type'],
        userToken: data['payload']['userToken']);

    try {
      var result;
      switch (requestContainer.operations) {
        case _OPERATION_REGISTER_DEVICE:
          {
            result =
                await BridgeUIBuilderFunctions.registerForPushNotifications();
            if (result == null) throw Exception('Cannot register device');
            return buildResponse(
              data: requestContainer,
              response: {
                'deviceToken': (result as DeviceRegistrationResult).deviceToken
              },
            );
          }
        case _SOCIAL_LOGIN:
          {
            if (data['payload']['options']['providerCode'] == 'apple') {
              final credential = await SignInWithApple.getAppleIDCredential(
                  scopes: [
                    AppleIDAuthorizationScopes.email,
                    AppleIDAuthorizationScopes.fullName,
                  ],
                  webAuthenticationOptions: WebAuthenticationOptions(
                    clientId: data['payload']['options']['clientId'],
                    redirectUri: Uri(),
                  ));
              result = await Backendless.customService
                  .invoke('AppleAuth', 'login', credential.identityToken);
            } else {
              result = await BridgeUIBuilderFunctions.socialLogin(
                  data['payload']['options']['providerCode'], data['_context']);
            }
            if (result == null) result = '_CANCELED BY USER';
            return buildResponse(
              data: requestContainer,
              response: {
                result,
              },
            );
          }
      }
      throw Exception(
          'Flutter error in bridge logic. Unknown operation type or something else.');
    } catch (ex) {
      return buildResponse(
        data: requestContainer,
        error: data['payload']['error'] != null
            ? data['payload']['error']
            : ex.toString(),
      );
    }
  }

  static String buildResponse(
      {required RequestContainer data, dynamic response, String? error}) {
    Map? result = {
      'event': 'RESPONSE',
      'payload': <String?, dynamic>{
        'type': data.operations,
        'id': data.id,
        'userToken': data.userToken
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
