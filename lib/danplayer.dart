library flutter_danplayer;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import './utils.dart';

part 'controller.dart';

part 'route.dart';

part 'ui/video_gesture.dart';

part 'ui/buttons.dart';

part 'ui/danmaku_layer.dart';

part 'ui/monitor.dart';

part 'ui/post_danmaku_layer.dart';

part 'ui/progress_bar.dart';

part 'ui/ui_layer.dart';

part 'ui/playing_duration.dart';

part 'class/danmaku.dart';

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

final Widget defaultProgressBarIndicator = Container(
  width: 10,
  height: 10,
  decoration: BoxDecoration(
    color: Colors.purpleAccent,
    shape: BoxShape.circle,
  ),
);

final Widget defaultLoadingIndicator = Container(
  width: 40,
  height: 40,
  child: CircularProgressIndicator(),
);

enum DanPlayerMode {
  Normal,
  Live,
}

enum DanmakuOverlapType {
  Normal, // 防重叠
  Unlimited, // 不限制，海量弹幕模式
  _25Percent, // 只在25%的区域高度显示弹幕
  _50Percent, // 只在50%的区域高度显示弹幕
  _75Percent, // 只在75%的区域高度显示弹幕
}

class DanPlayerConfig {
  final Color backgroundColor;
  final Color backgroundLightColor;
  final Color backgroundDeepColor;
  final Color progressBarColor;
  final Color progressBarBufferAreaColor;
  Widget progressBarIndicator, loadingWidget;

  /// the appBar actions
  final List<Widget> actions;

  final Duration uiFadeOutDuration,
      uiFadeOutSpeed,
      danmakuMoveDuration,
      danmakuFadeOutDuration;

  /// enable / disable danmaku functions
  final bool danmaku;

  final bool showTitleBar, showFullScreenButton;

  final double fontSize;

  final DanmakuOverlapType danmakuOverlapType;

  final DanPlayerMode mode;

  DanPlayerConfig({
    Widget progressBarIndicator,
    Widget loadingWidget,
    this.danmakuOverlapType: DanmakuOverlapType.Normal,
    this.backgroundColor: const Color.fromRGBO(0, 0, 0, 0.3),
    this.backgroundLightColor: Colors.transparent,
    this.backgroundDeepColor: const Color.fromRGBO(0, 0, 0, 0.5),
    this.progressBarColor: Colors.blue,
    this.progressBarBufferAreaColor: Colors.blueGrey,
    this.actions: const [],
    this.danmaku: true,
    this.uiFadeOutDuration: const Duration(seconds: 5),
    this.uiFadeOutSpeed: const Duration(milliseconds: 200),
    this.danmakuMoveDuration: const Duration(seconds: 8),
    this.danmakuFadeOutDuration: const Duration(seconds: 5),
    this.fontSize: 18,
    this.showTitleBar: true,
    this.showFullScreenButton: true,
    this.mode: DanPlayerMode.Normal,
  })  : assert(backgroundDeepColor != null),
        assert(progressBarColor != null),
        assert(progressBarBufferAreaColor != null),
        assert(progressBarIndicator != null),
        progressBarIndicator =
            progressBarIndicator ?? defaultProgressBarIndicator,
        loadingWidget = loadingWidget ?? defaultLoadingIndicator;

  copyWith({
    Widget progressBarIndicator,
    Widget loadingWidget,
    Color backgroundColor,
    DanmakuOverlapType danmakuOverlapType,
    Color backgroundLightColor,
    Color backgroundDeepColor,
    Color progressBarColor,
    Color progressBarBufferAreaColor,
    List<Widget> actions,
    bool danmaku,
    Duration uiFadeOutDuration,
    Duration uiFadeOutSpeed,
    Duration danmakuMoveDuration,
    Duration danmakuFadeOutDuration,
    int fontSize,
    bool showFullScreenButton,
    bool showTitleBar,
    DanPlayerMode mode,
  }) {
    return DanPlayerConfig(
      danmakuOverlapType: danmakuOverlapType ?? this.danmakuOverlapType,
      progressBarIndicator: progressBarIndicator ?? this.progressBarIndicator,
      loadingWidget: loadingWidget ?? this.loadingWidget,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundLightColor: backgroundLightColor ?? this.backgroundLightColor,
      backgroundDeepColor: backgroundDeepColor ?? this.backgroundDeepColor,
      progressBarColor: progressBarColor ?? this.progressBarColor,
      progressBarBufferAreaColor:
          progressBarBufferAreaColor ?? this.progressBarBufferAreaColor,
      actions: actions ?? this.actions,
      danmaku: danmaku ?? this.danmaku,
      uiFadeOutDuration: uiFadeOutDuration ?? this.uiFadeOutDuration,
      uiFadeOutSpeed: uiFadeOutSpeed ?? this.uiFadeOutSpeed,
      danmakuMoveDuration: danmakuMoveDuration ?? this.danmakuMoveDuration,
      danmakuFadeOutDuration:
          danmakuFadeOutDuration ?? this.danmakuFadeOutDuration,
      fontSize: fontSize ?? this.fontSize,
      showTitleBar: showTitleBar ?? this.showTitleBar,
      showFullScreenButton: showFullScreenButton ?? this.showFullScreenButton,
      mode: mode ?? this.mode,
    );
  }
}

class DanPlayer extends StatefulWidget {
  final DanPlayerController controller;
  final bool fullScreen;

  const DanPlayer({
    Key key,
    @required this.controller,
    this.fullScreen = false,
  }) : super(key: key);

  @override
  DanPlayerState createState() => DanPlayerState();
}

class DanPlayerState extends State<DanPlayer> {
  final GlobalKey<DanmakuLayerState> _danmakuLayer = GlobalKey();
  final GlobalKey<_Monitor> _monitorKey = GlobalKey();
  String name;
  double _videoAspectRatio = 1;
  Size _size;

  @override
  void initState() {
    super.initState();
    widget.controller._initEvents.add(_init);
    widget.controller._configChangedEvents.add(_configChanged);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      final RenderBox box = context.findRenderObject();
      _size = box.size;
      _configChanged(null);
    });
    if (widget.fullScreen) {
      _fullScreenAction(true);
    }
  }

  @override
  void dispose() {
    // print('danplayer dispose');
    widget.controller._initEvents.remove(_init);
    widget.controller._configChangedEvents.remove(_configChanged);
    super.dispose();
  }

  void _configChanged(_) {
    print('_configChanged');
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(DanPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('danplayer didUpdateWidget');
  }

  void _init(VideoPlayerValue value) {
    _videoAspectRatio = value.aspectRatio;
    if (_videoAspectRatio > 1) {
      // 16:9

    } else if (_videoAspectRatio < 1) {
      // 9:16
    }
    print('_initVideoSize $_videoAspectRatio');
    _configChanged(null);
  }

  void _createFullScreen() async {
    Navigator.push(
        context,
        FullScreenRoute((context) => DanPlayer(
              controller: widget.controller.copyWith(
                  config: widget.controller.config.copyWith(
                showTitleBar: true,
                showFullScreenButton: true,
              )),
            )));
  }

  void _fullScreenAction(bool fullScreen) async {
    if (fullScreen) {
      /// 隐藏系统栏
      _hideStatusBar();

      /// 允许任何方向
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        // DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
        // DeviceOrientation.portraitDown,
      ]);
    } else {
      /// 恢复系统栏
      _showStatusBar();

      () async {
        /// 恢复竖屏
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
//
//        /// 允许所有方向
//        SystemChrome.setPreferredOrientations([
//          DeviceOrientation.portraitUp,
//          DeviceOrientation.portraitDown,
//          DeviceOrientation.landscapeLeft,
//          DeviceOrientation.landscapeRight,
//        ]);
      }();
    }
  }

  void _hideStatusBar() {
    SystemChrome.setEnabledSystemUIOverlays([]);
  }

  void _showStatusBar() {
    SystemChrome.restoreSystemUIOverlays();
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
  }

  @override
  Widget build(BuildContext context) {
    print('danplayer build');
    final children = <Widget>[];
    if (_size != null) {
      children.addAll([
        Container(color: Colors.black),

        /// 视频画面
        Visibility(
          visible: widget.controller.initialized,
          child: Center(
            child: AspectRatio(
              aspectRatio: _videoAspectRatio,
              child: danPlayerRenderVideo
                  ? VideoPlayer(widget.controller._videoPlayerController)
                  : Monitor(key: _monitorKey, controller: widget.controller),
            ),
          ),
        ),
        DanmakuLayer(
          key: _danmakuLayer,
          controller: widget.controller,
          moveDuration:
              widget.controller.config.danmakuMoveDuration.inMilliseconds,
          fadeOutDuration:
              widget.controller.config.danmakuFadeOutDuration.inMilliseconds,
          monitor: _monitorKey,
          size: _size,
        ),
        UILayer(
          controller: widget.controller,
          fullScreen: widget.fullScreen,
          uiSize: UIData(
              appBarHeight:
                  kToolbarHeight + MediaQuery.of(context).padding.top),
          onTapFullScreenButton: () {
            if (widget.fullScreen) {
              Navigator.pop(context);
            } else {
              _createFullScreen();
            }
          },
        ),
      ]);
    }
    return Container(
      constraints: BoxConstraints.expand(),
      child: Stack(
        overflow: Overflow.clip,
        children: children,
      ),
    );
  }
}
