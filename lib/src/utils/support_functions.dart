Future<Map> createHeadersForOnTapPushAction(Map message) async {
  return {
    'chatId': message['id'],
    'page': message['page'],
    'activeTab': message['activeTab']
  };
}
