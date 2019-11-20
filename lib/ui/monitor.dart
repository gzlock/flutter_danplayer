part of '../danplayer.dart';

class Monitor extends StatefulWidget {
  final DanPlayerController controller;

  const Monitor({Key key, this.controller}) : super(key: key);

  @override
  _Monitor createState() => _Monitor();
}

class _Monitor extends State<Monitor> with SingleTickerProviderStateMixin {
  final duration = const Duration(seconds: 20);
  final Animatable<Color> colors = TweenSequence<Color>(
    [
      TweenSequenceItem(
        weight: 1.0,
        tween: ColorTween(
          begin: Colors.red,
          end: Colors.green,
        ),
      ),
      TweenSequenceItem(
        weight: 1.0,
        tween: ColorTween(
          begin: Colors.green,
          end: Colors.blue,
        ),
      ),
      TweenSequenceItem(
        weight: 1.0,
        tween: ColorTween(
          begin: Colors.blue,
          end: Colors.pink,
        ),
      ),
    ],
  );
  AnimationController _controller;
  bool playing = false;
  int _totalDanmaku = 0,
      _moveShowing = 0,
      _topShowing = 0,
      _bottomShowing = 0,
      _movePool = 0,
      _fixedPool = 0,
      _frameTime = 0;

  void _updateDanmaku({
    @required int total,
    @required int move,
    @required int top,
    @required int bottom,
    @required int movePool,
    @required int fixedPool,
    @required int frameTime,
  }) {
    _totalDanmaku = total;
    _moveShowing = move;
    _topShowing = top;
    _bottomShowing = top;
    _movePool = movePool;
    _fixedPool = fixedPool;
    _frameTime = frameTime;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addPlayStateChanged(_playState);
    _controller = AnimationController(duration: duration, vsync: this);
  }

  @override
  void dispose() {
    widget.controller.removePlayStateChanged(_playState);
    _controller.dispose();
    super.dispose();
  }

  void _playState(bool isPlaying) {
    if (isPlaying != playing)
      setState(() {
        playing = isPlaying;
        if (playing)
          _controller?.repeat();
        else
          _controller?.stop();
      });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Container(
              constraints: BoxConstraints.expand(),
              color: colors.evaluate(AlwaysStoppedAnimation(_controller.value)),
              child: Center(
                child: Text('When danPlayerRenderVideo = false\n'
                    'Use this widget instead of video\n'
                    'Playing: $playing\n'
                    'Frame time: $_frameTime\n'
                    'Total Danmakus: $_totalDanmaku\n'
                    'Showing Danmakus\n'
                    '    Top: $_topShowing\n'
                    '    Move: $_moveShowing\n'
                    '    Bottom: $_bottomShowing\n'
                    'Pool\n'
                    '    Move: $_movePool\n'
                    '    Fixed: $_fixedPool'),
              ),
            ));
  }
}
