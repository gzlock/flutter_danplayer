import 'package:danplayer/danplayer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'widgets.dart';

final url = 'https://vfx.mtime.cn/Video/2019/07/25/mp4/190725150727428271.mp4';

class InListView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _InListView();
}

class _InListView extends State<InListView>
    with SingleTickerProviderStateMixin {
  ScrollController _scrollController = ScrollController();
  TabController _tabController;
  DanPlayerController _controller;
  final actions = <Widget>[
    IconButton(
      icon: Text('🏀'),
      onPressed: () {
        Fluttertoast.showToast(
            msg: 'Clicked the 🏀️ button',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIos: 1,
            textColor: Colors.white,
            fontSize: 16.0);
      },
    ),
    IconButton(
      icon: Text('⚽️'),
      onPressed: () {
        Fluttertoast.showToast(
            msg: 'Clicked the ⚽️ button',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIos: 1,
            textColor: Colors.white,
            fontSize: 16.0);
      },
    )
  ];

  final _tabs = [
    {'id': 1, 'title': '播放器相关'},
    {'id': 2, 'title': '弹幕相关'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = DanPlayerController(
        config: DanPlayerConfig(
      backgroundDeepColor: Colors.blue.withOpacity(0.5),
      progressBarIndicator: Text('🚚'),
      loadingWidget: LoadingView(
        duration: Duration(seconds: 1),
        child: Text(
          '😂',
          style: TextStyle(fontSize: 40),
        ),
      ),
      // danmaku: false,
      // showFullScreenButton: false,
      showTitleBar: false,
      actions: actions,
    ));
    _scrollController = ScrollController();
    _tabController = TabController(length: _tabs.length, vsync: this);

    _controller.setDataSource(DataSource.network(
      url,
      autoPlay: false,
      title: 'Network Video',
    ));
  }

  @override
  void dispose() {
    _controller?.dispose();
    _tabController?.dispose();
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        cacheExtent: 220,
        slivers: [
          DanPlayerPersistentHeader(
            controller: _controller,
            scrollController: _scrollController,
            maxExtent: 220,
            pinned: true,
            floating: true,
            title: FlatButton.icon(
              onPressed: () {
                _scrollController.jumpTo(0);
                _controller.play();
              },
              icon: Icon(
                Icons.play_arrow,
              ),
              textColor: Colors.white,
              label: Text('播放'),
            ),
            actions: actions,
            child: DanPlayer(
              controller: _controller,
              fullScreen: false,
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: SliverTabBarDelegate(_buildTabs(),
                color: Theme.of(context).scaffoldBackgroundColor),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                VideoControlWidget(
                  url:url,
                  controller: _controller,
                ),
                DanmakuControlWidget(
                  url:url,
                  controller: _controller,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tab选项卡
  Widget _buildTabs() {
    return TabBar(
        controller: _tabController,
        isScrollable: false,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: Color(0xffAB001D),
        unselectedLabelColor: Colors.black,
        indicatorColor: Color(0xffAB001D),
        indicatorWeight: 2,
        tabs: _tabs.map((item) {
          return Tab(
            text: '${item['title']}',
          );
        }).toList());
  }
}

class DanPlayerPersistentHeader extends StatefulWidget {
  final Widget title;
  final DanPlayer child;
  final DanPlayerController controller;
  final ScrollController scrollController;
  final double maxExtent;
  final List<Widget> actions;
  final bool pinned, floating;
  final Color backgroundColor;

  const DanPlayerPersistentHeader({
    Key key,
    this.title,
    @required this.maxExtent,
    @required this.controller,
    @required this.child,
    @required this.scrollController,
    this.actions: const [],
    this.pinned: true,
    this.floating: true,
    this.backgroundColor: Colors.blue,
  })  : assert(maxExtent != null && maxExtent > 0),
        assert(child != null),
        assert(actions != null),
        super(key: key);

  @override
  _DanPlayerPersistentHeader createState() => _DanPlayerPersistentHeader();
}

class _DanPlayerPersistentHeader extends State<DanPlayerPersistentHeader>
    with SingleTickerProviderStateMixin {
  VideoHeaderDelegate delegate;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    delegate = VideoHeaderDelegate(
        title: widget.title,
        child: widget.child,
        controller: widget.controller,
        scrollController: widget.scrollController,
        color: widget.backgroundColor,
        maxExtent: widget.maxExtent,
        actions: widget.actions);
    widget.controller.addPlayStateChanged(_playState);
  }

  void _playState(bool value) {
    _playing = value;
  }

  @override
  Widget build(BuildContext context) {
    print('DanPlayerPersistentHeader build');
    return SliverPersistentHeader(
      pinned: widget.pinned,
      floating: widget.floating,
      delegate: delegate,
    );
  }
}

class VideoHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget title;
  final DanPlayer child;
  final DanPlayerController controller;
  final ScrollController scrollController;
  final double maxExtent;
  final List<Widget> actions;
  final Color color;
  double _minExtent = 0;
  bool _isSetMinExtent = false;
  bool _isPlaying = false;

  VideoHeaderDelegate({
    @required this.child,
    @required this.maxExtent,
    @required this.controller,
    @required this.scrollController,
    this.color,
    this.title,
    this.actions = const [],
  })  : assert(child != null),
        assert(actions != null) {
    controller.addPlayStateChanged(_playState);
    SchedulerBinding.instance.addPostFrameCallback((_) {});
  }

  dispose() {
    controller.removePlayStateChanged(_playState);
  }

  void _playState(bool value) {
    _isPlaying = value;
  }

  @override
  double get minExtent {
    if (_isPlaying) return maxExtent;
    return _minExtent;
  }

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => false;

  void _setMinExtent(context) {
    // print('set minExtent');
    _minExtent = kToolbarHeight + MediaQuery.of(context).padding.top;
    _isSetMinExtent = true;
  }

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    if (_isSetMinExtent == false) {
      _setMinExtent(context);
    }
    final double opacity =
        (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final double contentOpacity = _isPlaying ? 1 : 1.0 - opacity;
    Widget title = Opacity(
      opacity: _isPlaying ? 0 : opacity,
      child: this.title,
    );
    return AppBar(
      title: title,
      centerTitle: true,
      backgroundColor: color,
      actions: actions,
      // toolbarOpacity: 1.0 - opacity,
      flexibleSpace: Stack(
        overflow: Overflow.clip,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: maxExtent,
            child: Opacity(
              opacity: contentOpacity,
              child: IgnorePointer(ignoring: contentOpacity != 1, child: child),
            ),
          ),
        ],
      ),
    );
  }
}
