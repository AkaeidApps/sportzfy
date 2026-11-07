/// A single stream entry from `streams.json`.
class StreamModel {
  const StreamModel({
    required this.channel,
    required this.url,
    this.feed,
    this.title,
    this.quality,
    this.userAgent,
    this.referrer,
    this.labels = const <String>[],
  });

  /// May be `null` in the public API for unattached streams.
  final String? channel;
  final String? feed;
  final String? title;
  final String url;
  final String? quality;
  final String? userAgent;
  final String? referrer;
  final List<String> labels;

  bool get hasUrl => url.trim().isNotEmpty;
  bool get isHttps => url.trim().toLowerCase().startsWith('https://');

  /// `1080p` becomes `1080`; unknown qualities become `0`.
  int get qualityValue {
    final match = RegExp(r'(\d{3,4})').firstMatch(quality ?? '');
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  bool get isAlwaysOn =>
      !labels.any((label) => label.toLowerCase().contains('not 24/7'));

  factory StreamModel.fromJson(Map<String, dynamic> json) {
    final rawLabels = json['labels'];
    return StreamModel(
      channel: json['channel'] as String?,
      feed: json['feed'] as String?,
      title: json['title'] as String?,
      url: json['url'] as String? ?? '',
      quality: json['quality'] as String?,
      userAgent: json['user_agent'] as String?,
      referrer: json['referrer'] as String?,
      labels: rawLabels is List
          ? rawLabels.whereType<String>().toList(growable: false)
          : const <String>[],
    );
  }
}
