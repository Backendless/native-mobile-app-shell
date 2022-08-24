import 'dart:convert';
import 'dart:io';
import '../utils/request_container.dart';
import '../bridge/bridge_ui_builder_functions.dart';
import 'package:backendless_sdk/backendless_sdk.dart';
import 'package:native_app_shell_mobile/src/utils/coder.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class BridgeManager {
  static const String _OPERATION_REGISTER_DEVICE = 'REGISTER_DEVICE';
  static const String _SOCIAL_LOGIN = 'SOCIAL_LOGIN';

  static Future<String> executeRequest(Map data) async {
    final requestContainer =
        RequestContainer(data['payload']['id'], data['payload']['type']);

    try {
      var result;
      switch (requestContainer.operations) {
        case _OPERATION_REGISTER_DEVICE:
          {
            result =
                await BridgeUIBuilderFunctions.registerForPushNotifications(
                    channels: <String>['default']);
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
              if (Platform.isAndroid)
                return result = '_UNSUPPORTED FOR THIS PLATFORM';
              final credential = await SignInWithApple.getAppleIDCredential(
                  scopes: [
                    AppleIDAuthorizationScopes.email,
                    AppleIDAuthorizationScopes.fullName,
                  ],
                  webAuthenticationOptions: WebAuthenticationOptions(
                    clientId: data['payload']['options']['options']['clientId'],
                    redirectUri: Uri(),
                  ));
              result = await Backendless.customService.invoke('AppleAuth',
                  'login', credential.identityToken); //get your user
              result = BackendlessUser.fromJson(result);
            } else {
              result = await BridgeUIBuilderFunctions.socialLogin(
                  data['payload']['options']['providerCode'], data['_context']);
            }
            if (result == null) {
              result = '_CANCELED BY USER';
            } /*else {
              if (result.getProperty('userToken') != null) {
                requestContainer.userToken = result.getProperty('userToken');
              }
            }*/
            return buildResponse(
              data: requestContainer,
              response: result,
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
    Map? finalResult = {
      'event': 'RESPONSE',
      'payload': <String?, dynamic>{
        'type': data.operations,
        'id': data.id,
        'userToken': data.userToken
      }
    };

    if (response != null) {
      if (response is BackendlessUser)
        finalResult['payload']['result'] = response.toJson();
      else
        finalResult['payload']['result'] = response;
    } else
      finalResult['payload']['error'] = error;

    try {
      return json.encode(
        finalResult,
        toEncodable: Coder.dateSerializer,
      );
    } catch (ex) {
      throw new Exception(ex);
    }
  }
}
