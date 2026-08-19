import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/currency_provider.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _query = '';

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<CurrencyProvider>();
    final entries = provider.currencies.entries.where((entry) {
      final text = '${entry.key} ${entry.value}'.toLowerCase();
      return text.contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('Đơn vị tiền tệ'),
        actions: [
          IconButton(
            onPressed: provider.isLoading
                ? null
                : () => provider.refreshRates(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Cập nhật tỷ giá',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummary(provider),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              enableSuggestions: false,
              autocorrect: false,
              smartDashesType: SmartDashesType.disabled,
              smartQuotesType: SmartQuotesType.disabled,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm USD, EUR, JPY...',
              ),
              onChanged: (_) => _scheduleSearch(),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final isSelected = entry.key == provider.selectedCurrency;
                final rate = provider.ratesFromVnd[entry.key];
                final primaryColor = isDark ? AppColors.accent : AppColors.primary;
                final primarySurfaceColor = isDark ? AppColors.primarySurfaceDark : AppColors.primarySurface;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected
                        ? primaryColor
                        : primarySurfaceColor,
                    child: Text(
                      CurrencySymbols.symbolFor(entry.key),
                      style: TextStyle(
                        color: isSelected ? Colors.white : primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text('${entry.key} - ${entry.value}'),
                  subtitle: Text(
                    rate == null
                        ? 'Chưa có tỷ giá'
                        : '1 VND = ${rate.toStringAsPrecision(4)} ${entry.key}',
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: primaryColor)
                      : null,
                  onTap: rate == null
                      ? null
                      : () async {
                          await provider.changeCurrency(entry.key);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Đã đổi sang ${entry.key}')),
                          );
                        },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(CurrencyProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.cardGradientDark : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.dynamicElevatedShadow(isDark),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiền tệ đang dùng',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            '${provider.selectedCurrency} - ${provider.selectedCurrencyName}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.ratesUpdatedAt == null
                ? 'Dùng tỷ giá dự phòng'
                : 'Tỷ giá cập nhật: ${DateFormatter.formatDate(provider.ratesUpdatedAt!)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (provider.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              provider.errorMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  void _scheduleSearch() {
    _searchDebounce?.cancel();
    final composing = _searchController.value.composing;
    if (composing.isValid && !composing.isCollapsed) return;

    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _query = _searchController.text);
    });
  }
}
