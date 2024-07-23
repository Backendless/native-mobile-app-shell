# Overview
This repository contains the project to build a native app shell for your UI Builder application. The native shell is a Flutter project that can be compiled to run natively on Android and iOS devices. It includes support for the functionality available natively on devices and provides a bridge between a UI Builder application and native mobile features. Using the native app shell, you can achieve the following capabilities:
* Run your UI Builder app in a native mobile container
* Register your app to receive push notifications
* Request user permissions for features available natively, for instance to obtain the user's contact list
* Enable bidirectional communication between the native code and the code in a UI Builder app (even when built with Codeless)

## Setup
1. Prepare your IDE. [How to prepare your IDE](https://flutter.dev/docs/get-started/install/macos)
#### Note:
```diff
- The Java SDK version must be at least 11.
```
2. Fetch/get this project from github.
3. Navigate to UI Builder and click the `Publish the container` icon. Select a directory where the UI Container (i.e. your UI Builder app) will be published. It is recommended to select a subdirectory under the `/web` directory.
4. Switch to the `BACKEND` section of Backendless Console and navigate to the `Files` section. Locate the directory from step above and navigate into the directory. Create an archive by clicking the 'Zip Directory' button.
5. Download the created archive and place the files from it in the `assets/ui_builder_app` folder of the native app shell project. We strongly discourage creating additional folders inside the `ui_builder_app` directory.
6. After completing these steps, run the following commands in a command prompt window (make sure to switch to the root directory of this project):
   ```
   flutter clean
   flutter pub get
   ```

   6.1. If you want to use some custom fonts or icons, you need to declare that in your `pubspec.yaml` file.
        You can find out how to do this [here](https://flutter.dev/docs/cookbook/design/fonts).
   
   6.2. If you are using custom or reusable components, make sure they don't use custom styles/images etc. If they are used, indicate this in the `pubspec.yaml` file.:
     
      Add the following line to the assets of the `pubspec.yaml` file like this:
      <img width="600" alt="Screenshot 2022-12-27 at 14 50 50" src="https://user-images.githubusercontent.com/50683634/209670256-d577d89d-b1b3-4d93-9bec-0613b0627407.png">

      
### Important: 
```diff
- Flutter ignores all subfolders, so if there are subfolders, styles, etc., they must be specified.
```

7. For iOS, create a team at https://developer.apple.com and set Bundle Identifier [more details](https://docs.flutter.dev/deployment/ios):
<img width="888" alt="Screenshot 2022-02-14 at 02 19 23" src="https://user-images.githubusercontent.com/50683634/153781929-bfba9e13-deac-4482-b614-321722854bba.png">

After that, your application will be ready for testing.

## Build for Release
#### Note:
```diff
- The changes described below are specifically to build your app for release into the app store and google play.
- Before proceeding to this section of preparing your application, we recommend that you thoroughly test 
- the application in preparation for the release.
```
1. Change the app name here in your `pubspec.yaml` file: https://github.com/Backendless/native-mobile-app-shell/blob/master/pubspec.yaml#L1
   After this step, don't forget to change the package names in another part of the project:
   Make sure the package name in `AndroidManifest.xml` and `android/app/build.gradle` and `android/app/src/.../MainActivity.java` are the same. 
   Also check `ios/Runner/Info.plist` the value of `CFBundleName` for iOS versions.
2. Change the app name as you would like to have it in the app stores. This is done in the [app manifest for Android](https://github.com/Backendless/native-mobile-app-shell/blob/master/android/app/src/main/AndroidManifest.xml#L4) and xCode for iOS.
3. Change applicationId and package name for Android.

   https://github.com/Backendless/native-mobile-app-shell/blob/master/android/app/build.gradle#L38
   https://github.com/Backendless/native-mobile-app-shell/blob/master/android/app/src/main/AndroidManifest.xml#L2
4. Change Bundle Identifier and Display Name(The name of the application that will be displayed in the AppStore and on the desktop of the mobile device).
   This is can be done in xCode here: Runner - Runner(Targets) -> General. 
   <img width="857" alt="Screenshot 2022-01-18 at 11 59 57" src="https://user-images.githubusercontent.com/50683634/149915140-b0aa82fd-4a08-4b1e-9b51-67cc33496506.png">

5. For Android, create a team at https://play.google.com/console/developers.
6. Add certificates for push notifications:                                                 
   7.1. For Android - add `google-services.json` to the `android/app` directory                          
   7.2. For iOS, create a profile and a `PRODUCTION` certificate in your Apple Developer account and add to xCode.
7. Add a launch screen for iOS in xCode in `Runner > Runner > LaunchScreen` (the source file is in `Runner > Runner > Assets`)
   ![image](https://user-images.githubusercontent.com/50683634/149917290-d53d4328-b1a0-41c4-9b99-e55be437829c.png)

8. Add a launch screen for Android (`android > app  src > main > res > drawable && drawable-v21`)
9. Add app icon for iOS (`ios > Assets.xassets > AppIcon.appiconset`). Alternatively it can be done in xCode.
    ![image](https://user-images.githubusercontent.com/50683634/149918213-aff29c9f-f1e7-4bd3-acd9-5e8f8f3eb200.png)
    Icons can be generated here: https://appicon.co/
   
10. Add app icon for Android (`android > app > src > main > res > mipmap-xxx)`)

    <img height="400" alt="Screenshot 2022-01-18 at 11 59 57" src="https://user-images.githubusercontent.com/50683634/149917564-d0ccc93e-312f-4ad4-af89-e80f50bb3f73.png">

11. Add keystore for Android release. Using the following command you generate jks file:
    ```
    keytool -genkeypair -alias upload -keyalg RSA -keysize 2048 -validity 9125 -keystore keystore.jks
    ```
12. Add the `key.properties` file to `android > app`. The file should have the password and file location for the previous step.
13. Add the following code to `android > app > build.gradle`:
    ```
    def keystoreProperties = new Properties()
    def keystorePropertiesFile = rootProject.file('app/key.properties')
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
    }
    ```
14. Add the following code/configuration to the same section as above:
    ```gradle
    android {
    //some code
    ....
        signingConfigs {
            release {
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
                storePassword keystoreProperties['storePassword']
            }
        }
    
        buildTypes {
            release {
                signingConfig signingConfigs.release
    
                minifyEnabled true
                proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
            }
        }
    }
    ```
Additional information for iOS:
https://docs.flutter.dev/deployment/ios

Additional information for Android:
https://docs.flutter.dev/deployment/android

If you have some questions and suggestions to improve our product you can write here:
- [Our support forum](https://support.backendless.com)
- [Our slack](http://slack.backendless.com)
