import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'danplayer.dart';
import 'ui_layer.dart';

class DanPlayerProgressBar extends StatefulWidget {
  final DanPlayerConfig theme;
  final double barHeight;
  final DanPlayerState playerState;
  final UILayerState uiState;

  const DanPlayerProgressBar({
    Key key,
    this.theme,
    this.barHeight = 2,
    @required this.playerState,
    @required this.uiState,
  }) : super(key: key);

  @override
  DanPlayerProgressBarState createState() => DanPlayerProgressBarState();
}

class DanPlayerProgressBarState extends State<DanPlayerProgressBar> {
  final GlobalKey _container = GlobalKey();
  final Size handlerSize = const Size(10, 10);
  double _width = 0, _playerX = 0, _bufferedX = 0, _handlerX = 0;
  bool _isDragging = false;
  Duration _handlerDuration = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();
    widget.playerState.addListener(listener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox box = _container.currentContext.findRenderObject();
      _width = box.size.width;
    });
  }

  void listener(VideoPlayerValue value) {
    if (value.duration == null) return;
    final current =
        value.position.inMilliseconds / value.duration.inMilliseconds;
    _playerX = _width * current;
    _bufferedX = 0;
    if (value.buffered?.isNotEmpty == true) {
      _bufferedX = _width *
          (value.buffered[0].end.inMilliseconds /
              value.duration.inMilliseconds);
    }
    if (_isDragging == false) _handlerX = _playerX;
    _update();
  }

  void _update() {
    if (mounted) setState(() {});
  }

  void _seekTo(double x, {bool seek: true}) {
    if (x < 0 || x > _width) return;
    _playerX = x;
    _handlerX = x;
    if (seek && widget.playerState.videoValue != null) {
      final millisecond =
          x / _width * widget.playerState.videoValue.duration.inMilliseconds;
      widget.playerState.seekTo(Duration(milliseconds: millisecond.toInt()));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (TapDownDetails details) {
        print('进度条 onTapDown');
        widget.uiState.show();
      },
      onTapUp: (TapUpDetails details) {
        print('进度条 onTapUp');
        widget.uiState.hide();
        _seekTo(details.localPosition.dx);
      },
      onPanStart: (DragStartDetails details) {
        _isDragging = true;
        _handlerDuration = Duration.zero;
        _seekTo(details.localPosition.dx, seek: false);
      },
      onPanUpdate: (DragUpdateDetails details) {
        final x = _playerX + details.delta.dx;
        _seekTo(x);
      },
      onPanEnd: (_) {
        _isDragging = false;
        _handlerDuration = Duration(milliseconds: 100);
        widget.uiState.hide();
      },
      child: Container(
        key: _container,
        height: 20,
        child: Stack(
          overflow: Overflow.visible,
          children: <Widget>[
            /// 底色
            Container(
              constraints: BoxConstraints.expand(height: widget.barHeight),
              color: Colors.grey,
            ),

            /// 缓存区域
            Container(
              constraints: BoxConstraints.expand(
                width: _bufferedX,
                height: widget.barHeight,
              ),
              color: widget.theme.progressBarBufferAreaColor,
            ),

            /// 已经播放区域
            Container(
              width: _playerX,
              height: widget.barHeight,
              color: widget.theme.progressBarColor,
            ),

            /// 进度条 指示器
            AnimatedPositioned(
              duration: _handlerDuration,
              left: _handlerX,
              top: -4,
              child: widget.theme.progressBarHandler,
            ),
          ],
        ),
      ),
    );
  }
}
