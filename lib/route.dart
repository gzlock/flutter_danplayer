part of './danplayer.dart';

class TransparentRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  TransparentRoute({@required this.builder, RouteSettings settings})
      : assert(builder != null),
        super(settings: settings);

  @override
  bool get opaque => false;

  @override
  Color get barrierColor => null;

  @override
  String get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    final child = builder(context);
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(animation),
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        child: child,
      ),
    );
  }

  @override
  Duration get transitionDuration => Duration.zero;
}

class FullScreenRoute extends PageRoute {
  final Color barrierColor;
  final String barrierLabel;
  final bool maintainState;
  final Duration transitionDuration;
  final WidgetBuilder builder;

  FullScreenRoute(
    this.builder, {
    this.barrierLabel,
    this.barrierColor = Colors.blue,
    this.maintainState = true,
    this.transitionDuration = Duration.zero,
  });

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return Scaffold(body: builder(context));
  }
}
