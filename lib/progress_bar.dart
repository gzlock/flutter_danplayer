import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'danplayer.dart';
import 'ui_layer.dart';

class DanPlayerProgressBar extends StatefulWidget {
  final DanPlayerTheme theme;
  final double barHeight;
  final DanPlayerState playerState;
  final UILayerState controllerState;

  const DanPlayerProgressBar({
    Key key,
    this.theme,
    this.barHeight = 2,
    @required this.playerState,
    @required this.controllerState,
  }) : super(key: key);

  @override
  DanPlayerProgressBarState createState() => DanPlayerProgressBarState();
}

class DanPlayerProgressBarState extends State<DanPlayerProgressBar> {
  final GlobalKey _container = GlobalKey();
  final Size handlerSize = const Size(10, 10);
  double _width = 0;
  double _playerX = 0, _bufferedX = 0;

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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        widget.controllerState.show();
      },
      onTapCancel: () {
        widget.controllerState.hide(immediately: false);
      },
      child: Container(
        key: _container,
        height: 20,
        child: Stack(
          overflow: Overflow.visible,
          children: <Widget>[
            Container(
              constraints: BoxConstraints.expand(height: widget.barHeight),
              color: Colors.grey,
            ),
            Container(
              constraints: BoxConstraints.expand(
                  width: _bufferedX, height: widget.barHeight),
              color: widget.theme.progressBarBufferAreaColor,
            ),
            Positioned(
              left: 0,
              width: _playerX,
              height: widget.barHeight,
              child: Container(
                color: widget.theme.progressBarColor,
              ),
            ),
            AnimatedPositioned(
              duration: Duration(milliseconds: 100),
              left: _playerX,
              top: -4,
              child: widget.theme.progressBarHandler,
            ),
          ],
        ),
      ),
    );
  }
}
