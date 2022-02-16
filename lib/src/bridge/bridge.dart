import 'dart:convert';
import 'bridge_manager.dart';
import 'bridge_validator.dart';
import 'package:uuid/uuid.dart';
import '../types/system_events.dart';
import '../types/function_handler.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class Bridge {
  late InAppWebViewController controller;
  bool _isRegistered = false;

  Bridge({required this.controller});

  Future addWebMessageListener() async {
    this.controller.addWebMessageListener(WebMessageListener(
        jsObjectName: 'UI_BUILDER_WEB_MESSAGE_LISTENER_OBJECT',
        allowedOriginRules: Set.from(['*']),
        onPostMessage: (message, sourceOrigin, isMainFrame, replyProxy) async {
          String? result;
          try {
            Map data = jsonDecode(message!);

            var systemEvent = BridgeValidator.hasSystemEvent(data['event']);
            switch (systemEvent) {
              case SystemEvents.REQUEST:
                result = await BridgeManager.executeRequest(data);
                break;
              case SystemEvents.RESPONSE:
                break;
              default:
                break;
            }
            await replyProxy.postMessage(result!);
          } catch (ex) {
            throw Exception(ex);
          }
        }));
  }

  Future dispatchEvent({required String type, required Map body}) async {
    //TODO: add id
    var uuid = Uuid();
    body['id'] = uuid.v5('', type);
    if (!body['id']) {
      throw new Exception('The body does not have\'id\' value');
    }
    String jsonBody = json.encode(body);
    await this.controller.evaluateJavascript(source: """
      window.dispatchEvent(new CustomEvent($type, {
        detail: $jsonBody}))
    """);
  }
}
