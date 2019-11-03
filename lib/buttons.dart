import 'package:flutter/material.dart';

class MyIconButton extends StatefulWidget {
  final int fromIcon, toIcon;
  final Function(MyIconButtonState state) onTap;
  final bool state;
  final double size;

  const MyIconButton({
    Key key,
    @required this.onTap,
    this.fromIcon,
    this.toIcon,
    this.state: true,
    this.size: 32,
  })  : assert(onTap != null),
        super(key: key);

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
            fontFamily: 'iconfont', fontPackage: 'danplayer'),
        color: Colors.white,
        size: widget.size,
      ),
      onTap: () => widget.onTap(this),
    );
  }
}

class SelectionButton<T> extends StatefulWidget {
  final int icon;
  final double size;
  final T value;
  final Color defaultColor, selectedColor;
  final bool state;
  final Function(SelectionButtonState<T> state, T value) onTap;

  const SelectionButton({
    Key key,
    @required this.onTap,
    this.icon,
    this.defaultColor,
    this.selectedColor,
    this.size: 32,
    this.value,
    this.state = false,
  })  : assert(onTap != null),
        super(key: key);

  @override
  SelectionButtonState createState() => SelectionButtonState<T>();
}

class SelectionButtonState<T> extends State<SelectionButton> {
  bool _disable = false;
  bool _state = false;

  get state => _state;

  set state(bool v) {
    _state = v;
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _state = widget.state;
  }

  @override
  Widget build(BuildContext context) {
    final color = _state ? widget.selectedColor : widget.defaultColor;
    return GestureDetector(
        onTap: () {
          if (_disable) return;
          _state = true;
          widget.onTap(this, widget.value);
        },
        child: Icon(
          IconData(widget.icon,
              fontFamily: 'iconfont', fontPackage: 'danplayer'),
          color: color,
          size: widget.size,
        ));
  }
}

class OptionValue<T> {
  final int icon;
  final T value;

  const OptionValue(this.icon, this.value);
}

class OptionsGroup<T> extends StatelessWidget {
  final String hint;
  final Function(T value) onTap;
  final Color defaultColor, selectedColor;
  final List<OptionValue<T>> values;
  final List<SelectionButton> _buttons = [];
  final List<GlobalKey<SelectionButtonState<T>>> _buttonStates = [];
  final OptionValue<T> defaultValue;

  OptionsGroup(
      {Key key,
      this.hint,
      this.onTap,
      this.defaultColor = Colors.white,
      this.selectedColor = Colors.purpleAccent,
      this.values,
      this.defaultValue})
      : assert(values != null),
        assert(values.length > 0),
        super(key: key) {
    this.values.forEach((value) {
      final key = GlobalKey<SelectionButtonState<T>>();
      _buttonStates.add(key);
      final button = SelectionButton(
        key: key,
        icon: value.icon,
        defaultColor: defaultColor,
        selectedColor: selectedColor,
        value: value.value,
        state: value == this.defaultValue,
        onTap: tapButton,
      );
      _buttons.add(button);
    });
  }

  void tapButton(SelectionButtonState<T> state, T value) {
    print('点击了 $value');
    _buttonStates
        .forEach((key) => key.currentState.state = key.currentState == state);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          hint,
          style: TextStyle(color: Colors.white),
        ),
        Container(
          width: 10,
        ),
        ..._buttons
      ],
    );
  }
}
