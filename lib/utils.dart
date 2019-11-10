import 'dart:math';
import 'dart:ui';

String durationToString(Duration duration) {
  return duration.inMinutes.toString().padLeft(2, '0') +
      ':' +
      duration.inSeconds.remainder(60).toString().padLeft(2, '0');
}

Color randomColor({int min = 150}) {
  final random = Random.secure();
  return Color.fromARGB(255, random.nextInt(255 - min) + min,
      random.nextInt(255 - min) + min, random.nextInt(255 - min) + min);
}
