import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controller/current_color_controller.dart';
import '../../controller/player_controller.dart';
import '../../controller/settings_controller.dart';
import '../../core/broken_icons.dart';
import '../../core/extensions.dart';
import '../../services/artwork_service.dart';
import '../widgets/artwork.dart';
import 'player_page.dart';

class MiniplayerBar extends StatefulWidget {
  const MiniplayerBar({super.key});

  @override
  State<MiniplayerBar> createState() => _MiniplayerBarState();
}

class _MiniplayerBarState extends State<MiniplayerBar> {
  ImageProvider? _cachedImage;
  int? _cachedTrackId;

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
          }
        });
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 12.0),
      child: SizedBox(
        height: 82.0,
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
                  padding: const EdgeInsets.all(12.0),
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
                          width: 40.0,
                          height: 40.0,
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
                  child: GestureDetector(
                    onTap: () {},
                    behavior: HitTestBehavior.opaque,
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
    final track = context.read<PlayerController>().currentTrack;
    if (track == null) {
      return SizedBox(
        width: 58.0,
        height: 58.0,
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(
            Broken.musicnote,
            size: 30.0,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final image = _cachedImage;
    return SizedBox(
      width: 58.0,
      height: 58.0,
      child: image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image(image: image, fit: BoxFit.cover),
            )
          : Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                Broken.musicnote,
                size: 30.0,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
    );
  }

  void _openPlayer(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PlayerPage(),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
      ),
    );
  }
}
