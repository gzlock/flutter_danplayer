import 'dart:math';

import 'package:danplayer/danplayer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final titleStyle = TextStyle(color: Colors.blue, fontSize: 18);

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

class VideoControlWidget extends StatefulWidget {
  final DanPlayerController controller;
  final String url;

  const VideoControlWidget({Key key, this.controller, this.url})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoControlWidget();
}

class _VideoControlWidget extends State<VideoControlWidget> {
  DanPlayerMode _mode = DanPlayerMode.Normal;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Card(
              child: Padding(
            padding: EdgeInsets.all(5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('切换播放器形态', style: titleStyle),
                Column(children: [
                  CheckboxListTile(
                    onChanged: (bool selected) {
                      if (selected)
                        setState(() {
                          _mode = DanPlayerMode.Normal;
                          widget.controller.setDataSource(DataSource.network(
                              widget.url,
                              mode: DanPlayerMode.Normal));
                        });
                    },
                    selected: _mode == DanPlayerMode.Normal,
                    value: _mode == DanPlayerMode.Normal,
                    title: Text('正常模式'),
                    subtitle: Text('显示播放进度条和播放时间'),
                  ),
                  CheckboxListTile(
                    onChanged: (bool selected) {
                      if (selected)
                        setState(() {
                          _mode = DanPlayerMode.Live;
                          widget.controller.setDataSource(DataSource.network(
                              widget.url,
                              mode: DanPlayerMode.Live));
                        });
                    },
                    selected: _mode == DanPlayerMode.Live,
                    value: _mode == DanPlayerMode.Live,
                    title: Text('直播模式'),
                    subtitle: Text('不显示播放进度条，播放时间用"直播中"代替'),
                  ),
                ]),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class DanmakuControlWidget extends StatefulWidget {
  final DanPlayerController controller;
  final String url;

  const DanmakuControlWidget({Key key, this.controller, this.url})
      : super(key: key);

  @override
  _DanmakuControlWidget createState() => _DanmakuControlWidget();
}

class _DanmakuControlWidget extends State<DanmakuControlWidget> {
  TextEditingController _timeController, _countController;
  String danmakuType = '随机';
  final danmakuTypeList = {
    '置顶': DanmakuType.Top,
    '置底': DanmakuType.Bottom,
    '滚动': DanmakuType.Normal
  };

  @override
  void initState() {
    super.initState();
    _timeController = TextEditingController(text: '10');
    _countController = TextEditingController(text: '500');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints.expand(),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '批量填充弹幕，模拟有很多弹幕的视频',
                    style: titleStyle,
                  ),
                  Row(children: [
                    Text('弹幕类型'),
                    Container(width: 5),
                    DropdownButton<String>(
                      value: danmakuType,
                      onChanged: (String value) {
                        setState(() {
                          this.danmakuType = value;
                        });
                      },
                      items: ['随机', ...danmakuTypeList.keys]
                          .map((name) => DropdownMenuItem<String>(
                                value: name,
                                child: Text(name),
                              ))
                          .toList(),
                    ),
                  ]),
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
                        onPressed: () {
                          final time = int.parse(_timeController.text),
                              count = int.parse(_countController.text);
                          assert(time > 0);
                          assert(count > 0);
                          print('time $time, count $count');
                          final random = Random();
                          () async {
                            final danmakus = <Danmaku>[];
                            final isRandom = danmakuType == '随机';
                            DanmakuType type;
                            String text;
                            for (var i = 0; i < count; i++) {
                              if (isRandom) {
                                type = DanmakuType.values[
                                    random.nextInt(DanmakuType.values.length)];
                              } else {
                                type = danmakuTypeList[this.danmakuType];
                              }
                              text = danmakuTypeList.keys.firstWhere(
                                      (key) => danmakuTypeList[key] == type) +
                                  '弹幕 $i';
                              danmakus.add(Danmaku(
                                  text: text,
                                  type: type,
                                  fill: Color.fromRGBO(
                                      100 + random.nextInt(155),
                                      100 + random.nextInt(155),
                                      100 + random.nextInt(155),
                                      1),
                                  currentTime: widget.controller
                                          .videoPlayerValue.position +
                                      Duration(
                                          milliseconds:
                                              random.nextInt(time * 1000))));
                            }
                            widget.controller.addDanmakus(danmakus);
                          }();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
