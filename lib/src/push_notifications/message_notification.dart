import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import '../bridge/bridge_ui_builder_functions.dart';

class MessageNotification extends StatelessWidget {
  const MessageNotification(
      {Key? key, this.title, this.body, this.id, this.headers})
      : super(key: key);

  final id;
  final title;
  final body;
  final headers;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: SafeArea(
        bottom: false,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            elevation: 0.0,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            side: BorderSide(
              width: 0.0,
              color: Colors.transparent,
            ),
          ),
          onPressed: () {
            BridgeUIBuilderFunctions.dispatchTapOnPushEvent(headers);
            try {
              OverlaySupportEntry.of(context)?.dismiss(animate: true);
            } catch (ex) {
              print('cannot dismiss overlay');
            }
          },
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
      ),
    );
  }
}
