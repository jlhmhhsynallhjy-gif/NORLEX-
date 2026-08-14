import 'package:flutter/material.dart';

class ChatEmptyState extends StatelessWidget {
  final Function(String) onSuggestionTap;
  const ChatEmptyState({super.key, required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      {'en': 'Explain quantum computing simply', 'ar': 'اشرح الحوسبة الكمومية ببساطة'},
      {'en': 'Help me plan a project', 'ar': 'ساعدني في تخطيط مشروع'},
      {'en': 'Write a Flutter widget', 'ar': 'اكتب واجهة Flutter'},
      {'en': 'Summarize this document', 'ar': 'لخص هذا المستند'},
    ];

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'مرحبا بك في نورلكس' : 'Welcome to NORLEX AI',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isArabic ? 'مساعدك الذكي الموحد - ابدأ محادثة الآن' : 'Your unified AI assistant - start a conversation',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: suggestions.map((s) {
                final text = isArabic ? s['ar']! : s['en']!;
                return ActionChip(
                  label: Text(text),
                  onPressed: () => onSuggestionTap(text),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Card(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        isArabic
                            ? 'ملاحظة: مزود AI الحقيقي سيتم ربطه عبر Backend Gateway لاحقاً. لا توجد ردود وهمية.'
                            : 'Note: Real AI provider will be connected via Backend Gateway later. No fake responses.',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
