class ReceiptDraft {
  const ReceiptDraft({
    required this.amount,
    required this.note,
    this.receiptImagePath,
  });

  final double amount;
  final String note;
  final String? receiptImagePath;
}

class ReceiptParser {
  ReceiptParser._();

  static ReceiptDraft parse(String rawText, {String? imagePath}) {
    final lines = rawText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final amount = _extractLargestAmount(rawText);
    final merchant = lines.isEmpty ? 'Hóa đơn' : lines.first;
    final note = amount > 0
        ? 'OCR: $merchant'
        : 'OCR: $merchant - cần nhập số tiền';

    return ReceiptDraft(
      amount: amount,
      note: note,
      receiptImagePath: imagePath,
    );
  }

  static double _extractLargestAmount(String text) {
    final matches = RegExp(r'\d{1,3}(?:[.,]\d{3})+|\d+').allMatches(text);
    var largest = 0.0;
    for (final match in matches) {
      final raw = match.group(0)!;
      final normalized = raw.replaceAll('.', '').replaceAll(',', '');
      final value = double.tryParse(normalized) ?? 0;
      if (value > largest) largest = value;
    }
    return largest;
  }
}
