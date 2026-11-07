/// A logo entry from `logos.json`.
class LogoModel {
  const LogoModel({
    required this.channel,
    required this.url,
    this.feed,
    this.inUse = false,
    this.width = 0,
    this.height = 0,
    this.format = '',
    this.tags = const <String>[],
  });

  final String? channel;
  final String? feed;
  final bool inUse;
  final List<String> tags;
  final int width;
  final int height;
  final String format;
  final String url;

  bool get hasUrl => url.trim().isNotEmpty;

  /// `CachedNetworkImage` renders raster images only, so SVG logos are skipped
  /// in favour of PNG/JPEG alternatives.
  bool get isSvg =>
      format.toUpperCase() == 'SVG' ||
      url.trim().toLowerCase().endsWith('.svg');

  factory LogoModel.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    return LogoModel(
      channel: json['channel'] as String?,
      feed: json['feed'] as String?,
      inUse: json['in_use'] as bool? ?? false,
      tags: rawTags is List
          ? rawTags.whereType<String>().toList(growable: false)
          : const <String>[],
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      format: json['format'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }
}
