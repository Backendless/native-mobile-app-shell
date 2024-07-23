import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:square_in_app_payments/in_app_payments.dart';
import 'package:square_in_app_payments/models.dart' as sm;
import '../utils/request_container.dart';
import '../bridge/bridge_ui_builder_functions.dart';
import 'package:backendless_sdk/backendless_sdk.dart';
import '../utils/coder.dart';
import 'package:square_in_app_payments/google_pay_constants.dart'
    as google_pay_constants;

import 'bridge_event.dart';

class BridgeManager {
  static const String _GET_CURRENT_LOCATION = 'GET_CURRENT_LOCATION';
  static const String _OPERATION_REGISTER_DEVICE = 'REGISTER_DEVICE';
  static const String _GET_RUNNING_ENV = 'GET_RUNNING_ENV';
  static const String _REQUEST_CAMERA_PERMISSIONS =
      'REQUEST_CAMERA_PERMISSIONS';
  static const String _REQUEST_SQUARE = 'REQUEST_SQUARE';
  static const String _CAN_USE_GOOGLE_PAY = 'CAN_USE_GOOGLE_PAY';
  static const String _CAN_USE_APPLE_PAY = 'CAN_USE_APPLE_PAY';
  static const String _SQUARE_GOOGLE_PAY = 'SQUARE_GOOGLE_PAY';
  static const String _SQUARE_APPLE_PAY = 'SQUARE_APPLE_PAY';
  static const String _GET_APP_STATE = 'GET_APP_STATE';
  static const String _ADD_LISTENER = 'ADD_LISTENER';
  static const String _REMOVE_LISTENER = 'REMOVE_LISTENER';

  static AppLifecycleState currentState = AppLifecycleState.resumed;

  static bool isInitializedSquare = false;

  static Future<String> executeRequest(
      Map data, JavaScriptReplyProxy replier) async {
    final requestContainer =
        RequestContainer(data['payload']['id'], data['payload']['type']);

    try {
      var result;
      switch (requestContainer.operations) {
        case _GET_APP_STATE:
          {
            result = currentState.name;
            return buildResponse(data: requestContainer, response: result);
          }
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
        case _REQUEST_SQUARE:
          {
            Completer completer = Completer<String>();
            if (!isInitializedSquare) {
              await InAppPayments.setSquareApplicationId(
                  'sq0idp-SZOFvwhG6YSgo4CZQ3NC6Q');
              isInitializedSquare = true;
            }

            var monBuilder = sm.MoneyBuilder();
            monBuilder.currencyCode = 'USD';
            monBuilder.amount = 0;
            var mon = monBuilder.build();
            var contactBuilder = sm.ContactBuilder();
            contactBuilder.givenName = 'test 123';
            var cont = contactBuilder.build();

            InAppPayments.startCardEntryFlowWithBuyerVerification(
              onBuyerVerificationSuccess: (details) {
                result = buildResponse(data: requestContainer, response: {
                  'card': details.card,
                  'token': details.token,
                  'nonce': details.nonce
                });
                completer.complete(result);
              },
              onBuyerVerificationFailure: (errInfo) {
                result = buildResponse(
                    data: requestContainer,
                    response: null,
                    error: errInfo.message);

                completer.complete(result);
              },
              onCardEntryCancel: () {
                result = buildResponse(
                  data: requestContainer,
                  response: '_CANCELED BY USER',
                );
                completer.complete(result);
              },
              buyerAction: 'Pay',
              money: mon,
              squareLocationId: data['payload']['options']['locationId'],
              contact: cont,
              collectPostalCode: false,
            );

            return await completer.future;
          }
        case _CAN_USE_GOOGLE_PAY:
          {
            if (!isInitializedSquare) {
              await InAppPayments.setSquareApplicationId(
                  'sq0idp-SZOFvwhG6YSgo4CZQ3NC6Q');
              isInitializedSquare = true;
            }

            if (io.Platform.isAndroid) {
              await InAppPayments.initializeGooglePay(
                  data['payload']['options']['locationId'],
                  google_pay_constants.environmentProduction);
              return buildResponse(
                  data: requestContainer,
                  response: await InAppPayments.canUseGooglePay);
            }

            return buildResponse(data: requestContainer, response: false);
          }
        case _CAN_USE_APPLE_PAY:
          {
            if (!isInitializedSquare) {
              await InAppPayments.setSquareApplicationId(
                  'sq0idp-SZOFvwhG6YSgo4CZQ3NC6Q');
              isInitializedSquare = true;
            }

            if (io.Platform.isIOS) {
              await BridgeUIBuilderFunctions.setIOSCardEntryTheme();
              await InAppPayments.initializeApplePay(
                  'merchant.com.royalcoffeeroasting.app');
              return buildResponse(
                  data: requestContainer,
                  response: await InAppPayments.canUseApplePay);
            }

            return buildResponse(data: requestContainer, response: false);
          }
        case _SQUARE_GOOGLE_PAY:
          {
            String totalAmount =
                (data['payload']['options']['totalAmount'] / 100).toString();
            Completer completer = Completer<String>();
            try {
              InAppPayments.requestGooglePayNonce(
                  price: totalAmount,
                  currencyCode: 'USD',
                  priceStatus: google_pay_constants.totalPriceStatusFinal,
                  onGooglePayNonceRequestSuccess: (details) {
                    result = buildResponse(data: requestContainer, response: {
                      'nonce': details.nonce,
                    });

                    completer.complete(result);
                  },
                  onGooglePayNonceRequestFailure: (errInfo) {
                    result = buildResponse(
                        data: requestContainer,
                        response: null,
                        error: errInfo.message);
                    completer.complete(result);
                  },
                  onGooglePayCanceled: () {
                    result = buildResponse(
                      data: requestContainer,
                      response: '_CANCELED BY USER',
                    );
                    completer.complete(result);
                  });
            } on PlatformException catch (ex) {
              result = buildResponse(
                  data: requestContainer, response: null, error: ex.message);
              completer.complete(result);
            }
            return await completer.future;
          }
        case _SQUARE_APPLE_PAY:
          {
            ApplePayStatus applePayStatus = ApplePayStatus.unknown;
            String totalAmount =
                (data['payload']['options']['totalAmount'] / 100).toString();
            Completer completer = Completer<String>();
            InAppPayments.requestApplePayNonce(
                price: totalAmount,
                summaryLabel: 'Ollies Slices',
                countryCode: 'US',
                currencyCode: 'USD',
                paymentType: sm.ApplePayPaymentType.finalPayment,
                onApplePayNonceRequestSuccess: (details) {
                  applePayStatus = ApplePayStatus.success;
                  result = buildResponse(data: requestContainer, response: {
                    'nonce': details.nonce,
                  });
                  InAppPayments.completeApplePayAuthorization(isSuccess: true);
                  completer.complete(result);
                },
                onApplePayNonceRequestFailure: (errInfo) {
                  applePayStatus = ApplePayStatus.fail;
                  result = buildResponse(
                      data: requestContainer,
                      response: null,
                      error: errInfo.message);
                  InAppPayments.completeApplePayAuthorization(
                      isSuccess: false, errorMessage: errInfo.message);
                  completer.complete(result);
                },
                onApplePayComplete: () {
                  if (applePayStatus == ApplePayStatus.unknown) {
                    result = buildResponse(
                      data: requestContainer,
                      response: '_CANCELED BY USER',
                    );

                    completer.complete(result);
                  }
                });

            return await completer.future;
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
                    channels: <String>['push']);
            if (result == null) throw Exception('Cannot register device');
            return buildResponse(
              data: requestContainer,
              response: {
                'deviceToken': (result as DeviceRegistrationResult).deviceToken
              },
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
      if (response is Map) {
        if (response.containsKey('card') && response['card'] is sm.Card) {
          finalResult['payload']['result'] = <String, dynamic>{
            'card': {
              'brand': response['card'].brand.name,
              'lastFourDigits': response['card'].lastFourDigits,
              'expirationMonth': response['card'].expirationMonth,
              'expirationYear': response['card'].expirationYear,
              'type': response['card'].type.name,
              'prepaidType': response['card'].prepaidType.name,
              'postalCode': response['card'].postalCode,
            },
            'token': response['token'],
            'nonce': response['nonce'],
          };
        } else {
          finalResult['payload']['result'] = response;
        }
      } else if (response is BackendlessUser) {
        finalResult['payload']['result'] = response.toJson();
      } else if (response is Position) {
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

enum ApplePayStatus { success, fail, unknown }
