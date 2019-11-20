import 'dart:math';

import 'package:danplayer/danplayer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      child: Center(child: widget.child),
    );
  }
}

/// Tab Bar
class SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar widget;
  final Color color;

  const SliverTabBarDelegate(this.widget, {this.color})
      : assert(widget != null);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return new Container(
      child: widget,
      height: widget.preferredSize.height,
      color: color,
    );
  }

  @override
  bool shouldRebuild(SliverTabBarDelegate oldDelegate) {
    return false;
  }

  @override
  double get maxExtent => widget.preferredSize.height;

  @override
  double get minExtent => widget.preferredSize.height;
}

class VideoControlWidget extends StatelessWidget {
  final DanPlayerController controller;

  const VideoControlWidget({Key key, this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints.expand(),
      child: Column(
        children: [
          Row(
            children: <Widget>[],
          ),
          Row(),
          Row(),
          Row(),
        ],
      ),
    );
  }
}

class DanmakuControlWidget extends StatefulWidget {
  final DanPlayerController controller;

  const DanmakuControlWidget({Key key, this.controller}) : super(key: key);

  @override
  _DanmakuControlWidget createState() => _DanmakuControlWidget();
}

class _DanmakuControlWidget extends State<DanmakuControlWidget> {
  TextEditingController _timeController, _countController;

  @override
  void initState() {
    super.initState();
    _timeController = TextEditingController(text: '5');
    _countController = TextEditingController(text: '100');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints.expand(),
      padding: EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: <Widget>[
              SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _timeController,
                    inputFormatters: [
                      WhitelistingTextInputFormatter.digitsOnly
                    ],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      suffixText: '秒内填充',
                      suffixStyle: TextStyle(color: Colors.grey),
                      prefixText: '在',
                    ),
                  )),
              SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _countController,
                    inputFormatters: [
                      WhitelistingTextInputFormatter.digitsOnly
                    ],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      suffixText: '条弹幕',
                    ),
                  )),
              new RawMaterialButton(
                child: new Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20.0,
                ),
                shape: new CircleBorder(),
                elevation: 2,
                fillColor: Colors.blue,
                padding: const EdgeInsets.all(5),
                onPressed: () {
                  final time = int.parse(_timeController.text),
                      count = int.parse(_countController.text);
                  assert(time > 0);
                  assert(count > 0);
                  print('time $time, count $count');
                  final random = Random();
                  () async {
                    final danmakus = <Danmaku>[];
                    for (var i = 0; i < count; i++) {
                      danmakus.add(Danmaku(
                          text: '测试弹幕 $i',
                          fill: Color.fromRGBO(
                              100 + random.nextInt(155),
                              100 + random.nextInt(155),
                              100 + random.nextInt(155),
                              1),
                          currentTime: widget
                                  .controller.videoPlayerValue.position +
                              Duration(
                                  milliseconds: random.nextInt(time * 1000))));
                    }
                    widget.controller.addDanmakus(danmakus);
                  }();
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}
