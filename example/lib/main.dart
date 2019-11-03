import 'package:danplayer/danplayer.dart';
import 'package:example/vod.dart';
import 'package:flutter/material.dart';

import 'custom.dart';
import 'live.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
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
                    'The normal(VOD) mode demo',
                    softWrap: true,
                  ),
                  RaisedButton(
                    color: Colors.blue,
                    child: Text(
                      'VOD Demo',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => VODModeDemo()));
                    },
                  )
                ],
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
                    'The live mode demo\n'
                    'No progress bar',
                    softWrap: true,
                  ),
                  RaisedButton(
                    color: Colors.green,
                    child: Text(
                      'Live Demo',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => LiveModeDemo()));
                    },
                  )
                ],
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
                    'Customize everything use the DanPlayerConfig\n'
                    'Just for fun',
                    softWrap: true,
                  ),
                  RaisedButton(
                    color: Colors.orange,
                    child: Text(
                      'Custom Demo',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => CustomDemo()));
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
