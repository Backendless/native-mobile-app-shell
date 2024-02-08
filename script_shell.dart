#!/usr/bin/env dart

import 'dart:io';

void main(List<String>? args) async {
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

  if (args?.isEmpty ?? true) {
    print(
        'Please set application name like a first parameter and package name as second parameter. Example:\n'
        './script_shell.dart MyNewApplication com.example.myNewApplication');
    return;
  }

  String appName = args![0];
  String packageId = args[1];
  print('APPNAME: $appName');
  print('PACKAGE_ID: $packageId');

  // REPLACE APP_NAME IN pubspec.yaml
  String pubspecStr = await pubspec.readAsString();
  pubspecStr = pubspecStr.replaceFirst('native_app_shell_mobile', appName);

  // RECEIVE ALL CUSTOM_COMPONENTS IN assets/ui_builder_app/components/custom/

  Directory directory = Directory('assets/ui_builder_app/components/custom/');
  var customComponentsDirectories = await directory.list().toList();
  String customComponentsLinks = '';

  for (var folder in customComponentsDirectories) {
    customComponentsLinks += '    - ${folder.path}\n';
  }
  print('FOLDER LINKS:\n$customComponentsLinks');

  // ADD CUSTOM_COMPONENTS LINKS IN pubspec.yaml
  pubspecStr =
      pubspecStr.replaceFirst('modules/', 'modules/\n$customComponentsLinks');

  // RECEIVE ALL CUSTOM STYLES AND IMAGES IN assets/ui_builder_app/styles/
  directory = Directory('assets/ui_builder_app/styles/');
  var customStylesAndImagesFiles =
      await directory.list(recursive: true).toList();

  String customStylesLinks = '';

  for (var style in customStylesAndImagesFiles) {
    customStylesLinks += '        - asset: ${style.path}\n';
  }

  print('STYLES LINKS:\n$customStylesLinks');
  // ADD CUSTOM STYLES LINKS IN pubspec.yaml
  pubspecStr = pubspecStr.replaceFirst(
      '      fonts:', '      fonts:\n$customStylesLinks');
  print(pubspecStr);

  // SAVE CHANGES TO pubspec.yaml
  File newPubspec = File('pubspec.yaml');
  await newPubspec.writeAsString(pubspecStr);

  // _______________-________________-____________--_____

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

  // SAVING PACKAGE_ID IN android/app/src/main/AndroidManifest.xml FILE
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
  oldComDirectory.delete(recursive: true);

  // SPLIT PACKAGE_ID BY DOTS TO CREATE ANOTHER DIRECTORIES
  List<String> splitPackageId = packageId.split('.');
  String currentPath = 'android/app/src/main/kotlin/';

  for (String item in splitPackageId) {
    currentPath += '$item/';
  }

  Directory newDirectoryForMainActivity =
      await Directory(currentPath).create(recursive: true);

  // REPLACE PACKAGE_ID in MainActivity file
  String mainActivityStr = await mainActivity.readAsString();
  mainActivityStr = mainActivityStr.replaceFirst(
      'com.backendless.native_app_shell', packageId);

  // SAVING PACKAGE_ID IN android/app/src/main/com.backendless.native_app_shell_mobile
  File newMainActivity = File('${currentPath}MainActivity.kt');
  await newMainActivity.writeAsString(mainActivityStr);

  // WORKING WITH IOS DIRECTORY

  // REPLACE BUNDLE_ID WITH PACKAGE_ID in ios/Runner/Info.plist
  String infoPlistStr = await infoPlist.readAsString();
  String iosStylePackageId = packageId.replaceAll('_', '-');
  infoPlistStr = infoPlistStr.replaceFirst(
      'com.backendless.native-app-shell', iosStylePackageId);

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

  print('DONE');
}
