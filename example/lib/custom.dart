import 'package:danplayer/danplayer.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CustomDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DanPlayer(
        video:
            'https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8',
        mode: DanPlayerMode.Normal,
        autoPlay: false,
        config: DanPlayerConfig(
          backgroundDeepColor: Colors.blue.withOpacity(0.5),
          progressBarHandler: Text('🚚'),
          loadingWidget: LoadingView(
            duration: Duration(seconds: 1),
            child: Text(
              '😂',
              style: TextStyle(fontSize: 40),
            ),
          ),
          danmaku: false,
          actions: [
            IconButton(
              icon: Text('🏀'),
              onPressed: () {
                Fluttertoast.showToast(
                    msg: 'Clicked the 🏀️ button',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIos: 1,
                    textColor: Colors.white,
                    fontSize: 16.0);
              },
            ),
            IconButton(
              icon: Text('⚽️'),
              onPressed: () {
                Fluttertoast.showToast(
                    msg: 'Clicked the ⚽️ button',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIos: 1,
                    textColor: Colors.white,
                    fontSize: 16.0);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingView extends StatefulWidget {
  final Duration duration;
  final Widget child;

  const LoadingView({Key key, @required this.duration, @required this.child})
      : super(key: key);

  @override
  _LoadingViewState createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: Tween(begin: 0.0, end: 1.0).animate(_controller),
//      alignment: Alignment.center,
      child: Center(child: widget.child),
    );
  }
}
