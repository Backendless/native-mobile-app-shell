import '../utils/coder.dart';
import '../types/system_events.dart';

class BridgeValidator {
  static Future<SystemEvents?> hasSystemEvent(String eventType) async {
    var data = SystemEvents.values;

    for (SystemEvents ev in data) {
      if (eventType == await Coder.decodeEnum(ev)) {
        return ev;
      }
    }

    return null;
  }
}
