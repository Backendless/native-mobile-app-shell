import 'dart:io';
import 'src/utils/initializer.dart';
import 'src/web_view/logic_builder.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initApp(pathToSettings: 'assets/ui_builder_app/settings.json');

  //TODO add your permissions here:
  //Permission.storage.request();

  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  runApp(StartPageStateless());
}
