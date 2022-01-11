enum SystemEvents { REQUEST, RESPONSE }

extension ExtensionSystemEvents on SystemEvents {
  String get systemEvent {
    switch (this) {
      case SystemEvents.REQUEST:
        return 'REQUEST';
      case SystemEvents.RESPONSE:
        return 'RESPONSE';
    }
  }
}
