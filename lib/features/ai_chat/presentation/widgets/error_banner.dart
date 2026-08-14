import 'package:flutter/material.dart';
import '../../../../core/errors/failures.dart';

class ErrorBanner extends StatelessWidget {
  final String message;
  final String? code;
  const ErrorBanner({super.key, required this.message, this.code});

  factory ErrorBanner.fromFailure(Failure failure) {
    return ErrorBanner(message: failure.message, code: failure.code);
  }

  String _localizedMessage(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    switch (code) {
      case 'provider_unavailable':
        return isAr ? 'مزود الذكاء الاصطناعي غير متوفر. يجب إعداد البوابة الخلفية.' : 'AI provider unavailable. Backend gateway required.';
      case 'no_internet':
        return isAr ? 'لا يوجد اتصال بالإنترنت' : 'No internet connection';
      case 'timeout':
        return isAr ? 'انتهت مهلة الطلب' : 'Request timeout';
      default:
        return message;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Expanded(child: Text(_localizedMessage(context), style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer))),
            if (code != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Chip(label: Text(code!, style: const TextStyle(fontSize: 10))),
              ),
          ],
        ),
      ),
    );
  }
}
