# native_app_shell

Native App Shell for UI Builder applications

## Getting Started

This application is a native shell for your application built with the UI Builder in the Backendless Console.

- [How to prepare your IDE](https://flutter.dev/docs/get-started/install/macos)

Once your IDE is ready to use, you need to click the 'Publish the container' button
in the 'Publish' section of the UI Builder.
Then, you need to go to the folder with the application, and create an archive by clicking the 'Zip Directory' button.
Download this archive, and place the files from there in the ```assets/ui_builder_app``` folder.
We strongly discourage creating additional folders inside ```ui_builder_app```.
After completing these steps, use the following commands:
```
flutter clean
flutter pub get
```

If you want to use some custom fonts or icons, you need to declare that in your ```pubspec.yaml``` file.
You can find out how to do this [here](https://flutter.dev/docs/cookbook/design/fonts).

After that, your application will be ready to use.

Here's what should be done to build it for release:
1. Change the app name as you'd like to have it in the app stores.
2. Change bundle id from com.backendless.native_app_shell to one that would match your identity.
3. For iOS, create a team at https://developer.apple.com
4. For Android, create a team at https://play.google.com/console/developers.
5. Add certificates for push notifications:
   5.1. For Android - add google-services.json to the android/app directory 
   5.2. For iOS, create a profile and PRODUCTION certificate in your Apple Developer account and add to xCode.
6. Add a launch screen for iOS in xCode in Runner > Runner > LaunchScreen (the source file is in Runner > Runner > Assets)
7. Add a launch screen for Android (android > app  src > main > res)
8. Add app icon for iOS (ios > Assets.xassets > AppIcon.appiconset). Alternatively it can be done in xCode.
9. Add app icon for Android (android > app > src > main > res)
10. Add keystore for Android release. Using the following command you generate jks file:
    ```
    keytool -genkeypair -alias upload -keyalg RSA -keysize 2048 -validity 9125 -keystore keystore.jks
    ```
11. Add key.properties file to android > app. The file should have the password and file location for the previous step.
12. Add the following code to android > app > build.gradle:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('app/key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```
 Add the following code/configuration to the same section as above:
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

If you have a question, you can ask it here:
- [Our support forum](https://support.backendless.com)
- [Our slack](http://slack.backendless.com)
