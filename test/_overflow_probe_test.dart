import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportzfy/main.dart';
import 'package:sportzfy/models/channel_model.dart';
import 'package:sportzfy/models/highlight_model.dart';
import 'package:sportzfy/models/match_model.dart';
import 'package:sportzfy/providers/iptv_provider.dart';
import 'package:sportzfy/providers/theme_provider.dart';
import 'package:sportzfy/repository/iptv_repository.dart';

class FakeRepository implements IptvRepository {
  FakeRepository(this.channels);

  final List<Channel> channels;

  @override
  Future<CatalogResult> loadCatalog({bool forceRefresh = false}) async {
    return CatalogResult(
      channels: channels,
      savedAt: DateTime.now(),
      fromCache: false,
      networkFailed: false,
    );
  }

  @override
  List<MatchModel> buildMatches(List<Channel> channels) => const <MatchModel>[];

  @override
  List<HighlightModel> get highlights => const <HighlightModel>[];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final channels = <Channel>[
    for (var i = 0; i < 20; i++)
      Channel(
        id: 'ch$i',
        name: 'Very Long Sports Channel Name Number $i HD',
        logo: '',
        streamUrl: 'https://example.com/stream$i.m3u8',
        category: 'sports',
        country: 'BD',
        quality: '1080p',
      ),
  ];

  for (final size in <Size>[
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('no overflow at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            iptvRepositoryProvider.overrideWithValue(
              FakeRepository(channels),
            ),
          ],
          child: const SportzfyApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      // Visit every tab.
      for (final label in <String>[
        'Channels',
        'Schedule',
        'Highlights',
        'Home',
      ]) {
        await tester.tap(find.text(label).last);
        await tester.pump(const Duration(milliseconds: 600));
      }
    });
  }
}
