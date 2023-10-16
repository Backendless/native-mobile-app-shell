import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/request_container.dart';
import '../bridge/bridge_ui_builder_functions.dart';
import 'package:backendless_sdk/backendless_sdk.dart';
import '../utils/coder.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  static const String _SHARE_SHEET_REQUEST = 'SHARE_SHEET_REQUEST';
  static const String _GET_CONTACTS_LIST = 'GET_CONTACTS_LIST';
  static const String _GET_APP_INFO = 'GET_APP_INFO';
  static const String _UNREGISTER_DEVICE = 'UNREGISTER_DEVICE';
  static const String _TAP_PUSH_ACTION = 'TAP_PUSH_ACTION';
  static const String _GET_DEVICE_REGISTRATION = 'GET_DEVICE_REGISTRATION';
  //static const String _REMOTE_NOTIFICATION = ''

  static PackageInfo? info;
  static StreamController<bool> onTapEventInitializeController =
      StreamController.broadcast();

  static Future<String> executeRequest(
      Map data, JavaScriptReplyProxy replier) async {
    final requestContainer =
        RequestContainer(data['payload']['id'], data['payload']['type']);

    requestContainer.userToken = data['payload']['userToken'];

    try {
      if (requestContainer.userToken != null) {
        await Backendless.userService.setUserToken(requestContainer.userToken!);
      }

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
                  data: requestContainer,
                  response: null,
                  error: {'message': ex.toString()});
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
                  data: requestContainer,
                  response: null,
                  error: {'message': ex.toString()});
            }
          }
        case _TAP_PUSH_ACTION:
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

              if (!onTapEventInitializeController.isClosed) {
                onTapEventInitializeController.add(true);
              }

              return buildResponse(data: requestContainer, response: 'Ok');
            } catch (ex) {
              return buildResponse(
                  data: requestContainer,
                  response: null,
                  error: {'message': ex.toString()});
            }
          }
        case _GET_CURRENT_LOCATION:
          {
            try {
              result = await BridgeUIBuilderFunctions.getCurrentLocation();

              return buildResponse(data: requestContainer, response: result);
            } catch (ex) {
              return buildResponse(
                  data: requestContainer,
                  response: null,
                  error: {'message': ex.toString()});
            }
          }
        case _GET_CONTACTS_LIST:
          {
            try {
              result = await BridgeUIBuilderFunctions.getContactList();

              return buildResponse(data: requestContainer, response: result);
            } catch (ex) {
              return buildResponse(
                  data: requestContainer,
                  response: null,
                  error: {'message': ex.toString()});
            }
          }
        case _SHARE_SHEET_REQUEST:
          {
            String? message = data['payload']['options']['message'];
            String? resourceName = data['payload']['options']['resourceName'];
            String? link = data['payload']['options']['link'];

            if (link?.isNotEmpty ?? false) {
              if (message != null) {
                link = '$message\n$link';
              }

              await Share.share(link!, subject: resourceName);
              return buildResponse(data: requestContainer, response: null);
            }

            throw Exception('Link to share cannot be null');
          }
        case _OPERATION_REGISTER_DEVICE:
          {
            await Permission.notification.request();

            List<String> targetChannels = ['default'];

            if (data['payload']['options']['channels'] != null) {
              targetChannels =
                  List<String>.from(data['payload']['options']['channels']);
            }

            result =
                await BridgeUIBuilderFunctions.registerForPushNotifications(
                    channels: targetChannels);
            if (result is Exception || result is BackendlessException) {
              return buildResponse(
                  data: requestContainer, error: {'message': result.message});
            }

            if (result is DeviceRegistrationResult) {
              return buildResponse(
                data: requestContainer,
                response: {'deviceToken': result.deviceToken},
              );
            }

            return buildResponse(
                data: requestContainer, error: {'message': 'Unknown error'});
          }
        case _UNREGISTER_DEVICE:
          {
            try {
              result = await Backendless.messaging.unregisterDevice();

              return buildResponse(
                data: requestContainer,
                response: result,
              );
            } catch (ex) {
              print('EXCEPTION DURING UNREGISTER DEVICE: $ex');

              return buildResponse(data: requestContainer, response: false);
            }
          }
        case _GET_DEVICE_REGISTRATION:
          {
            try {
              result = await Backendless.messaging.getDeviceRegistration();

              return buildResponse(data: requestContainer, response: result);
            } catch (ex) {
              result = ex.toString();

              return buildResponse(data: requestContainer, error: result);
            }
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
        case _GET_APP_INFO:
          {
            if (info == null) {
              info = await PackageInfo.fromPlatform();
            }

            if (info != null) {
              result = {
                'appName': info!.appName,
                'packageName': info!.packageName,
                'version': info!.version,
                'buildNumber': info!.buildNumber,
                'buildSignature': info!.buildSignature,
              };
            }

            return buildResponse(data: requestContainer, response: result);
          }
        case _REQUEST_CAMERA_PERMISSIONS:
          {
            PermissionStatus status = await Permission.camera.request();

            result = status.name;

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
            : {'message': ex.toString()},
      );
    } finally {
      await Backendless.userService.removeUserToken();
    }
  }

  static String buildResponse(
      {required RequestContainer data, dynamic response, Map? error}) {
    Map? finalResult = {
      'event': 'RESPONSE',
      'payload': <String?, dynamic>{
        'type': data.operations,
        'id': data.id,
        'userToken': data.userToken,
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
      } else if (response is DeviceRegistration) {
        finalResult['payload']['result'] = response.toJson();
      } else if (response is List) {
        if (response.isNotEmpty && response[0] is Contact) {
          finalResult['payload']['result'] = List.empty(growable: true);

          response.forEach((element) {
            Map mappedElement = element.toMap();
            (finalResult['payload']['result'] as List).add(mappedElement);
          });
        } else {
          finalResult['payload']['result'] = response;
        }
      } else
        finalResult['payload']['result'] = response;
    } else if (error != null) {
      if (error.containsKey('message') &&
          error['message'] is BackendlessException) {
        error = (error['message'] as BackendlessException).toJson();
      }
      finalResult['payload']['error'] = error;
    }

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
