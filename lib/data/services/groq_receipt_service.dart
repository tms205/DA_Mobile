import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GroqReceiptResult {
  const GroqReceiptResult({
    required this.amount,
    required this.merchant,
    required this.note,
    this.suggestedCategory,
  });

  final double amount;
  final String merchant;
  final String note;
  final String? suggestedCategory;
}

/// Service phân tích hóa đơn bằng Groq AI đạt tiêu chuẩn Production.
class GroqReceiptService {
  GroqReceiptService._();

  /// API Key mặc định (Groq)
  static const String _defaultApiKey =
      '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';

  // ─── Groq Config ────────────────────────────────────────
  static const String _groqBaseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _groqModelsUrl =
      'https://api.groq.com/openai/v1/models';

  /// Danh sách các model dự phòng nếu không tải được danh sách động từ server
  static const List<String> _fallbackModels = [
    'qwen/qwen3.6-27b',
    'groq/compound',
    'openai/gpt-oss-120b',
    'groq/compound-mini',
    'openai/gpt-oss-20b',
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
    'llama-3.2-11b-vision-preview',
  ];

  static const String _systemPrompt = '''
Bạn là chuyên gia phân tích hóa đơn tài chính tại Việt Nam.
Hãy phân tích hình ảnh hoặc văn bản hóa đơn được cung cấp và trích xuất thông tin dưới dạng JSON chuẩn.

Yêu cầu dữ liệu trả về theo đúng định dạng JSON:
{
  "amount": <Tổng số tiền thanh toán cuối cùng dưới dạng số thực, ví dụ: 125000. Nếu không tìm thấy thì là 0>,
  "merchant": "<Tên cửa hàng/thương hiệu hoặc người bán>",
  "note": "<Tóm tắt ngắn gọn danh sách các món mua hoặc dịch vụ, ví dụ: Cà phê sữa, Bánh mì>",
  "suggestedCategory": "<Tên danh mục phù hợp nhất trong các danh mục: Ăn uống, Di chuyển, Mua sắm, Giải trí, Sức khỏe, Giáo dục, Hóa đơn, Nhà ở, Khác>"
}

CHỈ trả về JSON thuần túy, KHÔNG có markdown, giải thích, hay suy luận nào khác.
''';

  /// Lấy API Key mặc định
  static String getApiKey() => _defaultApiKey;

  /// Tải danh sách model đang thực sự hoạt động trên Groq API (Dynamic Model Discovery)
  static Future<List<String>> _fetchActiveModels(String apiKey) async {
    try {
      final res = await http
          .get(
            Uri.parse(_groqModelsUrl),
            headers: {
              'Authorization': 'Bearer ${apiKey.trim()}',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final dataList = json['data'] as List<dynamic>?;
        if (dataList != null && dataList.isNotEmpty) {
          final activeIds = <String>[];
          for (final item in dataList) {
            final id = item['id'] as String?;
            if (id != null && id.isNotEmpty) {
              // Lọc bỏ các model không phải chat/completion (whisper, guard, embedding...)
              final lower = id.toLowerCase();
              if (!lower.contains('whisper') &&
                  !lower.contains('guard') &&
                  !lower.contains('orpheus') &&
                  !lower.contains('embedding')) {
                activeIds.add(id);
              }
            }
          }
          if (activeIds.isNotEmpty) {
            debugPrint('Groq: Đã tải ${activeIds.length} active models động: $activeIds');
            return activeIds;
          }
        }
      }
    } catch (e) {
      debugPrint('Groq: Lỗi tải danh sách model động ($e), sử dụng danh sách dự phòng.');
    }
    return _fallbackModels;
  }

  /// Phân tích hóa đơn bằng Groq AI
  static Future<GroqReceiptResult> parseReceipt({
    required String apiKey,
    String? rawText,
    Uint8List? imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      throw ArgumentError('Vui lòng cung cấp Groq API Key hợp lệ.');
    }

    // Tải danh sách model đang hoạt động thực tế từ Groq API
    final candidateModels = await _fetchActiveModels(cleanKey);

    String? lastErrorMsg;

    // ── GIAI ĐOẠN 1: Thử phân tích Multimodal (Text + Ảnh) ──
    if (imageBytes != null && imageBytes.isNotEmpty) {
      for (final model in candidateModels) {
        try {
          debugPrint('Groq Multimodal: Đang thử model $model');
          final result = await _callGroqApi(
            apiKey: cleanKey,
            model: model,
            rawText: rawText,
            imageBytes: imageBytes,
            mimeType: mimeType,
          );
          if (result != null) {
            return result;
          }
        } on _GroqApiException catch (e) {
          debugPrint('Groq Multimodal error ($model): ${e.message} [Code ${e.statusCode}]');
          lastErrorMsg = e.userFriendlyMessage;
          if (e.isAuthError) rethrow; // Key không đúng -> dừng ngay
          if (e.isRateLimit) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
          // Tiếp tục thử model kế tiếp
        } catch (e) {
          debugPrint('Groq Multimodal unexpected error ($model): $e');
          lastErrorMsg = 'Sự cố kết nối với AI ($model)';
        }
      }
    }

    // ── GIAI ĐOẠN 2: Fallback sang phân tích văn bản OCR (Text-only) ──
    // Nếu gửi ảnh bị lỗi hoặc không có ảnh, dùng văn bản bóc tách từ OCR
    if (rawText != null && rawText.trim().isNotEmpty) {
      debugPrint('Groq Fallback: Chuyển sang phân tích văn bản OCR thuần túy');
      for (final model in candidateModels) {
        try {
          debugPrint('Groq Text OCR: Đang thử model $model');
          final result = await _callGroqApi(
            apiKey: cleanKey,
            model: model,
            rawText: rawText,
            imageBytes: null, // Không gửi kèm ảnh
            mimeType: mimeType,
          );
          if (result != null) {
            return result;
          }
        } on _GroqApiException catch (e) {
          debugPrint('Groq Text OCR error ($model): ${e.message} [Code ${e.statusCode}]');
          lastErrorMsg = e.userFriendlyMessage;
          if (e.isAuthError) rethrow;
          if (e.isRateLimit) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } catch (e) {
          debugPrint('Groq Text OCR unexpected error ($model): $e');
          lastErrorMsg = 'Sự cố kết nối với AI ($model)';
        }
      }
    }

    throw Exception(
      lastErrorMsg ??
          'Không thể kết nối Groq AI. Vui lòng kiểm tra kết nối mạng hoặc thử lại sau vài giây.',
    );
  }

  static Future<GroqReceiptResult?> _callGroqApi({
    required String apiKey,
    required String model,
    String? rawText,
    Uint8List? imageBytes,
    required String mimeType,
  }) async {
    final contentParts = <Map<String, dynamic>>[];

    var userText = 'Phân tích hóa đơn này và trả về kết quả định dạng JSON chuẩn.';
    if (rawText != null && rawText.trim().isNotEmpty) {
      userText += '\n\nNội dung văn bản OCR từ hóa đơn:\n$rawText';
    }
    contentParts.add({'type': 'text', 'text': userText});

    if (imageBytes != null && imageBytes.isNotEmpty) {
      final b64 = base64Encode(imageBytes);
      contentParts.add({
        'type': 'image_url',
        'image_url': {
          'url': 'data:$mimeType;base64,$b64',
        },
      });
    }

    final requestBody = jsonEncode({
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content': _systemPrompt,
        },
        {
          'role': 'user',
          'content': contentParts,
        },
      ],
      'temperature': 0.1,
      'max_tokens': 1024,
    });

    final response = await http
        .post(
          Uri.parse(_groqBaseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: requestBody,
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode == 200) {
      return _parseGroqResponse(response.body);
    }

    final statusCode = response.statusCode;
    final errorBody = response.body;
    final extractedMsg = _extractGroqErrorMessage(errorBody);

    if (statusCode == 401 || statusCode == 403) {
      throw _GroqApiException(
        extractedMsg ?? 'API Key không hợp lệ',
        userFriendlyMessage:
            'Groq API Key không hợp lệ hoặc đã hết hạn.\nVui lòng kiểm tra lại Key tại console.groq.com/keys',
        statusCode: statusCode,
        isAuthError: true,
      );
    }

    if (statusCode == 429) {
      throw _GroqApiException(
        extractedMsg ?? 'Rate limit exceeded',
        userFriendlyMessage:
            'Groq API đang bị giới hạn tần suất request (429). Vui lòng thử lại sau 30 giây.',
        statusCode: statusCode,
        isRateLimit: true,
      );
    }

    if (statusCode == 404 || statusCode == 400) {
      throw _GroqApiException(
        extractedMsg ?? 'Model $model không hỗ trợ hoặc không tồn tại',
        userFriendlyMessage:
            'Model $model hiện chưa sẵn sàng. Đang tự động thử model khác...',
        statusCode: statusCode,
        isModelUnavailable: true,
      );
    }

    throw _GroqApiException(
      extractedMsg ?? 'Lỗi Groq API ($statusCode)',
      userFriendlyMessage:
          'Máy chủ AI gặp sự cố ($statusCode). Đang thử phương án dự phòng...',
      statusCode: statusCode,
    );
  }

  static GroqReceiptResult _parseGroqResponse(String responseBody) {
    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    final choices = json['choices'] as List<dynamic>?;

    if (choices == null || choices.isEmpty) {
      throw Exception('Groq AI không trả về kết quả nào.');
    }

    final message = choices.first['message'] as Map<String, dynamic>;
    final rawContent = message['content'] as String? ?? '';
    final cleanedJson = _cleanJsonString(rawContent);

    return _parseReceiptJson(cleanedJson);
  }

  static String? _extractGroqErrorMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      return error?['message'] as String?;
    } catch (_) {
      return null;
    }
  }

  static GroqReceiptResult _parseReceiptJson(String cleanedJson) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(cleanedJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Groq JSON parse failed: $cleanedJson');
      throw Exception('Groq AI trả về dữ liệu không đúng cấu trúc JSON.');
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

    return GroqReceiptResult(
      amount: amount,
      merchant: merchant.isEmpty ? 'Hóa đơn' : merchant,
      note: note.isEmpty
          ? (merchant.isNotEmpty ? 'Groq AI: $merchant' : 'Groq AI Hóa đơn')
          : 'Groq AI: $merchant ($note)',
      suggestedCategory: suggestedCategory.isEmpty ? null : suggestedCategory,
    );
  }

  static String _cleanJsonString(String raw) {
    var text = raw.trim();
    // Loại bỏ suy luận trong cặp thẻ <think>...</think> nếu model trả về
    text = text.replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '').trim();
    if (text.startsWith('```json')) {
      text = text.substring(7);
    } else if (text.startsWith('```')) {
      text = text.substring(3);
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    return text.trim();
  }
}

class _GroqApiException implements Exception {
  _GroqApiException(
    this.message, {
    required this.userFriendlyMessage,
    required this.statusCode,
    this.isAuthError = false,
    this.isRateLimit = false,
    this.isModelUnavailable = false,
  });

  final String message;
  final String userFriendlyMessage;
  final int statusCode;
  final bool isAuthError;
  final bool isRateLimit;
  final bool isModelUnavailable;

  @override
  String toString() => userFriendlyMessage;
}
