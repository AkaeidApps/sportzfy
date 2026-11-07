/// The two languages supported by the app.
///
/// English is the default; the choice is persisted in `shared_preferences`
/// and can be changed at any time from the app bar or the drawer.
enum AppLanguage {
  english('en'),
  bangla('bn');

  const AppLanguage(this.code);

  final String code;

  bool get isBangla => this == AppLanguage.bangla;

  static AppLanguage fromCode(String? code) =>
      code == AppLanguage.bangla.code ? AppLanguage.bangla : AppLanguage.english;
}
