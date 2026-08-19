import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/transaction_model.dart';
import '../../data/services/smart_finance_service.dart';
import '../../providers/account_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';

class FinancialAssistantScreen extends StatefulWidget {
  const FinancialAssistantScreen({super.key});

  @override
  State<FinancialAssistantScreen> createState() =>
      _FinancialAssistantScreenState();
}

class _FinancialAssistantScreenState extends State<FinancialAssistantScreen> {
  final _messageController = TextEditingController();
  final _messages = <_AssistantMessage>[];
  List<String> _quickQuestions = FinancialAssistantService.starterQuestions;
  bool _isLoading = true;
  List<Transaction> _currentMonth = [];
  List<Transaction> _previousMonth = [];
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final previous = DateTime(now.year, now.month - 1, 1);
    final transactionProvider = context.read<TransactionProvider>();

    await Future.wait([
      context.read<CategoryProvider>().loadCategories(),
      context.read<AccountProvider>().loadAccounts(),
      context.read<BudgetProvider>().loadBudgets(),
    ]);

    final results = await Future.wait([
      transactionProvider.fetchTransactionsForMonth(now.year, now.month),
      transactionProvider.fetchTransactionsForMonth(
        previous.year,
        previous.month,
      ),
    ]);

    if (!mounted) return;
    setState(() {
      _selectedMonth = DateTime(now.year, now.month, 1);
      _currentMonth = results[0];
      _previousMonth = results[1];
      _isLoading = false;
      _messages.add(
        const _AssistantMessage(
          text:
              'Chào bạn, mình là trợ lý tài chính cá nhân. Bạn có thể hỏi về chi tiêu tháng này, ngân sách, số dư hoặc dự đoán cuối tháng.',
          isUser: false,
        ),
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.accent : AppColors.primary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Tải lại dữ liệu',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            LinearProgressIndicator(
              minHeight: 3,
              color: primaryColor,
              backgroundColor: isDark ? AppColors.borderDark : AppColors.surfaceVariant,
            ),
          _buildSuggestions(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surface;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 1.0,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _quickQuestions.map((question) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                backgroundColor: isDark ? AppColors.primarySurfaceDark : AppColors.dividerLight,
                side: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1.0,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                avatar: Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: isDark ? AppColors.accent : AppColors.primary,
                ),
                label: Text(question),
                onPressed: _isLoading ? null : () => _sendQuestion(question),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_AssistantMessage message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alignment = message.isUser
        ? Alignment.centerRight
        : Alignment.centerLeft;

    final userBubbleGradient = isDark 
        ? const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : AppColors.primaryGradient;

    final textColor = message.isUser ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(message.isUser ? 16 : 4),
      bottomRight: Radius.circular(message.isUser ? 4 : 16),
    );

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: message.isUser ? userBubbleGradient : null,
          color: message.isUser ? null : (isDark ? AppColors.surfaceDark : AppColors.surface),
          borderRadius: borderRadius,
          boxShadow: message.isUser ? null : AppColors.dynamicCardShadow(isDark),
          border: message.isUser 
              ? null 
              : Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1.0,
                ),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: textColor, height: 1.45, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final primaryColor = isDark ? AppColors.accent : AppColors.primary;
    final textPri = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHint;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              width: 1.0,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                style: TextStyle(color: textPri, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Hỏi về chi tiêu, ngân sách, số dư...',
                  hintStyle: TextStyle(color: hintColor, fontSize: 14),
                  filled: true,
                  fillColor: isDark ? AppColors.backgroundDark : AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: primaryColor.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: _isLoading ? null : _sendFromInput,
              style: IconButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: primaryColor.withValues(alpha: 0.3),
                padding: const EdgeInsets.all(12),
              ),
              icon: const Icon(Icons.send_rounded, size: 20),
              tooltip: 'Gửi',
            ),
          ],
        ),
      ),
    );
  }

  void _sendFromInput() {
    final composing = _messageController.value.composing;
    if (composing.isValid && !composing.isCollapsed) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    _sendQuestion(text);
  }

  void _sendQuestion(String question) {
    final response = FinancialAssistantService.answer(
      question: question,
      currentMonth: _currentMonth,
      previousMonth: _previousMonth,
      categories: context.read<CategoryProvider>().categories,
      accounts: context.read<AccountProvider>().accounts,
      budgets: context.read<BudgetProvider>().budgets,
      selectedMonth: _selectedMonth,
    );

    setState(() {
      _messages.add(_AssistantMessage(text: question, isUser: true));
      _messages.add(_AssistantMessage(text: response.answer, isUser: false));
      if (response.suggestions.isNotEmpty) {
        _quickQuestions = response.suggestions;
      }
    });
  }
}

class _AssistantMessage {
  const _AssistantMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}
