import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../utils/coder.dart';

typedef void CallbackFunction(Map data);

class BridgeEvent {
  final String id;
  final String eventName;
  final PlatformJavaScriptReplyProxy _replier;
  late CallbackFunction? dispatch;
  static Map<String, List<BridgeEvent>>? _eventsContainer;

  BridgeEvent(this.id, this.eventName, this._replier) {
    this.dispatch = _reply;
  }

  bool equalTo(String id) {
    return this.id == id;
  }

  static Future<void> dispatchEventsByName(String name, Map data) async {
    if (_eventsContainer?.isEmpty ?? true) {
      return;
    }

    if (_eventsContainer!.containsKey(name)) {
      for (var event in _eventsContainer![name]!) {
        event.dispatch!(data);
      }
    } else {
      print('Event with this name does not exist');
    }
  }

  static List<BridgeEvent>? getEventsByName(String name) {
    if (_eventsContainer?.isNotEmpty ?? false) {
      return _eventsContainer![name];
    }

    return null;
  }

  static void addToContainer(BridgeEvent event) {
    if (_eventsContainer == null) {
      _eventsContainer = Map<String, List<BridgeEvent>>();
    }

    if (!_eventsContainer!.containsKey(event.eventName)) {
      _eventsContainer![event.eventName] =
          List<BridgeEvent>.empty(growable: true);
    }

    BridgeEvent._eventsContainer![event.eventName]!.add(event);
    print('Event was added');
  }

  static Future<bool> removeEvent(String name, String id) async {
    if (_eventsContainer?.isNotEmpty ?? false) {
      if (_eventsContainer!.containsKey(name)) {
        for (var event in _eventsContainer![name]!) {
          if (event.equalTo(id)) {
            event.dispatch = null;
            _eventsContainer!.remove(event);
            _eventsContainer![name]!.remove(event);

            if (_eventsContainer![name]!.isEmpty) {
              _eventsContainer!.remove(name);
            }

            print('Event was removed');
            return true;
          }
        }
      }
    }

    print('This event does not exist. Can not remove event.');
    return false;
  }

  get isExist {
    if (_eventsContainer?.isNotEmpty ?? false) {
      if (_eventsContainer!.containsKey(this.eventName)) {
        for (var event in _eventsContainer![this.eventName]!) {
          if (this.equalTo(event.id)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  void _reply(Map data) async {
    Map replyMap = {
      'event': 'EVENT',
      'payload': {
        'event': this.eventName,
        'id': this.id,
        'data': data,
      },
    };
    String result = json.encode(
      replyMap,
      toEncodable: Coder.dateSerializer,
    );

    WebMessage webMessage = WebMessage(data: result);
    await this._replier.postMessage(webMessage);
  }
}
