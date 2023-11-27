// A widget for selecting which tables (2-10) the user wants to practice.
//
// You get a callback when the selection changes.
//
// The widget accepts a set of ints (2-10) that are initially selected.
import 'package:flutter/material.dart';

class TablesSelectorWidget extends StatefulWidget {
  final Set<int> initialSelection;
  final void Function(Set<int>) onSelectionChanged;

  const TablesSelectorWidget(
      {super.key,
      required this.initialSelection,
      required this.onSelectionChanged});

  @override
  State<TablesSelectorWidget> createState() => _TablesSelectorWidgetState();
}

class _TablesSelectorWidgetState extends State<TablesSelectorWidget> {
  Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelection;
  }

  @override
  Widget build(BuildContext context) {
    List<ChoiceChip> chips = [];
    for (int i = 2; i <= 10; i++) {
      chips.add(ChoiceChip(
        label: Text("$i"),
        showCheckmark: false,
        selected: _selected.contains(i),
        onSelected: (bool selected) {
          // Prevent deselecting all tables
          if (_selected.length == 1 && selected == false) {
            return;
          }

          setState(() {
            if (selected == true) {
              _selected.add(i);
            } else {
              _selected.remove(i);
            }
            widget.onSelectionChanged(_selected);
          });
        },
      ));
    }

    return Wrap(
      children: chips,
    );
  }
}
