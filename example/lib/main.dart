import 'package:danplayer/danplayer.dart';
import 'package:flutter/material.dart';

import 'listview.dart';

void main() {
  /// Be careful this variable
  danPlayerRenderVideo = false;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DanPlayer Demo',
      debugShowCheckedModeBanner: false,
      home: MyHomePage(title: 'DanPlayer Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView(
        children: <Widget>[
          Card(
            child: Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                'Packcage url\nhttps://pub.dev/packages/danplayer',
                softWrap: true,
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: EdgeInsets.all(5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'The DanPlayer in scrollable widget',
                    softWrap: true,
                  ),
                  RaisedButton(
                    color: Colors.red,
                    child: Text(
                      'Demo',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => InListView()));
                    },
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
