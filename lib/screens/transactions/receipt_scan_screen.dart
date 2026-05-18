import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/services/receipt_parser.dart';

class ReceiptScanScreen extends StatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  State<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends State<ReceiptScanScreen> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  Timer? _parseDebounce;

  String? _imagePath;
  ReceiptDraft? _draft;

  @override
  void dispose() {
    _parseDebounce?.cancel();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('OCR hóa đơn')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildImagePicker(),
          const SizedBox(height: 16),
          _buildTextInput(),
          const SizedBox(height: 16),
          if (_draft != null) _buildPreview(_draft!),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.document_scanner, color: AppColors.primary),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _pickImage,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            tooltip: 'Chọn ảnh',
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
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
            maxLines: 8,
            keyboardType: TextInputType.multiline,
            enableSuggestions: false,
            autocorrect: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            decoration: const InputDecoration(
              hintText:
                  'Dán nội dung hóa đơn sau khi quét, ví dụ:\nCửa hàng ABC\nTổng cộng 125.000',
              alignLabelWithHint: true,
            ),
            onChanged: (_) => _scheduleParse(),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _parse,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Nhận diện số tiền'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(ReceiptDraft draft) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CurrencyFormatter.format(draft.amount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  draft.note,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() => _imagePath = image.path);
    _parse();
  }

  void _parse() {
    setState(() {
      _draft = ReceiptParser.parse(_textController.text, imagePath: _imagePath);
    });
  }

  void _scheduleParse() {
    _parseDebounce?.cancel();
    final composing = _textController.value.composing;
    if (composing.isValid && !composing.isCollapsed) return;

    _parseDebounce = Timer(const Duration(milliseconds: 300), _parse);
  }
}
