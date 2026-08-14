import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/storage_keys.dart';
import '../storage/local_storage_service.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return LocaleNotifier(storage);
});

class LocaleNotifier extends StateNotifier<Locale> {
  final LocalStorageService _storage;
  LocaleNotifier(this._storage) : super(_loadInitial(_storage));

  static Locale _loadInitial(LocalStorageService storage) {
    final code = storage.getString(StorageKeys.locale);
    if (code == 'ar') return const Locale('ar');
    return const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _storage.setString(StorageKeys.locale, locale.languageCode);
  }

  bool get isArabic => state.languageCode == 'ar';
  bool get isEnglish => state.languageCode == 'en';
}

class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);

  static const supportedLocales = [Locale('en'), Locale('ar')];

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ?? AppLocalizations(const Locale('en'));
  }

  bool get isRtl => locale.languageCode == 'ar';

  // Placeholder strings - real translations will be via ARB/intl later
  String get appName => 'NORLEX';
  String get welcome => locale.languageCode == 'ar' ? 'مرحبا بك في نورلكس' : 'Welcome to NORLEX';
  String get home => locale.languageCode == 'ar' ? 'الرئيسية' : 'Home';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) => SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
