import 'package:native_app_shell_mobile/src/bridge/bridge_manager.dart';
import 'package:native_app_shell_mobile/src/custom_features/custom_events.dart';
import 'package:native_app_shell_mobile/src/custom_features/custom_methods.dart';
import 'package:native_app_shell_mobile/src/system_features/system_events.dart';
import 'package:native_app_shell_mobile/src/system_features/system_methods.dart';
import 'package:native_app_shell_mobile/src/utils/request.dart';

final bridgeMethods = {
  ...customMethods,
  ...systemMethods,
};

final bridgeEvents = {
  ...systemEvents,
  ...customEvents,
};

Future<String> methodReceiver(Request requestContainer, Map? payload) async {
  final processor = bridgeMethods[requestContainer.operationName];

  if (processor == null) {
    throw new Exception(
        'No processor registered for the method with name ${requestContainer.operationName}');
  }

  final result = await processor(payload);

  return await BridgeManager.buildResponse(
      data: requestContainer, response: result);
}

Future<String> listenerReceiver(
    Request requestContainer, Map payload, jsResponseProxy) async {
  final processor = bridgeEvents[requestContainer.operationName];

  if (processor == null) {
    throw new Exception(
        'No processor registered for the event with name ${requestContainer.operationName}');
  }

  final result = await processor(payload, jsResponseProxy);

  return await BridgeManager.buildResponse(
      data: requestContainer, response: result);
}