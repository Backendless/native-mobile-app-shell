import '../bridge/bridge_manager.dart';
import '../custom_features/custom_events.dart';
import '../custom_features/custom_methods.dart';
import '../system_features/system_events.dart';
import '../system_features/system_methods.dart';
import '../utils/request.dart';

final dynamic bridgeMethods = {
  ...customMethods,
  ...systemMethods,
};

final dynamic bridgeEvents = {
  ...customEvents,
  ...systemEvents,
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
  if (payload['event'] == null || payload['id'] == null) {
    throw new Exception('Failed to create event. Name or Id cannot be null');
  }

  final processor = bridgeEvents[payload['event']];

  if (processor == null) {
    throw new Exception(
        'No processor registered for the event with name ${requestContainer.operationName}');
  }

  final result = await processor(payload, jsResponseProxy);

  return await BridgeManager.buildResponse(
      data: requestContainer, response: result);
}
