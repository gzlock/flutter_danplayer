library flutter_danplayer;

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'danmaku_layer.dart';
import 'ui_layer.dart';

enum DanPlayerMode {
  Normal,
  Live,
}

class DanPlayerTheme {
  final Color controllerBackgroundColor;
  final Color highLightColor;
  final Color progressBarColor;
  final Color progressBarBufferAreaColor;
  final Widget progressBarHandler;

  const DanPlayerTheme({
    @required this.controllerBackgroundColor,
    @required this.highLightColor,
    @required this.progressBarColor,
    @required this.progressBarBufferAreaColor,
    @required this.progressBarHandler,
  });
}

enum DanmakuType {
  Top,
  Normal,
  Bottom,
}

class Danmaku {
  final String text, id;
  final Duration currentTime;
  final Color fill, borderColor;
  final DanmakuType type;

  Danmaku({
    @required this.text,
    this.id,
    this.currentTime: Duration.zero,
    this.type: DanmakuType.Normal,
    this.fill: Colors.white,
    this.borderColor: Colors.transparent,
  });

  @override
  String toString() {
    return json.encode(toJson());
  }

  Map<String, dynamic> toJson() {
    return {'text': text, 'duration': currentTime.inMilliseconds};
  }

  static Danmaku fromJson(Map<String, dynamic> map) {
    var type;
    switch (map['type']) {
      case 0:
        type = DanmakuType.Top;
        break;
      case 2:
        type = DanmakuType.Bottom;
        break;
      default:
        type = DanmakuType.Normal;
        break;
    }
    return Danmaku(
        text: map['text'],
        fill: map['color'],
        type: type,
        currentTime: Duration(milliseconds: map['duration']));
  }
}

class DanPlayer extends StatefulWidget {
  final String name, video;
  final bool autoPlay;
  final DanPlayerMode mode;
  final DanPlayerTheme theme;
  final Duration uiFadeOutDuration, uiFadeOutSpeed;

  const DanPlayer({
    Key key,
    this.name: 'DanPlayer',
    @required this.video,
    this.autoPlay: true,
    this.mode: DanPlayerMode.Normal,
    this.theme,
    this.uiFadeOutDuration: const Duration(seconds: 5),
    this.uiFadeOutSpeed: const Duration(milliseconds: 200),
  }) : super(key: key);

  @override
  DanPlayerState createState() => DanPlayerState();
}

class DanPlayerState extends State<DanPlayer> {
  final List<Function(VideoPlayerValue value)> _listeners = [];
  final GlobalKey<DanmakuLayerState> _danmakuLayer = GlobalKey();
  final GlobalKey<UILayerState> _ui = GlobalKey();
  final GlobalKey _container = GlobalKey();
  String name;
  VideoPlayerController _controller;
  bool _displayDanmkau;
  bool _play;
  DanPlayerTheme _theme;
  double _videoAspectRatio = 1;
  DanPlayerMode mode;

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  void initState() {
    super.initState();
    _theme = widget.theme;
    if (_theme == null) {
      _theme = DanPlayerTheme(
        controllerBackgroundColor: Colors.black.withOpacity(0.5),
        highLightColor: Colors.blue,
        progressBarColor: Colors.blue,
        progressBarBufferAreaColor: Colors.blue.shade100,
        progressBarHandler: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.purpleAccent,
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    setVideo(widget.video, name: widget.name, mode: widget.mode);
    addListener(_initVideoSize);
  }

  void _initVideoSize(VideoPlayerValue value) {
    _videoAspectRatio = value.aspectRatio;
    setState(() {});
  }

  void setVideo(String video,
      {DanPlayerMode mode: DanPlayerMode.Normal, String name: 'Danplayer'}) {
    this.name = name;
    this.mode = mode;
    if (_controller?.dataSource == video) return;
    _controller?.dispose();
    _controller = VideoPlayerController.network(video)..initialize();
    if (widget.autoPlay)
      _controller.play();
    else
      _controller.pause();
    _controller.addListener(_listener);
    setState(() {});
  }

  void seekTo(Duration moment) async {
    if (_controller.value.initialized) await _controller.seekTo(moment);
  }

  void fillDanmakus(List<Danmaku> danmakus) {
    this._danmakuLayer?.currentState?.fillDanmakus(danmakus);
  }

  void addListener(void Function(VideoPlayerValue value) listener) {
    if (_listeners.contains(listener)) return;
    _listeners.add(listener);
  }

  void removeListener(Function listener) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listeners.remove(listener);
    });
  }

  void _listener() {
    if (!_controller.value.initialized) return;
    print('listener: ${_controller.value}');
    _listeners.forEach((func) => func(_controller.value));
  }

  set displayDanmkau(bool value) {
    _displayDanmkau = value;
    setState(() {});
  }

  get displayDanmkau => _displayDanmkau;

  set play(bool play) {
    _play = play;
    if (play)
      _controller?.play();
    else
      _controller?.pause();
  }

  get play => _play;

  void stop() {
    _controller.pause();
    _controller.seekTo(Duration());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _container,
      constraints: BoxConstraints.expand(),
      child: Stack(
        children: <Widget>[
          Container(color: Colors.black),
          bool.fromEnvironment('dart.vm.product')
              ? VideoPlayer(_controller)
              : Visibility(
                  visible: _controller.value.initialized,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _videoAspectRatio,
                      child: Container(
                        color: Colors.white,
                        child: Center(
                          child: Text(
                            'Debug模式\n用白底黑字\n模拟视频画面',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          DanmakuLayer(
            key: _danmakuLayer,
            playerState: this,
          ),
          UILayer(
            key: _ui,
            theme: _theme,
            fadeOutDuration: widget.uiFadeOutDuration,
            fadeOutSpeed: widget.uiFadeOutSpeed,
            playerState: this,
          ),
        ],
      ),
    );
  }
}
