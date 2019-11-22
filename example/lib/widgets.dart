import 'dart:math';

import 'package:danplayer/danplayer.dart';
import 'package:example/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final titleStyle = TextStyle(color: Colors.orange, fontSize: 18);

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
  final List<Widget> actions;

  const VideoControlWidget({Key key, this.controller, this.url, this.actions})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoControlWidget();
}

class _VideoControlWidget extends State<VideoControlWidget> {
  DanPlayerMode _mode = DanPlayerMode.Normal;
  bool _showFullScreen = true, _enableDanmkau = true, _showActions = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView(
        physics: NeverScrollableScrollPhysics(),
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
                          widget.controller.config =
                              widget.controller.config.copyWith(mode: _mode);
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
                          widget.controller.config =
                              widget.controller.config.copyWith(mode: _mode);
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
          Card(
            child: Padding(
              padding: EdgeInsets.all(5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '自定义界面',
                    style: titleStyle,
                  ),
                  CheckboxListTile(
                    onChanged: (bool selected) {
                      setState(() {
                        _showFullScreen = !_showFullScreen;
                        widget.controller.config = widget.controller.config
                            .copyWith(showFullScreenButton: _showFullScreen);
                      });
                    },
                    selected: _showFullScreen,
                    value: _showFullScreen,
                    title: Text('显示 / 隐藏 全屏按钮'),
                  ),
                  CheckboxListTile(
                    onChanged: (bool selected) {
                      setState(() {
                        _enableDanmkau = !_enableDanmkau;
                        widget.controller.config = widget.controller.config
                            .copyWith(danmaku: _enableDanmkau);
                      });
                    },
                    selected: _enableDanmkau,
                    value: _enableDanmkau,
                    title: Text('显示 / 隐藏 弹幕功能'),
                    subtitle: Text('包括：发弹幕的按钮、弹幕内容层'),
                  ),
                  CheckboxListTile(
                    onChanged: (bool selected) {
                      setState(() {
                        _showActions = !_showActions;
                        widget.controller.config = widget.controller.config
                            .copyWith(
                                actions: _showActions ? widget.actions : []);
                      });
                    },
                    selected: _showActions,
                    value: _showActions,
                    title: Text('显示 / 隐藏 右上角按钮(Actions)'),
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
      child: ListView(
        physics: NeverScrollableScrollPhysics(),
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
                              final hasBorder = random.nextBool();
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
                                  fill: randomColor(),
                                  borderColor: hasBorder ? randomColor() : null,
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
