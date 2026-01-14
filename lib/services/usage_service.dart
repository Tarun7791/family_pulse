import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class UsageService {
  static const _channel = MethodChannel('com.family.screentime/usage');

  static Future<bool> isPermissionGranted() async {
    try {
      final bool granted = await _channel.invokeMethod('checkUsagePermission');
      return granted;
    } on PlatformException catch (e) {
      print("Failed to check permission: ${e.message}");
      return false;
    }
  }

  static Future<void> openSettings() async {
    try {
      await _channel.invokeMethod('openUsageSettings');
    } on PlatformException catch (e) {
      print("Failed to open settings: ${e.message}");
    }
  }

  static Future<int> getTodayScreenTime() async {
    try {
      final dynamic minutes = await _channel.invokeMethod('getScreenTime');
      return (minutes as num?)?.toInt() ?? 0;
    } on PlatformException catch (e) {
      debugPrint("Failed to get screen time: ${e.message}");
      return 0;
    } catch (e) {
      debugPrint("Unexpected error in getTodayScreenTime: $e");
      return 0;
    }
  }

  static Future<List<Map<String, dynamic>>> getAppUsageBreakdown() async {
    try {
      final dynamic result = await _channel.invokeMethod('getAppUsageBreakdown');
      if (result == null) return [];
      
      final List<dynamic> list = result as List<dynamic>;
      return list.map((e) {
        final Map<dynamic, dynamic> map = e as Map<dynamic, dynamic>;
        return {
          'appName': map['appName']?.toString() ?? 'Unknown',
          'minutes': (map['minutes'] as num?)?.toInt() ?? 0,
        };
      }).toList();
    } on PlatformException catch (e) {
      debugPrint("Failed to get app breakdown: ${e.message}");
      return [];
    } catch (e) {
      debugPrint("Unexpected error in getAppUsageBreakdown: $e");
      return [];
    }
  }
}
