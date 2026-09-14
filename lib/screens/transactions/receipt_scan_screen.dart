
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../data/services/gemini_receipt_service.dart';
import '../../data/services/receipt_parser.dart';

class ReceiptScanScreen extends StatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  State<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends State<ReceiptScanScreen> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  Timer? _parseDebounce;

  Uint8List? _imageBytes;
  String? _imagePath;
  String? _statusMessage;
  bool _isPickingImage = false;
  bool _isProcessingImage = false;
  bool _isAnalyzingWithAi = false;
  ReceiptDraft? _draft;

  bool get _supportsOcr {
    if (kIsWeb) {
      return false;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }

  bool get _isBusy =>
      _isPickingImage ||
      _isProcessingImage ||
      _isAnalyzingWithAi;

  @override
  void initState() {
    super.initState();
    _recoverLostImage();
  }

  @override
  void dispose() {
    _parseDebounce?.cancel();
    unawaited(_textRecognizer.close());
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('OCR & AI hóa đơn'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildImagePicker(),
          const SizedBox(height: 16),
          _buildTextInput(),
          if (_statusMessage != null) ...[
            const SizedBox(height: 16),
            _buildStatusCard(),
          ],
          if (_draft != null) ...[
            const SizedBox(height: 16),
            _buildPreview(_draft!),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _draft == null || _draft!.amount <= 0
                ? null
                : () => Navigator.pop(context, _draft),
            icon: const Icon(Icons.receipt_long),
            label: const Text('Tạo giao dịch từ hóa đơn'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final primaryColor = isDark ? AppColors.accent : AppColors.primary;
    final primarySurfaceColor = isDark ? AppColors.primarySurfaceDark : AppColors.primarySurface;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHint;
    final textSecColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.dynamicCardShadow(isDark),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: primarySurfaceColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.document_scanner,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ảnh hóa đơn',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _imagePath == null ? 'Chưa chọn ảnh' : _imagePath!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hintColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_imagePath != null)
                IconButton(
                  onPressed: _isBusy ? null : _clearSelection,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Xóa ảnh',
                ),
            ],
          ),
          if (_imageBytes != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(
                _imageBytes!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isBusy || !_supportsOcr
                      ? null
                      : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Thư viện'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isBusy || !_supportsOcr
                      ? null
                      : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Chụp ảnh'),
                ),
              ),
            ],
          ),
          if (_isPickingImage) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              'Đang mở bộ chọn ảnh...',
              style: TextStyle(color: textSecColor),
            ),
          ] else if (_isProcessingImage) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              'Đang OCR hóa đơn...',
              style: TextStyle(color: textSecColor),
            ),
          ] else if (!_supportsOcr) ...[
            const SizedBox(height: 12),
            const Text(
              'OCR chỉ hỗ trợ trên Android và iOS.',
              style: TextStyle(color: AppColors.warning),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surface;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.dynamicCardShadow(isDark),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nội dung hóa đơn',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _textController,
            maxLines: 10,
            keyboardType: TextInputType.multiline,
            enableSuggestions: false,
            autocorrect: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            decoration: const InputDecoration(
              hintText:
                  'Chọn ảnh hóa đơn hoặc dán nội dung OCR vào đây.\nVí dụ:\nCửa hàng ABC\nTổng cộng 125.000',
              alignLabelWithHint: true,
            ),
            onChanged: (_) => _scheduleParse(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isBusy ? null : _parseWithGoogleAi,
                  icon: _isAnalyzingWithAi
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: const Text(AppStrings.reanalyzeWithAi),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _isBusy ? null : _parse,
                icon: const Icon(Icons.refresh),
                label: const Text('Cục bộ'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceVariantColor = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final primaryColor = isDark ? AppColors.accent : AppColors.primary;
    final textSecColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceVariantColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _statusMessage!.contains('thất bại') || _statusMessage!.contains('Lỗi')
                ? Icons.error_outline
                : (_draft != null && _draft!.amount > 0
                    ? Icons.check_circle_outline
                    : Icons.info_outline),
            color: _statusMessage!.contains('thất bại') || _statusMessage!.contains('Lỗi')
                ? AppColors.expense
                : (_draft != null && _draft!.amount > 0
                    ? primaryColor
                    : AppColors.info),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _statusMessage!,
              style: TextStyle(color: textSecColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(ReceiptDraft draft) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.accent : AppColors.primary;
    final primarySurfaceColor = isDark ? AppColors.primarySurfaceDark : AppColors.primarySurface;
    final textSecColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primarySurfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CurrencyFormatter.format(draft.amount),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
                Text(
                  draft.note,
                  style: TextStyle(color: textSecColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _recoverLostImage() async {
    if (!_supportsOcr) {
      return;
    }

    final response = await _picker.retrieveLostData();
    if (response.isEmpty) {
      return;
    }

    final files = response.files;
    if (files != null && files.isNotEmpty) {
      await _handlePickedImage(
        files.first,
        statusMessage: 'Đã khôi phục ảnh vừa chọn. Đang OCR lại.',
      );
      return;
    }

    if (!mounted || response.exception == null) {
      return;
    }

    setState(() {
      _statusMessage = 'Không thể khôi phục ảnh vừa chọn.';
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!_supportsOcr || _isBusy) {
      return;
    }

    try {
      setState(() {
        _isPickingImage = true;
        _statusMessage = source == ImageSource.camera
            ? 'Đang mở camera...'
            : 'Đang mở thư viện ảnh...';
      });

      final image = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          _statusMessage = 'Bạn chưa chọn ảnh nào.';
        });
        return;
      }

      await _handlePickedImage(
        image,
        statusMessage: source == ImageSource.camera
            ? 'Đã chụp ảnh. Đang OCR hóa đơn.'
            : 'Đã chọn ảnh từ thư viện. Đang OCR hóa đơn.',
      );
    } on PlatformException catch (error, stackTrace) {
      debugPrint('Image picker error: ${error.code} ${error.message}');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = switch (error.code) {
          'already_active' =>
            'Bộ chọn ảnh đang mở. Vui lòng đợi một chút rồi thử lại.',
          'camera_access_denied' => 'Camera bị từ chối quyền truy cập.',
          'photo_access_denied' => 'Thư viện ảnh bị từ chối quyền truy cập.',
          _ =>
            source == ImageSource.camera
                ? 'Không mở được camera.'
                : 'Không mở được thư viện ảnh.',
        };
      });
    } catch (error, stackTrace) {
      debugPrint('Unexpected image picker error: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = source == ImageSource.camera
            ? 'Không mở được camera.'
            : 'Không mở được thư viện ảnh.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _handlePickedImage(
    XFile image, {
    required String statusMessage,
  }) async {
    setState(() {
      _imagePath = image.path;
      _imageBytes = null;
      _statusMessage = statusMessage;
      _isProcessingImage = true;
      _draft = null;
    });

    try {
      final bytes = await image.readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() {
        _imageBytes = bytes;
      });

      final recognizedText = await _processImageForText(image.path, bytes);
      final extractedText = recognizedText.text.trim();

      if (!mounted) {
        return;
      }

      _textController.text = extractedText;
      _textController.selection = TextSelection.collapsed(
        offset: _textController.text.length,
      );

      setState(() {
        _statusMessage = extractedText.isEmpty
            ? 'Không đọc được chữ trong ảnh này. Bạn có thể thử ảnh khác hoặc sửa tay.'
            : 'Đã OCR xong. Bạn có thể sửa nội dung trước khi tạo giao dịch.';
      });

      _parse();
    } catch (error, stackTrace) {
      debugPrint('OCR error: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }

      _textController.clear();
      setState(() {
        _imageBytes = null;
        _draft = null;
        _statusMessage =
            'OCR thất bại. Vui lòng thử lại bằng ảnh rõ hơn hoặc chọn lại.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
        });
      }
    }
  }

  Future<RecognizedText> _processImageForText(
    String imagePath,
    Uint8List bytes,
  ) async {
    try {
      final fileInput = InputImage.fromFilePath(imagePath);
      return await _textRecognizer.processImage(fileInput);
    } catch (error, stackTrace) {
      debugPrint(
        'OCR file-path processing failed, trying bitmap fallback: $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      final bitmapInput = await _buildBitmapInputImage(bytes);
      return _textRecognizer.processImage(bitmapInput);
    }
  }

  Future<InputImage> _buildBitmapInputImage(Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (byteData == null) {
      image.dispose();
      codec.dispose();
      buffer.dispose();
      throw StateError('Unable to decode image bytes for OCR.');
    }

    final inputImage = InputImage.fromBitmap(
      bitmap: byteData.buffer.asUint8List(),
      width: image.width,
      height: image.height,
    );

    image.dispose();
    codec.dispose();
    buffer.dispose();
    return inputImage;
  }

  void _clearSelection() {
    _textController.clear();
    setState(() {
      _imageBytes = null;
      _imagePath = null;
      _draft = null;
      _statusMessage = null;
    });
  }

  void _parse() {
    setState(() {
      _draft = ReceiptParser.parse(_textController.text, imagePath: _imagePath);
    });
  }

  void _scheduleParse() {
    _parseDebounce?.cancel();
    final composing = _textController.value.composing;
    if (composing.isValid && !composing.isCollapsed) {
      return;
    }

    _parseDebounce = Timer(const Duration(milliseconds: 300), _parse);
  }

  Future<void> _parseWithGoogleAi() async {
    if (!GeminiReceiptService.hasApiKey()) {
      setState(() {
        _statusMessage = 'Chưa cấu hình API Key trong file .env.';
      });
      return;
    }

    setState(() {
      _isAnalyzingWithAi = true;
      _statusMessage = AppStrings.aiAnalyzing;
    });

    try {
      final mimeType = _imagePath?.toLowerCase().endsWith('.png') == true
          ? 'image/png'
          : 'image/jpeg';

      final result = await GeminiReceiptService.parseReceipt(
        rawText: _textController.text,
        imageBytes: _imageBytes,
        mimeType: mimeType,
      );

      if (!mounted) return;

      setState(() {
        _draft = ReceiptDraft(
          amount: result.amount,
          note: result.note,
          receiptImagePath: _imagePath,
        );
        _statusMessage = result.amount > 0
            ? 'AI phân tích thành công! Số tiền: ${CurrencyFormatter.format(result.amount)}'
            : 'AI đã phân tích. Vui lòng kiểm tra lại số tiền.';
      });
    } catch (error) {
      debugPrint('AI error: $error');
      if (!mounted) return;
      final cleanMsg = error.toString().replaceAll('Exception: ', '');
      setState(() {
        _statusMessage = 'Phân tích AI thất bại: $cleanMsg';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzingWithAi = false;
        });
      }
    }
  }
}
