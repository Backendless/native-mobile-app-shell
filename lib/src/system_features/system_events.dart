import '../bridge/bridge_ui_builder_functions.dart';

final systemEvents = {
  'TAP_PUSH_ACTION': BridgeUIBuilderFunctions.tapOnPushAction,
  'ACCELEROMETER_DATA': BridgeUIBuilderFunctions.setAccelerometerEvent,
  'USER_ACCELEROMETER_DATA': BridgeUIBuilderFunctions.setUserAccelerometerEvent,
  'GYROSCOPE_DATA': BridgeUIBuilderFunctions.setGyroscopeEvent,
  'MAGNETOMETER_DATA': BridgeUIBuilderFunctions.setMagnetometerEvent,
};
