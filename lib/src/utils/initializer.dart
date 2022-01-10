import 'coder.dart';
import 'package:backendless_sdk/backendless_sdk.dart';
import 'package:overlay_support/overlay_support.dart';

Future<void> initApp({required String pathToSettings}) async {
  kNotificationSlideDuration = const Duration(milliseconds: 500);
  kNotificationDuration = const Duration(milliseconds: 1500);

  final initData = await Coder.readJson(path: pathToSettings);

  if (initData['apiDomain'] != null) {
    await Backendless.initApp(
      customDomain: initData['apiDomain'],
    );
    return;
  }

  await Backendless.initApp(
      applicationId: initData['appId'],
      iosApiKey: initData['apiKey'],
      androidApiKey: initData['apiKey']);

  await Backendless.setUrl(initData['serverURL']);
}
