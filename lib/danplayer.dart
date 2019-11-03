library flutter_danplayer;

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'danmaku_layer.dart';
import 'ui_layer.dart';

///
///
/// Some simulators when render video throw exception.
/// Let it to false, DanPlayer will not render video to screen.
///
///
bool danPlayerRenderVideo = true;

enum DanPlayerMode {
  Normal,
  Live,
}

class DanPlayerConfig {
  final Color controllerBackgroundColor;
  final Color progressBarColor;
  final Color progressBarBufferAreaColor;
  final Widget progressBarHandler, loadingWidget;

  /// the appBar actions
  final List<Widget> actions;

  final Duration uiFadeOutDuration;

  /// enable / disable danmaku functions
  final bool danmaku;

  const DanPlayerConfig({
    @required this.progressBarHandler,
    this.loadingWidget,
    this.controllerBackgroundColor: const Color.fromARGB(255, 0, 0, 0),
    this.progressBarColor: Colors.blue,
    this.progressBarBufferAreaColor: Colors.blueGrey,
    this.actions: const [],
    this.danmaku: true,
    this.uiFadeOutDuration: const Duration(seconds: 4),
  })  : assert(controllerBackgroundColor != null),
        assert(progressBarColor != null),
        assert(progressBarBufferAreaColor != null),
        assert(progressBarHandler != null);
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
  final DanPlayerConfig config;
  final Duration uiFadeOutDuration, uiFadeOutSpeed;
  final Future<bool> Function(Danmaku danmaku) onBeforeSubmit;

  const DanPlayer({
    Key key,
    this.name: 'DanPlayer',
    @required this.video,
    this.autoPlay: true,
    this.mode: DanPlayerMode.Normal,
    this.config,
    this.uiFadeOutDuration: const Duration(seconds: 2),
    this.uiFadeOutSpeed: const Duration(milliseconds: 200),
    this.onBeforeSubmit,
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
  DanPlayerConfig config;
  double _videoAspectRatio = 1;
  DanPlayerMode mode;
  VideoPlayerValue _videoValue;

  VideoPlayerValue get videoValue => _videoValue;

  @override
  void dispose() {
    SystemChrome.restoreSystemUIOverlays();
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIOverlays([]);
    config = widget.config;
    if (config == null) {
      config = DanPlayerConfig(
        controllerBackgroundColor: Colors.black.withOpacity(0.5),
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
    removeListener(_initVideoSize);
    _videoAspectRatio = value.aspectRatio;
    setState(() {});
  }

  void setVideo(String video,
      {DanPlayerMode mode: DanPlayerMode.Normal, String name: 'Danplayer'}) {
    this.name = name;
    this.mode = mode;
    _play = widget.autoPlay;
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
    if (moment < Duration.zero || moment > _videoValue.duration) return;
    print('seek $moment');
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
    _videoValue = _controller.value;
    if (!_videoValue.initialized) return;
    print('danplayer listener: $_videoValue');
    _listeners.forEach((func) => func(_videoValue));
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
          danPlayerRenderVideo
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
                            'When danPlayerRenderVideo = false\n'
                            'Use this widget instead of video',
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
            config: config,
            fadeOutDuration: widget.uiFadeOutDuration,
            fadeOutSpeed: widget.uiFadeOutSpeed,
            playerState: this,
          ),
        ],
      ),
    );
  }
}
