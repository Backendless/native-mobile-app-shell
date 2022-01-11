import 'dart:convert';

class BridgeManager {
  static Future<String?> processFunc(Function() func, Map data) async {
    try {
      await func().call();
      return buildResponse(
        id: data['payload']['id']!,
        type: data['payload']['type'],
        response: 'SUCCESSFUL',
      );
    } catch (ex) {
      return buildResponse(
        id: data['payload']['id']!,
        type: data['payload']['type'],
        error: data['payload']['error'] != null
            ? data['payload']['error']
            : ex.toString(),
      );
    }
  }

  static String buildResponse(
      {required String id,
      required String type,
      dynamic response,
      String? error}) {
    Map result = {
      'event': 'RESPONSE',
      'payload': {'type': type, 'id': id, 'data': {}}
    };

    if (response != null)
      result['payload']['data']['result'] = response;
    else
      result['payload']['data']['error'] = error;

    try {
      return json.encode(result);
    } catch (ex) {
      throw new Exception(ex);
    }
  }
}
