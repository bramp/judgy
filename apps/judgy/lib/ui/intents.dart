import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class CheckAnswerIntent extends Intent {
  const CheckAnswerIntent();
}

class NextLevelIntent extends Intent {
  const NextLevelIntent();
}

class PrevLevelIntent extends Intent {
  const PrevLevelIntent();
}

class GameShortcuts {
  static final Map<LogicalKeySet, Intent> bindings = {
    LogicalKeySet(LogicalKeyboardKey.enter): const CheckAnswerIntent(),
    LogicalKeySet(LogicalKeyboardKey.numpadEnter): const CheckAnswerIntent(),
    LogicalKeySet(LogicalKeyboardKey.bracketRight): const NextLevelIntent(),
    LogicalKeySet(LogicalKeyboardKey.bracketLeft): const PrevLevelIntent(),
    LogicalKeySet(LogicalKeyboardKey.period): const NextLevelIntent(),
    LogicalKeySet(LogicalKeyboardKey.comma): const PrevLevelIntent(),
    LogicalKeySet(LogicalKeyboardKey.pageDown): const NextLevelIntent(),
    LogicalKeySet(LogicalKeyboardKey.pageUp): const PrevLevelIntent(),
  };
}
