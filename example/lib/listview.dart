import 'package:danplayer/danplayer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

final url = 'http://vfx.mtime.cn/Video/2019/03/09/mp4/190309153658147087.mp4';

class InListView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _InListView();
}

class _InListView extends State<InListView>
    with SingleTickerProviderStateMixin {
  ScrollController _scrollController = ScrollController();
  TabController _tabController;
  DanPlayerController _controller;

  final _tabs = [
    {'id': 1, 'title': '简介'},
    {'id': 2, 'title': '评论'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = DanPlayerController();
    _scrollController = ScrollController();
    _tabController = TabController(length: _tabs.length, vsync: this);

    _controller.setDataSource(
        DataSource.network(url, autoPlay: true, title: 'Network Video'));
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
        slivers: [
          DanPlayerPersistentHeader(
            maxExtent: 220,
            pinned: true,
            title: FlatButton.icon(
              onPressed: () {
                _scrollController.jumpTo(0);
              },
              icon: Icon(
                Icons.play_arrow,
              ),
              textColor: Colors.white,
              label: Text('播放'),
            ),
            child: DanPlayer(
              controller: _controller,
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: SliverTabBarDelegate(_buildTabs()),
          ),
          SliverFillRemaining(
            child: _tabsView(), // TabBarView
          )
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

  Widget _tabsView() {
    return TabBarView(
      controller: _tabController,
      children: _tabs
          .map((tab) => Container(
                child: Center(
                  child: Text(tab['title']),
                ),
              ))
          .toList(),
    );
  }
}

/// Tab Bar
class SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar widget;
  final Color color;

  const SliverTabBarDelegate(this.widget, {this.color})
      : assert(widget != null);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return new Container(
      child: widget,
      color: color,
    );
  }

  @override
  bool shouldRebuild(SliverTabBarDelegate oldDelegate) {
    return false;
  }

  @override
  double get maxExtent => widget.preferredSize.height;

  @override
  double get minExtent => widget.preferredSize.height;
}

class DanPlayerPersistentHeader extends StatefulWidget {
  final Widget title;
  final DanPlayer child;
  final double maxExtent;
  final List<Widget> actions;
  final bool pinned, pauseCollapse;
  final Color backgroundColor;

  const DanPlayerPersistentHeader({
    Key key,
    this.title,
    @required this.maxExtent,
    this.actions: const [],
    this.child,
    this.pauseCollapse: true,
    this.backgroundColor: Colors.blue,
    this.pinned: true,
  })  : assert(maxExtent != null && maxExtent > 0),
        assert(child != null),
        assert(actions != null),
        super(key: key);

  @override
  _DanPlayerPersistentHeader createState() => _DanPlayerPersistentHeader();
}

class _DanPlayerPersistentHeader extends State<DanPlayerPersistentHeader>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    print('DanPlayerPersistentHeader build');
    return SliverPersistentHeader(
      pinned: widget.pinned,
      delegate: VideoHeaderDelegate(
          title: widget.title,
          child: widget.child,
          color: widget.backgroundColor,
          maxExtent: widget.maxExtent,
          actions: widget.actions),
    );
  }
}

class VideoHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget title;
  final DanPlayer child;
  final double maxExtent;
  final List<Widget> actions;
  final Color color;
  double _minExtent = 0;
  bool _isSetMinExtent = false;

  VideoHeaderDelegate({
    @required this.child,
    @required this.maxExtent,
    this.color,
    this.title,
    this.actions = const [],
  })  : assert(child != null),
        assert(actions != null);

  @override
  double get minExtent => _minExtent;

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
    double opacity =
        (1.0 - shrinkOffset / (maxExtent - _minExtent)).clamp(0.0, 1.0);
    Widget title = this.title;
    if (title != null) {
      title = Opacity(
        opacity: 1.0 - opacity,
        child: title,
      );
    }
    return AppBar(
      title: title,
      centerTitle: true,
      backgroundColor: color,
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
              opacity: opacity,
              child: IgnorePointer(ignoring: opacity != 1, child: child),
            ),
          ),
        ],
      ),
    );
  }
}
