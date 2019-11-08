part of '../danplayer.dart';

class DanmakuLayer extends StatefulWidget {
  final DanPlayerController controller;

  const DanmakuLayer({Key key, @required this.controller}) : super(key: key);

  @override
  State<StatefulWidget> createState() => DanmakuLayerState();
}

class DanmakuLayerState extends State<DanmakuLayer> {
  final List<Widget> widgets = [];
  final List<Danmaku> danmakus = [];

  @override
  void initState() {
    super.initState();
    widget.controller.addPositionChanged(listener);
  }

  @override
  void dispose() {
    widget.controller.removePositionChanged(listener);
    super.dispose();
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
