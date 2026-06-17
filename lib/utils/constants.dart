// lib/utils/constants.dart
import 'package:flutter/material.dart';

// ── SonarSweep palette: abyssal navy + sonar green + buoy orange ────────
const Color kBg          = Color(0xFF071219);
const Color kSurface     = Color(0xFF0E2230);
const Color kBorder      = Color(0xFF1D3D52);
const Color kAccent      = Color(0xFF35E0A1); // sonar green
const Color kCovered     = Color(0xFF15394E);
const Color kCoveredHi   = Color(0xFF1F4B66);
const Color kRevealed    = Color(0xFF0A1B26);
const Color kMineColor   = Color(0xFFFF5252);
const Color kFlagColor   = Color(0xFFFFA726); // buoy orange
const Color kTextPrimary = Color(0xFFE3F2EC);
const Color kTextDim     = Color(0xFF6E94A8);

const Color kStarOn  = Color(0xFFFFD54F);
const Color kStarOff = Color(0xFF1C3242);

const Color kEasyColor   = Color(0xFF35E0A1);
const Color kMediumColor = Color(0xFF4FC3F7);
const Color kHardColor   = Color(0xFFFF7043);

/// Classic minesweeper number colors, sonar-flavored
const List<Color> kNumColors = [
  Colors.transparent,
  Color(0xFF4FC3F7), // 1
  Color(0xFF35E0A1), // 2
  Color(0xFFFFEE58), // 3
  Color(0xFFFFA726), // 4
  Color(0xFFFF7043), // 5
  Color(0xFFFF5252), // 6
  Color(0xFFE040FB), // 7
  Color(0xFFFFFFFF), // 8
];

const int kTotalLevels = 150;

TextStyle techno(double size,
        {Color color = kTextPrimary,
        FontWeight weight = FontWeight.bold,
        double letterSpacing = 1.5}) =>
    TextStyle(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: letterSpacing);
