part of '../danplayer.dart';

class DanPlayerProgressBar extends StatefulWidget {
  final double barHeight;
  final DanPlayerController controller;
  final UILayerState uiState;

  const DanPlayerProgressBar({
    Key key,
    this.barHeight = 2,
    @required this.controller,
    @required this.uiState,
  }) : super(key: key);

  @override
  DanPlayerProgressBarState createState() => DanPlayerProgressBarState();
}

class DanPlayerProgressBarState extends State<DanPlayerProgressBar> {
  final GlobalKey _container = GlobalKey();
  final Size handlerSize = const Size(10, 10);
  double _width = 0, _playingX = 0, _bufferedX = 0, _handlerX = 0;
  bool _isDragging = false;
  Duration _handlerDuration = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();
    widget.controller.addPlaying(_playing);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final RenderBox box = _container.currentContext.findRenderObject();
      _width = box.size.width;
    });
  }

  @override
  void dispose() {
    widget.controller.removePlaying(_playing);
    super.dispose();
  }

  VideoPlayerValue _videoValue;

  _playing(VideoPlayerValue value) {
    _videoValue = value;
    if (value.duration == null) return;
    final current =
        value.position.inMilliseconds / value.duration.inMilliseconds;
    _playingX = _width * current;
    _bufferedX = 0;
    if (value.buffered?.isNotEmpty == true) {
      _bufferedX = _width *
          (value.buffered[0].end.inMilliseconds /
              value.duration.inMilliseconds);
    }
    if (_isDragging == false) _handlerX = _playingX;
    _update();
  }

  void _update() {
    if (mounted) setState(() {});
  }

  void _seekTo(double x, {bool seek: true}) {
    x = x.clamp(0.0, _width);
    _playingX = x;
    _handlerX = x;
    if (seek && _videoValue != null) {
      final millisecond = x / _width * _videoValue.duration.inMilliseconds;
      widget.controller.seekTo(Duration(milliseconds: millisecond.toInt()));
    }
    setState(() {});
  }

  bool _beforeDragIsPlaying;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (TapDownDetails details) {
        print('进度条 onTapDown');
        widget.uiState.show();
        _playingX = _handlerX = details.localPosition.dx;
      },
      onTapUp: (TapUpDetails details) {
        print('进度条 onTapUp');
        widget.uiState.hide();
        _seekTo(details.localPosition.dx);
      },
      onPanStart: (DragStartDetails details) {
        _isDragging = true;
        _handlerDuration = Duration.zero;
        _beforeDragIsPlaying = widget.controller.videoPlayerValue.isPlaying;
        widget.controller.pause();
//        _seekTo(details.localPosition.dx, seek: false);
      },
      onPanUpdate: (DragUpdateDetails details) {
        _seekTo(details.localPosition.dx, seek: false);
      },
      onPanEnd: (DragEndDetails details) {
        _seekTo(_playingX);
        _isDragging = false;
        _handlerDuration = Duration(milliseconds: 100);
        widget.uiState.hide();
        if (_beforeDragIsPlaying) widget.controller.play();
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
              color: widget.controller.config.progressBarBufferAreaColor,
            ),

            /// 已经播放区域
            Container(
              width: _playingX,
              height: widget.barHeight,
              color: widget.controller.config.progressBarColor,
            ),

            /// 进度条 指示器
            AnimatedPositioned(
              duration: _handlerDuration,
              left: _handlerX,
              top: -4,
              child: widget.controller.config.progressBarIndicator,
            ),
          ],
        ),
      ),
    );
  }
}
