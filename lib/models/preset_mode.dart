import 'package:flutter/material.dart';

class PresetMode {
  final int id;
  final String name;
  final String description;
  final IconData icon;
  final List<Color> colors;
  final Map<String, int> rgbValues;
  final int brightness;

  const PresetMode({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.colors,
    required this.rgbValues,
    required this.brightness,
  });

  // Getter untuk RGB values
  int get red => rgbValues['r'] ?? 255;
  int get green => rgbValues['g'] ?? 255;
  int get blue => rgbValues['b'] ?? 255;
  
  static List<PresetMode> get allModes => [
    PresetMode(
      id: 0,
      name: 'Santai',
      description: 'Cahaya hangat untuk bersantai',
      icon: Icons.coffee,
      colors: [const Color(0xFFFFA500), const Color(0xFFFF8C00)],
      rgbValues: {'r': 255, 'g': 165, 'b': 0}, // Orange #FFA500
      brightness: 60,
    ),
    PresetMode(
      id: 1,
      name: 'Kerja',
      description: 'Cahaya terang untuk fokus',
      icon: Icons.work_outline,
      colors: [const Color(0xFFFFFFFF), const Color(0xFFE6E6E6)],
      rgbValues: {'r': 255, 'g': 255, 'b': 255}, // White #FFFFFF
      brightness: 90,
    ),
    PresetMode(
      id: 2,
      name: 'Tidur',
      description: 'Cahaya redup untuk tidur',
      icon: Icons.bedtime_outlined,
      colors: [const Color(0xFFFF6B6B), const Color(0xFFFF5252)],
      rgbValues: {'r': 255, 'g': 107, 'b': 107}, // Warm red #FF6B6B
      brightness: 20,
    ),
    PresetMode(
      id: 3,
      name: 'Film',
      description: 'Suasana bioskop',
      icon: Icons.tv,
      colors: [const Color(0xFF9B59B6), const Color(0xFF8E44AD)],
      rgbValues: {'r': 155, 'g': 89, 'b': 182}, // Purple #9B59B6
      brightness: 40,
    ),
  ];
}
