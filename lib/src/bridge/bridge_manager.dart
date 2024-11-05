import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:geolocator/geolocator.dart';
import '../bridge/bridge_features.dart';
import '../utils/request.dart';
import 'package:backendless_sdk/backendless_sdk.dart';
import '../utils/coder.dart';
import 'package:package_info_plus/package_info_plus.dart';

class BridgeManager {
  static PackageInfo? info;

  static Future<String> executeRequest(
      Map data, PlatformJavaScriptReplyProxy jsResponseProxy) async {
    final request = Request(data['payload']['id'], data['payload']['type']);

    request.userToken = data['payload']['userToken'];

    try {
      if (request.userToken != null) {
        await Backendless.userService.setUserToken(request.userToken!);
      }

      Map? customPayload = data['payload']['options'];

      if (request.operationName == 'ADD_LISTENER' && customPayload != null) {
        return await listenerReceiver(request, customPayload, jsResponseProxy);
      }

      return await methodReceiver(request, customPayload);
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
      } else if (response is DeviceRegistrationResult) {
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
