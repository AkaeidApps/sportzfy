/// Last-resort media used when every upstream stream URL for a channel fails.
///
/// iptv-org links go offline regularly and many providers are geo-blocked or
/// rate-limited. Instead of ending on a dead player, each channel falls back to
/// these public, freely hosted demo videos/HLS streams so the viewer always
/// gets a working video.
///
/// These are clearly labelled as a backup in the player and are not the
/// channel's real broadcast.
abstract final class FallbackStreams {
  /// Ordered best-first. MP4 sources come first so playback also works in
  /// browsers that do not support HLS natively; HLS streams follow.
  static const List<String> urls = <String>[
    'https://media.w3.org/2010/05/bunny/trailer.mp4',
    'https://media.w3.org/2010/05/sintel/trailer.mp4',
    'https://media.w3.org/2010/05/video/movie_300.mp4',
    'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
    'https://test-videos.co.uk/vids/jellyfish/mp4/h264/360/Jellyfish_360_10s_1MB.mp4',
    'https://test-videos.co.uk/vids/sintel/mp4/h264/360/Sintel_360_10s_1MB.mp4',
    'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
    'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8',
    'https://storage.googleapis.com/shaka-demo-assets/angel-one-hls/hls.m3u8',
  ];

  static bool contains(String url) => urls.contains(url.trim());
}
