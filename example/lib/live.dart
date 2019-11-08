import 'package:flutter/material.dart';
import 'package:danplayer/danplayer.dart';

const url = 'http://vfx.mtime.cn/Video/2019/03/09/mp4/190309153658147087.mp4';

class LiveDemo extends StatefulWidget {
  @override
  _LiveDemo createState() => _LiveDemo();
}

class _LiveDemo extends State<LiveDemo> {
  DanPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DanPlayerController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DanPlayer(controller: _controller, mode: DanPlayerMode.Live),
    );
  }
}
