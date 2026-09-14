import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Quản lý cấu hình biến môi trường tự động từ file .env
class EnvConfig {
  EnvConfig._();

  static bool _dotenvLoaded = false;

  /// Khởi tạo nạp file .env khi ứng dụng bắt đầu
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
      _dotenvLoaded = true;
      debugPrint('EnvConfig: Đã nạp thành công cấu hình từ .env');
    } catch (e) {
      _dotenvLoaded = false;
      debugPrint('EnvConfig: Không thể nạp file .env ($e).');
    }
  }

  /// Lấy Google Gemini API Key tự động từ file .env
  static String get geminiApiKey {
    if (_dotenvLoaded) {
      final envKey = dotenv.maybeGet('GEMINI_API_KEY');
      if (envKey != null && envKey.trim().isNotEmpty) {
        return envKey.trim();
      }
    }

    const dartDefineKey = String.fromEnvironment('GEMINI_API_KEY');
    if (dartDefineKey.isNotEmpty) {
      return dartDefineKey.trim();
    }

    return '';
  }

  /// Kiểm tra xem đã có API Key trong file .env chưa
  static bool get hasGeminiApiKey => geminiApiKey.isNotEmpty;

  /// Kiểm tra xem có phải là định dạng key mới (bắt đầu bằng AQ. hoặc AQ)
  static bool get isAqFormatKey {
    final key = geminiApiKey;
    return key.startsWith('AQ.') || key.startsWith('AQ');
  }
}
