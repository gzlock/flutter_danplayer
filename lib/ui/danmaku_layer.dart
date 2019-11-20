part of '../danplayer.dart';

class DanmakuLayer extends StatefulWidget {
  final DanPlayerController controller;
  final int moveDuration, fadeOutDuration;
  final GlobalKey<_Monitor> monitor;

  const DanmakuLayer({
    Key key,
    @required this.controller,
    @required this.moveDuration,
    @required this.fadeOutDuration,
    @required this.monitor,
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
    RenderBox box = context.findRenderObject();
    _danmakuPainter = DanmakuPainter(
        monitor: widget.monitor,
        controller: widget.controller,
        moveDuration: widget.moveDuration,
        fadeOutDuration: widget.fadeOutDuration,
        widgetSize: box.size);
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
  final List<Danmaku> _waitToShow = [];
  final int moveDuration, fadeOutDuration;
  final DanPlayerController controller;
  final GlobalKey<_Monitor> monitor;
  final Size widgetSize;

  TextStyle textStyle;
  List<DanmakuMoveDrawer> _movePool = [];
  List<DanmakuFixedDrawer> _fixedPool = [];

  Map<int, List<DanmakuMoveDrawer>> _moveShowing = {};
  Map<int, List<DanmakuFixedDrawer>> _topShowing = {};
  Map<int, List<DanmakuFixedDrawer>> _bottomShowing = {};

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
    _total.clear();
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
    init();
  }

  void _playStateChanged(bool isPlaying) {
    _isPlaying = isPlaying;
  }

  void _playing(VideoPlayerValue value) {
    _playerValue = value;
  }

  void _seek(VideoPlayerValue value) {
    _waitToShow
      ..clear()
      ..addAll(_total);
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
    _total.add(danmaku);
    _waitToShow.add(danmaku);
  }

  _addDanmakus(List<Danmaku> danmakus) {
    print('add danmakus ${danmakus.length}');
    _total.addAll(danmakus);
    _waitToShow.addAll(danmakus);
  }

  void _drawerDead(DanmakuDrawer drawer) {
    print('drawer dead ${drawer.danmaku}');
    if (drawer is DanmakuMoveDrawer) {
      _movePool.add(drawer);
      _moveShowing[drawer.y].remove(drawer);
    } else {
      _fixedPool.add(drawer);
      if (drawer.danmaku.type == DanmakuType.Top)
        _topShowing[drawer.y].remove(drawer);
      else
        _bottomShowing[drawer.y].remove(drawer);
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
          _waitToShow.removeAt(i);
          _createDrawer(tempDanmaku, size);
        }
      }
    }
    int top = 0, move = 0, bottom = 0;
    _topShowing.values.forEach((List<DanmakuDrawer> list) {
      top += list.length;
      list.forEach((drawer) => drawer.draw(canvas, size, frameDetail));
    });
    _bottomShowing.values.forEach((List<DanmakuDrawer> list) {
      move += list.length;
      list.forEach((drawer) => drawer.draw(canvas, size, frameDetail));
    });
    _moveShowing.values.forEach((List<DanmakuDrawer> list) {
      bottom += list.length;
      list.forEach((drawer) => drawer.draw(canvas, size, frameDetail));
    });
//    print('paint 显示:$_showingLength 等待：${_waitToShow.length}'
//        ' 耗时：$frameDetail 尺寸：$size');
    SchedulerBinding.instance.addPostFrameCallback((_) {
      monitor?.currentState?._updateDanmaku(
        total: _total.length,
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

  _createDrawer(Danmaku danmaku, Size size) {
    if (controller.config.danmakuOverlapType != DanmakuOverlapType.Normal &&
        controller.config.danmakuOverlapType != DanmakuOverlapType.Unlimited &&
        danmaku.type == DanmakuType.Bottom) {
      /// 有显示区域限制，不显示: 固定在下方位置的弹幕
      return;
    }

    int y = 0;

    if (danmaku.type == DanmakuType.Normal) {
      DanmakuMoveDrawer drawer;
      final entries = _moveShowing.entries;
      List line;
      entries.every((kv) {
        if (kv.value.length == 0) {
          line = kv.value;
          y = kv.key;
        } else {
          kv.value.every((drawer) {
            if (drawer.y + drawer.painter.size.width > size.width) return false;
            line = kv.value;
            y = kv.key;
            return false;
          });
        }
        return line == null;
      });

      if (line == null &&
          controller.config.danmakuOverlapType ==
              DanmakuOverlapType.Unlimited) {
        /// 找不到可以填入的空行
        drawer = _createMoveDrawer(danmaku);
        drawer.speed = (size.width + drawer.painter.width) / moveDuration;
        drawer.x = size.width;
        drawer.y = y.toDouble();
        line.add(drawer);
      } else if (line != null) {
        /// 找到空行
        lastMoveLine = y;
        drawer = _createMoveDrawer(danmaku);
        drawer.speed = (size.width + drawer.painter.width) / moveDuration;
        drawer.x = size.width;
        drawer.y = y.toDouble();
        line.add(drawer);
      }
    } else {
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
          controller.config.danmakuOverlapType ==
              DanmakuOverlapType.Unlimited) {
        /// 找不到空行
        drawer = _createFixedDrawer(danmaku);
        if (danmaku.type == DanmakuType.Top) {
          lastTopLine += lineHeight;
          if (lastTopLine > size.height) lastTopLine = 0;
          drawer.y = lastTopLine.toDouble();
        } else {
          lastBottomLine += lineHeight;
          if (lastBottomLine > size.height) lastBottomLine = 0;
          drawer.y = lastBottomLine + size.height - lineHeight;
        }
      } else if (line != null) {
        /// 找到空行
        drawer = _createFixedDrawer(danmaku);
        drawer.showTime = fadeOutDuration;
        drawer.x = (size.width - drawer.painter.size.width) / 2;
        drawer.y = y.toDouble();
        if (danmaku.type == DanmakuType.Bottom) {
          drawer.y += size.height - lineHeight;
          lastBottomLine = y;
        } else
          lastTopLine = y;
        line.add(drawer);
      }
    }
  }

  DanmakuFixedDrawer _createFixedDrawer(Danmaku danmaku) {
    if (_fixedPool.isEmpty)
      return DanmakuFixedDrawer(_drawerDead, danmaku, textStyle);
    else
      return _fixedPool.removeAt(0)..reset(danmaku, textStyle);
  }

  DanmakuMoveDrawer _createMoveDrawer(Danmaku danmaku) {
    if (_fixedPool.isEmpty)
      return DanmakuMoveDrawer(_drawerDead, danmaku, textStyle);
    else
      return _movePool.removeAt(0)..reset(danmaku, textStyle);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }

  void init() {
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
    print('lineHeight $widgetSize $lineHeight ');
  }
}
