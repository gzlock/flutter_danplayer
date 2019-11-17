part of '../danplayer.dart';

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
        assert(state != null),
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

typedef OptionValueBuilder = Widget Function(
    BuildContext context, bool selected, Color color);

class OptionValue<T> {
  final T value;
  final OptionValueBuilder builder;

  const OptionValue(this.value, this.builder);
}

class OptionsGroup<T> extends StatefulWidget {
  final String hint;
  final Function(T value) onTap;
  final Color defaultColor, selectedColor;
  final List<OptionValue<T>> values;
  final OptionValue<T> defaultValue;
  final bool singleSelect;

  OptionsGroup(
      {Key key,
      this.hint,
      this.onTap,
      this.defaultColor = Colors.white,
      this.selectedColor = Colors.purpleAccent,
      this.values,
      this.singleSelect = true,
      this.defaultValue})
      : assert(singleSelect != null),
        assert(values != null),
        assert(values.length > 0),
        super(key: key);

  @override
  _OptionsGroup<T> createState() => _OptionsGroup<T>();
}

class _OptionsGroup<T> extends State<OptionsGroup> {
  final List<T> _selected = [];

  @override
  void initState() {
    super.initState();
    _selected.add(widget.defaultValue.value);
  }

  void _buttonTap(OptionValue<T> value) {
    if (widget.singleSelect) {
      if (_selected.contains(value.value))
        _selected.clear();
      else
        _selected
          ..clear()
          ..add(value.value);
    } else {
      if (_selected.contains(value.value))
        _selected.remove(value.value);
      else
        _selected.add(value.value);
    }
    if (widget.singleSelect && _selected.isEmpty)
      _selected.add(widget.defaultValue.value);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];
    for (var i = 0; i < widget.values.length; i++) {
      OptionValue<T> value = widget.values[i];
      final selected = _selected.contains(value.value);
      buttons.add(GestureDetector(
        child: value.builder(context, selected,
            selected ? widget.selectedColor : widget.defaultColor),
        onTap: () => _buttonTap(value),
      ));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: EdgeInsets.only(right: 10),
          alignment: Alignment.topCenter,
          child: Text(
            widget.hint,
            style: TextStyle(color: Colors.white),
          ),
        ),
        Container(
          width: 100,
          child: Wrap(
            alignment: WrapAlignment.start,
            direction: Axis.horizontal,
            children: buttons,
            spacing: 5,
            runSpacing: 5,
          ),
        )
      ],
    );
  }
}
