part of '../danplayer.dart';

class PostDanmakuLayer extends StatefulWidget {
  final DanPlayerConfig theme;
  final double appBarHeight;
  final Duration currentTime;

  const PostDanmakuLayer({
    Key key,
    this.theme,
    this.appBarHeight,
    @required this.currentTime,
  }) : super(key: key);

  @override
  PostDanmakuLayerState createState() => PostDanmakuLayerState();
}

const double iconButtonSize = 30, colorButtonSize = 20;

class PostDanmakuLayerState extends State<PostDanmakuLayer> {
  final TextEditingController _controller = TextEditingController();
  final _danmakuOptions = [
    OptionValue(
      0,
      (context, selected, color) => Icon(
        IconData(0xe69b, fontFamily: 'iconfont', fontPackage: 'danplayer'),
        color: color,
        size: iconButtonSize,
      ),
    ), // 顶部
    OptionValue(
      1,
      (context, selected, color) => Icon(
        IconData(0xe69f, fontFamily: 'iconfont', fontPackage: 'danplayer'),
        color: color,
        size: iconButtonSize,
      ),
    ), // 移动
    OptionValue(
      2,
      (context, selected, color) => Icon(
        IconData(0xe69d, fontFamily: 'iconfont', fontPackage: 'danplayer'),
        color: color,
        size: iconButtonSize,
      ),
    ), // 底部
  ];
  final _danmakuColors = [
    OptionValue(
      Colors.white,
      (context, selected, color) => Container(
        width: colorButtonSize,
        height: colorButtonSize,
        decoration: BoxDecoration(
            color: Colors.white, border: Border.all(color: color, width: 2)),
      ),
    ),
    OptionValue(
      Colors.black,
      (context, selected, color) => Container(
        width: colorButtonSize,
        height: colorButtonSize,
        decoration: BoxDecoration(
            color: Colors.black, border: Border.all(color: color, width: 2)),
      ),
    ),
    OptionValue(
      Colors.red,
      (context, selected, color) => Container(
        width: colorButtonSize,
        height: colorButtonSize,
        decoration: BoxDecoration(
            color: Colors.red, border: Border.all(color: color, width: 2)),
      ),
    ),
    OptionValue(
      Colors.green,
      (context, selected, color) => Container(
        width: colorButtonSize,
        height: colorButtonSize,
        decoration: BoxDecoration(
            color: Colors.green, border: Border.all(color: color, width: 2)),
      ),
    ),
    OptionValue(
      Colors.blue,
      (context, selected, color) => Container(
        width: colorButtonSize,
        height: colorButtonSize,
        decoration: BoxDecoration(
            color: Colors.blue, border: Border.all(color: color, width: 2)),
      ),
    ),
    OptionValue(
      Colors.pinkAccent,
      (context, selected, color) => Container(
        width: colorButtonSize,
        height: colorButtonSize,
        decoration: BoxDecoration(
            color: Colors.pinkAccent,
            border: Border.all(color: color, width: 2)),
      ),
    ),
    OptionValue(
      Colors.yellow,
      (context, selected, color) => Container(
        width: colorButtonSize,
        height: colorButtonSize,
        decoration: BoxDecoration(
            color: Colors.yellow, border: Border.all(color: color, width: 2)),
      ),
    ),
    OptionValue(
      Colors.lightGreenAccent,
      (context, selected, color) => Container(
        width: colorButtonSize,
        height: colorButtonSize,
        decoration: BoxDecoration(
            color: Colors.lightGreenAccent,
            border: Border.all(color: color, width: 2)),
      ),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final danmaku = Danmaku(
      text: text,
      borderColor: Colors.white,
      currentTime: widget.currentTime,
    );
    Navigator.pop(context, danmaku);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          if (event.runtimeType != RawKeyUpEvent) return;
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            print('pressed enter');
            return _submit();
          }
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            print('pressed esc');
            Navigator.pop(context, null);
          }
          // print('onKey $event');
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context, null);
              },
            ),

            /// 选择弹幕的类型和字体颜色
            Positioned(
              top: widget.appBarHeight,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(8),
                  width: MediaQuery.of(context).size.width / 2,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Column(
                    children: [
                      OptionsGroup(
                        hint: '弹幕位置',
                        values: _danmakuOptions,
                        defaultValue: _danmakuOptions[1],
                      ),
                      OptionsGroup(
                        hint: '弹幕颜色',
                        values: _danmakuColors,
                        defaultValue: _danmakuColors[0],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            /// appBar，弹幕输入框在这，使用了autoFocus=true
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: widget.appBarHeight,
              child: Container(
                height: widget.appBarHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.theme.backgroundDeepColor,
                      widget.theme.backgroundDeepColor.withOpacity(0),
                    ],
                  ),
                ),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: Row(
                    children: [
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: TextField(
//                          focusNode: _inputNode,
                            autofocus: true,
                            controller: _controller,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.all(8),
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey),
                              hintText: '输入弹幕内容',
                            ),
                          ),
                        ),
                      ),
                      FlatButton(
                        color: Colors.white.withOpacity(0.4),
                        child: Text(
                          '发送',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          _submit();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
