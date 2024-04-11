import '../bridge/bridge_ui_builder_functions.dart';

final systemMethods = {
  'REMOVE_LISTENER': BridgeUIBuilderFunctions.removeListener,
  'GET_CURRENT_LOCATION': BridgeUIBuilderFunctions.getCurrentLocation,
  'GET_CONTACTS_LIST': BridgeUIBuilderFunctions.getContactsList,
  'CREATE_CONTACT': BridgeUIBuilderFunctions.createContact,
  'UPDATE_CONTACT': BridgeUIBuilderFunctions.updateContact,
  'SHARE_SHEET_REQUEST': BridgeUIBuilderFunctions.shareSheet,
  'REGISTER_DEVICE': BridgeUIBuilderFunctions.registerDevice,
  'UNREGISTER_DEVICE': BridgeUIBuilderFunctions.unregisterDevice,
  'GET_DEVICE_REGISTRATION': BridgeUIBuilderFunctions.getDeviceRegistrations,
  'SOCIAL_LOGIN': BridgeUIBuilderFunctions.socialLogin,
  'GET_RUNNING_ENV': BridgeUIBuilderFunctions.getRunningEnvironment,
  'GET_APP_INFO': BridgeUIBuilderFunctions.getAppInfo,
  'REQUEST_CAMERA_PERMISSIONS':
      BridgeUIBuilderFunctions.requestCameraPermissions,
  'GOOGLE_PAY_INIT' : BridgeUIBuilderFunctions.googlePayInit,
  'APPLE_PAY_INIT' : BridgeUIBuilderFunctions.applePayInit,
  'GOOGLE_PAY_REQUEST' : BridgeUIBuilderFunctions.googlePayRequest,
  'APPLE_PAY_REQUEST' : BridgeUIBuilderFunctions.applePayRequest,
};
