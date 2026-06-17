// lib/game/game_state.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/preferences.dart';
import '../utils/audio_manager.dart';

class Cell {
  bool isMine = false;
  bool revealed = false;
  bool flagged = false;
  int adj = 0;
}

class GameState extends ChangeNotifier {
  int currentLevelIndex = 0;
  late int width;
  late int height;
  late int mineCount;
  late String difficulty;
  late int parSeconds;
  late List<Cell> cells;
  bool minesPlaced = false;
  bool gameOver = false; // hit a mine
  bool isComplete = false;
  int stars = 0;
  bool flagMode = false;
  bool initialized = false;
  DateTime? _startTime;
  int elapsedOnFinish = 0;

  int get flagsUsed => cells.where((c) => c.flagged).length;
  int get minesLeft => mineCount - flagsUsed;
  int get elapsedSeconds => _startTime == null
      ? 0
      : (isComplete || gameOver)
          ? elapsedOnFinish
          : DateTime.now().difference(_startTime!).inSeconds;

  void loadLevel(int index) {
    currentLevelIndex = index;
    if (index < 50) {
      width = 8;
      height = 8;
      mineCount = 8 + index ~/ 10; // 8-12
      difficulty = 'Easy';
    } else if (index < 100) {
      width = 10;
      height = 10;
      mineCount = 15 + (index - 50) ~/ 8; // 15-21
      difficulty = 'Medium';
    } else {
      width = 12;
      height = 12;
      mineCount = 24 + (index - 100) ~/ 7; // 24-31
      difficulty = 'Hard';
    }
    parSeconds = ((width * height - mineCount) * 1.1).round();
    cells = List.generate(width * height, (_) => Cell());
    minesPlaced = false;
    gameOver = false;
    isComplete = false;
    stars = 0;
    flagMode = false;
    _startTime = null;
    elapsedOnFinish = 0;
    initialized = true;
    notifyListeners();
  }

  List<int> _neighbors(int i) {
    final r = i ~/ width, c = i % width;
    final out = <int>[];
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = r + dr, nc = c + dc;
        if (nr >= 0 && nr < height && nc >= 0 && nc < width) {
          out.add(nr * width + nc);
        }
      }
    }
    return out;
  }

  /// Mines are placed on the first reveal so that tap (and its ring)
  /// is always safe. Seeded per level for fairness across retries... of the
  /// same opening; a different opening yields a different (still seeded) board.
  void _placeMines(int safeIndex) {
    final rng = Random(currentLevelIndex * 9743 + safeIndex * 131 + 7);
    final forbidden = <int>{safeIndex, ..._neighbors(safeIndex)};
    final spots = <int>[
      for (int i = 0; i < cells.length; i++)
        if (!forbidden.contains(i)) i
    ]..shuffle(rng);
    for (int k = 0; k < mineCount && k < spots.length; k++) {
      cells[spots[k]].isMine = true;
    }
    for (int i = 0; i < cells.length; i++) {
      cells[i].adj = _neighbors(i).where((n) => cells[n].isMine).length;
    }
    minesPlaced = true;
    _startTime = DateTime.now();
  }

  void toggleFlagMode() {
    flagMode = !flagMode;
    notifyListeners();
  }

  void tapCell(int i) {
    if (gameOver || isComplete) return;
    final c = cells[i];
    if (flagMode && !c.revealed) {
      _flag(i);
      return;
    }
    if (c.flagged) return;
    if (c.revealed) {
      _chord(i);
      return;
    }
    if (!minesPlaced) _placeMines(i);
    _reveal(i);
    _finishCheck();
    notifyListeners();
  }

  void longPressCell(int i) {
    if (gameOver || isComplete) return;
    if (!cells[i].revealed) _flag(i);
  }

  void _flag(int i) {
    final c = cells[i];
    if (c.revealed) return;
    c.flagged = !c.flagged;
    AudioManager.instance.playPing();
    notifyListeners();
  }

  void _reveal(int i) {
    final c = cells[i];
    if (c.revealed || c.flagged) return;
    c.revealed = true;
    if (c.isMine) {
      _explode();
      return;
    }
    AudioManager.instance.playPing();
    if (c.adj == 0) {
      // flood fill
      final q = [i];
      while (q.isNotEmpty) {
        final cur = q.removeLast();
        for (final n in _neighbors(cur)) {
          final nc = cells[n];
          if (!nc.revealed && !nc.flagged && !nc.isMine) {
            nc.revealed = true;
            if (nc.adj == 0) q.add(n);
          }
        }
      }
    }
  }

  /// Tap a satisfied number to reveal its remaining neighbors.
  void _chord(int i) {
    final c = cells[i];
    if (c.adj == 0) return;
    final nbrs = _neighbors(i);
    final flags = nbrs.where((n) => cells[n].flagged).length;
    if (flags != c.adj) return;
    for (final n in nbrs) {
      if (!cells[n].revealed && !cells[n].flagged) {
        _reveal(n);
        if (gameOver) break;
      }
    }
    _finishCheck();
    notifyListeners();
  }

  void _explode() {
    gameOver = true;
    elapsedOnFinish = elapsedSecondsRaw();
    for (final c in cells) {
      if (c.isMine) c.revealed = true;
    }
    AudioManager.instance.playBoom();
  }

  int elapsedSecondsRaw() => _startTime == null
      ? 0
      : DateTime.now().difference(_startTime!).inSeconds;

  void _finishCheck() {
    if (gameOver || isComplete) return;
    final allClear =
        cells.every((c) => c.isMine || c.revealed);
    if (allClear) {
      isComplete = true;
      elapsedOnFinish = elapsedSecondsRaw();
      stars = _calcStars(elapsedOnFinish);
      AudioManager.instance.playComplete();
      Preferences.instance.saveLevelResult(currentLevelIndex, stars);
    }
  }

  int _calcStars(int t) {
    if (t <= parSeconds) return 3;
    if (t <= parSeconds * 2) return 2;
    return 1;
  }

  void restartLevel() => loadLevel(currentLevelIndex);

  void nextLevel() {
    if (currentLevelIndex < 149) loadLevel(currentLevelIndex + 1);
  }
}
