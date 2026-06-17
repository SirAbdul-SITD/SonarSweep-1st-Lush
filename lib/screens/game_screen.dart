// lib/screens/game_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';
import '../game/board_painter.dart';
import '../utils/constants.dart';
import '../utils/preferences.dart';
import 'level_select_screen.dart';

class GameScreen extends StatefulWidget {
  final int levelIndex;
  const GameScreen({super.key, required this.levelIndex});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _victoryCtrl;
  late final Animation<double> _victoryAnim;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _victoryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _victoryAnim =
        CurvedAnimation(parent: _victoryCtrl, curve: Curves.elasticOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameState>().loadLevel(widget.levelIndex);
    });
    _clock = Timer.periodic(
        const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _clock?.cancel();
    _victoryCtrl.dispose();
    super.dispose();
  }

  void _haptic() {
    if (Preferences.instance.isVibrationEnabled()) {
      HapticFeedback.selectionClick();
    }
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Consumer<GameState>(builder: (ctx, st, _) {
        if (!st.initialized) {
          return const Center(child: CircularProgressIndicator(color: kAccent));
        }
        if (st.isComplete && !_victoryCtrl.isCompleted) {
          _victoryCtrl.forward();
          if (Preferences.instance.isVibrationEnabled()) {
            HapticFeedback.heavyImpact();
          }
        }
        return Stack(children: [
          SafeArea(
            child: Column(children: [
              _hud(st),
              const SizedBox(height: 4),
              _statusRow(st),
              Expanded(child: Center(child: _board(st))),
              _bottomBar(st),
              const SizedBox(height: 12),
            ]),
          ),
          if (st.isComplete) _victory(st),
          if (st.gameOver) _defeat(st),
        ]);
      }),
    );
  }

  Widget _hud(GameState st) {
    final diffColor = st.difficulty == 'Easy'
        ? kEasyColor
        : st.difficulty == 'Medium'
            ? kMediumColor
            : kHardColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorder)),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: kTextDim, size: 16),
          ),
        ),
        const Spacer(),
        Column(children: [
          Text('LEVEL ${st.currentLevelIndex + 1}',
              style: techno(14, letterSpacing: 3)),
          Text(st.difficulty.toUpperCase(),
              style: techno(10, color: diffColor, letterSpacing: 2)),
        ]),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_fmt(st.elapsedSeconds),
              style: techno(16, color: kAccent, weight: FontWeight.w900)),
          Text('PAR ${_fmt(st.parSeconds)}',
              style: techno(8, color: kTextDim, letterSpacing: 1.5)),
        ]),
      ]),
    );
  }

  Widget _statusRow(GameState st) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, color: kMineColor, size: 15),
          const SizedBox(width: 5),
          Text('${st.minesLeft} MINES LEFT',
              style: techno(11, color: kTextDim, letterSpacing: 2)),
        ],
      );

  Widget _board(GameState st) {
    final size = MediaQuery.of(context).size;
    final boardW = (size.width - 24).clamp(0.0, size.height * 0.58);
    final boardH = boardW * st.height / st.width;
    final cell = boardW / st.width;

    int? cellAt(Offset p) {
      final c = (p.dx / cell).floor();
      final r = (p.dy / cell).floor();
      if (r < 0 || c < 0 || r >= st.height || c >= st.width) return null;
      return r * st.width + c;
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: kSurface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder, width: 1.5),
      ),
      child: GestureDetector(
        onTapUp: (d) {
          final i = cellAt(d.localPosition);
          if (i != null) {
            _haptic();
            st.tapCell(i);
          }
        },
        onLongPressStart: (d) {
          final i = cellAt(d.localPosition);
          if (i != null) {
            if (Preferences.instance.isVibrationEnabled()) {
              HapticFeedback.mediumImpact();
            }
            st.longPressCell(i);
          }
        },
        child: CustomPaint(
          size: Size(boardW, boardH),
          painter: BoardPainter(st),
        ),
      ),
    );
  }

  Widget _bottomBar(GameState st) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // flag mode toggle
          GestureDetector(
            onTap: () {
              _haptic();
              st.toggleFlagMode();
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: st.flagMode ? kFlagColor.withOpacity(0.18) : kSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: st.flagMode ? kFlagColor : kBorder,
                    width: st.flagMode ? 1.6 : 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.flag_rounded,
                    color: st.flagMode ? kFlagColor : kTextDim, size: 16),
                const SizedBox(width: 6),
                Text('FLAG MODE',
                    style: techno(10,
                        color: st.flagMode ? kFlagColor : kTextDim,
                        letterSpacing: 2)),
              ]),
            ),
          ),
          const SizedBox(width: 16),
          _actionBtn(Icons.refresh_rounded, 'RESTART', () {
            _victoryCtrl.reset();
            st.restartLevel();
          }),
          const SizedBox(width: 16),
          _actionBtn(Icons.grid_view_rounded, 'LEVELS', () {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (_) => const LevelSelectScreen()));
          }),
        ],
      );

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kBorder),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: kTextDim, size: 16),
            const SizedBox(width: 6),
            Text(label, style: techno(10, color: kTextDim, letterSpacing: 2)),
          ]),
        ),
      );

  Widget _victory(GameState st) => _overlay(
        icon: Icons.radar_rounded,
        iconColor: kAccent,
        title: 'SECTOR CLEARED',
        subtitle:
            'TIME ${_fmt(st.elapsedOnFinish)}  ·  PAR ${_fmt(st.parSeconds)}',
        stars: st.stars,
        st: st,
        primaryLabel: 'NEXT',
        onPrimary: () {
          _victoryCtrl.reset();
          if (st.currentLevelIndex < 149) {
            st.nextLevel();
          } else {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (_) => const LevelSelectScreen()));
          }
        },
        animated: true,
      );

  Widget _defeat(GameState st) => _overlay(
        icon: Icons.dangerous_rounded,
        iconColor: kMineColor,
        title: 'MINE DETONATED',
        subtitle: 'TIME ${_fmt(st.elapsedOnFinish)}',
        stars: null,
        st: st,
        primaryLabel: 'RETRY',
        onPrimary: () {
          _victoryCtrl.reset();
          st.restartLevel();
        },
        animated: false,
      );

  Widget _overlay({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required int? stars,
    required GameState st,
    required String primaryLabel,
    required VoidCallback onPrimary,
    required bool animated,
  }) {
    final card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: iconColor.withOpacity(0.2),
              blurRadius: 40,
              spreadRadius: 4)
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconColor.withOpacity(0.12),
            border: Border.all(color: iconColor, width: 2),
          ),
          child: Icon(icon, color: iconColor, size: 30),
        ),
        const SizedBox(height: 16),
        Text(title,
            style: techno(16,
                color: iconColor, weight: FontWeight.w900, letterSpacing: 3)),
        const SizedBox(height: 6),
        Text(subtitle, style: techno(11, color: kTextDim, letterSpacing: 2)),
        if (stars != null) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                3,
                (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < stars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: i < stars ? kStarOn : kStarOff,
                        size: 36,
                      ),
                    )),
          ),
        ],
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
              child: _vBtn('REPLAY', Icons.refresh_rounded, false, () {
            _victoryCtrl.reset();
            st.restartLevel();
          })),
          const SizedBox(width: 10),
          Expanded(
              child: _vBtn(
                  primaryLabel, Icons.arrow_forward_rounded, true, onPrimary)),
        ]),
      ]),
    );

    return Container(
      color: Colors.black.withOpacity(0.78),
      child: Center(
        child: animated
            ? ScaleTransition(scale: _victoryAnim, child: card)
            : card,
      ),
    );
  }

  Widget _vBtn(String label, IconData icon, bool primary, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: primary
                ? const LinearGradient(
                    colors: [Color(0xFF128F66), Color(0xFF1FBF8A)])
                : null,
            color: primary ? null : kBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: primary ? kAccent.withOpacity(0.5) : kBorder),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: primary ? kBg : Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: techno(12,
                    color: primary ? kBg : kTextPrimary, letterSpacing: 2)),
          ]),
        ),
      );
}
