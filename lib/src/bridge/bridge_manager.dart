import 'dart:convert';
import 'dart:io';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/request_container.dart';
import '../bridge/bridge_ui_builder_functions.dart';
import 'package:backendless_sdk/backendless_sdk.dart';
import 'package:native_app_shell_mobile/src/utils/coder.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'bridge_event.dart';

class BridgeManager {
  static const String _ADD_LISTENER = 'ADD_LISTENER';
  static const String _REMOVE_LISTENER = 'REMOVE_LISTENER';
  static const String _GET_CURRENT_LOCATION = 'GET_CURRENT_LOCATION';
  static const String _OPERATION_REGISTER_DEVICE = 'REGISTER_DEVICE';
  static const String _SOCIAL_LOGIN = 'SOCIAL_LOGIN';
  static const String _GET_RUNNING_ENV = 'GET_RUNNING_ENV';
  static const String _REQUEST_CAMERA_PERMISSIONS =
      'REQUEST_CAMERA_PERMISSIONS';

  static Future<String> executeRequest(
      Map data, JavaScriptReplyProxy replier) async {
    final requestContainer =
        RequestContainer(data['payload']['id'], data['payload']['type']);

    try {
      var result;
      switch (requestContainer.operations) {
        case _ADD_LISTENER:
          {
            try {
              String eventName = data['payload']['options']['event'];
              String eventId = data['payload']['options']['id'];

              BridgeEvent event = BridgeEvent(
                eventId,
                eventName,
                replier,
              );

              await BridgeUIBuilderFunctions.addListener(event);
              return buildResponse(data: requestContainer, response: result);
            } catch (ex) {
              return buildResponse(
                  data: requestContainer, response: null, error: ex.toString());
            }
          }
        case _REMOVE_LISTENER:
          {
            try {
              String eventName = data['payload']['options']['event'];
              String eventId = data['payload']['options']['id'];

              await BridgeUIBuilderFunctions.removeListener(eventName, eventId);
              return buildResponse(data: requestContainer, response: result);
            } catch (ex) {
              return buildResponse(
                  data: requestContainer, response: null, error: ex.toString());
            }
          }
        case _GET_CURRENT_LOCATION:
          {
            try {
              result = await BridgeUIBuilderFunctions.getCurrentLocation();
            } catch (ex) {
              return buildResponse(
                  data: requestContainer, response: null, error: ex.toString());
            }

            return buildResponse(data: requestContainer, response: result);
          }
        case _OPERATION_REGISTER_DEVICE:
          {
            await Permission.notification.request();

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
            }

            return buildResponse(
              data: requestContainer,
              response: result,
            );
          }
        case _GET_RUNNING_ENV:
          {
            return buildResponse(
                data: requestContainer, response: 'NATIVE_SHELL');
          }
        case _REQUEST_CAMERA_PERMISSIONS:
          {
            await Permission.camera.request();

            return buildResponse(
              data: requestContainer,
              response: true,
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
      }
    };

    if (response != null) {
      if (response is BackendlessUser)
        finalResult['payload']['result'] = response.toJson();
      else if (response is Position) {
        finalResult['payload']['result'] = <String, double>{
          'lat': response.latitude,
          'lng': response.longitude,
        };
      } else
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
