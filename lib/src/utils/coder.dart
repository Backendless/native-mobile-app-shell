import 'dart:convert';
import '../types/system_events.dart';
import 'package:flutter/services.dart';

class Coder {
  static Future<String> decodeEnum(SystemEvents se) async {
    return se.systemEvent;
  }

  static Future<dynamic> readJson({required String path}) async {
    final String response = await rootBundle.loadString(path);
    final data = await json.decode(response);

    return data;
  }

  static dynamic dateSerializer(dynamic object) {
    if (object is DateTime) {
      return object.toIso8601String();
    }
    return object;
  }
}
