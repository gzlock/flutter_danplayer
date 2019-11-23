part of '../danplayer.dart';

class UIData {
  final double appBarHeight;
  final double controllerHeight;

  UIData({
    @required this.appBarHeight,
    this.controllerHeight: kToolbarHeight + 30,
  });
}

class UILayer extends StatefulWidget {
  final DanPlayerController controller;
  final bool fullScreen;
  final VoidCallback onTapFullScreenButton;
  final UIData uiSize;

  const UILayer({
    Key key,
    @required this.controller,
    @required this.uiSize,
    this.fullScreen,
    this.onTapFullScreenButton,
  }) : super(key: key);

  @override
  UILayerState createState() => UILayerState();
}

class UILayerState extends State<UILayer> {
  GlobalKey<MyIconButtonState> _playButton = GlobalKey();
  double _titleTop = 0, _controllerBottom = 0;
  Timer _fadeOutTimer;
  bool _isShow = true, _isLoading = true, _inputMode = false;
  VideoPlayerValue _playerValue;
  String _error = '';

  get isShow => _isShow;

  @override
  void initState() {
    super.initState();
    widget.controller.addVideoPlayerInit(_init);
    widget.controller.addPlaying(_playing);
    widget.controller.addPlayStateChanged(_playState);
  }

  @override
  void dispose() {
    _cancelTimer();
    widget.controller.removeSeek(_playing);
    super.dispose();
  }

  void _init(VideoPlayerValue value) {
    _playerValue = value;
    _isLoading = value.isBuffering;
  }

  void _playState(bool isPlaying) {
    if (isPlaying)
      hide();
    else
      show();
  }

  void _playing(VideoPlayerValue value) {
    if (value.hasError) {
      _error = value.errorDescription;
      return;
    }
    _playerValue = value;
    _isLoading = value.isBuffering;
    _playButton.currentState?.state = widget.controller.playing;
  }

  /// immediately=true 立即隐藏UI
  /// immediately=false 倒计时后隐藏UI
  void hide({bool immediately: false}) {
    print('隐藏UI');
    _cancelTimer();
    if (immediately) {
      _hide();
    } else {
      _fadeOutTimer = Timer(widget.controller.config.uiFadeOutDuration, _hide);
    }
  }

  void _hide() {
    _isShow = false;
    _titleTop = -widget.uiSize.appBarHeight;
    _controllerBottom = -widget.uiSize.controllerHeight;
    widget.controller._outputStream.add(EventData.uiVisibleChanged(_isShow));
    setState(() {});
  }

  void show() {
    _cancelTimer();
    _titleTop = _controllerBottom = 0;
    if (_isShow == false) {
      _isShow = true;
      widget.controller._outputStream.add(EventData.uiVisibleChanged(_isShow));
      if (mounted) setState(() {});
    }
  }

  void _cancelTimer() {
    _fadeOutTimer?.cancel();
    _fadeOutTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    print('ui build');
    if (_playerValue?.initialized != true) return Container();
    final List<Widget> leftButtons = [
      /// 播放 / 暂停按钮
      MyIconButton(
        key: _playButton,
        fromIcon: 0xe6a5,
        toIcon: 0xe6a4,
        state: widget.controller.playing,
        onTap: (state) {
          if (widget.controller.playing)
            widget.controller.pause();
          else
            widget.controller.play();
          state.state = widget.controller.playing;
          hide();
        },
      ),
      Container(width: 5),

      /// 时间
      PlayingDuration(
        controller: widget.controller,
      ),
    ];

    final List<Widget> rightButtons = [];
    if (widget.controller.config.showFullScreenButton) {
      rightButtons.add(MyIconButton(
        onTap: (state) {
          print('全屏');
          if (widget.onTapFullScreenButton != null)
            widget.onTapFullScreenButton();
        },
        fromIcon: 0xe6e8,
        toIcon: 0xe6d9,
        size: 24,
        state: widget.fullScreen,
      ));
    }

    if (widget.controller.config.danmaku) {
      leftButtons.add(Container(width: 10));

      /// 显示 / 隐藏 弹幕内容
      leftButtons.add(MyIconButton(
        fromIcon: 0xe697,
        toIcon: 0xe696,
        onTap: (state) {
          state.state = !state.state;
          widget.controller
              ._distributeEvents(EventData.showDanmakus(state.state));
          hide();
        },
      ));
      leftButtons.add(Container(width: 10));

      /// 进入 发弹幕 界面
      leftButtons.add(GestureDetector(
        onTap: () async {
          if (_playerValue?.initialized != true) return;
          _inputMode = true;
          bool isPlaying = widget.controller.playing;
          widget.controller.pause();
          setState(() {});
          final danmaku = await Navigator.push<Danmaku>(
              this.context,
              TransparentRoute<Danmaku>(
                  builder: (_) => PostDanmakuLayer(
                        appBarHeight: widget.uiSize.appBarHeight,
                        theme: widget.controller.config,
                        currentTime: _playerValue.position,
                      )));
          _inputMode = false;
          if (danmaku != null) {
            bool isPost = true;
            if (widget.controller.onBeforeSubmit != null) {
              isPost = await widget.controller.onBeforeSubmit(danmaku);
            }
            if (isPost) {
              widget.controller.addDanmaku(danmaku);
              // print('发表弹幕内容 $danmaku');
              setState(() {});
            }
          }
          if (isPlaying) widget.controller.play();
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
      children: <Widget>[
        /// loading 界面
        Visibility(
          visible: _isLoading,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                child: widget.controller.config.loadingWidget,
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

        /// 触控、滑动等操作
        VideoGestures(
          controller: widget.controller,
          uiState: this,
        ),

        /// AppBar
        Visibility(
          visible: widget.controller.config.showTitleBar && !_inputMode,
          child: AnimatedPositioned(
            left: 0,
            right: 0,
            top: _titleTop,
            duration: widget.controller.config.uiFadeOutSpeed,
            child: Container(
              height: widget.uiSize.appBarHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.controller.config.backgroundDeepColor,
                    widget.controller.config.backgroundDeepColor.withOpacity(0),
                  ],
                ),
              ),
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(widget.controller._ds._title ?? ''),
                actions: widget.controller.config.actions,
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
            duration: widget.controller.config.uiFadeOutSpeed,
            child: Container(
              height: widget.uiSize.controllerHeight,
              padding:
                  EdgeInsets.only(top: 18, left: 10, right: 10, bottom: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.controller.config.backgroundDeepColor.withOpacity(0),
                    widget.controller.config.backgroundDeepColor,
                  ],
                ),
              ),
              margin: EdgeInsets.only(top: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Visibility(
                    visible:
                        widget.controller.config.mode == DanPlayerMode.Normal,
                    child: DanPlayerProgressBar(
                      controller: widget.controller,
                      uiState: this,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ...leftButtons,
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: rightButtons,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        /// 视频读取错误信息 提示框
        Visibility(
          visible: widget.controller.videoPlayerValue?.hasError == true,
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
