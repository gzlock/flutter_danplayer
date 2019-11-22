import 'dart:math';
import 'dart:ui';

Color randomColor({int min = 100, double opacity = 1}) {
  opacity = opacity.clamp(0.0, 1.0);
  final random = Random();
  return Color.fromRGBO(
      min + random.nextInt(255 - min),
      min + random.nextInt(255 - min),
      min + random.nextInt(255 - min),
      opacity);
}
