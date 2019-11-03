import 'package:flutter/material.dart';

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
