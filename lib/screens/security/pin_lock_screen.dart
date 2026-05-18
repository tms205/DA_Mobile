import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/security_provider.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final _pinController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: AppColors.elevatedShadow,
                ),
                child: const Icon(Icons.lock_outline, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nhập mã PIN',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mở khóa để truy cập dữ liệu tài chính của bạn',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _pinController,
                obscureText: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '••••',
                  counterText: '',
                  errorText: _errorText,
                ),
                onSubmitted: (_) => _unlock(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _unlock,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Mở khóa'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _unlock() async {
    final pin = _pinController.text;
    if (pin.length < 4) {
      setState(() => _errorText = 'PIN phải có ít nhất 4 số');
      return;
    }

    final isValid = await context.read<SecurityProvider>().verifyPin(pin);
    if (!mounted) return;
    if (!isValid) {
      setState(() => _errorText = 'Mã PIN không đúng');
      return;
    }
    setState(() => _errorText = null);
  }
}

class PinSettingsScreen extends StatefulWidget {
  const PinSettingsScreen({super.key});

  @override
  State<PinSettingsScreen> createState() => _PinSettingsScreenState();
}

class _PinSettingsScreenState extends State<PinSettingsScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final security = context.watch<SecurityProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.security)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                Icon(
                  security.isPinEnabled ? Icons.lock : Icons.lock_open,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    security.isPinEnabled
                        ? 'PIN đang được bật'
                        : 'Chưa thiết lập mã PIN',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _pinField(_pinController, 'Mã PIN mới'),
          const SizedBox(height: 12),
          _pinField(_confirmController, 'Nhập lại mã PIN'),
          if (_errorText != null) ...[
            const SizedBox(height: 10),
            Text(_errorText!, style: const TextStyle(color: AppColors.expense)),
          ],
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _savePin,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Lưu mã PIN'),
          ),
          if (security.isPinEnabled) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _removePin,
              icon: const Icon(Icons.lock_open),
              label: const Text('Tắt mã PIN'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pinField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 6,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, counterText: ''),
    );
  }

  Future<void> _savePin() async {
    final pin = _pinController.text;
    final confirm = _confirmController.text;
    if (pin.length < 4) {
      setState(() => _errorText = 'PIN phải có ít nhất 4 số');
      return;
    }
    if (pin != confirm) {
      setState(() => _errorText = 'Mã PIN nhập lại không khớp');
      return;
    }

    await context.read<SecurityProvider>().setPin(pin);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu mã PIN')),
    );
    Navigator.pop(context);
  }

  Future<void> _removePin() async {
    await context.read<SecurityProvider>().removePin();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã tắt mã PIN')),
    );
    Navigator.pop(context);
  }
}
