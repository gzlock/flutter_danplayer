part of './danplayer.dart';

typedef DanPlayerPositionChanged = Function(VideoPlayerValue value);
typedef DanPlayerFullScreenChanged = Function(bool isFullScreen);
typedef DanPlayerPlayStateChanged = Function(bool isPlaying);
typedef DanPlayerDataSourceChanged = Function(DataSource ds);
typedef DanPlayerVolumeChanged = Function(double volume);
typedef DanPlayerUIChanged = Function(bool show);

class FullScreenInfo {
  final bool value;

  FullScreenInfo(this.value);
}

class PlayStateInfo extends FullScreenInfo {
  PlayStateInfo(bool playState) : super(playState);
}

class UIInfo extends FullScreenInfo {
  UIInfo(bool show) : super(show);
}

class VolumeInfo {
  double volume;
}

/// Entity classe for data sources.
class DataSource {
  /// See [DataSourceType]
  DataSourceType _type;

  String _title;

  File _file;

  String _assetName;

  String _assetPackage;

  String _url;

  bool _autoPlay;

  DataSource._();

  /// Create file data source
  factory DataSource.file(File file, {String title, bool autoPlay: true}) {
    var ds = DataSource._();
    ds._title = title;
    ds._autoPlay = autoPlay;
    ds._file = file;
    ds._type = DataSourceType.file;
    return ds;
  }

  /// Create network data source
  factory DataSource.network(String url, {String title, bool autoPlay: true}) {
    var ds = DataSource._();
    ds._title = title;
    ds._autoPlay = autoPlay;
    ds._url = url;
    ds._type = DataSourceType.network;
    return ds;
  }

  /// Create asset data source
  factory DataSource.asset(String assetName,
      {String package, String title, bool autoPlay: true}) {
    var ds = DataSource._();
    ds._title = title;
    ds._autoPlay = autoPlay;
    ds._assetName = assetName;
    ds._assetPackage = package;
    ds._type = DataSourceType.asset;
    return ds;
  }

  @override
  String toString() {
    var type;
    switch (_type) {
      case DataSourceType.asset:
        type = 'asset';
        break;
      case DataSourceType.file:
        type = 'file';
        break;
      default:
        type = 'network';
    }
    return json.encode({
      'type': type,
      'title': _title,
      'autoPlay': _autoPlay,
      'url': _url,
      'file': _file,
    });
  }
}

class DanPlayerController {
  final StreamController<dynamic> _outputStream = StreamController.broadcast();
  final List<DanPlayerPositionChanged> _position = [];
  final List<DanPlayerFullScreenChanged> _fullScreen = [];
  final List<DanPlayerPlayStateChanged> _playState = [];
  final List<DanPlayerUIChanged> _ui = [];
  final List<DanPlayerDataSourceChanged> _dataSource = [];
  final List<DanPlayerVolumeChanged> _volume = [];
  VideoPlayerController _videoPlayerController;

  /// cache
  VideoPlayerValue _videoPlayerValue;

  DanPlayerController() {
    _outputStream.stream.listen(_listen);
  }

  /// output
  void _listen(dynamic data) {
    if (data is PlayStateInfo) {
      print('触发 PlayStateInfo ${data.value}');
      _playState.forEach((fun) => fun(data.value));
    } else if (data is FullScreenInfo) {
      _fullScreen.forEach((fun) => fun(data.value));
    } else if (data is VideoPlayerValue) {
      _position.forEach((fun) => fun(data));
    } else if (data is DataSource) {
      _dataSource.forEach((fun) => fun(data));
    } else if (data is UIInfo) {
      _ui.forEach((fun) => fun(data.value));
    }
  }

  setDataSource(DataSource ds) {
    assert(ds != null);
    _videoPlayerController?.dispose();
    switch (ds._type) {
      case DataSourceType.asset:
        _videoPlayerController = VideoPlayerController.asset(ds._assetName,
            package: ds._assetPackage);
        break;
      case DataSourceType.file:
        _videoPlayerController = VideoPlayerController.file(ds._file);
        break;
      case DataSourceType.network:
        _videoPlayerController = VideoPlayerController.network(ds._url);
        break;
    }
    _videoPlayerController.initialize();
    if (ds._autoPlay) _videoPlayerController.play();
    _videoPlayerController.addListener(_listener);
  }

  void _listener() {
    _videoPlayerValue = _videoPlayerController.value;
  }

  dispose() {
    _videoPlayerValue = null;
    _videoPlayerController?.dispose();
    _outputStream?.close();
    _position.clear();
    _fullScreen.clear();
    _playState.clear();
    _dataSource.clear();
  }

  addPositionChanged(DanPlayerPositionChanged event) {
    if (_position.contains(event) == false) _position.add(event);
    if (_videoPlayerValue != null) event(_videoPlayerValue);
  }

  removePositionChanged(DanPlayerPositionChanged event) {
    _position.remove(event);
  }

  addFullScreenChanged(DanPlayerFullScreenChanged event) {
    if (_fullScreen.contains(event) == false) _fullScreen.add(event);
  }

  removeFullScreenChanged(DanPlayerFullScreenChanged event) {
    _fullScreen.remove(event);
  }

  addPlayStateChanged(DanPlayerPlayStateChanged event) {
    if (_playState.contains(event) == false) _playState.add(event);

    if (_videoPlayerValue != null) event(_videoPlayerValue.isPlaying);
  }

  removePlayStateChanged(DanPlayerPlayStateChanged event) {
    _playState.remove(event);
  }

  addVolumeChanged(DanPlayerVolumeChanged event) {
    if (_volume.contains(event) == false) _volume.add(event);
    if (_videoPlayerValue != null) event(_videoPlayerValue.volume);
  }

  removeVolumeChanged(DanPlayerVolumeChanged event) {
    _volume.remove(event);
  }

  addUIChanged(DanPlayerUIChanged event) {
    if (_ui.contains(event) == false) _ui.add(event);
  }

  removeUIChanged(DanPlayerUIChanged event) {
    _ui.remove(event);
  }

  seekTo(Duration position) {
    _videoPlayerController?.seekTo(position);
  }

  volume(double value) {
    _videoPlayerController?.setVolume(value);
  }
}
