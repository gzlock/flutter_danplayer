part of '../danplayer.dart';

class DanmakuLayer extends StatefulWidget {
  final DanPlayerController controller;
  final double fontSize;
  final int moveDuration, fadeOutDuration;

  const DanmakuLayer({
    Key key,
    @required this.controller,
    @required this.moveDuration,
    @required this.fadeOutDuration,
    this.fontSize = 14,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => DanmakuLayerState();
}

class DanmakuLayerState extends State<DanmakuLayer> {
  DanmakuPainter _danmakuPainter;

  @override
  void initState() {
    super.initState();
    _danmakuPainter = DanmakuPainter(
        controller: widget.controller,
        moveDuration: widget.moveDuration,
        fadeOutDuration: widget.fadeOutDuration);
    _danmakuPainter.textStyle = TextStyle(
      fontSize: widget.fontSize,
      shadows: [
        Shadow(
          blurRadius: 2.0,
          color: Colors.black,
        ),
      ],
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RenderBox box = context.findRenderObject();
      _danmakuPainter.init(box.size);
    });
  }

  @override
  void dispose() {
    _danmakuPainter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints.expand(),
      child: CustomPaint(painter: _danmakuPainter),
    );
  }
}

abstract class DanmakuDrawer {
  final Function(DanmakuDrawer drawer) onHide;
  Danmaku danmaku;
  TextPainter painter;
  Path path;
  Paint paint;

  double x = 0, y = 0;

  DanmakuDrawer(
      {@required this.onHide,
      @required this.danmaku,
      @required TextStyle style}) {
    _init(this, style);
  }

  double get width => painter.size.width;

  reset(Danmaku danmaku, TextStyle style) {
    this.danmaku = danmaku;
    _init(this, style);
  }

  void _draw(Canvas canvas) {
    painter.paint(canvas, Offset(x, y));
    if (danmaku.hasBorderColor) {
      canvas.drawRect(
          Rect.fromLTWH(x, y, painter.size.width, painter.size.height), paint);
    }
  }

  static _init(DanmakuDrawer drawer, TextStyle style) {
    drawer.painter = TextPainter(
      text: TextSpan(
          text: drawer.danmaku.text,
          style: style.copyWith(color: drawer.danmaku.fill)),
      textDirection: TextDirection.ltr,
    )..layout();
    drawer.x = drawer.y = 0;
    drawer.paint = null;
    if (drawer.danmaku.hasBorderColor) {
      drawer.paint = Paint()
        ..color = drawer.danmaku.borderColor
        ..style = PaintingStyle.stroke;
    }
  }

  void draw(Canvas canvas, Size size, int frameDetails);
}

class DanmakuMoveDrawer extends DanmakuDrawer {
  DanmakuMoveDrawer(
      Function(DanmakuDrawer drawer) onHide, Danmaku danmaku, TextStyle style)
      : super(onHide: onHide, danmaku: danmaku, style: style);
  double speed;

  @override
  void draw(Canvas canvas, Size size, int frameDetail) {
    _draw(canvas);
    x -= speed * frameDetail.toDouble();
    print('速度 ${speed * frameDetail}');
    if (x < 0) onHide(this);
  }
}

class DanmakuFixedDrawer extends DanmakuDrawer {
  DanmakuFixedDrawer(
      Function(DanmakuDrawer drawer) onHide, Danmaku danmaku, TextStyle style)
      : super(onHide: onHide, danmaku: danmaku, style: style);
  int showTime;

  @override
  void draw(Canvas canvas, Size size, int frameDetail) {
    _draw(canvas);
    showTime -= frameDetail;
    if (showTime < 0) onHide(this);
  }
}

class DanmakuPainter extends CustomPainter {
  final List<Danmaku> _total = [];
  final int moveDuration, fadeOutDuration;
  final DanPlayerController controller;

  TextStyle textStyle;
  List<Danmaku> _waitToShow = [];
  List<DanmakuMoveDrawer> _movePool = [];
  List<DanmakuFixedDrawer> _fixedPool = [];

  Map<int, List<DanmakuMoveDrawer>> _moveShowing = {};
  Map<int, List<DanmakuFixedDrawer>> _topShowing = {};
  Map<int, List<DanmakuFixedDrawer>> _bottomShowing = {};

  int _lastFrameTime = 0;
  bool _isPlaying = false;
  VideoPlayerValue _playerValue;

  DanmakuPainter({this.controller, this.moveDuration, this.fadeOutDuration}) {
    controller.addVideoPlayerInit(_init);
    controller.addPlayStateChanged(_playStateChanged);
    controller.addPlaying(_playing);
    controller.addSeek(_playing);
  }

  dispose() {
    _isPlaying = false;
    _total.clear();
    _waitToShow.clear();

    _moveShowing.clear();
    _movePool.clear();

    _topShowing.clear();
    _fixedPool.clear();
    controller.removeVideoPlayerInit(_init);
    controller.removePlayStateChanged(_playStateChanged);
    controller.removePlaying(_playing);
    controller.removeAddDanmaku(_addDanmaku);
  }

  void _init(_) {}

  void _playStateChanged(bool isPlaying) {
    _isPlaying = isPlaying;
  }

  void _playing(VideoPlayerValue value) {
    _playerValue = value;
  }

  void _seek(VideoPlayerValue value) {
    _waitToShow = _total;
    _moveShowing.values.forEach((list) => _movePool.addAll(list));
    _topShowing.values.forEach((list) => _fixedPool.addAll(list));
    _bottomShowing.values.forEach((list) => _fixedPool.addAll(list));
  }

  _addDanmaku(Danmaku danmaku) {
    print('danmaku_layer $danmaku');
    _total.add(danmaku);
    _waitToShow.add(danmaku);
  }

  void _drawerDead(DanmakuDrawer drawer) {
    print('drawer dead ${drawer.danmaku}');
    if (drawer is DanmakuMoveDrawer) {
      _movePool.add(drawer);
      _moveShowing.remove(drawer);
    } else {
      _fixedPool.add(drawer);
      _topShowing.remove(drawer);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (controller.initialized == false) return;
    var frameDetail =
        _isPlaying ? DateTime.now().millisecondsSinceEpoch - _lastFrameTime : 0;
    Danmaku tempDanmaku;
    int different;
    if (_isPlaying) {
      for (var i = 0; i < _waitToShow.length; i++) {
        tempDanmaku = _waitToShow[i];
        different = tempDanmaku.currentTime.inMilliseconds -
            controller.videoPlayerValue.position.inMilliseconds;
        print('different $different');
        if (different < 200) {
          print('显示');
          _waitToShow.remove(tempDanmaku);
          _createDrawer(tempDanmaku, size);
        }
      }
    }
    int _showingLength = 0;
    _topShowing.values.forEach((List<DanmakuDrawer> list) {
      _showingLength += list.length;
      list.forEach((drawer) => drawer.draw(canvas, size, frameDetail));
    });
    _bottomShowing.values.forEach((List<DanmakuDrawer> list) {
      _showingLength += list.length;
      list.forEach((drawer) => drawer.draw(canvas, size, frameDetail));
    });
    _moveShowing.values.forEach((List<DanmakuDrawer> list) {
      _showingLength += list.length;
      list.forEach((drawer) => drawer.draw(canvas, size, frameDetail));
    });
//    print('paint 显示:$_showingLength 等待：${_waitToShow.length}'
//        ' 耗时：$frameDetail 尺寸：$size');
    _lastFrameTime = DateTime.now().millisecondsSinceEpoch;
  }

  DanmakuDrawer _createDrawer(Danmaku danmaku, Size size) {
    if (danmaku.type == DanmakuType.Normal) {
      DanmakuMoveDrawer drawer;
      if (_movePool.isEmpty)
        drawer = DanmakuMoveDrawer(_drawerDead, danmaku, textStyle);
      else
        drawer = _movePool.removeAt(0)..reset(danmaku, textStyle);
      drawer.speed = (size.width + drawer.painter.width) / moveDuration;
      drawer.x = size.width;
      _moveShowing[0].add(drawer);
      //todo 计算重叠位置
      return drawer;
    } else {
      DanmakuFixedDrawer drawer;
      if (_fixedPool.isEmpty)
        drawer = DanmakuFixedDrawer(_drawerDead, danmaku, textStyle);
      else
        drawer = _fixedPool.removeAt(0)..reset(danmaku, textStyle);
      drawer.showTime = fadeOutDuration;
      drawer.x = (size.width - drawer.painter.size.width) / 2;
      _topShowing[0].add(drawer);
      if (danmaku.type == DanmakuType.Top) {
        drawer.y = 0;
      } else {
        drawer.y = size.height;
      }
      //todo 计算重叠位置
      return drawer;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }

  void init(Size size) {
    final test = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(text: 'M', style: textStyle))
      ..layout();
    final lineHeight = test.size.height.toInt() + 2;
    _moveShowing.clear();
    _topShowing.clear();
    var height = 0;
    print('lineHeight $size ${test.size} $lineHeight');
    while (true) {
      _moveShowing[height] = [];
      _topShowing[height] = [];
      _bottomShowing[height] = [];
      height += lineHeight;
      if ((height + lineHeight) > size.height) break;
    }
  }
}
