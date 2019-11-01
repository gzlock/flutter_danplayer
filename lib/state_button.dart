import 'package:flutter/material.dart';

class MyIconButton extends StatefulWidget {
  final int fromIcon, toIcon;
  final Function(MyIconButtonState state) onTap;
  final bool state;
  final double size;

  const MyIconButton(
      {Key key,
      this.fromIcon,
      this.toIcon,
      this.onTap,
      this.state: true,
      this.size: 32})
      : super(key: key);

  @override
  MyIconButtonState createState() => MyIconButtonState();
}

class MyIconButtonState extends State<MyIconButton> {
  bool _state = true;

  get state => _state;

  set state(bool v) {
    setState(() {
      _state = v;
    });
  }

  @override
  void initState() {
    super.initState();
    _state = widget.state;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        child: Icon(
          IconData(_state ? widget.fromIcon : widget.toIcon,
              fontFamily: 'iconfont', fontPackage: 'flutter_danplayer'),
          color: Colors.white,
          size: widget.size,
        ),
        onTap: () {
          if (widget.onTap != null) widget.onTap(this);
        });
  }
}
