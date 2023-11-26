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
    return ListView.builder(
      shrinkWrap: true,
      itemCount: 9,
      itemBuilder: (BuildContext context, int index) {
        return CheckboxListTile(
          title: Text("${index + 2}"),
          value: _selected.contains(index + 2),
          onChanged: (bool? value) {
            // Prevent deselecting all tables
            if (_selected.length == 1 && value == false) {
              return;
            }

            setState(() {
              if (value == true) {
                _selected.add(index + 2);
              } else {
                _selected.remove(index + 2);
              }
              widget.onSelectionChanged(_selected);
            });
          },
        );
      },
    );
  }
}
