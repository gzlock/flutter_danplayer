part of '../danplayer.dart';

class PlayingDuration extends StatefulWidget {
  final DanPlayerController controller;

  const PlayingDuration({Key key, this.controller}) : super(key: key);

  @override
  _PlayDuration createState() => _PlayDuration();
}

class _PlayDuration extends State<PlayingDuration> {
  String text = '请稍候';

  @override
  void initState() {
    super.initState();
    widget.controller.addVideoPlayerInit(_init);
  }

  @override
  void dispose() {
    widget.controller.removeVideoPlayerInit(_init);
    widget.controller.removeVideoPlayerInit(_playing);
    super.dispose();
  }

  void _init(VideoPlayerValue value) {
    if (widget.controller._ds._mode == DanPlayerMode.Live) {
      text = '直播中';
    } else if (widget.controller._ds._mode == DanPlayerMode.Normal) {
      widget.controller.addPlaying(_playing);
    }
  }

  void _playing(VideoPlayerValue value) {
    text = durationToString(value.position) +
        ' / ' +
        durationToString(value.duration);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(color: Colors.white),
      );
}
