import 'package:flutter/material.dart';
import 'border_constructor.dart';

class MessageNotification extends StatelessWidget {
  const MessageNotification({Key? key, this.title, this.body})
      : super(key: key);

  final title;
  final body;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: SafeArea(
        bottom: false,
        child: Container(
          decoration: border(),
          child: ListTile(
            tileColor: Colors.blue.shade200,
            leading: SizedBox.fromSize(
              size: const Size(80, 50),
              child:
                  ClipOval(child: Image.asset('images/backendless_logo.png')),
            ),
            title: Text(
              this.title,
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              this.body,
              style: TextStyle(
                fontSize: 13.0,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
