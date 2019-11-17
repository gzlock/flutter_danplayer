part of '../danplayer.dart';

class VideoGesture extends StatefulWidget {
  final DanPlayerController controller;
  final UILayerState uiState;

  const VideoGesture({
    Key key,
    @required this.uiState,
    @required this.controller,
  }) : super(key: key);

  @override
  VideoGestureState createState() => VideoGestureState();
}

class VideoGestureState extends State<VideoGesture> {
  final GlobalKey _container = GlobalKey();
  VideoPlayerValue _playerValue;
  double _volumeY;
  double _width = 0;
  bool _changingVolume = false, _changingPosition = false;
  Offset _videoDurationOriginal;
  int _positionChange = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addSeek(listener);
    SchedulerBinding.instance.addPostFrameCallback(init);
  }

  @override
  void dispose() {
    widget.controller.removeSeek(listener);
    super.dispose();
  }

  void init(_) {
    RenderBox box = _container.currentContext.findRenderObject();
    _width = box.size.width - box.size.width * 0.3;
    print('音量区域宽度 $_width');
  }

  void listener(VideoPlayerValue value) {
    _playerValue = value;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// 音量大小提示
        Visibility(
          visible: _changingVolume,
          child: Positioned(
            left: _width - 20,
            top: _volumeY,
            child: Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: widget.controller.config.backgroundColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  children: [
                    Icon(
                      IconData(
                        widget.controller.volume > 0 ? 0xe63d : 0xe63e,
                        fontFamily: 'iconfont',
                        fontPackage: 'danplayer',
                      ),
                      color: Colors.white,
                    ),
                    Container(width: 10),
                    Text(
                      (widget.controller.volume * 100).toStringAsFixed(0),
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                )),
          ),
        ),

        /// 视频进度提示
        Visibility(
          visible: _changingPosition,
          child: Center(
            child: UnconstrainedBox(
              child: Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: widget.controller.config.backgroundColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.white),
                    Container(width: 10),
                    Text(
                      '$_positionChange s',
                      style: TextStyle(color: Colors.white),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),

        /// 视频画面上的手势检测
        GestureDetector(
          onTap: () {
            if (_playerValue?.initialized != true) return;
            print('onTap');
            if (widget.uiState.isShow) {
              if (widget.controller.playing)
                widget.controller.pause();
              else
                widget.controller.play();
              widget.uiState.hide();
            } else {
              widget.uiState.show();
              widget.uiState.hide();
            }
          },
          onVerticalDragStart: (DragStartDetails details) {
            print('音量 onPanStart');
            _changingVolume = details.localPosition.dx >= _width;
            _volumeY = details.localPosition.dy;
          },
          onVerticalDragUpdate: (DragUpdateDetails details) {
            if (!_changingVolume) return;
            // print('音量 onPanUpdate');
            final dy = details.localPosition.dy - _volumeY;
            if (dy.abs() > 20) {
              final value = dy > 0 ? 1 : -1;
              widget.controller.volume += value * 0.1;
              _volumeY = details.localPosition.dy;
            }
            setState(() {});
          },
          onVerticalDragEnd: (_) {
            _changingVolume = false;
            setState(() {});
          },
          onHorizontalDragStart: (DragStartDetails details) {
            _videoDurationOriginal = details.localPosition;
            _changingPosition = true;
          },
          onHorizontalDragUpdate: (DragUpdateDetails details) {
            final dx = (details.localPosition - _videoDurationOriginal).dx;
            if (dx.abs() > 50) {
              final value = dx > 0 ? 1 : -1;
              _positionChange += value * 5;
              final to = Duration(
                  milliseconds: _playerValue.position.inMilliseconds +
                      value * 5 * Duration.millisecondsPerSecond);
              widget.controller.seekTo(to);
              _videoDurationOriginal = details.localPosition;
            }
            setState(() {});
          },
          onHorizontalDragEnd: (_) {
            _changingPosition = false;
            setState(() {});
          },
          child: Container(
            key: _container,
            color: Colors.transparent,
          ),
        )
      ],
    );
  }
}
