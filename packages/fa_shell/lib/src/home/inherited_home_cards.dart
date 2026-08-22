import 'package:flutter/widgets.dart';

class InheritedHomeCards extends InheritedWidget {
  final List<Widget> cards;

  const InheritedHomeCards({
    required this.cards,
    required super.child,
    super.key,
  });

  static InheritedHomeCards of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedHomeCards>()!;

  @override
  bool updateShouldNotify(InheritedHomeCards old) => cards != old.cards;
}
