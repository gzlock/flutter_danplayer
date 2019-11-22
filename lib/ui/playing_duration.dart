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
    widget.controller.addVideoPlayerInit(_configChanged);
    widget.controller.addConfig(_configChanged);
  }

  @override
  void dispose() {
    widget.controller.removeVideoPlayerInit(_configChanged);
    widget.controller.removePlaying(_playing);
    widget.controller.removeConfig(_configChanged);
    super.dispose();
  }

  void _configChanged(_) {
    if (widget.controller.config.mode == DanPlayerMode.Live) {
      text = '直播中';
      setState(() {});
      widget.controller.removePlaying(_playing);
    } else if (widget.controller.config.mode == DanPlayerMode.Normal) {
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
