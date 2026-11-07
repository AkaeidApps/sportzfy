/// A feed entry from `feeds.json`.
///
/// Feeds describe regional/quality variants of a channel. They are used to
/// prefer a channel's main feed when several streams are available.
class FeedModel {
  const FeedModel({
    required this.channel,
    required this.id,
    this.name,
    this.isMain = false,
  });

  final String? channel;
  final String id;
  final String? name;
  final bool isMain;

  factory FeedModel.fromJson(Map<String, dynamic> json) {
    return FeedModel(
      channel: json['channel'] as String?,
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      isMain: json['is_main'] as bool? ?? false,
    );
  }
}
