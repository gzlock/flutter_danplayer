import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'danplayer.dart';
import 'progress_bar.dart';
import 'state_button.dart';

class UILayer extends StatefulWidget {
  final DanPlayerTheme theme;
  final Duration fadeOutDuration;
  final DanPlayerState playerState;

  final Duration fadeOutSpeed;

  const UILayer({
    Key key,
    this.theme,
    this.fadeOutDuration,
    this.fadeOutSpeed,
    @required this.playerState,
  }) : super(key: key);

  @override
  UILayerState createState() => UILayerState();
}

class UILayerState extends State<UILayer> {
  GlobalKey _progressBar = GlobalKey(), _barHandler = GlobalKey();
  FocusNode _focus = new FocusNode();
  TextEditingController _controller = new TextEditingController();
  double titleHeight = 0, controllerHeight = kToolbarHeight + 20;
  double _titleTop = 0, _controllerBottom = 0;
  Timer _fadeOutTimer;
  bool _playing = true, _isShow = true, _isLoading = true, _inputMode = false;
  String _timeString = '请稍候';

  get isShow => _isShow;

  @override
  void initState() {
    super.initState();
    widget.playerState.addListener(listener);
    WidgetsBinding.instance.addPostFrameCallback(init);
    _focus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    print('focus ${_focus.hasFocus}');
    if (!_focus.hasFocus) {
      Navigator.pop(context);
    }
  }

  void listener(VideoPlayerValue value) {
    _playing = value.isPlaying;
    if (_isLoading != value.isBuffering) {
      _isLoading = value.isBuffering;
      setState(() {});
    }
    if (widget.playerState.mode == DanPlayerMode.Normal) {
      _timeString = value.position.inMinutes.toString().padLeft(2, '0') +
          ':' +
          value.position.inSeconds.remainder(60).toString().padLeft(2, '0') +
          '/' +
          value.duration.inMinutes.toString().padLeft(2, '0') +
          ':' +
          value.duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    } else {
      _timeString = '直播中';
    }
  }

  void init(_) {
    titleHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
//    Future.delayed(Duration(seconds: 1)).then((_) => hide());
//    Future.delayed(Duration(seconds: 2)).then((_) => show());
  }

  void hide({bool immediately: false}) {
    print('隐藏UI');
    _cancelTimer();
    if (immediately) {
      _titleTop = -titleHeight;
      _controllerBottom = -controllerHeight;
      setState(() {});
    } else {
      _fadeOutTimer =
          Timer(widget.fadeOutDuration, () => hide(immediately: true));
    }
  }

  void show() {
    _cancelTimer();
    _titleTop = _controllerBottom = 0;
    setState(() {});
  }

  void _cancelTimer() {
    _fadeOutTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    var title;
    print('build inputMode $_inputMode');
    if (_inputMode) {
      title = WillPopScope(
        onWillPop: () async {
          print('onWillPop inputMode $_inputMode');
          if (_inputMode) {
            setState(() {
              _inputMode = false;
            });
            return false;
          }
          return true;
        },
        child: Container(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  margin: EdgeInsets.only(right: 8),
                  child: TextField(
                    textInputAction: TextInputAction.send,
                    autofocus: true,
//                    focusNode: _focus,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(8),
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      hintText: '输入弹幕内容',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
              FlatButton(
                child: Text(
                  '发送',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5)),
                color: Colors.white.withOpacity(0.2),
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
    } else {
      title = Text(widget.playerState.name);
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
                child: CircularProgressIndicator(),
                width: 50,
                height: 50,
                margin: EdgeInsets.only(bottom: 10),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image(
                    width: 20,
                    image: AssetImage('assets/logo.png',
                        package: 'flutter_danplayer'),
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

        /// AppBar
        AnimatedPositioned(
          left: 0,
          right: 0,
          top: _titleTop,
          duration: widget.fadeOutSpeed,
          child: Container(
            height: titleHeight + 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.theme.controllerBackgroundColor,
                  widget.theme.controllerBackgroundColor.withOpacity(0),
                ],
              ),
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: title,
            ),
          ),
        ),
        // controller

        /// 底部控制栏
        AnimatedPositioned(
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
                  widget.theme.controllerBackgroundColor.withOpacity(0),
                  widget.theme.controllerBackgroundColor,
                ],
              ),
            ),
            margin: EdgeInsets.only(top: 4),
            child: Column(
              children: <Widget>[
                DanPlayerProgressBar(
                  theme: widget.theme,
                  playerState: widget.playerState,
                  controllerState: this,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    /// 播放按钮
                    MyIconButton(
                      fromIcon: 0xe6a4,
                      toIcon: 0xe6a5,
                      state: _playing,
                      onTap: (state) {
                        _playing = !_playing;
                        state.state = !_playing;
                        widget.playerState.play = _playing;
                      },
                    ),

                    /// 间隔
                    Container(
                      width: 5,
                    ),

                    /// 时间
                    Text(
                      _timeString,
                      style: TextStyle(color: Colors.white),
                    ),

                    /// 间隔
                    Container(
                      width: 10,
                    ),

                    /// 弹幕开关
                    MyIconButton(
                      fromIcon: 0xe697,
                      toIcon: 0xe696,
                      onTap: (state) {
                        state.state = !state.state;
                      },
                    ),

                    /// 间隔
                    Container(
                      width: 10,
                    ),

                    /// 切换到发弹幕模式
                    GestureDetector(
                      onTap: () {
                        _inputMode = true;
                        setState(() {});
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          '发个弹幕试试',
                          style:
                              TextStyle(color: Colors.white.withOpacity(0.7)),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
