import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'formatters.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final isVnd = CurrencyFormatter.usesBaseCurrency;
    final bool isDeleting = oldValue.text.length > newValue.text.length;
    int selectionIndex = newValue.selection.end;
    String newText = newValue.text;

    // Detect backspace on separator
    if (isDeleting && oldValue.selection.end > 0) {
      final int deletedIdx = newValue.selection.end;
      if (deletedIdx < oldValue.text.length) {
        final charDeleted = oldValue.text[deletedIdx];
        if (charDeleted == '.' || charDeleted == ',') {
          if (deletedIdx > 0) {
            newText = oldValue.text.substring(0, deletedIdx - 1) +
                oldValue.text.substring(deletedIdx + 1);
            selectionIndex = deletedIdx - 1;
          }
        }
      }
    }

    String cleanText;
    if (isVnd) {
      cleanText = newText.replaceAll(RegExp(r'[^0-9]'), '');
    } else {
      cleanText = newText.replaceAll(RegExp(r'[^0-9.]'), '');
      final parts = cleanText.split('.');
      if (parts.length > 2) {
        cleanText = '${parts[0]}.${parts.sublist(1).join('')}';
      }
    }

    if (cleanText.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    String formattedText;
    if (isVnd) {
      final parsed = double.tryParse(cleanText) ?? 0.0;
      final formatter = NumberFormat('#,###', 'vi_VN');
      formattedText = formatter.format(parsed);
    } else {
      final parts = cleanText.split('.');
      final intPart = double.tryParse(parts[0]) ?? 0.0;
      final formatter = NumberFormat('#,###', 'en_US');
      String formattedInt = formatter.format(intPart);
      if (parts.length > 1) {
        formattedText = '$formattedInt.${parts[1]}';
      } else {
        formattedText = formattedInt;
      }
    }

    int digitsBeforeCursor = 0;
    for (int i = 0; i < selectionIndex && i < newText.length; i++) {
      if (RegExp(r'[0-9]').hasMatch(newText[i])) {
        digitsBeforeCursor++;
      }
    }

    int newSelectionIndex = 0;
    int digitCount = 0;
    while (digitCount < digitsBeforeCursor && newSelectionIndex < formattedText.length) {
      if (RegExp(r'[0-9]').hasMatch(formattedText[newSelectionIndex])) {
        digitCount++;
      }
      newSelectionIndex++;
    }

    if (newSelectionIndex > formattedText.length) {
      newSelectionIndex = formattedText.length;
    }

    if (newValue.selection.end == newValue.text.length) {
      newSelectionIndex = formattedText.length;
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newSelectionIndex),
    );
  }
}
