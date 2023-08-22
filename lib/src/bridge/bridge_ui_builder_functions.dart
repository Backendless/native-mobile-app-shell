import 'dart:io' as io;
import '../utils/contacts_controller.dart';
import 'bridge_event.dart';
import '../utils/geo_controller.dart';
import 'package:flutter/material.dart';
import '../utils/support_functions.dart';
import 'package:geolocator/geolocator.dart';
import 'package:audioplayers/audioplayers.dart';
import '../types/push_notification_message.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:backendless_sdk/backendless_sdk.dart';
import 'package:contacts_service/contacts_service.dart';
import '../push_notifications/message_notification.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class BridgeUIBuilderFunctions {
  static const GOOGLE_CLIENT_ID_IOS = 'xxxxxx.apps.googleusercontent.com';
  static const GOOGLE_CLIENT_ID_WEB = 'xxxxxx.apps.googleusercontent.com';

  static late LocationPermission permission;

  static Future<void> addListener(BridgeEvent event) async {
    if (event.isExist) throw Exception('Event with same id already exists');

    BridgeEvent.addToContainer(event);
  }

  static Future<bool> removeListener(String name, String id) async {
    return BridgeEvent.removeEvent(name, id);
  }

  static Future<dynamic> registerForPushNotifications(
      {List<String>? channels}) async {
    List<String> channelsList = [];

    if (channels != null)
      channelsList.addAll(channels);
    else
      channelsList.add('default');

    try {
      DateTime time = DateTime.now().add(const Duration(days: 15));
      return await Backendless.messaging
          .registerDevice(channelsList, time, onMessage);
    } catch (ex) {
      return ex;
    }
  }

  static Future<BackendlessUser?> socialLogin(
      String providerCode, BuildContext context,
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
          token = fbResult.accessToken!.token;
        } else {
          print(fbResult.status);
          print(fbResult.message);
        }
      }

      user = await Backendless.userService
          .loginWithOauth2(providerCode, token!, <String, String>{}, true);
      userId = user!.getUserId();

      if (io.Platform.isAndroid) {
        userToken = await Backendless.userService.getUserToken();
        user.setProperty('user-token', userToken);
      } else {
        userToken = user.getProperty('userToken');
        user.removeProperty('userToken');
        user.setProperty('user-token', userToken);
      }
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
              width: MediaQuery.of(context).size.width * 1.2,
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  Expanded(
                      child: InAppWebView(
                          initialUrlRequest: URLRequest(
                            url: Uri.parse(result!),
                          ),
                          initialOptions: InAppWebViewGroupOptions(
                            crossPlatform: InAppWebViewOptions(
                                useShouldOverrideUrlLoading: true,
                                disableHorizontalScroll: true,
                                cacheEnabled: true,
                                userAgent:
                                    'Mozilla/5.0 (iPhone; CPU iPhone OS 15_6_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.6 Mobile/15E148 Safari/604.1'
                                //providerCode != 'facebook' ? 'random' : '',
                                ),
                            android: AndroidInAppWebViewOptions(
                              useHybridComposition: true,
                              safeBrowsingEnabled: false,
                            ),
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
      user = BackendlessUser()..setProperty('objectId', userId);

      await Backendless.userService.setCurrentUser(user);
      await Backendless.userService.setUserToken(userToken!);

      user = await Backendless.userService.findById(userId!);
      user!.setProperty('user-token', userToken);
    }

    return user;
  }

  static Future<Position?> getCurrentLocation() async {
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

  static Future<List<Contact>?> getContactList() async {
    var contactsList = await ContactsController.getContactsList();

    return contactsList;
  }

  static void onMessage(Map<String, dynamic> message) async {
    AudioCache pushSound = AudioCache();
    pushSound.play('notification_sounds/push_sound.wav');
    PushNotificationMessage notification = PushNotificationMessage();

    if (io.Platform.isIOS) {
      Map pushData = message['aps']['alert'];
      notification.title = pushData['title'];
      notification.body = pushData['body'];
    } else if (io.Platform.isAndroid) {
      notification.title = message['android-content-title'];
      notification.body = message['message'];
    }

    var headers = await createHeadersForOnTapPushAction();

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

  static void dispatchTapOnPushEvent(Map headers) {
    if (BridgeEvent.getEventsByName('onTapPushAction') != null) {
      BridgeEvent.dispatchEventsByName('onTapPushAction', {'data': headers});
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
}
