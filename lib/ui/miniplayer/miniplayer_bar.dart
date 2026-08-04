import 'package:flutter/material.dart';

import '../../core/broken_icons.dart';
import '../../core/extensions.dart';

class MiniplayerBar extends StatelessWidget {
  final String trackTitle;
  final String trackArtist;
  final Widget? artworkWidget;
  final bool isPlaying;
  final VoidCallback? onPlayPauseTap;
  final VoidCallback? onTap;
  final Color accentColor;

  const MiniplayerBar({
    super.key,
    this.trackTitle = 'No track playing',
    this.trackArtist = '',
    this.artworkWidget,
    this.isPlaying = false,
    this.onPlayPauseTap,
    this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.vertical(top: Radius.circular(20.0));

    final hasTrack = trackTitle != 'No track playing';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 12.0),
      child: SizedBox(
        height: 82.0,
        width: double.infinity,
        child: GestureDetector(
          onTap: onTap,
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
                      color: accentColor,
                      borderRadius: borderRadius,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.alphaBlend(
                            theme.colorScheme.onSurface.withAlpha(100),
                            accentColor,
                          ).withOpacityExt(0.38),
                          Color.alphaBlend(
                            theme.colorScheme.onSurface.withAlpha(40),
                            accentColor,
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
                      SizedBox(
                        width: 58.0,
                        height: 58.0,
                        child:
                            artworkWidget ??
                            Container(
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
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trackTitle,
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
                            if (trackArtist.isNotEmpty) ...[
                              const SizedBox(height: 4.0),
                              Text(
                                trackArtist,
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
                        onTap: hasTrack ? onPlayPauseTap : null,
                        child: Container(
                          width: 40.0,
                          height: 40.0,
                          decoration: BoxDecoration(
                            color: hasTrack
                                ? accentColor
                                : theme.colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                            boxShadow: hasTrack
                                ? [
                                    BoxShadow(
                                      color: accentColor.withAlpha(80),
                                      blurRadius: 6.0,
                                      offset: const Offset(0.0, 2.0),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            isPlaying ? Broken.pause : Broken.play,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
