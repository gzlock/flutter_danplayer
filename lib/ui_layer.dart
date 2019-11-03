import 'dart:async';

import 'package:danplayer/route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'danplayer.dart';
import 'post_danmaku_layer.dart';
import 'progress_bar.dart';
import 'buttons.dart';

class UILayer extends StatefulWidget {
  final DanPlayerConfig config;
  final Duration fadeOutDuration;
  final DanPlayerState playerState;

  final Duration fadeOutSpeed;

  const UILayer({
    Key key,
    this.config,
    this.fadeOutDuration,
    this.fadeOutSpeed,
    @required this.playerState,
  }) : super(key: key);

  @override
  UILayerState createState() => UILayerState();
}

class UILayerState extends State<UILayer> {
  GlobalKey _progressBar = GlobalKey(), _barHandler = GlobalKey();
  GlobalKey<MyIconButtonState> _playButton = GlobalKey();
  double appBarHeight = 0, controllerHeight = kToolbarHeight + 20;
  double _titleTop = 0, _controllerBottom = 0;
  Timer _fadeOutTimer;
  bool _isShow = true, _isLoading = true, _inputMode = false;
  String _timeString = '请稍候';
  VideoPlayerValue _playerValue;
  String _error = '';

  get isShow => _isShow;

  @override
  void initState() {
    super.initState();
    widget.playerState.addListener(listener);
    WidgetsBinding.instance.addPostFrameCallback(init);
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  void listener(VideoPlayerValue value) {
    if (value.hasError) {
      _error = value.errorDescription;
      return;
    }
    _playerValue = value;
    if (_isLoading != value.isBuffering) {
      _isLoading = value.isBuffering;
      if (value.isPlaying) hide();
    }
    if (widget.playerState.mode == DanPlayerMode.Normal) {
      _timeString = value.position.inMinutes.toString().padLeft(2, '0') +
          ':' +
          value.position.inSeconds.remainder(60).toString().padLeft(2, '0') +
          ' / ' +
          value.duration.inMinutes.toString().padLeft(2, '0') +
          ':' +
          value.duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    } else {
      _timeString = '直播中';
    }
  }

  void init(_) {
    appBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
    setState(() {});
  }

  /// immediately=true 立即隐藏UI
  /// immediately=false 倒计时后隐藏UI
  void hide({bool immediately: false}) {
    print('隐藏UI');
    _cancelTimer();
    if (immediately) {
      _hide();
    } else {
      _fadeOutTimer = Timer(widget.fadeOutDuration, _hide);
    }
  }

  void _hide() {
    _isShow = false;
    _titleTop = -appBarHeight;
    _controllerBottom = -controllerHeight;
    setState(() {});
  }

  void show() {
    _cancelTimer();
    _titleTop = _controllerBottom = 0;
    if (_isShow == false)
      setState(() {
        _isShow = true;
      });
  }

  void _cancelTimer() {
    if (_fadeOutTimer?.isActive == true) {
      _fadeOutTimer.cancel();
      _fadeOutTimer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('ui build');
    final List<Widget> buttons = [
      /// 播放 / 暂停按钮
      MyIconButton(
        key: _playButton,
        fromIcon: 0xe6a5,
        toIcon: 0xe6a4,
        state: widget.playerState.play,
        onTap: (state) {
          widget.playerState.play = !widget.playerState.play;
          state.state = widget.playerState.play;
        },
      ),
      Container(width: 5),

      /// 时间
      Text(
        _timeString,
        style: TextStyle(color: Colors.white),
      ),
    ];

    if (widget.config.danmaku) {
      buttons.add(Container(width: 10));

      /// 显示 / 隐藏 弹幕内容
      buttons.add(MyIconButton(
        fromIcon: 0xe697,
        toIcon: 0xe696,
        onTap: (state) {
          state.state = !state.state;
        },
      ));
      buttons.add(Container(width: 10));

      /// 进入 发弹幕 界面
      buttons.add(GestureDetector(
        onTap: () async {
          if (_playerValue?.initialized != true) return;
          _inputMode = true;
          bool isPlaying = widget.playerState.play;
          widget.playerState.play = false;
          setState(() {});
          final danmaku = await Navigator.push<Danmaku>(
              context,
              TransparentRoute<Danmaku>(
                  builder: (_) => PostDanmakuLayer(
                        appBarHeight: appBarHeight,
                        theme: widget.config,
                        onBeforeSubmit:
                            widget.playerState.widget.onBeforeSubmit,
                      )));
          _inputMode = false;
          widget.playerState.play = isPlaying;
          print('弹幕内容 $danmaku');
          setState(() {});
        },
        child: Container(
          padding: EdgeInsets.all(8),
          child: Text(
            '发个弹幕试试',
            style: TextStyle(color: Colors.white.withOpacity(0.9)),
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
        ),
      ));
    }
    return Stack(
      fit: StackFit.expand,
      overflow: Overflow.visible,
      children: <Widget>[
        /// loading 界面
        Visibility(
          visible: _isLoading,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                child:
                    widget.config.loadingWidget ?? CircularProgressIndicator(),
                width: 50,
                height: 50,
                margin: EdgeInsets.only(bottom: 10),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image(
                    width: 20,
                    image: AssetImage('assets/logo.png', package: 'danplayer'),
                  ),
                  Container(
                    width: 5,
                  ),
                  Text('Powered by DanPlayer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        shadows: [
                          Shadow(
                            blurRadius: 2.0,
                            color: Colors.black,
                          ),
                        ],
                      )),
                ],
              ),
            ],
          ),
        ),

        GestureDetector(
          onTap: () {
            if (_playerValue?.initialized != true) return;
            print('onTap');
            if (_isShow) {
              widget.playerState.play = !widget.playerState.play;
              _playButton.currentState.state = widget.playerState.play;
              hide();
            } else {
              show();
              hide();
            }
          },
          child: Container(
            color: Colors.transparent,
          ),
        ),

        /// AppBar
        Visibility(
          visible: !_inputMode,
          child: AnimatedPositioned(
            left: 0,
            right: 0,
            top: _titleTop,
            duration: widget.fadeOutSpeed,
            child: Container(
              height: appBarHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.config.controllerBackgroundColor,
                    widget.config.controllerBackgroundColor.withOpacity(0),
                  ],
                ),
              ),
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(widget.playerState.name),
                actions: widget.playerState.config.actions,
              ),
            ),
          ),
        ),
        // controller

        /// 底部控制栏
        Visibility(
          visible: !_inputMode,
          child: AnimatedPositioned(
            left: 0,
            right: 0,
            bottom: _controllerBottom,
            duration: widget.fadeOutSpeed,
            child: Container(
              height: controllerHeight,
              padding: EdgeInsets.only(top: 18, left: 10, right: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.config.controllerBackgroundColor.withOpacity(0),
                    widget.config.controllerBackgroundColor,
                  ],
                ),
              ),
              margin: EdgeInsets.only(top: 4),
              child: Column(
                children: <Widget>[
                  Visibility(
                    visible: widget.playerState.mode == DanPlayerMode.Normal,
                    child: DanPlayerProgressBar(
                      theme: widget.config,
                      playerState: widget.playerState,
                      uiState: this,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: buttons,
                  ),
                ],
              ),
            ),
          ),
        ),

        /// 视频读取错误信息 提示框
        Visibility(
          visible: widget.playerState.videoValue?.hasError == true,
          child: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
            child: Text(
              _error,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
