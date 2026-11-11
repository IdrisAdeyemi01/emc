import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// One option in a [DayChips] row.
typedef DayChipOption = ({String label, bool isToday, bool selected});

/// Row of toggle chips for picking a day. Today shows a second "Today" line.
class DayChips extends StatelessComponent {
  const DayChips({
    required this.options,
    required this.onSelect,
    required this.groupLabel,
    required this.todayLabel,
    super.key,
  });

  final List<DayChipOption> options;
  final void Function(int index) onSelect;
  final String groupLabel;
  final String todayLabel;

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'chips',
      attributes: {'role': 'group', 'aria-label': groupLabel},
      [
        for (final (index, option) in options.indexed)
          button(
            type: ButtonType.button,
            classes: option.isToday ? 'chip chip-today' : 'chip',
            attributes: {'aria-pressed': '${option.selected}'},
            onClick: () => onSelect(index),
            [
              Component.text(option.label),
              if (option.isToday) small([Component.text(todayLabel)]),
            ],
          ),
      ],
    );
  }
}
