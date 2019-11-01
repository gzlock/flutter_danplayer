import 'package:flutter/material.dart';
import 'package:flutter_danplayer/flutter_danplayer.dart';

class LiveModeDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DanPlayer(
        video:
            'https://file-examples.com/wp-content/uploads/2017/04/file_example_MP4_1280_10MG.mp4',
        mode: DanPlayerMode.Live,
      ),
    );
  }
}
