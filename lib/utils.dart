String durationToString(Duration duration) {
  return duration.inMinutes.toString().padLeft(2, '0') +
      ':' +
      duration.inSeconds.remainder(60).toString().padLeft(2, '0') +
      ' / ' +
      duration.inMinutes.toString().padLeft(2, '0') +
      ':' +
      duration.inSeconds.remainder(60).toString().padLeft(2, '0');
}
