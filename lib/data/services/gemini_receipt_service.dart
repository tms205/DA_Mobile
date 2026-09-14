import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import '../../core/config/env_config.dart';

class GeminiReceiptResult {
  const GeminiReceiptResult({
    required this.amount,
    required this.merchant,
    required this.note,
    this.suggestedCategory,
    this.modelUsed,
  });

  final double amount;
  final String merchant;
  final String note;
  final String? suggestedCategory;
  final String? modelUsed;
}

/// Service phân tích hóa đơn bằng Google Gemini AI
class GeminiReceiptService {
  GeminiReceiptService._();

  /// Danh sách các model Gemini thế hệ mới nhất đang hoạt động
  static const List<String> _modernCandidateModels = [
    'gemini-3.6-flash',
    'gemini-3.7-flash',
    'gemini-3.5-flash',
    'gemini-3.5-flash-lite',
    'gemini-2.5-flash',
  ];

  static const String _systemPrompt = '''
Bạn là chuyên gia phân tích hóa đơn tài chính tại Việt Nam.
Hãy phân tích hình ảnh hoặc văn bản hóa đơn được cung cấp và trích xuất thông tin dưới dạng JSON chuẩn.

Yêu cầu định dạng JSON chính xác:
{
  "amount": <Tổng số tiền thanh toán cuối cùng của hóa đơn dưới dạng số (ví dụ: 125000). Nếu không tìm thấy hoặc mờ thì trả về 0>,
  "merchant": "<Tên cửa hàng, siêu thị, nhà hàng, quán ăn, thương hiệu hoặc người bán>",
  "note": "<Tóm tắt ngắn gọn các món hoặc dịch vụ đã mua, ví dụ: Cà phê sữa, Bánh mì kẹp>",
  "suggestedCategory": "<Một trong các danh mục: Ăn uống, Di chuyển, Mua sắm, Giải trí, Sức khỏe, Giáo dục, Hóa đơn, Nhà ở, Khác>"
}

Chỉ trả về JSON thuần túy, không kèm bất kỳ giải thích nào.
''';

  /// Lấy API Key hiện tại từ file .env
  static String getApiKey() => EnvConfig.geminiApiKey;

  /// Kiểm tra đã có API Key hợp lệ chưa
  static bool hasApiKey() => EnvConfig.hasGeminiApiKey;

  /// Lấy danh sách model theo cấu hình trong service
  static List<String> _resolveModels() => _modernCandidateModels;

  /// Phân tích hóa đơn bằng Google Gemini AI
  static Future<GeminiReceiptResult> parseReceipt({
    String? apiKey,
    String? rawText,
    Uint8List? imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    final key = (apiKey != null && apiKey.trim().isNotEmpty)
        ? apiKey.trim()
        : EnvConfig.geminiApiKey;

    if (key.isEmpty) {
      throw ArgumentError(
        'Chưa cấu hình GEMINI_API_KEY trong file .env.',
      );
    }

    final candidateModels = _resolveModels();
    String? lastErrorMsg;

    for (final modelName in candidateModels) {
      try {
        debugPrint('Gemini: Đang phân tích với model $modelName');
        
        // Phương án 1: Gọi Direct REST API chuẩn (truyền API key qua x-goog-api-key và query parameter)
        GeminiReceiptResult? result;
        try {
          result = await _callGeminiRest(
            apiKey: key,
            modelName: modelName,
            rawText: rawText,
            imageBytes: imageBytes,
            mimeType: mimeType,
          );
        } catch (restError) {
          debugPrint('Gemini Direct REST lỗi ($modelName): $restError, thử qua SDK client...');
        }

        // Phương án 2: Gọi qua GenerativeModel SDK chính thức
        result ??= await _callGeminiSdk(
          apiKey: key,
          modelName: modelName,
          rawText: rawText,
          imageBytes: imageBytes,
          mimeType: mimeType,
        );

        if (result != null) {
          return result;
        }
      } catch (e) {
        debugPrint('Gemini model $modelName gặp lỗi: $e');
        final errorString = e.toString();

        if (errorString.contains('API_KEY_INVALID') ||
            errorString.contains('API key not valid') ||
            errorString.contains('UNAUTHENTICATED')) {
          throw Exception(
            'Google Gemini API Key không hợp lệ hoặc chưa được kích hoạt quyền Generative Language API.',
          );
        }

        if (errorString.contains('RESOURCE_EXHAUSTED') ||
            errorString.contains('Quota exceeded') ||
            errorString.contains('429')) {
          lastErrorMsg = 'Google Gemini API bị giới hạn tần suất request (429/Quota). Vui lòng thử lại sau giây lát.';
          continue;
        }

        lastErrorMsg = _cleanErrorMessage(errorString);
      }
    }

    throw Exception(
      lastErrorMsg ?? 'Không thể phân tích hóa đơn bằng Google AI. Vui lòng kiểm tra kết nối mạng.',
    );
  }

  /// Gọi trực tiếp Google Generative Language REST API
  /// (Dùng chuẩn x-goog-api-key và query parameter ?key=, tuyệt đối không dùng Bearer token cho API key)
  static Future<GeminiReceiptResult?> _callGeminiRest({
    required String apiKey,
    required String modelName,
    String? rawText,
    Uint8List? imageBytes,
    required String mimeType,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=${Uri.encodeComponent(apiKey)}',
    );

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'x-goog-api-key': apiKey,
    };

    final parts = <Map<String, dynamic>>[];

    var textPrompt = 'Hãy phân tích hóa đơn này và trả về JSON chuẩn.';
    if (rawText != null && rawText.trim().isNotEmpty) {
      textPrompt += '\n\nVăn bản OCR nhận diện từ hóa đơn:\n$rawText';
    }
    parts.add({'text': textPrompt});

    if (imageBytes != null && imageBytes.isNotEmpty) {
      final cleanMime = mimeType.contains('/') ? mimeType : 'image/jpeg';
      final base64Image = base64Encode(imageBytes);
      parts.add({
        'inlineData': {
          'mimeType': cleanMime,
          'data': base64Image,
        },
      });
    }

    final requestBody = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': _systemPrompt}
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': parts,
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.1,
      },
    });

    final res = await http
        .post(uri, headers: headers, body: requestBody)
        .timeout(const Duration(seconds: 30));

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates.first['content'] as Map<String, dynamic>?;
        final responseParts = content?['parts'] as List<dynamic>?;
        if (responseParts != null && responseParts.isNotEmpty) {
          final rawJson = responseParts.first['text'] as String?;
          if (rawJson != null && rawJson.trim().isNotEmpty) {
            return _parseJsonOutput(rawJson, modelUsed: modelName);
          }
        }
      }
    } else {
      debugPrint('Gemini Direct REST status ${res.statusCode}: ${res.body}');
      final errorMsg = _extractErrorMessage(res.body);
      if (res.statusCode == 404) {
        // Model không hỗ trợ hoặc deprecated -> trả về null để thử model kế tiếp
        return null;
      }
      if (res.statusCode == 401 || res.statusCode == 403) {
        throw Exception('API Key không có quyền truy cập hoặc không hợp lệ: $errorMsg');
      }
      throw Exception('Lỗi Google AI (${res.statusCode}): $errorMsg');
    }

    return null;
  }

  /// Gọi qua official SDK google_generative_ai
  static Future<GeminiReceiptResult?> _callGeminiSdk({
    required String apiKey,
    required String modelName,
    String? rawText,
    Uint8List? imageBytes,
    required String mimeType,
  }) async {
    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.1,
      ),
      systemInstruction: Content.system(_systemPrompt),
    );

    final parts = <Part>[];

    if (imageBytes != null && imageBytes.isNotEmpty) {
      final cleanMime = mimeType.contains('/') ? mimeType : 'image/jpeg';
      parts.add(DataPart(cleanMime, imageBytes));
    }

    var textPrompt = 'Hãy phân tích hóa đơn này và trả về JSON.';
    if (rawText != null && rawText.trim().isNotEmpty) {
      textPrompt += '\n\nVăn bản OCR nhận diện được từ hóa đơn:\n$rawText';
    }
    parts.add(TextPart(textPrompt));

    final content = [Content.multi(parts)];
    final response = await model.generateContent(content).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException('Quá thời gian phản hồi từ Google AI (30s).');
      },
    );

    final text = response.text;
    if (text == null || text.trim().isEmpty) {
      return null;
    }

    return _parseJsonOutput(text, modelUsed: modelName);
  }

  static String _extractErrorMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      return error?['message'] as String? ?? body;
    } catch (_) {
      return body;
    }
  }

  static GeminiReceiptResult _parseJsonOutput(String raw, {String? modelUsed}) {
    var cleaned = raw.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    Map<String, dynamic> data;
    try {
      data = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Gemini JSON parse failed on: $cleaned');
      throw Exception('Google AI trả về kết quả không đúng cấu trúc JSON.');
    }

    final rawAmount = data['amount'];
    double amount = 0.0;
    if (rawAmount is num) {
      amount = rawAmount.toDouble();
    } else if (rawAmount is String) {
      final sanitized = rawAmount.replaceAll(RegExp(r'[^\d.]'), '');
      amount = double.tryParse(sanitized) ?? 0.0;
    }

    final merchant = (data['merchant'] as String? ?? '').trim();
    final note = (data['note'] as String? ?? '').trim();
    final suggestedCategory =
        (data['suggestedCategory'] as String? ?? '').trim();

    return GeminiReceiptResult(
      amount: amount,
      merchant: merchant.isEmpty ? 'Hóa đơn' : merchant,
      note: note.isEmpty
          ? (merchant.isNotEmpty ? 'Google AI: $merchant' : 'Google AI Hóa đơn')
          : 'Google AI: $merchant ($note)',
      suggestedCategory: suggestedCategory.isEmpty ? null : suggestedCategory,
      modelUsed: modelUsed,
    );
  }

  static String _cleanErrorMessage(String error) {
    if (error.contains('SocketException') ||
        error.contains('HandshakeException') ||
        error.contains('Failed host lookup')) {
      return 'Không có kết nối Internet. Vui lòng kiểm tra mạng.';
    }
    return error.replaceAll('Exception: ', '').replaceAll('GenerativeAIException: ', '');
  }
}
