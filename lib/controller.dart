part of './danplayer.dart';

typedef OnPlaying = Function(VideoPlayerValue value);
typedef OnSeek = Function(VideoPlayerValue value);
typedef OnChangedPosition = Function(VideoPlayerValue value);
typedef OnFullScreenChanged = Function(bool isFullScreen);
typedef OnPlayStateChanged = Function(bool isPlaying);
typedef OnDataSourceChanged = Function(DataSource ds);
typedef OnVolumeChanged = Function(double volume);
typedef OnUIChanged = Function(bool show);
typedef OnAddDanmaku = Function(Danmaku danmaku);
typedef OnAddDanmakus = Function(List<Danmaku> danmakus);
typedef OnVideoInit = Function(VideoPlayerValue value);
typedef OnConfigChanged = Function(DanPlayerConfig config);

enum EventType {
  playing,
  seek,
  fullScreenChanged,
  volumeChanged,
  uiVisibleChanged,
  playStateChanged,
  addDanmaku,
  addDanmakus,
  videoPlayerInit,
}

class EventData<T> {
  final EventType type;
  final T value;

  EventData(this.type, this.value);

  /// value is [VideoPlayerValue]
  factory EventData.playing(T value) => EventData<T>(EventType.playing, value);

  /// value is [bool]
  factory EventData.fullScreenChanged(T value) =>
      EventData<T>(EventType.fullScreenChanged, value);

  /// value is [double], from 0 to 1
  factory EventData.volumeChanged(T value) =>
      EventData<T>(EventType.volumeChanged, value);

  /// value is [VideoPlayerValue]
  factory EventData.seek(T value) => EventData<T>(EventType.seek, value);

  /// value is [bool]
  factory EventData.uiVisibleChanged(T value) =>
      EventData<T>(EventType.uiVisibleChanged, value);

  /// value is [Danmaku]
  factory EventData.addDanmaku(T value) =>
      EventData<T>(EventType.addDanmaku, value);

  /// value is [bool]
  factory EventData.playState(T value) =>
      EventData<T>(EventType.playStateChanged, value);

  factory EventData.playerInit(T value) =>
      EventData<T>(EventType.videoPlayerInit, value);

  factory EventData.addDanmakus(T value) =>
      EventData<T>(EventType.addDanmakus, value);
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
  factory DataSource.file(
    File file, {
    String title,
    bool autoPlay: true,
    DanPlayerMode mode = DanPlayerMode.Normal,
  }) {
    var ds = DataSource._()
      .._title = title
      .._autoPlay = autoPlay
      .._file = file
      .._type = DataSourceType.file;
    return ds;
  }

  /// Create network data source
  factory DataSource.network(
    String url, {
    String title,
    bool autoPlay: true,
  }) {
    return DataSource._()
      .._title = title
      .._autoPlay = autoPlay
      .._url = url
      .._type = DataSourceType.network;
  }

  /// Create asset data source
  factory DataSource.asset(
    String assetName, {
    String package,
    String title,
    bool autoPlay: true,
  }) {
    var ds = DataSource._()
      .._title = title
      .._autoPlay = autoPlay
      .._assetName = assetName
      .._assetPackage = package
      .._type = DataSourceType.asset;
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
  final Future<bool> Function(Danmaku danmaku) onBeforeSubmit;

  final StreamController<dynamic> _outputStream = StreamController.broadcast();
  final List<OnSeek> _playingEvents = [];
  final List<OnChangedPosition> _seekEvents = [];
  final List<OnFullScreenChanged> _fullScreenEvents = [];
  final List<OnPlayStateChanged> _playStateEvents = [];
  final List<OnUIChanged> _uiEvents = [];
  final List<OnDataSourceChanged> _dataSourceEvents = [];
  final List<OnVolumeChanged> _volumeEvents = [];
  final List<OnAddDanmaku> _addDanmakuEvents = [];
  final List<OnAddDanmakus> _addDanmakusEvents = [];
  final List<OnVideoInit> _initEvents = [];
  final List<OnConfigChanged> _configChangedEvents = [];

  final List<Danmaku> _danmakus = [];

  DanPlayerController({
    this.onBeforeSubmit,
    DanPlayerConfig config,
    DataSource ds,
  }) {
    _config = config;
    if (_config == null)
      _config = DanPlayerConfig(
        progressBarIndicator: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.purpleAccent,
            shape: BoxShape.circle,
          ),
        ),
      );
    _outputStream.stream.listen(_distributeEvents);
    if (ds != null) setDataSource(ds);
  }

  DanPlayerConfig _config;
  VideoPlayerController _videoPlayerController;
  DataSource _ds;
  bool _initialized = false;
  bool _isPlaying = false;
  double _volume = 1;
  bool _fullScreen = false;

  bool get initialized => _initialized;

  bool get playing => _isPlaying;

  DanPlayerConfig get config => _config;

  set config(DanPlayerConfig config) {
    _config = config;
    _configChangedEvents.forEach((fun) => fun(config));
  }

  /// cache
  VideoPlayerValue videoPlayerValue;

  double get volume => _volume;

  set volume(double value) {
    if (value != _volume) send(EventData.volumeChanged(value));
    _volume = value;
    _videoPlayerController?.setVolume(value);
  }

  bool get fullScreen => _fullScreen;

  set fullScreen(bool value) {
    if (_fullScreen != value) send(EventData.fullScreenChanged(value));
    _fullScreen = value;
  }

  /// Distribute events
  void _distributeEvents(dynamic data) {
    if (data is EventData) {
      switch (data.type) {
        case EventType.playing:
          _playingEvents.forEach((fun) => fun(data.value));
          break;
        case EventType.fullScreenChanged:
          _fullScreenEvents.forEach((fun) => fun(data.value));
          break;
        case EventType.seek:
          _seekEvents.forEach((fun) => fun(data.value));
          break;
        case EventType.volumeChanged:
          _volumeEvents.forEach((fun) => fun(data.value));
          break;
        case EventType.uiVisibleChanged:
          _uiEvents.forEach((fun) => fun(data.value));
          break;
        case EventType.addDanmaku:
          _addDanmakuEvents.forEach((fun) => fun(data.value));
          break;
        case EventType.addDanmakus:
          _addDanmakusEvents.forEach((fun) => fun(data.value));
          break;
        case EventType.playStateChanged:
          _playStateEvents.forEach((fun) => fun(data.value));
          break;
        case EventType.videoPlayerInit:
          _initEvents.forEach((fun) => fun(data.value));
          break;
      }
    }
  }

  setDataSource(DataSource ds) {
    assert(ds != null);
    _ds = ds;
    _initialized = false;
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
    videoPlayerValue = null;
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
    _videoPlayerController.addListener(_videoPlayerInit);
  }

  /// 当controller准备好后的第一次事件
  void _videoPlayerInit() {
    if (_videoPlayerController.value?.initialized == true) {
      _initialized = true;
      videoPlayerValue = _videoPlayerController.value;
      _videoPlayerController.removeListener(_videoPlayerInit);
      send(EventData.playerInit(_videoPlayerController.value));
      _videoPlayerController.addListener(_videoPlayerListener);
    }
  }

  void _videoPlayerListener() {
    videoPlayerValue = _videoPlayerController.value;
    if (_isPlaying != videoPlayerValue.isPlaying) {
      _isPlaying = videoPlayerValue.isPlaying;
      send(EventData.playState(_isPlaying));
    }
    if (_volume != videoPlayerValue.volume) {
      _volume = videoPlayerValue.volume;
      send(EventData.volumeChanged(volume));
    }
    send(EventData.playing(videoPlayerValue));
  }

  dispose() {
    videoPlayerValue = null;
    _videoPlayerController?.dispose();
    _outputStream?.close();
    _playingEvents.clear();
    _fullScreenEvents.clear();
    _playStateEvents.clear();
    _dataSourceEvents.clear();
  }

  /// The following is about the event methods
  ///
  send(EventData data) {
    _outputStream.add(data);
  }

  addVideoPlayerInit(OnVideoInit event) {
    if (_initEvents.contains(event) == false) _initEvents.add(event);
    if (videoPlayerValue != null) event(videoPlayerValue);
  }

  removeVideoPlayerInit(OnVideoInit event) {
    _initEvents.remove(event);
  }

  addPlaying(OnPlaying event) {
    if (_playingEvents.contains(event) == false) _playingEvents.add(event);
    if (videoPlayerValue != null) event(videoPlayerValue);
  }

  removePlaying(OnPlaying event) {
    _playingEvents.remove(event);
  }

  addConfig(OnConfigChanged event) {
    if (_configChangedEvents.contains(event) == false)
      _configChangedEvents.add(event);
    event(_config);
  }

  removeConfig(OnConfigChanged event) {
    _configChangedEvents.remove(event);
  }

  addSeek(OnSeek event) {
    if (_seekEvents.contains(event) == false) _seekEvents.add(event);
    if (videoPlayerValue != null) event(videoPlayerValue);
  }

  removeSeek(OnSeek event) {
    _seekEvents.remove(event);
  }

  addFullScreenChanged(OnFullScreenChanged event) {
    if (_fullScreenEvents.contains(event) == false)
      _fullScreenEvents.add(event);
  }

  removeFullScreenChanged(OnFullScreenChanged event) {
    _fullScreenEvents.remove(event);
  }

  addPlayStateChanged(OnPlayStateChanged event) {
    if (_playStateEvents.contains(event) == false) _playStateEvents.add(event);

    if (videoPlayerValue != null) event(videoPlayerValue.isPlaying);
  }

  removePlayStateChanged(OnPlayStateChanged event) {
    _playStateEvents.remove(event);
  }

  addVolumeChanged(OnVolumeChanged event) {
    if (_volumeEvents.contains(event) == false) _volumeEvents.add(event);
    if (videoPlayerValue != null) event(videoPlayerValue.volume);
  }

  removeVolumeChanged(OnVolumeChanged event) {
    _volumeEvents.remove(event);
  }

  addUIChanged(OnUIChanged event) {
    if (_uiEvents.contains(event) == false) _uiEvents.add(event);
  }

  removeUIChanged(OnUIChanged event) {
    _uiEvents.remove(event);
  }

  addAddDanmaku(OnAddDanmaku event) {
    if (_addDanmakuEvents.contains(event) == false)
      _addDanmakuEvents.add(event);
  }

  removeAddDanmaku(OnAddDanmaku event) {
    _addDanmakuEvents.remove(event);
  }

  addAddDanmakus(OnAddDanmakus event) {
    if (_addDanmakusEvents.contains(event) == false) {
      _addDanmakusEvents.add(event);
      event(_danmakus);
    }
  }

  removeAddDanmakus(OnAddDanmakus event) {
    _addDanmakusEvents.remove(event);
  }

  /// Normal methods
  play() {
    print('controller play');
    _videoPlayerController?.play();
  }

  pause() {
    _videoPlayerController?.pause();
  }

  seekTo(Duration position) {
    _videoPlayerController?.seekTo(position);
    send(EventData.seek(_videoPlayerController.value));
  }

  addDanmaku(Danmaku danmaku) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // print('controller addDanmaku $danmaku');
      _danmakus.add(danmaku);
      _outputStream.add(EventData.addDanmaku(danmaku));
    });
  }

  addDanmakus(Iterable<Danmaku> danmakus) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      print('controller addDanmakus ${danmakus.length}');
      _danmakus.addAll(danmakus);
      _outputStream.add(EventData.addDanmakus(danmakus));
    });
  }

  List<Danmaku> get danmakus => List.from(_danmakus);

  DanPlayerController copyWith({DanPlayerConfig config}) {
    return DanPlayerController(config: config)
      .._initEvents.addAll(this._initEvents)
      .._playingEvents.addAll(this._playingEvents)
      .._seekEvents.addAll(this._seekEvents)
      .._dataSourceEvents.addAll(this._dataSourceEvents)
      .._volumeEvents.addAll(this._volumeEvents)
      .._fullScreenEvents.addAll(this._fullScreenEvents)
      .._videoPlayerController = this._videoPlayerController
      .._addDanmakuEvents.addAll(this._addDanmakuEvents)
      .._addDanmakusEvents.addAll(this._addDanmakusEvents)
      ..videoPlayerValue = this.videoPlayerValue
      .._danmakus.addAll(this._danmakus)
      .._ds = this._ds;
  }
}
