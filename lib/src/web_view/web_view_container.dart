import 'dart:convert';
import 'dart:io' as io;
import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../web_view/build_child_web_view.dart';
import '../utils/geo_controller.dart';
import '../utils/initializer.dart';
import '/configurator.dart';
import '../bridge/bridge.dart';
import 'package:flutter/material.dart';
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

class _WebViewContainerState extends State<WebViewContainer> {
  final _key = UniqueKey();

  String? syncPath;
  String? initLink;

  InAppWebViewController? webViewController;
  InAppWebViewSettings? options;
  Bridge? manager;
  _WebViewContainerState(this.syncPath);

  @override
  void initState() {
    super.initState();
    options = InAppWebViewSettings(
      allowUniversalAccessFromFileURLs: true,
      allowFileAccessFromFileURLs: true,
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
      javaScriptCanOpenWindowsAutomatically: true,
      javaScriptEnabled: true,
      preferredContentMode: UserPreferredContentMode.MOBILE,
      useOnLoadResource: true,
      useOnDownloadStart: true,
      mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
      useHybridComposition: true,
      allowFileAccess: true,
      allowContentAccess: true,
      geolocationEnabled: true,
      allowsInlineMediaPlayback: true,
      allowsPictureInPictureMediaPlayback: true,
      isPagingEnabled: true,
      disallowOverScroll: true,
    );
    _configureWebView();
    initLinkURL();
  }

  Future<void> initLinkURL() async {
    final appLink = AppLinks();
    initLink = await appLink.getInitialLinkString();

    appLink.stringLinkStream.listen((link) {
      _openSpecificPage(fullLink: link);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // TODO: This method is general template with logic that implements opening page from Deep Link.
  // If you want to specify your own logic you need to rewrite this method.
  Future<void> _openSpecificPage({String? fullLink, String? query}) async {
    if (fullLink != null || query != null) {
      var url = (await webViewController!.getUrl()).toString();

      if (!url.endsWith('index.html')) {
        url = url.substring(0, url.indexOf('index.html') + 10);
      }
      var resultQuery = query;

      if (resultQuery == null) {
        resultQuery = fullLink!.substring(fullLink.indexOf('?'));
      }

      URLRequest urlRequest = URLRequest(url: WebUri(url + resultQuery));
      await webViewController!.loadUrl(urlRequest: urlRequest);
    }
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
            initialSettings: options,
            onWebViewCreated: (InAppWebViewController controller) async {
              webViewController = controller;
              manager = Bridge(controller: webViewController!);
              await setBridge(context);

              await controller.loadFile(assetFilePath: syncPath!);

              if (initLink != null) {
                await _openSpecificPage(fullLink: initLink);
                initLink = null;
              }
            },
            onPermissionRequest: (InAppWebViewController controller, PermissionRequest request) async {
              return PermissionResponse(
                  action: PermissionResponseAction.GRANT);
            },
            onGeolocationPermissionsShowPrompt:
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
            onReceivedError: (controller, url, error) {
              print('code: ${error.type.toValue()}\n'
                  'url: $url\n'
                  'message: ${error.description}');
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
                              error.type.toValue(),
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
                              error.description,
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
            onReceivedHttpError: (controller, url, error) {
              print('code: ${error.statusCode}\n'
                  'url: $url\n'
                  'message: ${error.reasonPhrase}');
            },
            onLoadStop: (controller, url) async {
              print('load stopped: $url');
              print('progress: ' + (await controller.getProgress()).toString());

              if (io.Platform.isAndroid) {
                if (url.toString().contains('.jpg') ||
                    url.toString().contains('png')) {
                  await controller.zoomBy(zoomFactor: 0.02);
                }
              }
            },
            onLoadResource: (controller, loadedResources) async {
              print('type: $loadedResources');
            },
            onProgressChanged: (controller, progress) {
              print('progress: $progress %');
            },
            onNavigationResponse: (controller, response) async {
              print(response.response);

              return NavigationResponseAction.ALLOW;
            },
            onDownloadStartRequest: (controller, req) async {
              print('Downloading started with url: ${req.url}');

              if (req.url.toString().contains('.pdf')) {
                if (io.Platform.isAndroid) {
                  await _handleOpenPdfView(context, req.url.toString());
                }
              }
            },
            onPrintRequest: (controller, url, jobController) async {
              print('onPrint event: $url');

              return true;
            },
            onWebContentProcessDidTerminate: (controller) async {
              print('reload IOS');
              await controller.reload();
            },
            onRenderProcessGone: (controller, detail) async {
              print('reload Android');
              await controller.reload();
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

  Future setBridge(BuildContext context) async {
    if (!io.Platform.isAndroid ||
        await WebViewFeature.isFeatureSupported(
            WebViewFeature.WEB_MESSAGE_LISTENER)) {
      await manager!.addWebMessageListener(context);
    }

    ShellInitializer.bridgeInitialized = true;

    if (ShellInitializer.launchDetails!.didNotificationLaunchApp) {
      print('LAUNCHED BY NOTIFICATION');

      String payload =
          ShellInitializer.launchDetails!.notificationResponse!.payload!;
      Map jsonPayload = jsonDecode(payload);

      await BridgeUIBuilderFunctions.dispatchTapOnPushEvent(jsonPayload);
    }

    if (ShellInitializer.initController.hasListener) {
      ShellInitializer.initController.add('initialized');
    }
  }

  Future<void> _handleCreateWindow(
      BuildContext context, String childUrl) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => buildChildWebView(context, childUrl)));
  }

  Future<void> _handleOpenPdfView(context, String url) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SfPdfViewer.network(url)),
    );
  }

  void _configureWebView() {
    if (AppConfigurator.USE_GEOLOCATION) GeoController.geoInit();

    if (AppConfigurator.REGISTER_FOR_PUSH_NOTIFICATIONS_ON_RUN) {
      BridgeUIBuilderFunctions.registerForPushNotifications();
    }

    if (io.Platform.isIOS) {
      ShellInitializer.platform
          .setMethodCallHandler((call) => nativeEventHandler(call));
    }
  }

  ///TODO(This feature is in develop now)
  Future<dynamic> nativeEventHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'TAP_PUSH_ACTION':
        print('TEST METHOD ON TAP PUSH');
        print(methodCall.arguments);

        ///TODO
        if (!io.Platform.isAndroid ||
            await WebViewFeature.isFeatureSupported(
                WebViewFeature.POST_WEB_MESSAGE)) {
          //BridgeEvent.dispatchEventsByName('onTapPushAction', {});
        } else {
          await BridgeUIBuilderFunctions.onTapIOS(
              data: methodCall.arguments as Map);
        }

        break;
      default:
        print('Just DEFAULT section');
    }
  }

  Future<void> requestPermission() async {
    Map<Permission, PermissionStatus> statuses =
        await [Permission.location].request();
  }
}
