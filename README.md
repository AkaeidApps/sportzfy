# Sportzfy Clone

A production-style IPTV learning app built with **Flutter**, **Riverpod**, **Dio**, **Hive**, **go_router** and **video_player**. The interface is **bilingual (English & বাংলা)** with **English as the default**, and supports both **dark and light** themes. The visual identity mirrors Sportzfy's cyan/orange palette.

> **For educational use only.** This project is not affiliated with Sportzfy or any broadcaster. Channel metadata and stream links come from the open-source [iptv-org](https://github.com/iptv-org) project. Nothing in this repository is hosted or owned by this app.

---

## Features

- **Bilingual UI** — every label, date, countdown and relative time renders in English or Bangla. The language can be switched from the app bar or drawer and is persisted with `shared_preferences`. English is the default.
- **Four tabs** — Live (Home), Channels, Schedule and Highlights — powered by `StatefulShellRoute` and `BottomNavigationBar`.
- **Home** — curated live/upcoming matches with team logos, league, venue, localized date/time and a **Watch Live** button, plus a horizontal sports-channel rail.
- **Channels** — a polished 2-column channel grid with live search and language-aware sport filters.
- **Schedule** — the full upcoming-fixture list with per-match reminders.
- **Highlights** — recent match highlights with 16:9 thumbnails, duration, sport and relative time.
- **Player** — immersive full-screen `video_player` with custom play/pause, seek, mute, buffering/error states, retry and **automatic multi-source fallback**. Channels keep up to six ranked stream URLs, so a channel stays playable when its primary provider is down.
- **Dark/Light theme** persisted with `shared_preferences`.
- **Offline-friendly** — merged channel list cached in Hive for 12 hours; stale cache is used when the network fails and a localized offline banner is shown.
- **Cached images** everywhere through `cached_network_image`.

---

## Data pipeline

The repository downloads four public data sets concurrently:

| Endpoint | Purpose |
| --- | --- |
| `https://iptv-org.github.io/api/channels.json` | channel id, name, country, categories |
| `https://iptv-org.github.io/api/streams.json` | stream URLs, quality, user-agent/referrer |
| `https://iptv-org.github.io/api/logos.json` | channel logos |
| `https://iptv-org.github.io/api/feeds.json` | main-feed preference |

`IptvRepository.mergeCatalog()` joins everything by the `channel` ID and:

1. keeps only `sports` channels,
2. removes closed, replaced, NSFW and stream-less channels,
3. ranks every usable stream: HTTPS → main feed → highest quality,
4. keeps up to six fallback URLs per channel,
5. skips SVG logos (Flutter's `CachedNetworkImage` renders raster images),
6. sorts Bangladeshi, Indian and Pakistani channels first.

The raw payloads are ~25 MB, so only the final merged sports list (~420 channels) is persisted. Subsequent launches are instant.

> The provided iptv-org APIs do **not** expose fixtures or highlights. The match schedule and highlight feed are clearly marked demo data in `iptv_repository.dart`. Live fixtures are linked to real channels from the loaded catalog, so the play button opens the same production player as the channel grid. Replace the curated fixtures with a real fixtures API in production.

---

## Project structure

```text
lib/
├── main.dart
├── l10n/
│   ├── app_language.dart
│   ├── app_localizations.dart
│   └── localized_text.dart
├── theme/
│   ├── app_colors.dart
│   └── app_theme.dart
├── models/
│   ├── channel_model.dart
│   ├── stream_model.dart
│   ├── logo_model.dart
│   ├── feed_model.dart
│   ├── match_model.dart
│   └── highlight_model.dart
├── services/
│   ├── api_service.dart
│   └── cache_service.dart
├── repository/
│   └── iptv_repository.dart
├── providers/
│   ├── iptv_provider.dart
│   ├── language_provider.dart
│   └── theme_provider.dart
├── routes/
│   ├── app_router.dart
│   └── app_routes.dart
├── screens/
│   ├── main_shell.dart
│   ├── home_screen.dart
│   ├── category_screen.dart
│   ├── schedule_screen.dart
│   ├── highlight_screen.dart
│   └── player_screen.dart
├── widgets/
│   ├── channel_card.dart
│   ├── match_card.dart
│   ├── highlight_card.dart
│   ├── custom_bottom_nav.dart
│   ├── connection_banner.dart
│   ├── error_view.dart
│   └── pressable.dart
└── utils/
    └── bangla_formatters.dart
```

Architecture: **MVVM** — models + repository (data), Riverpod `StateNotifier` (view-model state), screens/widgets (view).

---

## Run it

```bash
flutter pub get
flutter run
```

Requirements: Flutter 3.47+ / Dart 3.13+.

### Platform notes

- **Android**: Internet permission and `usesCleartextTraffic` are enabled because some public streams are HTTP.
- **iOS/macOS**: ATS arbitrary loads and network-client entitlement are enabled for the same reason. Review these before shipping to a store.
- **Web**: HLS streams use `video_player_web_hls` with hls.js so browsers such as Chrome can play `.m3u8` sources. The stream host still needs to allow cross-origin requests (CORS).
- The first channel load downloads the four API files; expect a few seconds on a slow connection.

---

## Verify

```bash
flutter analyze   # no issues
flutter test      # formatters, models, merge rules, localization
```

## License / attribution

- Channel, stream and logo metadata: [iptv-org](https://github.com/iptv-org) (open-source).
- Demo videos: [test-videos.co.uk](https://test-videos.co.uk) and [W3C media](https://media.w3.org).
- Demo thumbnails: [picsum.photos](https://picsum.photos).
- This project is for learning; do not redistribute copyrighted streams.
