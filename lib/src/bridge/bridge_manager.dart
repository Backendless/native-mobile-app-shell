import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:geolocator/geolocator.dart';
import 'package:native_app_shell_mobile/src/bridge/bridge_features.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/request.dart';
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
  static const String _SAVE_CONTACT = 'SAVE_CONTACT';
  static const String _GET_APP_INFO = 'GET_APP_INFO';
  static const String _UNREGISTER_DEVICE = 'UNREGISTER_DEVICE';
  static const String _TAP_PUSH_ACTION = 'TAP_PUSH_ACTION';
  static const String _GET_DEVICE_REGISTRATION = 'GET_DEVICE_REGISTRATION';
  static const String _ACCELEROMETER_DATA = 'ACCELEROMETER_DATA';
  static const String _USER_ACCELEROMETER_DATA = 'USER_ACCELEROMETER_DATA';
  static const String _GYROSCOPE_DATA = 'GYROSCOPE_DATA';
  static const String _MAGNETOMETER_DATA = 'MAGNETOMETER_DATA';
  //static const String _REMOTE_NOTIFICATION = ''

  static PackageInfo? info;
  // static StreamController<bool> onTapEventInitializeController =
  //     StreamController.broadcast();

  static Future<String> executeRequest(
      Map data, JavaScriptReplyProxy jsResponseProxy) async {
    final request = Request(data['payload']['id'], data['payload']['type']);

    request.userToken = data['payload']['userToken'];

    try {
      if (request.userToken != null) {
        await Backendless.userService.setUserToken(request.userToken!);
      }
      var result;
      Map? customPayload = data['payload']['options'];

      if (customPayload != null && customPayload.isNotEmpty) {
        if (customPayload.containsKey('event') &&
            customPayload.containsKey('id')) {
          return await listenerReceiver(
              request, customPayload, jsResponseProxy);
        }
      }

      return await methodReceiver(request, customPayload);
      // switch (requestContainer.operations) {
      //   case _ADD_LISTENER:
      //     {
      //       try {
      //         // String eventName = data['payload']['options']['event'];
      //         // String eventId = data['payload']['options']['id'];
      //         //
      //         // BridgeEvent event = BridgeEvent(
      //         //   eventId,
      //         //   eventName,
      //         //   replier,
      //         // );
      //
      //         //await BridgeUIBuilderFunctions.addListener(event);
      //         return buildResponse(data: requestContainer, response: result);
      //       } catch (ex) {
      //         return buildResponse(
      //             data: requestContainer,
      //             response: null,
      //             error: {'message': ex.toString()});
      //       }
      //     }
      //   case _REMOVE_LISTENER:
      //     {
      //       try {
      //         await BridgeUIBuilderFunctions.removeListener(data);
      //         return buildResponse(data: requestContainer, response: result);
      //       } catch (ex) {
      //         return buildResponse(
      //             data: requestContainer,
      //             response: null,
      //             error: {'message': ex.toString()});
      //       }
      //     }
      //   case _TAP_PUSH_ACTION:
      //     {
      //       try {
      //         String eventName = data['payload']['options']['event'];
      //         String eventId = data['payload']['options']['id'];
      //
      //         BridgeEvent event = BridgeEvent(
      //           eventId,
      //           eventName,
      //           replier,
      //         );
      //
      //         // await BridgeUIBuilderFunctions.addListener(event);
      //         //
      //         // if (!onTapEventInitializeController.isClosed) {
      //         //   onTapEventInitializeController.add(true);
      //         // }
      //
      //         return buildResponse(data: requestContainer, response: 'Ok');
      //       } catch (ex) {
      //         return buildResponse(
      //             data: requestContainer,
      //             response: null,
      //             error: {'message': ex.toString()});
      //       }
      //     }
      //   case _GET_CURRENT_LOCATION:
      //     {
      //       try {
      //         result = await BridgeUIBuilderFunctions.getCurrentLocation();
      //
      //         return buildResponse(data: requestContainer, response: result);
      //       } catch (ex) {
      //         return buildResponse(
      //             data: requestContainer,
      //             response: null,
      //             error: {'message': ex.toString()});
      //       }
      //     }
      //   case _GET_CONTACTS_LIST:
      //     {
      //       try {
      //         result = await BridgeUIBuilderFunctions.getContactsList();
      //
      //         return buildResponse(data: requestContainer, response: result);
      //       } catch (ex) {
      //         return buildResponse(
      //             data: requestContainer,
      //             response: null,
      //             error: {'message': ex.toString()});
      //       }
      //     }
      //   case _SAVE_CONTACT:
      //     {
      //       try {
      //         // Map<String, dynamic> contactData =
      //         //     data['payload']['options']['contact'];
      //         // Contact contact = Contact.fromJson(contactData);
      //         //var result = await BridgeUIBuilderFunctions.saveContact(contact);
      //
      //         return buildResponse(data: requestContainer, response: result);
      //       } catch (ex) {
      //         return buildResponse(
      //             data: requestContainer,
      //             response: null,
      //             error: {'message': ex.toString()});
      //       }
      //     }
      //   case _SHARE_SHEET_REQUEST:
      //     {
      //       String? message = data['payload']['options']['message'];
      //       String? resourceName = data['payload']['options']['resourceName'];
      //       String? link = data['payload']['options']['link'];
      //
      //       if (link?.isNotEmpty ?? false) {
      //         if (message != null) {
      //           link = '$message\n$link';
      //         }
      //
      //         await Share.share(link!, subject: resourceName);
      //         return buildResponse(data: requestContainer, response: null);
      //       }
      //
      //       throw Exception('Link to share cannot be null');
      //     }
      //   case _OPERATION_REGISTER_DEVICE:
      //     {
      //       await Permission.notification.request();
      //
      //       List<String> targetChannels = ['default'];
      //
      //       if (data['payload']['options']['channels'] != null) {
      //         targetChannels =
      //             List<String>.from(data['payload']['options']['channels']);
      //       }
      //
      //       result =
      //           await BridgeUIBuilderFunctions.registerForPushNotifications(
      //               channels: targetChannels);
      //       if (result is Exception || result is BackendlessException) {
      //         return buildResponse(
      //             data: requestContainer, error: {'message': result.message});
      //       }
      //
      //       if (result is DeviceRegistrationResult) {
      //         return buildResponse(
      //           data: requestContainer,
      //           response: {'deviceToken': result.deviceToken},
      //         );
      //       }
      //
      //       return buildResponse(
      //           data: requestContainer, error: {'message': 'Unknown error'});
      //     }
      //   case _UNREGISTER_DEVICE:
      //     {
      //       try {
      //         result = await Backendless.messaging.unregisterDevice();
      //
      //         return buildResponse(
      //           data: requestContainer,
      //           response: result,
      //         );
      //       } catch (ex) {
      //         print('EXCEPTION DURING UNREGISTER DEVICE: $ex');
      //
      //         return buildResponse(data: requestContainer, response: false);
      //       }
      //     }
      //   case _GET_DEVICE_REGISTRATION:
      //     {
      //       try {
      //         result = await Backendless.messaging.getDeviceRegistration();
      //
      //         return buildResponse(data: requestContainer, response: result);
      //       } catch (ex) {
      //         result = ex.toString();
      //
      //         return buildResponse(data: requestContainer, error: result);
      //       }
      //     }
      //   case _SOCIAL_LOGIN:
      //     {
      //       // if (data['payload']['options']['providerCode'] == 'apple') {
      //       //   if (Platform.isAndroid)
      //       //     return result = '_UNSUPPORTED FOR THIS PLATFORM';
      //       //   final credential = await SignInWithApple.getAppleIDCredential(
      //       //       scopes: [
      //       //         AppleIDAuthorizationScopes.email,
      //       //         AppleIDAuthorizationScopes.fullName,
      //       //       ],
      //       //       webAuthenticationOptions: WebAuthenticationOptions(
      //       //         clientId: data['payload']['options']['options']['clientId'],
      //       //         redirectUri: Uri(),
      //       //       ));
      //       //   result = await Backendless.customService.invoke('AppleAuth',
      //       //       'login', credential.identityToken); //get your user
      //       //   result = BackendlessUser.fromJson(result);
      //       // } else {
      //       //   result = await BridgeUIBuilderFunctions.socialLogin(
      //       //       data['payload']['options']['providerCode'], data['_context']);
      //       // }
      //       // if (result == null) {
      //       //   result = '_CANCELED BY USER';
      //       // }
      //
      //       return buildResponse(
      //         data: requestContainer,
      //         response: result,
      //       );
      //     }
      //   case _GET_RUNNING_ENV:
      //     {
      //       return buildResponse(
      //           data: requestContainer, response: 'NATIVE_SHELL');
      //     }
      //   case _GET_APP_INFO:
      //     {
      //       if (info == null) {
      //         info = await PackageInfo.fromPlatform();
      //       }
      //
      //       if (info != null) {
      //         result = {
      //           'appName': info!.appName,
      //           'packageName': info!.packageName,
      //           'version': info!.version,
      //           'buildNumber': info!.buildNumber,
      //           'buildSignature': info!.buildSignature,
      //         };
      //       }
      //
      //       return buildResponse(data: requestContainer, response: result);
      //     }
      //   case _ACCELEROMETER_DATA:
      //     {
      //       try {
      //         // String eventName = data['payload']['options']['event'];
      //         // String eventId = data['payload']['options']['id'];
      //         //
      //         // BridgeEvent event = BridgeEvent(
      //         //   eventId,
      //         //   eventName,
      //         //   replier,
      //         // );
      //         //
      //         // await BridgeUIBuilderFunctions.addListener(event);
      //         // await BridgeUIBuilderFunctions.setAccelerometerEvent(event);
      //
      //         return buildResponse(data: requestContainer, response: 'Ok');
      //       } catch (ex) {
      //         return buildResponse(
      //             data: requestContainer,
      //             response: null,
      //             error: {'message': ex.toString()});
      //       }
      //     }
      //   case _USER_ACCELEROMETER_DATA:
      //     {
      //       try {
      //         String eventName = data['payload']['options']['event'];
      //         String eventId = data['payload']['options']['id'];
      //
      //         BridgeEvent event = BridgeEvent(
      //           eventId,
      //           eventName,
      //           replier,
      //         );
      //
      //         await BridgeUIBuilderFunctions.addListener(event);
      //         await BridgeUIBuilderFunctions.setUserAccelerometerEvent(event);
      //
      //         return buildResponse(data: requestContainer, response: 'Ok');
      //       } catch (ex) {
      //         return buildResponse(
      //             data: requestContainer,
      //             response: null,
      //             error: {'message': ex.toString()});
      //       }
      //     }
      //   case _MAGNETOMETER_DATA:
      //     {
      //       try {
      //         String eventName = data['payload']['options']['event'];
      //         String eventId = data['payload']['options']['id'];
      //
      //         BridgeEvent event = BridgeEvent(
      //           eventId,
      //           eventName,
      //           replier,
      //         );
      //
      //         await BridgeUIBuilderFunctions.addListener(event);
      //         await BridgeUIBuilderFunctions.setMagnetometerEvent(event);
      //
      //         return buildResponse(data: requestContainer, response: 'Ok');
      //       } catch (ex) {
      //         return buildResponse(
      //             data: requestContainer,
      //             response: null,
      //             error: {'message': ex.toString()});
      //       }
      //     }
      //   case _GYROSCOPE_DATA:
      //     {
      //       try {
      //         String eventName = data['payload']['options']['event'];
      //         String eventId = data['payload']['options']['id'];
      //
      //         BridgeEvent event = BridgeEvent(
      //           eventId,
      //           eventName,
      //           replier,
      //         );
      //
      //         await BridgeUIBuilderFunctions.addListener(event);
      //         await BridgeUIBuilderFunctions.setGyroscopeEvent(event);
      //
      //         return buildResponse(data: requestContainer, response: 'Ok');
      //       } catch (ex) {
      //         return buildResponse(
      //             data: requestContainer,
      //             response: null,
      //             error: {'message': ex.toString()});
      //       }
      //     }
      //   case _REQUEST_CAMERA_PERMISSIONS:
      //     {
      //       PermissionStatus status = await Permission.camera.request();
      //
      //       result = status.name;
      //
      //       return buildResponse(
      //         data: requestContainer,
      //         response: result,
      //       );
      //     }
      // }
      // throw Exception(
      //     'Flutter error in bridge logic. Unknown operation type or something else.');
    } catch (ex) {
      return buildResponse(
        data: request,
        error: data['payload']['error'] != null
            ? data['payload']['error']
            : {'message': ex.toString()},
      );
    } finally {
      await Backendless.userService.removeUserToken();
    }
  }

  static Future<String> buildResponse(
      {required Request data, dynamic response, Map? error}) async {
    Map? finalResult = {
      'event': 'RESPONSE',
      'payload': <String?, dynamic>{
        'type': data.operationName,
        'id': data.operationId,
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
      } else if (response is Contact) {
        Map mappedElement = response.toJson();
        if (mappedElement.containsKey('photo') ||
            mappedElement.containsKey('thumbnail')) {
          Uint8List? avatar = mappedElement['photo'];
          Uint8List? thumbnail = mappedElement['thumbnail'];

          if (avatar != null && avatar.isNotEmpty) {
            // ignore: non_constant_identifier_names
            String base64_avatar = base64Encode(avatar);

            mappedElement['photo'] = 'data:image/png;base64,' + base64_avatar;
          } else {
            mappedElement['photo'] = null;
          }

          if (thumbnail != null && thumbnail.isNotEmpty) {
            // ignore: non_constant_identifier_names
            String base64_thumbnail = base64Encode(thumbnail);

            mappedElement['thumbnail'] =
                'data:image/png;base64,' + base64_thumbnail;
          } else {
            mappedElement['thumbnail'] = null;
          }
        }

        finalResult['payload']['result'] = mappedElement;
      } else if (response is List) {
        if (response.isNotEmpty && response[0] is Contact) {
          finalResult['payload']['result'] = List.empty(growable: true);

          response.forEach((element) {
            Map mappedElement = element.toJson();
            if (mappedElement.containsKey('photo') ||
                mappedElement.containsKey('thumbnail')) {
              Uint8List? avatar = mappedElement['photo'];
              Uint8List? thumbnail = mappedElement['thumbnail'];

              if (avatar != null && avatar.isNotEmpty) {
                // ignore: non_constant_identifier_names
                String base64_avatar = base64Encode(avatar);

                mappedElement['photo'] =
                    'data:image/png;base64,' + base64_avatar;
              } else {
                mappedElement['photo'] = null;
              }

              if (thumbnail != null && thumbnail.isNotEmpty) {
                // ignore: non_constant_identifier_names
                String base64_thumbnail = base64Encode(thumbnail);

                mappedElement['thumbnail'] =
                    'data:image/png;base64,' + base64_thumbnail;
              } else {
                mappedElement['thumbnail'] = null;
              }
            }
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
