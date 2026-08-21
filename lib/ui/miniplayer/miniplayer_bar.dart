import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controller/current_color_controller.dart';
import '../../controller/navigator_controller.dart';
import '../../controller/player_controller.dart';
import '../../controller/settings_controller.dart';
import '../../core/broken_icons.dart';
import '../../core/extensions.dart';
import '../../services/artwork_service.dart';
import '../widgets/artwork.dart';
import '../widgets/artwork_flight.dart';
import 'player_page.dart';

class MiniplayerBar extends StatefulWidget {
  const MiniplayerBar({super.key});

  @override
  State<MiniplayerBar> createState() => _MiniplayerBarState();
}

class _MiniplayerBarState extends State<MiniplayerBar> {
  ImageProvider? _cachedImage;
  int? _cachedTrackId;

  /// Key for the miniplayer thumbnail, used to read its on-screen rect for the
  /// shared-element flight into the full player.
  final artworkKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    NavigatorController.inst.miniplayerArtworkHidden.addListener(
      _onArtworkHiddenChanged,
    );
  }

  void _onArtworkHiddenChanged() => setState(() {});

  @override
  void dispose() {
    NavigatorController.inst.miniplayerArtworkHidden.removeListener(
      _onArtworkHiddenChanged,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playerData = context
        .select<
          PlayerController,
          ({
            bool hasTrack,
            int? trackId,
            String title,
            String artist,
            bool isPlaying,
          })
        >(
          (p) => (
            hasTrack: p.hasTrack,
            trackId: p.currentTrack?.id,
            title: p.title,
            artist: p.artist,
            isPlaying: p.isPlaying,
          ),
        );
    final accent = context.select<CurrentColorController, Color>(
      (c) => c.accentColor,
    );
    final position = context.select<PlayerController, Duration>(
      (p) => p.position,
    );
    final duration = context.select<PlayerController, Duration>(
      (p) => p.duration,
    );
    final ratio = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final borderRadius = BorderRadius.vertical(top: Radius.circular(20.0));
    final hasTrack = playerData.hasTrack;

    final trackId = playerData.trackId;
    if (trackId != _cachedTrackId) {
      _cachedTrackId = trackId;
      _cachedImage = null;
      NavigatorController.inst.currentArtworkImage = null;
      final currentTrack = context.read<PlayerController>().currentTrack;
      if (currentTrack != null) {
        ArtworkService.inst.getHighResArtwork(currentTrack).then((bytes) {
          if (mounted &&
              _cachedTrackId == trackId &&
              bytes != null &&
              bytes.isNotEmpty) {
            final image = resizeMemoryArtwork(
              bytes,
              SettingsController.inst.artworkQuality.listDecodeSize,
            );
            ArtworkService.inst.cacheImageProvider(
              trackId!,
              image,
              namespace: 'thumb',
            );
            setState(() {
              _cachedImage = image;
            });
            NavigatorController.inst.currentArtworkImage = image;
          }
        });
      }
    }

    // Cache the thumbnail's on-screen rect (for the close-flight landing
    // target) whenever it is visible and not mid-flight.
    if (!NavigatorController.inst.miniplayerArtworkHidden.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final box = artworkKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null) {
          NavigatorController.inst.miniplayerArtworkRect =
              box.localToGlobal(Offset.zero) & box.size;
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
      child: SizedBox(
        height: 80.0,
        width: double.infinity,
        child: GestureDetector(
          onTap: hasTrack ? () => _openPlayer(context) : null,
          child: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacityExt(0.2),
                  blurRadius: 20.0,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: borderRadius,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.alphaBlend(
                            theme.colorScheme.onSurface.withAlpha(100),
                            accent,
                          ).withOpacityExt(0.38),
                          Color.alphaBlend(
                            theme.colorScheme.onSurface.withAlpha(40),
                            accent,
                          ).withOpacityExt(0.10),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Row(
                    children: [
                      _buildArtwork(context, theme, trackId),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playerData.title.isNotEmpty
                                  ? playerData.title
                                  : 'No track playing',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                                color: hasTrack
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (playerData.artist.isNotEmpty) ...[
                              const SizedBox(height: 4.0),
                              Text(
                                playerData.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12.5,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      GestureDetector(
                        onTap: hasTrack
                            ? context.read<PlayerController>().playPause
                            : null,
                        child: Container(
                          width: 37.0,
                          height: 37.0,
                          decoration: BoxDecoration(
                            color: hasTrack
                                ? accent
                                : theme.colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                            boxShadow: hasTrack
                                ? [
                                    BoxShadow(
                                      color: accent.withAlpha(80),
                                      blurRadius: 6.0,
                                      offset: const Offset(0.0, 2.0),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            playerData.isPlaying ? Broken.pause : Broken.play,
                            size: 22.0,
                            color: hasTrack
                                ? Colors.white.withOpacityExt(0.7)
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0.0,
                  left: 0.0,
                  right: 0.0,
                  height: 10.0,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.0,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 0.0,
                        disabledThumbRadius: 0.0,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 0.0,
                      ),
                    ),
                    child: Slider(
                      value: ratio,
                      onChanged: hasTrack
                          ? (v) => context.read<PlayerController>().seek(
                              Duration(
                                milliseconds: (v * duration.inMilliseconds)
                                    .round(),
                              ),
                            )
                          : null,
                      activeColor: accent,
                      inactiveColor: theme.colorScheme.onSurfaceVariant
                          .withOpacityExt(0.35),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtwork(BuildContext context, ThemeData theme, int? trackId) {
    final hidden = NavigatorController.inst.miniplayerArtworkHidden.value;
    final track = context.read<PlayerController>().currentTrack;
    final image = _cachedImage;
    final placeholder = Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Icon(
        Broken.musicnote,
        size: 26.0,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    final thumb = track == null || image == null
        ? placeholder
        : ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image(image: image, fit: BoxFit.cover),
          );
    return KeyedSubtree(
      key: artworkKey,
      child: Opacity(
        opacity: hidden ? 0.0 : 1.0,
        child: SizedBox(width: 58.0, height: 58.0, child: thumb),
      ),
    );
  }

  void _openPlayer(BuildContext context) {
    final player = context.read<PlayerController>();
    final track = player.currentTrack;
    if (track == null) {
      _pushPlayer(context);
      return;
    }

    // Source rect: the miniplayer thumbnail's current on-screen position.
    final box = artworkKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      _pushPlayer(context);
      return;
    }
    final sourceRect = box.localToGlobal(Offset.zero) & box.size;
    final image = _cachedImage;

    // Hide the thumbnail while the airborne artwork flies, then push the route
    // (fade, no slide) and start the flight once the player artwork is laid
    // out, so the thumbnail lifts into the player's center.
    NavigatorController.inst.miniplayerArtworkHidden.value = true;
    _pushPlayer(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetBox =
          NavigatorController.inst.playerArtworkKey.currentContext
                  ?.findRenderObject()
              as RenderBox?;
      final targetRect = targetBox != null
          ? (targetBox.localToGlobal(Offset.zero) & targetBox.size)
          : _centerRect(context);
      startArtworkFlight(
        context: context,
        sourceRect: sourceRect,
        targetRect: targetRect,
        image: image,
        radiusStart: 8.0,
        radiusEnd: 24.0,
        durationMs: SettingsController.inst.artworkFlightOpenMs,
        curve: Curves.easeInOutCubic,
        onCompleted: () {
          NavigatorController.inst.miniplayerArtworkHidden.value = false;
        },
      );
    });
  }

  void _pushPlayer(BuildContext context) {
    NavigatorController.inst.navigatorKey.currentState?.push(
      PageRouteBuilder(
        settings: const RouteSettings(name: 'player'),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PlayerPage(),
        transitionDuration: Duration(
          milliseconds: SettingsController.inst.artworkFlightOpenMs,
        ),
        reverseTransitionDuration: Duration(
          milliseconds: SettingsController.inst.artworkFlightCloseMs,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  /// Fallback landing rect (centered, using the player artwork size) used only
  /// if the player artwork hasn't been laid out yet when the flight starts.
  Rect _centerRect(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final s = SettingsController.inst.artworkSize;
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: s,
      height: s,
    );
  }
}
