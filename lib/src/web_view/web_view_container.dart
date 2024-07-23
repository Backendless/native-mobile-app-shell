import 'dart:io' as io;
import '../web_view/build_child_web_view.dart';

import '../bridge/bridge_event.dart';
import '../bridge/bridge_manager.dart';
import '../utils/geo_controller.dart';
import '/configurator.dart';
import '../bridge/bridge.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bridge/bridge_ui_builder_functions.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewContainer extends StatefulWidget {
  final syncPath;

  WebViewContainer(this.syncPath);

  @override
  _WebViewContainerState createState() => _WebViewContainerState(syncPath);
}

class _WebViewContainerState extends State<WebViewContainer>
    with WidgetsBindingObserver {
  final _key = UniqueKey();

  String? syncPath;

  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions? options;
  Bridge? manager;
  _WebViewContainerState(this.syncPath);

  @override
  void initState() {
    super.initState();
    options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        allowUniversalAccessFromFileURLs: true,
        allowFileAccessFromFileURLs: true,
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
        javaScriptCanOpenWindowsAutomatically: true,
        javaScriptEnabled: true,
        preferredContentMode: UserPreferredContentMode.MOBILE,
        useOnLoadResource: true,
      ),
      android: AndroidInAppWebViewOptions(
        mixedContentMode: AndroidMixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
        useHybridComposition: true,
        allowFileAccess: true,
        allowContentAccess: true,
        geolocationEnabled: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
        allowsPictureInPictureMediaPlayback: true,
        isPagingEnabled: true,
        disallowOverScroll: true,
      ),
    );

    WidgetsBinding.instance.addObserver(this);
    _configureWebView();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    BridgeManager.currentState = state;

    if (BridgeEvent.getEventsByName('onAppResumed') != null &&
        state == AppLifecycleState.resumed) {
      BridgeEvent.dispatchEventsByName('onAppResumed', {});
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: Color(0xFFECEAE4),
        resizeToAvoidBottomInset: false,
        body: io.Platform.isAndroid
            ? SafeArea(
                child: this.buildBodyForBuild(),
                top: false,
              )
            : buildBodyForBuild(),
      );
    } catch (ex) {
      print('crush');
      setState(() {
        print('reload web_view_container.dart, L93. catch block');
      });
      return Container();
    }
  }

  Future<bool> _exitApp(BuildContext context) async {
    if (await webViewController!.canGoBack()) {
      print('onwill goback');
      webViewController!.goBack();
      return Future.value(false);
    } else {
      //await SystemNavigator.pop();
      return Future.value(true);
    }
  }

  Future setBridge(BuildContext context) async {
    if (!io.Platform.isAndroid ||
        await AndroidWebViewFeature.isFeatureSupported(
            AndroidWebViewFeature.WEB_MESSAGE_LISTENER)) {
      await manager!.addWebMessageListener(context);
    }
  }

  Future<void> _handleCreateWindow(
      BuildContext context, String childUrl) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => buildChildWebView(context, childUrl)));
  }

  void _configureWebView() {
    if (AppConfigurator.USE_GEOLOCATION) GeoController.geoInit();

    if (AppConfigurator.REGISTER_FOR_PUSH_NOTIFICATIONS_ON_RUN) {
      BridgeUIBuilderFunctions.registerForPushNotifications();
    }
  }

  Future<void> requestPermission() async {
    Map<Permission, PermissionStatus> statuses =
        await [Permission.location].request();
  }

  buildBodyForBuild() {
    return WillPopScope(
      onWillPop: () => _exitApp(context),
      child: InAppWebView(
        key: _key,
        initialOptions: options,
        onWebViewCreated: (InAppWebViewController controller) async {
          webViewController = controller;
          manager = Bridge(controller: webViewController!);
          await setBridge(context);

          await controller.loadFile(assetFilePath: syncPath!);
        },
        onCloseWindow: (controller) => print('closed window'),
        androidOnPermissionRequest: (InAppWebViewController controller,
            String origin, List<String> resources) async {
          return PermissionRequestResponse(
              resources: resources,
              action: PermissionRequestResponseAction.GRANT);
        },
        androidOnGeolocationPermissionsShowPrompt:
            (InAppWebViewController controller, String origin) async {
          await requestPermission();
          bool? result = await showDialog<bool>(
            context: context,
            barrierDismissible: false, // user must tap button!
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Allow access location $origin'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      Text('Allow access location $origin'),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('Allow'),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                  TextButton(
                    child: Text('Denied'),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),
                ],
              );
            },
          );
          if (result != null && result) {
            return Future.value(GeolocationPermissionShowPromptResponse(
                origin: origin, allow: true, retain: true));
          } else {
            return Future.value(GeolocationPermissionShowPromptResponse(
                origin: origin, allow: false, retain: false));
          }
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          var uri = navigationAction.request.url!;

          if (![
            "http",
            "https",
            "file",
            "chrome",
            "data",
            "javascript",
            "about"
          ].contains(uri.scheme)) {
            if (await canLaunchUrl(uri)) {
              // Launch the App
              await launchUrl(
                uri,
              );
              // and cancel the request
              return NavigationActionPolicy.CANCEL;
            }
          }

          return NavigationActionPolicy.ALLOW;
        },
        onConsoleMessage: (controller, consoleMessage) {
          print(consoleMessage);
        },
        onCreateWindow: (controller, action) async {
          await _handleCreateWindow(context, action.request.url.toString());
          return true;
        },
        onLoadStart: (InAppWebViewController controller, url) {},
        onLoadError: (controller, url, code, message) {
          print('code: $code\n'
              'url: $url\n'
              'message: $message');
          showDialog<String>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              titlePadding: EdgeInsets.all(8.0),
              insetPadding: EdgeInsets.symmetric(horizontal: 8.0),
              contentPadding: EdgeInsets.all(8.0),
              title: Text('Error'),
              content: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      children: [
                        Text(
                          'code:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          code.toString(),
                        ),
                      ],
                    ),
                    Wrap(
                      children: [
                        Text(
                          'message:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          message,
                          maxLines: 10,
                          softWrap: true,
                        ),
                        Text(
                          '\nTry restarting the app',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Ok'),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
              scrollable: true,
            ),
          );
        },
        onReceivedServerTrustAuthRequest: (controller, challenge) async {
          print('SERVER_AUTH_REQUEST: \n$challenge');
          return ServerTrustAuthResponse(
              action: ServerTrustAuthResponseAction.PROCEED);
        },
        onReceivedClientCertRequest: (controller, challenge) async {
          print('CLIENT_CERT_REQUEST: \n$challenge.protectionSpace');
          return ClientCertResponse(
              certificatePath: '', action: ClientCertResponseAction.PROCEED);
        },
        onReceivedHttpAuthRequest: (controller, challenge) async {
          print('HTTP_AUTH_REQUEST: \n$challenge');
          return HttpAuthResponse(action: HttpAuthResponseAction.PROCEED);
        },
        onLoadHttpError: (controller, url, code, message) {
          print('code: $code\n'
              'url: $url\n'
              'message: $message');
        },
        onLoadStop: (controller, url) async {
          print('load stopped: $url');
          print('progress: ' + (await controller.getProgress()).toString());
        },
        onLoadResource: (controller, loadedResources) {
          print('type: $loadedResources');
        },
        onProgressChanged: (controller, progress) {
          print('progress: $progress %');
        },
        iosOnNavigationResponse: (controller, response) async {
          print(response.response);
          return null;
        },
        onDownloadStart: (controller, url) {
          print('Downloading started with url: $url');
        },
        onPrint: (controller, url) {
          print('onPrint event: $url');
        },
        iosOnWebContentProcessDidTerminate: (controller) async {
          print('reload IOS');
          await controller.reload();
        },
        androidOnRenderProcessGone: (controller, detail) async {
          print('reload Android');
          await controller.reload();
        },
      ),
    );
  }
}
