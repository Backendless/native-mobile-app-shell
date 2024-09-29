import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import '../payment_service/shell_apple_pay.dart';
import '../payment_service/shell_google_pay.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pay/pay.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../utils/contacts_controller.dart';
import '../utils/initializer.dart';
import 'bridge.dart';
import 'bridge_event.dart';
import '../utils/geo_controller.dart';
import 'package:flutter/material.dart';
import '../utils/support_functions.dart';
import 'package:geolocator/geolocator.dart';
import '../types/push_notification_message.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:backendless_sdk/backendless_sdk.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../push_notifications/message_notification.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sensors_plus/sensors_plus.dart';

class BridgeUIBuilderFunctions {
  static const GOOGLE_CLIENT_ID_IOS = 'xxxxxx.apps.googleusercontent.com';
  static const GOOGLE_CLIENT_ID_WEB = 'xxxxxx.apps.googleusercontent.com';

  static StreamController<bool> onTapEventInitializeController =
  StreamController.broadcast();
  static late LocationPermission permission;
  static PackageInfo? info;
  static var _payObject;

  static Future<BridgeEvent> createBridgeEventFromMap(Map? data,
      PlatformJavaScriptReplyProxy replier) async {
    String eventName = data!['event'];
    String eventId = data['id'];

    BridgeEvent event = BridgeEvent(
      eventId,
      eventName,
      replier,
    );

    return event;
  }

  static Future<void> addListener(Map? mapEvent,
      PlatformJavaScriptReplyProxy jsResponseProxy) async {
    BridgeEvent event = await BridgeUIBuilderFunctions.createBridgeEventFromMap(
        mapEvent!, jsResponseProxy);

    if (event.isExist) throw Exception('Event with same id already exists');

    BridgeEvent.addToContainer(event);
  }

  static Future<bool> removeListener(Map data) async {
    String eventName = data['event'];
    String eventId = data['id'];

    return await BridgeEvent.removeEvent(eventName, eventId);
  }

  static Future<dynamic> registerDevice(Map? data) async {
    await Permission.notification.request();

    List<String> targetChannels = ['default'];

    if (data!['channels'] != null) {
      targetChannels = List<String>.from(data['channels']);
    }

    return await BridgeUIBuilderFunctions.registerForPushNotifications(
        channels: targetChannels);
  }

  static Future<void> tapOnPushAction(Map? data,
      PlatformJavaScriptReplyProxy jsResponseProxy) async {
    await BridgeUIBuilderFunctions.addListener(data!, jsResponseProxy);

    if (!onTapEventInitializeController.isClosed) {
      onTapEventInitializeController.add(true);
    }
  }

  static Future<bool> unregisterDevice(Map? payload) async {
    return await Backendless.messaging.unregisterDevice();
  }

  static Future<DeviceRegistration?> getDeviceRegistrations(
      Map? payload) async {
    return await Backendless.messaging.getDeviceRegistration();
  }

  static Future<dynamic> registerForPushNotifications({
    List<String>? channels,
  }) async {
    List<String> channelsList = [];
    var res;
    if (channels != null)
      channelsList.addAll(channels);
    else
      channelsList.add('default');

    try {
      DateTime time = DateTime.now().add(const Duration(days: 15));

      if (io.Platform.isAndroid) {
        res = await Backendless.messaging.registerDevice(
          channels: channelsList,
          expiration: time,
          onTapPushActionAndroid: onTapAndroid,
          onMessageOpenedAppAndroid: onTapAndroidBackground,
        );
      } else {
        res = await Backendless.messaging.registerDevice(
            channels: channelsList,
            expiration: time,
            onMessage: onMessage,
            onTapPushActionIOS: onTapIOS);
      }

      return res;
    } catch (ex) {
      return ex;
    }
  }

  static Future<dynamic> socialLogin(Map? data) async {
    var result;

    if (data!['providerCode'] == 'apple') {
      if (Platform.isAndroid) return result = '_UNSUPPORTED FOR THIS PLATFORM';
      final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          webAuthenticationOptions: WebAuthenticationOptions(
            clientId: data['options']['clientId'],
            redirectUri: Uri(),
          ));
      result = await Backendless.customService.invoke(
          'AppleAuth', 'login', credential.identityToken); //get your user
      result = BackendlessUser.fromJson(result);
    } else {
      result = await BridgeUIBuilderFunctions._socialLogin(
          data['providerCode'], Bridge.currentContext!);
    }
    if (result == null) {
      result = '_CANCELED BY USER';
    }

    return result;
  }

  static Future<BackendlessUser?> _socialLogin(String providerCode,
      BuildContext context,
      {Map<String, String>? fieldsMappings, List<String>? scope}) async {
    BackendlessUser? user;
    String? userId;
    String? userToken;

    await Backendless.userService.logout();

    if (providerCode == 'googleplus' || providerCode == 'facebook') {
      String? token;
      if (providerCode == 'googleplus') {
        GoogleSignIn _googleSignIn = GoogleSignIn(
          clientId:
          io.Platform.isIOS ? GOOGLE_CLIENT_ID_IOS : GOOGLE_CLIENT_ID_WEB,
          scopes: [
            'email',
            'https://www.googleapis.com/auth/plus.login',
          ],
        );

        await _googleSignIn.signOut();
        var resLog = await _googleSignIn.signIn();
        token = (await resLog!.authentication).accessToken;
      }

      if (providerCode == 'facebook') {
        await FacebookAuth.instance.logOut();
        final LoginResult fbResult = await FacebookAuth.instance.login();
        if (fbResult.status == LoginStatus.success) {
          token = fbResult.accessToken!.tokenString;
        } else {
          print(fbResult.status);
          print(fbResult.message);
        }
      }

      user = await Backendless.userService.loginWithOauth2(
        providerCode,
        token!,
        <String, String>{},
      );
      userId = user!.getUserId();
      userToken = await Backendless.userService.getUserToken();
      user.setProperty('user-token', userToken);
    } else {
      String? result = await Backendless.userService.getAuthorizationUrlLink(
        providerCode,
        fieldsMappings: fieldsMappings,
        scope: scope,
      );

      await showDialog(
          useSafeArea: true,
          context: context,
          builder: (context) {
            return Container(
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 1.2,
              height: MediaQuery
                  .of(context)
                  .size
                  .height,
              child: Column(
                children: [
                  Expanded(
                      child: InAppWebView(
                          initialUrlRequest: URLRequest(
                            url: WebUri(result!),
                          ),
                          initialSettings: InAppWebViewSettings(
                            useShouldOverrideUrlLoading: true,
                            disableHorizontalScroll: true,
                            cacheEnabled: true,
                            userAgent:
                            'Mozilla/5.0 (iPhone; CPU iPhone OS 15_6_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.6 Mobile/15E148 Safari/604.1',
                            //providerCode != 'facebook' ? 'random' : '',
                            useHybridComposition: true,
                            safeBrowsingEnabled: false,
                          ),
                          onLoadStop: (controller, url) async {
                            print('!!! called onLoadStop');
                            print("AUTH_WEBVIEW: $url");
                          },
                          shouldOverrideUrlLoading:
                              (controller, navigationAction) async {
                            print('override');
                            print('${navigationAction.request.url}');
                            if (navigationAction.request.url
                                .toString()
                                .contains('userId')) {
                              userId = navigationAction
                                  .request.url!.queryParameters['userId'];
                              userToken = navigationAction
                                  .request.url!.queryParameters['userToken'];
                              Navigator.pop(context);
                            }
                            return null;
                          }))
                ],
              ),
            );
          });
    }

    if (userId != null && user == null) {
      user = BackendlessUser()
        ..setProperty('objectId', userId);

      await Backendless.userService.setCurrentUser(user);
      await Backendless.userService.setUserToken(userToken!);

      user = await Backendless.userService.findById(userId!);
      user!.setProperty('user-token', userToken);
    }

    return user;
  }

  static Future<String> getRunningEnvironment(Map? payload) async {
    return 'NATIVE_SHELL';
  }

  static Future<Map> getAppInfo(Map? payload) async {
    var result;
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

    return result;
  }

  static Future<String> requestCameraPermissions(Map? payload) async {
    PermissionStatus status = await Permission.camera.request();

    return status.name;
  }

  static Future<Position?> getCurrentLocation(Map? payload) async {
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await GeoController.getCurrentLocation();
  }

  static Future<List<Contact>?> getContactsList(Map? payload) async {
    var contactsList = await ContactsController.getContactsList();

    return contactsList;
  }

  static Future<Contact> createContact(Map contactData) async {
    Map<String, dynamic> parsedContactData =
    await ContactsController.normalizeContact(contactData['contact']);

    Contact contact = Contact(
      displayName: parsedContactData['displayName'],
      accounts: parsedContactData['account'],
      photo: parsedContactData['photo'],
      events: parsedContactData['events'],
      name: parsedContactData['name'],
      organizations: parsedContactData['organizations'],
      addresses: parsedContactData['addresses'],
      emails: parsedContactData['emails'],
      phones: parsedContactData['phones'],
    );

    await ContactsController.requestContactPermissions();

    return await FlutterContacts.insertContact(contact);
  }

  static Future<Contact> updateContact(Map contactData) async {
    Map<String, dynamic> parsedContactData = contactData['contact'];
    String? photo = parsedContactData['photo'];
    String? thumbnail = parsedContactData['thumbnail'];
    if (photo?.isNotEmpty ?? false) {
      photo = photo!.substring(photo.indexOf('base64,') + 7);
      parsedContactData['photo'] = base64Decode(photo);
    }

    if ((parsedContactData['thumbnail'] as String?)?.isNotEmpty ?? false) {
      thumbnail = thumbnail!.substring(thumbnail.indexOf('base64,') + 7);
      parsedContactData['thumbnail'] = base64Decode(thumbnail);
    }

    Contact contact = Contact.fromJson(parsedContactData);

    await ContactsController.requestContactPermissions();

    bool isExists = await ContactsController.contactExists(contact);

    if (isExists) {
      return await FlutterContacts.updateContact(contact);
    } else {
      throw new ArgumentError('Contact with this id not exists');
    }
  }

  static Future<void> shareSheet(Map? data) async {
    String? message = data!['message'];
    String? resourceName = data['resourceName'];
    String? link = data['link'];

    if (link?.isNotEmpty ?? false) {
      if (message != null) {
        link = '$message\n$link';
      }

      return await Share.share(link!, subject: resourceName);
    }

    throw Exception('Link to share cannot be null');
  }

  static Future<void> googlePayInit(Map data) async {
    var configurationJson = data['configuration'];
    PaymentConfiguration configObj = PaymentConfiguration.fromJsonString(
        configurationJson);

    _payObject = ShellGooglePay(configObj);
  }

  static Future<void> applePayInit(Map data) async {
    var configurationJson = data['configuration'];
    PaymentConfiguration configObj = PaymentConfiguration.fromJsonString(
        configurationJson);
    _payObject = ShellApplePay(configObj);
  }

  static Future<void> googlePayRequest(Map data) async {
    var paymentItemsMap = data['paymentItems'];
    List<PaymentItem> paymentItemsEntity = List.of(
        (paymentItemsMap as List).map((e) =>
            PaymentItem(amount: e['amount'],
                label: e['label'],
                status: PaymentItemStatus.final_price)));

    if (_payObject == null) {
      throw Exception(
          'Google Pay Service must be initialized before pay request');
    }

    bool canPay = await (_payObject as ShellGooglePay).userCanPay();

    if (canPay) {
      try {
        var res = await (_payObject as ShellGooglePay).pay(paymentItemsEntity);
        print(res);
      } catch (ex) {
        if (ex is PlatformException) {
          if (ex.code == '10') {
            throw Exception(
                "This merchant is currently unable to accept payments using this payment method. Try a different payment method.");
          }
        } else {
          print(ex);
        }
      }
    } else {
      print('cannot pay');
    }
  }

  static Future<void> applePayRequest(Map data) async {
    var paymentItemsMap = data['paymentItems'];
    List<PaymentItem> paymentItemsEntity = List.of(
        (paymentItemsMap as List).map((e) =>
            PaymentItem(amount: e['amount'], label: e['label'])));

    if (_payObject == null) {
      throw Exception(
          'Apple Pay Service must be initialized before pay request');
    }

    bool canPay = await (_payObject as ShellApplePay).userCanPay();

    if (canPay) {
      var res = await (_payObject as ShellApplePay).pay(paymentItemsEntity);
      print(res);
    } else {
      print('cannot pay');
    }
  }

  static Future<void> setAccelerometerEvent(Map data,
      PlatformJavaScriptReplyProxy jsResponseProxy) async {
    BridgeEvent bridgeEvent =
    await createBridgeEventFromMap(data, jsResponseProxy);
    await addListener(data, jsResponseProxy);

    accelerometerEventStream(samplingPeriod: SensorInterval.normalInterval)
        .listen((event) async {
      await BridgeEvent.dispatchEventsByName(bridgeEvent.eventName,
          {'x': '${event.x}', 'y': '${event.y}', 'z': '${event.z}'});
    }, onError: (error) {
      print('Error in \'accelerometer event\' has appeared:$error');
    });
  }

  static Future<void> setMagnetometerEvent(Map data,
      PlatformJavaScriptReplyProxy jsResponseProxy) async {
    BridgeEvent bridgeEvent =
    await createBridgeEventFromMap(data, jsResponseProxy);
    await addListener(data, jsResponseProxy);

    magnetometerEventStream(samplingPeriod: SensorInterval.normalInterval)
        .listen((event) async {
      await BridgeEvent.dispatchEventsByName(bridgeEvent.eventName,
          {'x': '${event.x}', 'y': '${event.y}', 'z': '${event.z}'});
    }, onError: (error) {
      print('Error in \'magnetometer event\' has appeared:$error');
    });
  }

  static Future<void> setGyroscopeEvent(Map data,
      PlatformJavaScriptReplyProxy jsResponseProxy) async {
    BridgeEvent bridgeEvent =
    await createBridgeEventFromMap(data, jsResponseProxy);
    await addListener(data, jsResponseProxy);

    gyroscopeEventStream(samplingPeriod: SensorInterval.normalInterval).listen(
            (event) async {
          await BridgeEvent.dispatchEventsByName(bridgeEvent.eventName,
              {'x': '${event.x}', 'y': '${event.y}', 'z': '${event.z}'});
        }, onError: (error) {
      print('Error in \'gyroscope event\' has appeared');
    });
  }

  static Future<void> setUserAccelerometerEvent(Map data,
      PlatformJavaScriptReplyProxy jsResponseProxy) async {
    BridgeEvent bridgeEvent =
    await createBridgeEventFromMap(data, jsResponseProxy);
    await addListener(data, jsResponseProxy);

    userAccelerometerEventStream(samplingPeriod: SensorInterval.normalInterval)
        .listen((event) async {
      await BridgeEvent.dispatchEventsByName(bridgeEvent.eventName,
          {'x': '${event.x}', 'y': '${event.y}', 'z': '${event.z}'});
    }, onError: (error) {
      print('Error in \'gyroscope event\' has appeared');
    });
  }

  static Future<void> onMessage(Map message) async {
    PushNotificationMessage notification = PushNotificationMessage();

    if (io.Platform.isIOS) {
      Map pushData = message['aps']['alert'];
      notification.title = pushData['title'];
      notification.body = pushData['body'];
    } else if (io.Platform.isAndroid) {
      notification.title = message['android-content-title'];
      notification.body = message['message'];
    }

    var headers = await createHeadersForOnTapPushAction(message);

    var notificationMessage = MessageNotification(
      id: 0,
      title: notification.title,
      body: notification.body,
      headers: headers,
    );

    showSimpleNotification(
      notificationMessage,
      key: Key('same_key'),
      slideDismissDirection: DismissDirection.up,
      contentPadding: EdgeInsets.zero,
      background: Color.fromRGBO(0, 0, 0, 0.0),
      foreground: Color.fromRGBO(0, 0, 0, 0.0),
      elevation: 0.0,
    );
  }

  static Future<void> dispatchTapOnPushEvent(Map headers) async {
    if (BridgeEvent.getEventsByName('TAP_PUSH_ACTION') != null) {
      await BridgeEvent.dispatchEventsByName(
          'TAP_PUSH_ACTION', {'data': headers});
    } else {
      onTapEventInitializeController.stream.listen((event) async {
        if (event) {
          await Future.delayed(Duration(milliseconds: 500));

          if (BridgeEvent.getEventsByName('TAP_PUSH_ACTION') != null) {
            await BridgeEvent.dispatchEventsByName('TAP_PUSH_ACTION', {
              'data': io.Platform.isIOS
                  ? ShellInitializer.waitingInitializationData
                  : headers
            });
            await onTapEventInitializeController.close();
          }
        }
      });
    }
  }

  static Future<void> alertUnsupportedPlatform(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Unsupported for this platform'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Signing in with an Apple ID is not supported for this platform.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> onTapAndroid(NotificationResponse? response) async {
    if (response != null && response.payload != null) {
      Map map = jsonDecode(response.payload!);

      var headers = await createHeadersForOnTapPushAction(map);

      await dispatchTapOnPushEvent(headers);
    }

    print(
        'onTapAndroid section called. bridge_ui_builder_functions.dart file.');
  }

  static Future<void> onTapIOS({Map? data}) async {
    if (data != null) {
      var map = data;

      if (data.containsKey('payload')) {
        map = jsonDecode(data['payload']);
      }

      var headers = await createHeadersForOnTapPushAction(map);

      if (ShellInitializer.bridgeInitialized) {
        await dispatchTapOnPushEvent(headers);
      } else {
        ShellInitializer.waitingInitializationData = headers;
        ShellInitializer.initController.stream.listen((event) async {
          await dispatchTapOnPushEvent(
              ShellInitializer.waitingInitializationData!);
        });
      }
    }
    print(
        'onTapIOS section called. bridge_ui_builder_functions.dart file, 313 line');
  }
}

@pragma('vm:entry-point')
Future<void> onTapAndroidBackground(RemoteMessage response) async {
  print(
      'onTapAndroidBackground section called. bridge_ui_builder_functions.dart file.');
}
