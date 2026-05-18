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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Financial Assistant'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại dữ liệu',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            const LinearProgressIndicator(
              minHeight: 3,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceVariant,
            ),
          _buildSuggestions(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _quickQuestions.map((question) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: const Icon(Icons.auto_awesome, size: 16),
                label: Text(question),
                onPressed: _isLoading ? null : () => _sendQuestion(question),
                labelStyle: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_AssistantMessage message) {
    final alignment = message.isUser
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final color = message.isUser ? AppColors.primary : AppColors.surface;
    final textColor = message.isUser ? Colors.white : AppColors.textPrimary;
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
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
          boxShadow: message.isUser ? null : AppColors.cardShadow,
        ),
        child: Text(
          message.text,
          style: TextStyle(color: textColor, height: 1.35, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                enableSuggestions: false,
                autocorrect: false,
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                decoration: const InputDecoration(
                  hintText: 'Hỏi về chi tiêu, ngân sách, số dư...',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isLoading ? null : _sendFromInput,
              icon: const Icon(Icons.send_rounded),
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
