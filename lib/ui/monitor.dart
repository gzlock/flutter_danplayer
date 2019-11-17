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

  @override
  void initState() {
    super.initState();
    widget.controller.addPlayStateChanged(_playState);
    _controller = AnimationController(duration: duration, vsync: this)
      ..repeat();
  }

  @override
  void dispose() {
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
                    'Playing: $playing'),
              ),
            ));
  }
}
