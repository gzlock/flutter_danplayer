import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

class MyWidget extends StatelessWidget {
  final String title;
  final String message;

  const MyWidget({
    Key key,
    @required this.title,
    @required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

void main() {
  testWidgets('text size', (WidgetTester tester) async {
    final GlobalKey container = GlobalKey();
    final GlobalKey previewContainer = GlobalKey();
    await tester.pumpWidget(Builder(builder: (BuildContext context) {
      final style = DefaultTextStyle.of(context).style.copyWith(fontSize: 40);
      final text = TextSpan(text: '1', style: style);
      final painter = TextPainter(text: text, textDirection: TextDirection.ltr);

      painter.layout();
      print('text width: ${painter.width}');
      return MaterialApp(
        builder: (context, _) {
          return RepaintBoundary(
              key: previewContainer,
              child: Scaffold(
                body: Stack(
                  children: [
                    Container(
                        key: container,
                        child: Text(
                          text.text,
                          style: style,
                        ))
                  ],
                ),
              ));
        },
      );
    }));
    final RenderBox box = container.currentContext.findRenderObject();
    print('容器尺寸 ${box.size}');

//    RenderRepaintBoundary boundary =
//        previewContainer.currentContext.findRenderObject();
//    ui.Image image = await boundary.toImage();
//    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//    Uint8List pngBytes = byteData.buffer.asUint8List();
//    print(pngBytes);
//    File imgFile = new File('/Users/lock/Desktop/screenshot.png');
//    imgFile.writeAsBytes(pngBytes);
  });
}
