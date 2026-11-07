import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/channel_model.dart';

/// A cached copy of the merged sports channel list.
class CachedCatalog {
  const CachedCatalog({required this.channels, required this.savedAt});

  final List<Channel> channels;
  final DateTime savedAt;

  bool get isExpired =>
      DateTime.now().difference(savedAt) > CacheService.timeToLive;
}

/// Hive-backed storage for the merged API response.
///
/// The public iptv-org payloads total roughly 25 MB, so the app only persists
/// the small merged sports list. This makes subsequent launches instant.
class CacheService {
  CacheService._(this._box);

  static const String boxName = 'sportzfy_cache';
  static const String _catalogKey = 'catalog_v1';
  static const Duration timeToLive = Duration(hours: 24);

  final Box<String>? _box;

  /// Creates a no-op cache used when Hive cannot be initialised.
  factory CacheService.disabled() => CacheService._(null);

  static Future<CacheService> open() async {
    final box = await Hive.openBox<String>(boxName);
    return CacheService._(box);
  }

  bool get isEnabled => _box != null;

  Future<CachedCatalog?> readCatalog() async {
    final box = _box;
    if (box == null) return null;

    final raw = box.get(_catalogKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      final savedAt =
          DateTime.tryParse(decoded['savedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final rawChannels = decoded['channels'];
      final channels = <Channel>[];

      if (rawChannels is List) {
        for (final item in rawChannels) {
          if (item is Map) {
            channels.add(Channel.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }

      final validChannels = channels
          .where((channel) => channel.hasStream)
          .toList(growable: false);
      if (validChannels.isEmpty) return null;

      return CachedCatalog(channels: validChannels, savedAt: savedAt);
    } catch (error) {
      debugPrint('Corrupt channel cache cleared: $error');
      await box.delete(_catalogKey);
      return null;
    }
  }

  Future<void> writeCatalog(List<Channel> channels) async {
    final box = _box;
    if (box == null) return;

    try {
      await box.put(
        _catalogKey,
        jsonEncode(<String, dynamic>{
          'savedAt': DateTime.now().toIso8601String(),
          'channels': channels
              .map((channel) => channel.toJson())
              .toList(growable: false),
        }),
      );
    } catch (error) {
      // Caching is an optimization; a write failure must never break the UI.
      debugPrint('Could not write channel cache: $error');
    }
  }

  Future<void> clear() async {
    await _box?.delete(_catalogKey);
  }
}
