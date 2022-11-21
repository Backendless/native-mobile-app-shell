import 'dart:io';
import '/configurator.dart';
import 'src/utils/initializer.dart';
import 'package:flutter/material.dart';
import 'src/web_view/logic_builder.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ShellInitializer.initApp(
      pathToSettings: 'assets/ui_builder_app/settings.json');

  //Add your required permissions into this method
  await AppConfigurator.initializePermissions();

  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
    //await Firebase.initializeApp();
  }

  runApp(StartPageStateless());
}
