import 'dart:io' as io;
import '/configurator.dart';
import '../bridge/bridge.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bridge/bridge_ui_builder_functions.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewContainer extends StatefulWidget {
  final syncPath;

  WebViewContainer(this.syncPath);

  @override
  _WebViewContainerState createState() => _WebViewContainerState(syncPath);
}

class _WebViewContainerState extends State<WebViewContainer> {
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

    _configureWebView();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: WillPopScope(
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
            androidOnPermissionRequest: (InAppWebViewController controller,
                String origin, List<String> resources) async {
              return PermissionRequestResponse(
                  resources: resources,
                  action: PermissionRequestResponseAction.GRANT);
            },
            androidOnGeolocationPermissionsShowPrompt:
                (InAppWebViewController controller, String origin) async {
              return GeolocationPermissionShowPromptResponse(
                  origin: origin, allow: true, retain: true);
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
                if (await canLaunch(uri.toString())) {
                  // Launch the App
                  await launch(
                    uri.toString(),
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
            },
            onDownloadStart: (controller, url) {
              print('Downloading started with url: $url');
            },
            onPrint: (controller, url) {
              print('onPrint event: $url');
            },
          ),
        ),
      ),
    );
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

  void _geoInit() async {
    LocationPermission permission = await Geolocator.checkPermission();
    await Geolocator.requestPermission();
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future setBridge(BuildContext context) async {
    if (!io.Platform.isAndroid ||
        await AndroidWebViewFeature.isFeatureSupported(
            AndroidWebViewFeature.WEB_MESSAGE_LISTENER)) {
      await manager!.addWebMessageListener(context);
    }
  }

  void _configureWebView() {
    if (AppConfigurator.USE_GEOLOCATION) _geoInit();

    if (AppConfigurator.REGISTER_FOR_PUSH_NOTIFICATIONS_ON_RUN) {
      BridgeUIBuilderFunctions.registerForPushNotifications();
    }
  }
}
