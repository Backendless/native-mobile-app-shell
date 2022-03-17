///This class is used to configure your application.
///For example, to enable geolocation support or enable push notifications only upon request from the UI Builder application.
class AppConfigurator {
  static const bool REGISTER_FOR_PUSH_NOTIFICATIONS_ON_RUN = false;
  static const bool USE_GEOLOCATION = false;

  //TODO add your permissions here:
  static Future initializePermissions() async {
    //await Permission.storage.request();
  }
}
