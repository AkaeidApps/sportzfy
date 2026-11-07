import 'app_language.dart';

/// A tiny value object for copy that exists in both English and Bangla.
///
/// Demo fixtures use this so team names, leagues and venues switch together
/// with the rest of the interface.
class LocalizedText {
  const LocalizedText({required this.en, required this.bn});

  /// Creates text that is identical in both languages (brand names, etc.).
  const LocalizedText.same(String value) : en = value, bn = value;

  static const LocalizedText empty = LocalizedText.same('');

  final String en;
  final String bn;

  bool get isEmpty => en.trim().isEmpty && bn.trim().isEmpty;
  bool get isNotEmpty => !isEmpty;

  String resolve(AppLanguage language) => language.isBangla ? bn : en;

  @override
  String toString() => en;
}
