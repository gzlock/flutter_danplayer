part of '../danplayer.dart';

enum DanmakuType {
  Top,
  Normal,
  Bottom,
}

class Danmaku {
  String id;
  final String text;
  final Duration currentTime;
  final Color fill, borderColor;
  final DanmakuType type;
  bool _hasBorder = false;

  Danmaku({
    @required this.text,
    this.id,
    this.currentTime: Duration.zero,
    this.type: DanmakuType.Normal,
    this.fill: Colors.white,
    this.borderColor,
  }) {
    _hasBorder = borderColor != null && borderColor != Colors.transparent;
  }

  @override
  String toString() {
    return json.encode(toJson());
  }

  bool get hasBorderColor => _hasBorder;

  Map<String, dynamic> toJson() {
    var type;
    switch (type) {
      case DanmakuType.Top:
        type = 0;
        break;
      case DanmakuType.Bottom:
        type = 2;
        break;
      default:
        type = 1;
        break;
    }
    //todo 处理颜色
    return {
      'id': id,
      'text': text,
      'duration': currentTime.inMilliseconds,
      'type': type,
    };
  }

  static Danmaku fromJson(Map<String, dynamic> map) {
    var type;
    switch (map['type']) {
      case 0:
        type = DanmakuType.Top;
        break;
      case 2:
        type = DanmakuType.Bottom;
        break;
      default:
        type = DanmakuType.Normal;
        break;
    }

    //todo 处理颜色
    return Danmaku(
        id: map['id'],
        text: map['text'],
        fill: map['color'],
        type: type,
        currentTime: Duration(milliseconds: map['duration']));
  }
}
