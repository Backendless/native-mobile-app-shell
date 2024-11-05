import 'dart:convert';
import '../bridge/bridge_ui_builder_functions.dart';
import 'bridge_manager.dart';
import 'bridge_validator.dart';
import '../types/system_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class Bridge {
  late InAppWebViewController controller;
  static late BuildContext? currentContext;

  Bridge({required this.controller});

  Future addWebMessageListener(BuildContext context) async {
    await this.controller.addWebMessageListener(WebMessageListener(
        jsObjectName: 'UI_BUILDER_WEB_MESSAGE_LISTENER_OBJECT',
        allowedOriginRules: Set.from(['*']),
        onPostMessage: (message, sourceOrigin, isMainFrame, replyProxy) async {
          currentContext = context;

          String? result;
          try {
            print('got data from codeless: ${message!.data}');
            Map data = await jsonDecode(message.data);

            var systemEvent =
                await BridgeValidator.hasSystemEvent(data['event']);
            switch (systemEvent) {
              case SystemEvents.REQUEST:
                result = await BridgeManager.executeRequest(
                  data,
                  replyProxy,
                );
                break;
              case SystemEvents.RESPONSE:
                print('RESPONSE CALLED');
                return;
              default:
                break;
            }
            if (result!.contains('_CANCELED BY USER')) {
              return;
            }

            if (data['payload']['type'] == 'ON_TAP_EVENT_INITIALIZED') {
              await BridgeUIBuilderFunctions.onTapEventInitializeController
                  .close();
            }

            if (result.contains('_UNSUPPORTED FOR THIS PLATFORM')) {
              await BridgeUIBuilderFunctions.alertUnsupportedPlatform(context);
            } else if (result.contains('\"type\":\"ADD_LISTENER\"')) {}

            print('sent data to codeless: $result');

            WebMessage webMessage = WebMessage(data: result);
            await replyProxy.postMessage(webMessage);
          } catch (ex) {
            throw Exception(ex);
          }
        }));
  }
}
