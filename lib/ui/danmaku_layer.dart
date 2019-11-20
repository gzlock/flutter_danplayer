part of '../danplayer.dart';

class DanmakuLayer extends StatefulWidget {
  final DanPlayerController controller;
  final int moveDuration, fadeOutDuration;
  final GlobalKey<_Monitor> monitor;
  final Size size;

  const DanmakuLayer({
    Key key,
    @required this.controller,
    @required this.moveDuration,
    @required this.fadeOutDuration,
    @required this.monitor,
    @required this.size,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => DanmakuLayerState();
}

class DanmakuLayerState extends State<DanmakuLayer> {
  DanmakuPainter _danmakuPainter;

  @override
  void dispose() {
    _danmakuPainter?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _danmakuPainter = DanmakuPainter(
        monitor: widget.monitor,
        controller: widget.controller,
        moveDuration: widget.moveDuration,
        fadeOutDuration: widget.fadeOutDuration,
        widgetSize: widget.size);
    return Container(
      constraints: BoxConstraints.tight(widget.size),
      child: CustomPaint(painter: _danmakuPainter),
    );
  }
}

abstract class DanmakuDrawer {
  Danmaku danmaku;
  TextPainter painter;
  Path path;
  Paint paint;

  double x = 0, y = 0;

  DanmakuDrawer({@required this.danmaku, @required TextStyle style}) {
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

  bool draw(Canvas canvas, Size size, int frameDetails);
}

class DanmakuMoveDrawer extends DanmakuDrawer {
  DanmakuMoveDrawer(Danmaku danmaku, TextStyle style)
      : super(danmaku: danmaku, style: style);
  double speed;

  @override
  bool draw(Canvas canvas, Size size, int frameDetail) {
    _draw(canvas);
    x -= speed * frameDetail.toDouble();
    return x > -painter.size.width;
  }
}

class DanmakuFixedDrawer extends DanmakuDrawer {
  DanmakuFixedDrawer(Danmaku danmaku, TextStyle style)
      : super(danmaku: danmaku, style: style);
  int showTime;

  @override
  bool draw(Canvas canvas, Size size, int frameDetail) {
    _draw(canvas);
    showTime -= frameDetail;
    return showTime > 0;
  }
}

class DanmakuPainter extends CustomPainter {
  final List<Danmaku> _waitToShow = [];
  final int moveDuration, fadeOutDuration;
  final DanPlayerController controller;
  final GlobalKey<_Monitor> monitor;
  Size widgetSize;

  TextStyle textStyle;
  List<DanmakuMoveDrawer> _movePool = [];
  List<DanmakuFixedDrawer> _fixedPool = [];

  final Map<int, List<DanmakuMoveDrawer>> _moveShowing = {};
  final Map<int, List<DanmakuFixedDrawer>> _topShowing = {};
  final Map<int, List<DanmakuFixedDrawer>> _bottomShowing = {};

  int _lastFrameTime = 0;
  int lineHeight = 0;
  bool _isPlaying = false;
  VideoPlayerValue _playerValue;

  DanmakuPainter(
      {this.controller,
      this.moveDuration,
      this.fadeOutDuration,
      this.widgetSize,
      this.monitor}) {
    controller.addPlayStateChanged(_playStateChanged);
    controller.addSeek(_seek);
    controller.addPlaying(_playing);
    controller.addAddDanmaku(_addDanmaku);
    controller.addAddDanmakus(_addDanmakus);
    controller.addConfig(_configChange);
  }

  dispose() {
    _isPlaying = false;
    _waitToShow.clear();

    _moveShowing.clear();
    _movePool.clear();

    _topShowing.clear();
    _fixedPool.clear();
    controller.removePlayStateChanged(_playStateChanged);
    controller.removePlaying(_playing);
    controller.removeAddDanmaku(_addDanmaku);
    controller.removeAddDanmakus(_addDanmakus);
    controller.removeConfig(_configChange);
  }

  _configChange(DanPlayerConfig config) {
    print('painter _configChange');
    init();
  }

  void _playStateChanged(bool isPlaying) {
    _isPlaying = isPlaying;
    _lastFrameTime = DateTime.now().millisecondsSinceEpoch;
  }

  void _playing(VideoPlayerValue value) {
    _playerValue = value;
  }

  void _seek(VideoPlayerValue value) {
    _waitToShow
      ..clear()
      ..addAll(controller._danmakus);
    _moveShowing.values.forEach((list) {
      _movePool.addAll(list);
      list.clear();
    });
    _topShowing.values.forEach((list) {
      _fixedPool.addAll(list);
      list.clear();
    });
    _bottomShowing.values.forEach((list) {
      _fixedPool.addAll(list);
      list.clear();
    });
  }

  _addDanmaku(Danmaku danmaku) {
    // print('danmaku_layer $danmaku');
    _waitToShow.add(danmaku);
  }

  _addDanmakus(List<Danmaku> danmakus) {
    print('add danmakus 1 ${danmakus.length}');
    _waitToShow.addAll(danmakus);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (controller.initialized == false) return;
    if (widgetSize != size) {
      widgetSize = size;
      init();
    }
    var frameDetail =
        _isPlaying ? DateTime.now().millisecondsSinceEpoch - _lastFrameTime : 0;
    Danmaku tempDanmaku;
    final danmakus = _waitToShow
        .where((danmaku) =>
            (danmaku.currentTime.inMilliseconds -
                controller.videoPlayerValue.position.inMilliseconds) <
            200)
        .toList();
    if (_isPlaying) {
      for (var i = 0; i < danmakus.length; i++) {
        tempDanmaku = danmakus[i];
        _waitToShow.remove(tempDanmaku);
        tempDanmaku.type == DanmakuType.Normal
            ? _createMoveDrawer(tempDanmaku, size)
            : _createFixedDrawer(tempDanmaku, size);
        // _createDrawer(tempDanmaku, size);
      }
    }
    int top = 0, move = 0, bottom = 0;
    _topShowing.values.forEach((List<DanmakuDrawer> list) {
      list.removeWhere((drawer) {
        final bool isDelete = !drawer.draw(canvas, size, frameDetail);
        if (isDelete) _fixedPool.add(drawer);
        return isDelete;
      });
      top += list.length;
    });
    _bottomShowing.values.forEach((List<DanmakuDrawer> list) {
      list.removeWhere((drawer) {
        final bool isDelete = !drawer.draw(canvas, size, frameDetail);
        if (isDelete) _fixedPool.add(drawer);
        return isDelete;
      });
      bottom += list.length;
    });
    _moveShowing.values.forEach((List<DanmakuDrawer> list) {
      list.removeWhere((drawer) {
        final bool isDelete = !drawer.draw(canvas, size, frameDetail);
        if (isDelete) _movePool.add(drawer);
        return isDelete;
      });
      move += list.length;
    });
//    print('paint 显示:$_showingLength 等待：${_waitToShow.length}'
//        ' 耗时：$frameDetail 尺寸：$size');
    SchedulerBinding.instance.addPostFrameCallback((_) {
      monitor?.currentState?._updateDanmaku(
        total: controller._danmakus.length,
        top: top,
        move: move,
        bottom: bottom,
        fixedPool: _fixedPool.length,
        movePool: _movePool.length,
        frameTime: frameDetail,
      );
    });
    _lastFrameTime = DateTime.now().millisecondsSinceEpoch;
  }

  int lastMoveLine = 0, lastTopLine = 0, lastBottomLine = 0;

  _createMoveDrawer(Danmaku danmaku, Size size) {
    int y = 0;
    DanmakuMoveDrawer drawer;
    final entries = _moveShowing.entries;
    List line;
    entries.every((kv) {
      if (kv.value.length == 0) {
        line = kv.value;
        y = kv.key;
      } else {
        if (kv.value.last.x + kv.value.last.painter.size.width > size.width)
          return true;
        line = kv.value;
        y = kv.key;
      }
      // print('every ${kv.key} ${kv.value.length} ${line == null}');
      return line == null;
    });

    if (line == null &&
        controller.config.danmakuOverlapType == DanmakuOverlapType.Unlimited) {
      /// 找不到可以填入的空行
      y = lastMoveLine;
      lastMoveLine += lineHeight;
    } else if (line != null) {
      /// 找到空行
      lastMoveLine = y + lineHeight;
    } else if (line == null) {
      return;
    }
    if (lastMoveLine > size.height) lastMoveLine = 0;
    // print('move $y');
    drawer = _getMoveDrawer(danmaku);
    drawer.speed = (size.width + drawer.painter.width) / moveDuration;
    drawer.x = size.width;
    drawer.y = y.toDouble();
    line.add(drawer);
  }

  _createFixedDrawer(Danmaku danmaku, Size size) {
    if (controller.config.danmakuOverlapType != DanmakuOverlapType.Normal &&
        controller.config.danmakuOverlapType != DanmakuOverlapType.Unlimited &&
        danmaku.type == DanmakuType.Bottom) {
      /// 有显示区域限制，不显示: 固定在下方位置的弹幕
      return;
    }
    int y = 0;
    DanmakuFixedDrawer drawer;

    List line;
    Map<int, List<DanmakuFixedDrawer>> target =
        danmaku.type == DanmakuType.Top ? _topShowing : _bottomShowing;

    target.entries.every((kv) {
      if (kv.value.length == 0) {
        line = kv.value;
        y = kv.key;
      }
      return line == null;
    });

    if (line == null &&
        controller.config.danmakuOverlapType == DanmakuOverlapType.Unlimited) {
      /// 找不到空行
      drawer = _getFixedDrawer(danmaku);
      if (danmaku.type == DanmakuType.Top) {
        y = lastTopLine;
        line = _topShowing[lastTopLine];
        lastTopLine += lineHeight;
        if (lastTopLine > size.height) lastTopLine = 0;
        drawer.y = lastTopLine.toDouble();
      } else {
        y = (size.height - lastBottomLine - lineHeight).toInt();
        line = _bottomShowing[lastBottomLine];
        lastBottomLine += lineHeight;
        if (lastBottomLine > size.height) lastBottomLine = 0;
      }
    } else if (line != null) {
      /// 找到空行
      if (danmaku.type == DanmakuType.Top) {
        lastTopLine = y + lineHeight;
        if (lastTopLine > size.height) lastTopLine = 0;
      } else {
        y = lastBottomLine = y + lineHeight;
        if (lastBottomLine > size.height) lastBottomLine = 0;
        y = (size.height - y).toInt();
      }
    } else if (line == null) return;
    drawer = _getFixedDrawer(danmaku);
    drawer.showTime = fadeOutDuration;
    drawer.x = (size.width - drawer.painter.size.width) / 2;
    drawer.y = y.toDouble();
    line.add(drawer);
  }

  DanmakuFixedDrawer _getFixedDrawer(Danmaku danmaku) {
    if (_fixedPool.isEmpty)
      return DanmakuFixedDrawer(danmaku, textStyle);
    else
      return _fixedPool.removeAt(0)..reset(danmaku, textStyle);
  }

  DanmakuMoveDrawer _getMoveDrawer(Danmaku danmaku) {
    if (_movePool.isEmpty)
      return DanmakuMoveDrawer(danmaku, textStyle);
    else
      return _movePool.removeAt(0)..reset(danmaku, textStyle);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }

  void init() {
    print('danmaku layer init $widgetSize');
    if (widgetSize == null) return;
    textStyle = TextStyle(
      fontSize: controller.config.fontSize,
      shadows: [
        Shadow(
          blurRadius: 2.0,
          color: Colors.black,
        ),
      ],
    );
    final test = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(text: 'M', style: textStyle))
      ..layout();
    lineHeight = test.size.height.round() + 4;
    _moveShowing.clear();
    _topShowing.clear();
    _bottomShowing.clear();
    var height = 0;
    while (true) {
      _moveShowing[height] = [];
      _topShowing[height] = [];
      _bottomShowing[height] = [];
      height += lineHeight;
      if ((height + lineHeight) > widgetSize.height) break;
    }
    print(
        'danmaku layer size: $widgetSize, lineHeight: $lineHeight, lines:${_moveShowing.keys}');
  }
}
