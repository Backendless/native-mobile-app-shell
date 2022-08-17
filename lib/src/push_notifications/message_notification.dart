import 'package:flutter/material.dart';
import 'border_constructor.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/*class NotificationsApi {
  static Future showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async =>
      _notifications.show(
        id,
        title,
        body,
        await _notificationDetails(),
        //payload: payload,
      );

  static Future _notificationDetails() async {
    return NotificationDetails(
        android: AndroidNotificationDetails(
          'channel id',
          'channel name',
          'channel description',
          importance: Importance.max,
        ),
        iOS: IOSNotificationDetails());
  }
}
*/
class MessageNotification extends StatelessWidget {
  const MessageNotification({Key? key, this.title, this.body, this.id})
      : super(key: key);

  final id;
  final title;
  final body;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: SafeArea(
        bottom: false,
        child: Container(
          //decoration: border(),
          child: ListTile(
            tileColor: Color.fromRGBO(8, 19, 20, 0.4),
            leading: SizedBox.fromSize(
              size: const Size(80, 50),
              child:
                  ClipOval(child: Image.asset('images/backendless_logo.png')),
            ),
            title: Text(
              this.title,
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.cyanAccent.shade200,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              this.body,
              style: TextStyle(
                fontSize: 13.0,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
