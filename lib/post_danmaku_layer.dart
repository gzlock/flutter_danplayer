import 'package:danplayer/buttons.dart';
import 'package:danplayer/danplayer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PostDanmakuLayer extends StatefulWidget {
  final DanPlayerConfig theme;
  final double appBarHeight;
  final Future<bool> Function(Danmaku danmaku) onBeforeSubmit;

  const PostDanmakuLayer(
      {Key key, this.theme, this.onBeforeSubmit, this.appBarHeight})
      : super(key: key);

  @override
  PostDanmakuLayerState createState() => PostDanmakuLayerState();
}

class PostDanmakuLayerState extends State<PostDanmakuLayer> {
  final TextEditingController _controller = TextEditingController();
  final _danmakuOptions = [
    OptionValue(0xe69b, 0), // 顶部
    OptionValue(0xe69f, 1), // 移动
    OptionValue(0xe69d, 2), // 底部
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final danmaku = Danmaku(text: text);
    bool isSubmit = true;
    if (widget.onBeforeSubmit != null) {
      isSubmit = await widget.onBeforeSubmit(danmaku);
    }
    if (isSubmit) Navigator.pop(context, danmaku);
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
            return submit();
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
                  width: 300,
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
                        values: _danmakuOptions,
                        defaultValue: _danmakuOptions[1],
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
                            onSubmitted: (_) => submit(),
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
                          submit();
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
