library flutter_danplayer;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import './utils.dart';
import './route.dart';
import './video_gesture.dart';

part 'ui/ui_layer.dart';

part 'ui/progress_bar.dart';

part 'ui/post_danmaku_layer.dart';

part 'ui/danmaku_layer.dart';

part 'ui/buttons.dart';

part 'controller.dart';

///
///
/// Some simulators when render video throw exception.
/// Let it to false, DanPlayer will not render video to screen.
/// But the video is actually playing, so you can hear the sound.
///
/// 因为有些安卓模拟器在渲染视频时会报错。
/// 所以专门设置了这个变量用于不渲染视频。
/// 但视频还是在播放的，所以你能听得到声音。
///
///
bool danPlayerRenderVideo = true;

enum DanPlayerMode {
  Normal,
  Live,
}

class DanPlayerConfig {
  final Color backgroundColor;
  final Color backgroundLightColor;
  final Color backgroundDeepColor;
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
    this.backgroundColor: const Color.fromRGBO(0, 0, 0, 0.3),
    this.backgroundLightColor: Colors.transparent,
    this.backgroundDeepColor: const Color.fromRGBO(0, 0, 0, 0.5),
    this.progressBarColor: Colors.blue,
    this.progressBarBufferAreaColor: Colors.blueGrey,
    this.actions: const [],
    this.danmaku: true,
    this.uiFadeOutDuration: const Duration(seconds: 4),
  })  : assert(backgroundDeepColor != null),
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
    var type;
    switch (type) {
      case DanmakuType.Top:
        type = 0;
        break;
      case DanmakuType.Bottom:
        type = 2;
        break;
      default:
        type = 1;
        break;
    }
    return {
      'text': text,
      'duration': currentTime.inMilliseconds,
      'type': type,
    };
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
  final DanPlayerMode mode;
  final DanPlayerConfig config;
  final Duration uiFadeOutDuration, uiFadeOutSpeed;
  final Future<bool> Function(Danmaku danmaku) onBeforeSubmit;
  final DanPlayerController controller;

  const DanPlayer({
    Key key,
    @required this.controller,
    this.mode: DanPlayerMode.Normal,
    this.uiFadeOutDuration: const Duration(seconds: 2),
    this.uiFadeOutSpeed: const Duration(milliseconds: 200),
    this.onBeforeSubmit,
    this.config,
  }) : super(key: key);

  @override
  DanPlayerState createState() => DanPlayerState();
}

class DanPlayerState extends State<DanPlayer>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<DanmakuLayerState> _danmakuLayer = GlobalKey();
  final GlobalKey _container = GlobalKey();
  String name;
  VideoPlayerController _controller;
  bool _displayDanmkau;
  bool _play = false;
  DanPlayerConfig config;
  double _videoAspectRatio = 1;
  DanPlayerMode mode;
  VideoPlayerValue _videoValue;
  bool _fullScreen = false;
  DataSource _ds;

  VideoPlayerValue get videoValue => _videoValue;
  StreamSubscription _dataSourceListen, _volumeListen;

  @override
  void initState() {
    super.initState();
    config = widget.config;
    if (config == null) {
      config = DanPlayerConfig(
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fullScreen = MediaQuery.of(context).orientation == Orientation.landscape;
      setState(() {});
    });
    _dataSourceListen =
        widget.controller._inputStream.stream.listen(_setDataSource);
  }

  @override
  void dispose() {
    // print('danplayer dispose');
    _dataSourceListen?.cancel();
    _volumeListen?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _setDataSource(ds) {
    if (ds is DataSource == false) return;
    print('_setDataSource $ds');
    if (_ds == ds) return;
    _controller?.dispose();
    _ds = ds;
    widget.controller._outputStream.sink.add(ds);
    _play = ds._autoPlay;
    name = ds._title ?? 'DanPlayer';

    switch (_ds._type) {
      case DataSourceType.asset:
        _controller = VideoPlayerController.asset(ds._assetName,
            package: ds._assetPackage);
        break;
      case DataSourceType.file:
        _controller = VideoPlayerController.file(ds._file);
        break;
      case DataSourceType.network:
        _controller = VideoPlayerController.network(ds._url);
        break;
    }
    _controller.initialize();
    _controller.addListener(_listener);
    setState(() {});
    _controller.addListener(_initVideoSize);
  }

  @override
  bool get wantKeepAlive => true;

  void _initVideoSize() {
    if (initialized == false) return;
    _controller.removeListener(_initVideoSize);
    _videoAspectRatio = _controller.value.aspectRatio;
    setState(() {});
  }

//  void setVideo(String video,
//      {DanPlayerMode mode: DanPlayerMode.Normal, String name: 'Danplayer'}) {
//    this.name = name;
//    this.mode = mode;
//    _play = widget.autoPlay;
//    if (_controller?.dataSource == video) return;
//    _controller?.dispose();
//    _controller = VideoPlayerController.network(video)..initialize();
//    if (widget.autoPlay)
//      _controller.play();
//    else
//      _controller.pause();
//    _controller.addListener(_listener);
//    setState(() {});
//  }

  void seekTo(Duration moment) async {
    if (moment < Duration.zero || moment > _videoValue.duration) return;
    print('seek $moment');
    if (_controller.value.initialized) await _controller.seekTo(moment);
  }

  void fillDanmakus(List<Danmaku> danmakus) {
    this._danmakuLayer?.currentState?.fillDanmakus(danmakus);
  }

  void _listener() {
    _videoValue = _controller.value;
    if (!_videoValue.initialized) return;
    print('danplayer listener: $_videoValue');
    widget.controller._outputStream.add(_controller.value);
  }

  set displayDanmkau(bool value) {
    _displayDanmkau = value;
    setState(() {});
  }

  get displayDanmkau => _displayDanmkau;

  set play(bool play) {
    _play = play;
    if (play) {
      _controller?.play();
    } else {
      _controller?.pause();
    }
  }

  get play => _play;

  set volume(double value) {
    _controller.setVolume(value);
  }

  get fullScreen => _fullScreen;

  set fullScreen(bool value) {
    _fullScreen = value;
    if (_fullScreen) {
      /// 隐藏系统栏
      _hideStatusBar();

      /// 只允许横向
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      /// 恢复系统栏
      _showStatusBar();

      () async {
        /// 恢复竖屏
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);

        /// 允许所有方向
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }();
    }
    widget.controller._outputStream.add(FullScreenInfo(_fullScreen));
  }

  void _hideStatusBar() {
    SystemChrome.setEnabledSystemUIOverlays([]);
  }

  void _showStatusBar() {
    SystemChrome.restoreSystemUIOverlays();
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
  }

  bool get initialized {
    return _controller?.value?.initialized == true;
  }

  double get volume => initialized ? _controller.value.volume : 1;

  void stop() {
    _controller.pause();
    _controller.seekTo(Duration());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      key: _container,
      constraints: BoxConstraints.expand(),
      child: Stack(
        overflow: Overflow.clip,
        children: <Widget>[
          Container(color: Colors.black),

          /// 视频画面
          Visibility(
            visible: initialized,
            child: Center(
              child: AspectRatio(
                aspectRatio: _videoAspectRatio,
                child: danPlayerRenderVideo
                    ? VideoPlayer(_controller)
                    : Container(
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
            controller: widget.controller,
          ),
          UILayer(
            config: config,
            fadeOutDuration: widget.uiFadeOutDuration,
            fadeOutSpeed: widget.uiFadeOutSpeed,
            playerState: this,
            controller: widget.controller,
          ),
        ],
      ),
    );
  }
}
