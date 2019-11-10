import 'package:flutter/material.dart';
import 'package:danplayer/danplayer.dart';

const url = 'http://vfx.mtime.cn/Video/2019/03/09/mp4/190309153658147087.mp4';

class VODDemo extends StatefulWidget {
  @override
  _VODDemo createState() => _VODDemo();
}

class _VODDemo extends State<VODDemo> {
  DanPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DanPlayerController();
    _controller.setDataSource(
        DataSource.network(url, autoPlay: true, title: 'Network Video'));
    Future.delayed(Duration(seconds: 2)).then((_) {
      _controller.setDataSource(
          DataSource.network(url, autoPlay: false, title: '第二个视频'));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: DanPlayer(
      controller: _controller,
      fullScreen: true,
    ));
  }
}
