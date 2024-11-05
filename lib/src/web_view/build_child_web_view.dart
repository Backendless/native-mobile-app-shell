import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

Widget buildChildWebView(BuildContext context, String childUrl) {
  return Scaffold(
    resizeToAvoidBottomInset: false,
    appBar: AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      backgroundColor: Colors.greenAccent[100],
      toolbarHeight: 30,
    ),
    body: InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri(childUrl),
      ),
      initialSettings: InAppWebViewSettings(
          useShouldOverrideUrlLoading: true,
          disableHorizontalScroll: true,
          userAgent: 'random'),
      onLoadStop: (controller, url) async {
        print('!!! called onLoadStop');
        print("AUTH_WEBVIEW: $url");
      },
    ),
  );
}
