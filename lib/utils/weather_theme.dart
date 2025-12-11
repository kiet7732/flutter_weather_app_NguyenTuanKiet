import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WeatherTheme {
  // Text Shadow giúp chữ dễ đọc hơn
  static List<Shadow> get textShadow => [
    Shadow(
      offset: const Offset(1, 1),
      blurRadius: 4.0,
      color: Colors.black.withOpacity(0.6),
    ),
  ];

  // Helper to apply shadow to existing TextStyle
  static TextStyle textStyle({double fontSize = 14, FontWeight fontWeight = FontWeight.normal, Color color = Colors.black87}) {
    return GoogleFonts.roboto(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      shadows: textShadow,
    );
  }

  // Sunny
  static const Color sunnyPrimary = Color(0xFFFDB813);
  static const Color sunnyGradientTop = Color(0xFFFDB813);
  static const Color sunnyGradientBottom = Color(0xFF87CEEB);

  // Rainy
  static const Color rainyPrimary = Color(0xFF4A5568);
  static const Color rainyGradientTop = Color(0xFF4A5568);
  static const Color rainyGradientBottom = Color(0xFF718096);

  // Cloudy
  static const Color cloudyPrimary = Color(0xFFA0AEC0);
  static const Color cloudyGradientTop = Color(0xFFA0AEC0);
  static const Color cloudyGradientBottom = Color(0xFFCBD5E0);

  // Night
  static const Color nightPrimary = Color(0xFF2D3748);
  static const Color nightGradientTop = Color(0xFF2D3748);
  static const Color nightGradientBottom = Color(0xFF1A202C);

  static LinearGradient getGradient(String condition) {
    final lowerCondition = condition.toLowerCase();
    Color top;
    Color bottom;

    if (lowerCondition.contains('rain') ||
        lowerCondition.contains('drizzle') ||
        lowerCondition.contains('thunder')) {
      top = rainyGradientTop;
      bottom = rainyGradientBottom;
    } else if (lowerCondition.contains('cloud') ||
        lowerCondition.contains('mist') ||
        lowerCondition.contains('fog')) {
      top = cloudyGradientTop;
      bottom = cloudyGradientBottom;
    } else if (lowerCondition.contains('night')) {
      top = nightGradientTop;
      bottom = nightGradientBottom;
    } else {
      // Default to Sunny/Clear
      top = sunnyGradientTop;
      bottom = sunnyGradientBottom;
    }

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [top, bottom],
    );
  }
}