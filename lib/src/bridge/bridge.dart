import 'dart:convert';
import 'package:native_app_shell_mobile/src/bridge/bridge_ui_builder_functions.dart';

import 'bridge_manager.dart';
import 'bridge_validator.dart';
import 'package:uuid/uuid.dart';
import '../types/system_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class Bridge {
  late InAppWebViewController controller;

  Bridge({required this.controller});

  Future addWebMessageListener(BuildContext context) async {
    await this.controller.addWebMessageListener(WebMessageListener(
        jsObjectName: 'UI_BUILDER_WEB_MESSAGE_LISTENER_OBJECT',
        allowedOriginRules: Set.from(['*']),
        onPostMessage: (message, sourceOrigin, isMainFrame, replyProxy) async {
          String? result;
          try {
            Map data = await jsonDecode(message!);
            data['_context'] = context;

            var systemEvent =
                await BridgeValidator.hasSystemEvent(data['event']);
            switch (systemEvent) {
              case SystemEvents.REQUEST:
                result = await BridgeManager.executeRequest(data);
                break;
              case SystemEvents.RESPONSE:
                break;
              default:
                break;
            }
            if (result!.contains('_CANCELED BY USER')) return;

            if (result.contains('_UNSUPPORTED FOR THIS PLATFORM'))
              await BridgeUIBuilderFunctions.alertUnsupportedPlatform(context);

            await replyProxy.postMessage(result);
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
