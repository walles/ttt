// A widget for selecting which tables (2-10) the user wants to practice.
//
// You get a callback when the selection changes.
//
// The widget accepts a set of ints (2-10) that are initially selected.
import 'package:flutter/material.dart';
import 'package:ttt/config.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GameConfigWidget extends StatefulWidget {
  final Config initialConfig;
  final void Function(Set<int>) onTableSelectionChanged;
  final void Function(bool multiplication, bool division) onOperationChanged;

  const GameConfigWidget(
      {super.key,
      required this.initialConfig,
      required this.onTableSelectionChanged,
      required this.onOperationChanged});

  @override
  State<GameConfigWidget> createState() => _GameConfigWidgetState();
}

class _GameConfigWidgetState extends State<GameConfigWidget> {
  Set<int> _selectedTables = {};
  bool _multiplication = true;
  bool _division = true;

  @override
  void initState() {
    super.initState();
    _selectedTables = widget.initialConfig.tablesToTest;
    _multiplication = widget.initialConfig.multiplication;
    _division = widget.initialConfig.division;
  }

  @override
  Widget build(BuildContext context) {
    List<ChoiceChip> chips = [];

    for (int i = 2; i <= 10; i++) {
      chips.add(ChoiceChip(
        label: Text("$i"),
        selected: _selectedTables.contains(i),
        onSelected: (bool selected) {
          // Prevent deselecting all tables
          if (_selectedTables.length == 1 && selected == false) {
            return;
          }

          setState(() {
            if (selected == true) {
              _selectedTables.add(i);
            } else {
              _selectedTables.remove(i);
            }
            widget.onTableSelectionChanged(_selectedTables);
          });
        },
      ));
    }

    chips.add(ChoiceChip(
      label: Text(AppLocalizations.of(context)!.multiplication),
      selected: _multiplication,
      onSelected: (bool selected) {
        setState(() {
          _multiplication = selected;
          if (!_multiplication && !_division) {
            _division = true;
          }

          widget.onOperationChanged(_multiplication, _division);
        });
      },
    ));

    chips.add(ChoiceChip(
      label: Text(AppLocalizations.of(context)!.division),
      selected: _division,
      onSelected: (bool selected) {
        setState(() {
          _division = selected;
          if (!_multiplication && !_division) {
            _multiplication = true;
          }

          widget.onOperationChanged(_multiplication, _division);
        });
      },
    ));

    return Wrap(
      spacing: 8.0,
      alignment: WrapAlignment.center,
      children: chips,
    );
  }
}
