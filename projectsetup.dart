#!/usr/bin/env dart

import 'dart:io';

void main(List<String> args) async {
  File pubspec = File('config_sources/config_pubspec.yaml');
  File appBuildGradle = File('config_sources/config_build.gradle');
  File debugManifest = File('config_sources/config_debugAndroidManifest.xml');
  File mainManifest = File('config_sources/config_mainAndroidManifest.xml');
  File profileManifest =
      File('config_sources/config_profileAndroidManifest.xml');
  File mainActivity = File(
      'config_sources/com/backendless/native_app_shell_mobile/config_MainActivity.kt');
  File infoPlist = File('config_sources/config_Info.plist');
  File projectPbxproj = File('config_sources/config_project.pbxproj');
  File googleServices = File('android/app/google-services.json');
  final regExp = RegExp(r'[\^$*.\[\]{}()?\-"!@#%&/\,><:;~`+='
      "'"
      ']');

  String? appName;
  String? packageId;

  try {
    appName = args[0];
    packageId = args[1];
  } catch (ex) {}

  if ((appName?.isEmpty ?? true) || (packageId?.isEmpty ?? true)) {
    print('''
      Unable to run the project setup script. Make sure the command includes two additional arguments as shown below:
    
      dart run ./projectsetup.dart AppName com.example.myApp
      
      where:
      AppName            - name of your application (without any spaces or special characters(excluding the underscore))
      com.example.myApp - application namespace. Use the dot-notation in the format of com.companyName.AppName
        ''');

    return;
  }

  if (appName!.contains(regExp)) {
    print('AppName must not contain special symbols(excluding the underscore)');

    return;
  }

  if (!packageId!.startsWith('com')) {
    print('packageId(second parameter) should start with \'com\'\n'
        'example:\n'
        'dart run ./projectsetup.dart AppName com.example.myApp');

    return;
  }

  print('Application Name: $appName');
  print('PackageId: $packageId');

  // REPLACE APP_NAME IN pubspec.yaml
  String pubspecStr = await pubspec.readAsString();
  pubspecStr = pubspecStr.replaceFirst('native_app_shell_mobile', appName);

  // RECEIVE ALL CUSTOM_COMPONENTS IN assets/ui_builder_app/components/custom/

  var directories =
      await getNestedDirectory('assets/ui_builder_app/components/custom/');
  String customComponentsLinks = '';

  if (directories.isNotEmpty) {
    for (var dir in directories) {
      if (dir.contains('\\')) {
        dir = dir.replaceAll('\\', '/');
      }
      customComponentsLinks += '\n    - $dir/';
    }
    print('Custom components links: $customComponentsLinks');
  } else {
    print('Custom components links:\n\tN/A');
  }

  // ADD CUSTOM_COMPONENTS LINKS IN pubspec.yaml
  pubspecStr =
      pubspecStr.replaceFirst('modules/', 'modules/$customComponentsLinks');

  // RECEIVE ALL CUSTOM LAYOUTS IN assets/ui_builder_app/layouts/
  directories = await getNestedDirectory('assets/ui_builder_app/layouts');

  var customLayoutsLinks = '';
  if (directories.isNotEmpty) {
    for (var dir in directories) {
      if (dir.contains('\\')) {
        dir = dir.replaceAll('\\', '/');
      }
      customLayoutsLinks += '\n    - $dir/';
    }
    print('Custom layouts links:$customLayoutsLinks');
  } else {
    print('Custom layouts links:\n\tN/A');
  }

  // ADD CUSTOM LAYOUTS IN assets/ui_builder_app/layouts/
  pubspecStr =
      pubspecStr.replaceFirst('modules/', 'modules/$customLayoutsLinks');

  // RECEIVE ALL CUSTOM STYLES AND IMAGES IN assets/ui_builder_app/styles/
  var directory = Directory('assets/ui_builder_app/styles/');
  var customStylesAndImagesFiles =
      await directory.list(recursive: true).toList();

  String customStylesLinks = '';

  for (var style in customStylesAndImagesFiles) {
    String stringifiedStyle = style.path;
    if (stringifiedStyle.contains('\\')) {
      stringifiedStyle = stringifiedStyle.replaceAll('\\', '/');
    }
    customStylesLinks += '        - asset: $stringifiedStyle\n';
  }

  print('STYLES LINKS:\n$customStylesLinks');
  // ADD CUSTOM STYLES LINKS IN pubspec.yaml
  pubspecStr = pubspecStr.replaceFirst(
      '      fonts:', '      fonts:\n$customStylesLinks');

  // SAVE CHANGES TO pubspec.yaml
  File newPubspec = File('pubspec.yaml');
  await newPubspec.writeAsString(pubspecStr);

  // _______________-________________-____________-______

  // WORKING WITH ANDROID DIRECTORY

  // REPLACE PACKAGE_ID IN build.gradle file
  String gradleStr = await appBuildGradle.readAsString();
  gradleStr =
      gradleStr.replaceFirst('com.backendless.native_app_shell', packageId);

  // SAVING build.gradle FILE
  File newBuildGradle = File('android/app/build.gradle');
  await newBuildGradle.writeAsString(gradleStr);

  // REPLACE PACKAGE_ID IN android/app/src/debug/AndroidManifest.xml
  String debugManifestStr = await debugManifest.readAsString();
  debugManifestStr = debugManifestStr.replaceFirst(
      'com.backendless.native_app_shell', packageId);

  // SAVING android/app/src/debug/AndroidManifest.xml FILE
  File newDebugManifest = File('android/app/src/debug/AndroidManifest.xml');
  await newDebugManifest.writeAsString(debugManifestStr);

  // REPLACE PACKAGE_ID IN android/app/src/main/AndroidManifest.xml
  String mainManifestStr = await mainManifest.readAsString();
  mainManifestStr = mainManifestStr.replaceFirst(
      'com.backendless.native_app_shell', packageId);

  // REPLACE APP_NAME IN android/app/src/main/AndroidManifest.xml
  mainManifestStr = mainManifestStr.replaceFirst('native app shell', appName);

  // SAVING PACKAGE_ID and APP_NAME IN android/app/src/main/AndroidManifest.xml FILE
  File newMainManifest = File('android/app/src/main/AndroidManifest.xml');
  await newMainManifest.writeAsString(mainManifestStr);

  // REPLACE PACKAGE_ID IN android/app/src/profile/AndroidManifest.xml
  String profileManifestStr = await profileManifest.readAsString();
  profileManifestStr = profileManifestStr.replaceFirst(
      'com.backendless.native_app_shell', packageId);

  // SAVING PACKAGE_ID IN android/app/src/profile/AndroidManifest.xml
  File newProfileManifest = File('android/app/src/profile/AndroidManifest.xml');
  await newProfileManifest.writeAsString(profileManifestStr);

  // CHANGING DIRECTORIES FOR .MainActivity file

  // REMOVE OLD DIRECTORY
  Directory oldComDirectory = Directory('android/app/src/main/kotlin/com/');
  await oldComDirectory.delete(recursive: true);

  // SPLIT PACKAGE_ID BY DOTS TO CREATE ANOTHER DIRECTORIES
  List<String> splitPackageId = packageId.split('.');
  String currentPath = 'android/app/src/main/kotlin/';

  for (String item in splitPackageId) {
    currentPath += '$item/';
  }

  await Directory(currentPath).create(recursive: true);

  // REPLACE PACKAGE_ID in MainActivity file
  String mainActivityStr = await mainActivity.readAsString();
  mainActivityStr = mainActivityStr.replaceFirst(
      'com.backendless.native_app_shell', packageId);

  // SAVING PACKAGE_ID IN android/app/src/main/com.backendless.native_app_shell_mobile
  File newMainActivity = File('${currentPath}MainActivity.kt');
  await newMainActivity.writeAsString(mainActivityStr);

  // WORKING WITH IOS DIRECTORY

  // REPLACE BUNDLE_ID WITH PACKAGE_ID IN ios/Runner/Info.plist
  String infoPlistStr = await infoPlist.readAsString();
  String iosStylePackageId = packageId.replaceAll('_', '-');
  infoPlistStr = infoPlistStr.replaceFirst(
      'com.backendless.native-app-shell', iosStylePackageId);

  // REPLACE APP_NAME IN ios/Runner/Info.plist
  infoPlistStr = infoPlistStr.replaceFirst('native app shell', appName);

  // SAVING Info.plist IN ios/Runner/Info.plist
  File newInfoPlist = File('ios/Runner/Info.plist');
  await newInfoPlist.writeAsString(infoPlistStr);

  // REPLACE BUNDLE_ID WITH PACKAGE_ID in ios/Runner.xcodeproj/project.pbxproj
  String projectPbxprojStr = await projectPbxproj.readAsString();
  projectPbxprojStr = projectPbxprojStr.replaceAll(
      'com.backendless.native-app-shell', iosStylePackageId);

  // SAVING project.pbxproj in ios/Runner.xcodeproj/project.pbxproj
  File newProjectPbxproj = File('ios/Runner.xcodeproj/project.pbxproj');
  await newProjectPbxproj.writeAsString(projectPbxprojStr);

  // CHECKING google-services.json in android/app/google-services.json
  String googleServicesStr = await googleServices.readAsString();

  if (googleServicesStr.contains('com.backendless.native_app_shell')) {
    googleServicesStr = googleServicesStr.replaceFirst(
        'com.backendless.native_app_shell', packageId);
    var nameFromPackageId = iosStylePackageId.split('.').last;
    googleServicesStr =
        googleServicesStr.replaceAll('native-app-shell', nameFromPackageId);

    await googleServices.writeAsString(googleServicesStr);

    print(
        'IMPORTANT:\nThe script has updated google-services.json located in the ./android/app directory. If you plan on using Android push notifications, it is important to update that file. Please follow the instructions from the Backendless documentation located at: https://backendless.com/docs/uibuilder/ui_configuring_flutter_shell.html#android-push-notifications-configuration');
  }

  print('\nDONE');
}

Future<List<String>> getNestedDirectory(String path) async {
  var dir = Directory(path);
  List<String> result = List.empty(growable: true);

  if (await dir.exists()) {
    var directories = await dir.list().toList();

    for (var folder in directories) {
      if (folder is Directory) {
        result.add(folder.path);
        var nested = await getNestedDirectory(folder.path);
        if (nested.isNotEmpty) {
          result.addAll(nested);
        }
      }
    }
  }

  return result;
}
