import 'package:flutter/material.dart';
import 'package:flutter_danplayer/flutter_danplayer.dart';

class VODModeDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DanPlayer(
        video:
            'https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8',
        mode: DanPlayerMode.Normal,
        autoPlay: false,
      ),
    );
  }
}
