import 'package:flutter/material.dart';
import '../web_view/web_view_container.dart';
import 'package:overlay_support/overlay_support.dart';

GlobalKey<NavigatorState> navigatorKeyT = GlobalKey<NavigatorState>();

class StartPageStateless extends StatelessWidget {
  //TODO Set path to your 'index.html' file!
  static final syncPath = 'assets/ui_builder_app/index.html';

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKeyT,
        home: isExists() ? WebViewContainer(syncPath) : StartPageStateful(),
      ),
    );
  }
}

class StartPageStateful extends StatefulWidget {
  const StartPageStateful({Key? key}) : super(key: key);

  @override
  _StartPageStatefulState createState() => _StartPageStatefulState();
}

class _StartPageStatefulState extends State<StartPageStateful> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Padding(
          padding: EdgeInsets.symmetric(vertical: 50.0, horizontal: 120.0),
          child: Image.asset(
            'images/backendless_logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              SizedBox(height: 50.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Please enter the path to the \'index.html\' file in \'syncPath\' variable(in logic_builder.dart)',
                  style: TextStyle(
                    fontSize: 24.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool isExists() {
  return StartPageStateless.syncPath.contains('/index.html');
}
