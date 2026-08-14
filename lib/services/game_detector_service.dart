import 'package:flutter/services.dart';

class GameDetectorService {
  static const _channel = MethodChannel('moonnlove/game_detector');

  static const Map<String, String> gamePackages = {
    'com.dts.freefireth': 'Free Fire',
    'com.dts.freefiremax': 'Free Fire MAX',
    'com.mobile.legends': 'Mobile Legends',
    'com.mojang.minecraftpe': 'Minecraft',
    'com.PlugInDigital.SuperSus': 'Super Sus',
    'com.roblox.client': 'Roblox',
  };

  static Future<bool> hasUsagePermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasUsagePermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openUsageSettings() async {
    try {
      await _channel.invokeMethod('openUsageSettings');
    } catch (_) {}
  }

  static Future<String?> getForegroundPackage() async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getForegroundApp',
      );
      if (result == null) return null;
      return result['package'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<DateTime?> getForegroundSince() async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getForegroundApp',
      );
      if (result == null) return null;
      final since = result['since'] as int?;
      if (since == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(since);
    } catch (_) {
      return null;
    }
  }

  static String? gameNameForPackage(String? package) {
    if (package == null) return null;
    for (final entry in gamePackages.entries) {
      if (package.contains(entry.key)) return entry.value;
    }
    return null;
  }
}
