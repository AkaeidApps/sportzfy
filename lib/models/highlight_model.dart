import '../l10n/app_language.dart';
import '../l10n/localized_text.dart';

/// A recent match highlight shown on the highlight tab.
class HighlightModel {
  const HighlightModel({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.streamUrl,
    required this.duration,
    required this.publishedAt,
    this.sport = 'other',
  });

  final String id;
  final LocalizedText title;
  final String thumbnail;
  final String streamUrl;
  final Duration duration;
  final DateTime publishedAt;

  /// Canonical sport id such as `cricket` or `football`.
  final String sport;

  String titleFor(AppLanguage language) => title.resolve(language);
}
