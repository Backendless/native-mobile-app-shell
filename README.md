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
```dart
flutter clean
flutter pub get
```

If you want to use some custom fonts or icons, you need to declare that in your ```pubspec.yaml``` file.
You can find out how to do this [here](https://flutter.dev/docs/cookbook/design/fonts).

After that, your application will be ready to use.

If you have a question, you can ask it here:
- [Our support forum](https://support.backendless.com)
- [Our slack](http://slack.backendless.com)
