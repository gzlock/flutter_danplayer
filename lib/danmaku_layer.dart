import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'danplayer.dart';



class DanmakuLayer extends StatefulWidget {
  final DanPlayerState playerState;

  const DanmakuLayer({Key key, @required this.playerState}) : super(key: key);

  @override
  State<StatefulWidget> createState() => DanmakuLayerState();
}

class DanmakuLayerState extends State<DanmakuLayer> {
  final List<Widget> widgets = [];
  final List<Danmaku> danmakus = [];

  @override
  void initState() {
    super.initState();
    widget.playerState.addListener(listener);
  }

  void listener(VideoPlayerValue value) {
    danmakus
        .where((danmaku) =>
    (danmaku.currentTime - value.position).inMilliseconds > 100)
        .forEach((danamku) => {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: widgets,
    );
  }

  void fillDanmakus(List<Danmaku> danmakus) {
    this.danmakus.addAll(danmakus);
  }

  void clear() {
    danmakus.clear();
    widgets.clear();
  }
}
