import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controller/current_color_controller.dart';
import '../../controller/player_controller.dart';
import '../../controller/settings_controller.dart';
import '../../core/broken_icons.dart';
import '../../core/extensions.dart';
import '../../data/models/track.dart';
import '../../services/artwork_service.dart';
import '../widgets/animated_artwork_widget.dart';
import 'lyrics_view.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  bool _showLyrics = false;
  bool _showQueue = false;
  int? _lastTrackId;
  ImageProvider? _staticArtworkImage;
  int? _staticArtworkTrackId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _extractColor();
    });
  }

  Future<void> _extractColor() async {
    if (!mounted) return;
    final player = context.read<PlayerController>();
    final colorCtrl = context.read<CurrentColorController>();
    if (player.currentTrack != null) {
      final image = await ArtworkService.inst.getArtworkImage(
        player.currentTrack!,
      );
      if (mounted) colorCtrl.extractFromImage(image);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final player = context.watch<PlayerController>();
    final colorCtrl = context.watch<CurrentColorController>();
    final accent = colorCtrl.accentColor;

    if (player.currentTrack?.id != _lastTrackId) {
      _lastTrackId = player.currentTrack?.id;
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: theme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarIconBrightness: theme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                accent.withOpacityExt(0.15),
                theme.scaffoldBackgroundColor,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, theme, player),
                Expanded(
                  child: _showLyrics
                      ? const LyricsView()
                      : _showQueue
                      ? _buildQueueView(context, theme, player, accent)
                      : _buildMainPlayer(context, theme, player, accent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    PlayerController player,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Broken.arrow_down_2, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Reproduciendo de',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  player.album,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _showLyrics ? Broken.musicnote : Broken.document_code,
              size: 24,
            ),
            onPressed: () {
              setState(() {
                _showLyrics = !_showLyrics;
                _showQueue = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainPlayer(
    BuildContext context,
    ThemeData theme,
    PlayerController player,
    Color accent,
  ) {
    return Column(
      children: [
        Expanded(
          child: Center(child: _buildArtwork(context, player, accent, theme)),
        ),
        _buildTrackInfo(context, player, theme),
        const SizedBox(height: 24),
        _buildControls(context, player, accent),
        const SizedBox(height: 12),
        _buildProgressBar(context, player, accent),
        const SizedBox(height: 8),
        _buildExtraButtons(context, player, accent),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildArtwork(
    BuildContext context,
    PlayerController player,
    Color accent,
    ThemeData theme,
  ) {
    final track = player.currentTrack;
    final settings = context.watch<SettingsController>();
    final size = settings.artworkSize;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacityExt(0.3),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: track != null && settings.enableAnimatedArtwork
            ? AnimatedArtworkWidget(
                key: ValueKey('artwork_${track.id}'),
                track: track,
                isPlaying: player.isPlaying,
                size: size,
                borderRadius: 24,
              )
            : _buildStaticArtwork(track, size, theme),
      ),
    );
  }

  Widget _buildStaticArtwork(ArcTrack? track, double size, ThemeData theme) {
    final trackId = track?.id;
    if (trackId != _staticArtworkTrackId) {
      _staticArtworkTrackId = trackId;
      _staticArtworkImage = null;
      if (track != null) {
        final cached = ArtworkService.inst.getCachedImageProvider(track.id);
        if (cached != null) {
          _staticArtworkImage = cached;
        } else {
          ArtworkService.inst.getArtworkImage(track).then((img) {
            if (mounted && _staticArtworkTrackId == trackId) {
              setState(() => _staticArtworkImage = img);
            }
          });
        }
      }
    }

    final imageProvider = _staticArtworkImage;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: size,
        height: size,
        child: imageProvider != null
            ? Image(image: imageProvider, fit: BoxFit.cover)
            : Container(
                color: theme.cardColor,
                child: Icon(
                  Broken.musicnote,
                  size: size * 0.29,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }

  Widget _buildTrackInfo(
    BuildContext context,
    PlayerController player,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          Text(
            player.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            player.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    PlayerController player,
    Color accent,
  ) {
    final position = player.position;
    final duration = player.duration;
    final maxMs = duration.inMilliseconds > 0
        ? duration.inMilliseconds.toDouble()
        : 1.0;
    final currentMs = position.inMilliseconds.toDouble().clamp(0.0, maxMs);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: accent,
              inactiveTrackColor: accent.withOpacityExt(0.2),
              thumbColor: accent,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              trackHeight: 3,
            ),
            child: Slider(
              value: currentMs,
              max: maxMs,
              onChanged: (value) {
                player.seek(Duration(milliseconds: value.toInt()));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  _formatDuration(duration),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    PlayerController player,
    Color accent,
  ) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _controlBtn(
            icon: Broken.shuffle,
            size: 24,
            color: player.shuffleMode ? accent : onVariant,
            onTap: player.toggleShuffleMode,
          ),
          const Spacer(),
          _controlBtn(
            icon: Broken.previous,
            size: 32,
            color: onSurface,
            onTap: player.skipPrevious,
          ),
          const Spacer(),
          _playBtn(player, accent),
          const Spacer(),
          _controlBtn(
            icon: Broken.next,
            size: 32,
            color: onSurface,
            onTap: player.skipNext,
          ),
          const Spacer(),
          _controlBtn(
            icon: _repeatIcon(player.repeatMode),
            size: 24,
            color: player.repeatMode != ArcRepeatMode.off ? accent : onVariant,
            onTap: player.toggleArcRepeatMode,
          ),
        ],
      ),
    );
  }

  Widget _controlBtn({
    required IconData icon,
    required double size,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: size, color: color),
    );
  }

  Widget _playBtn(PlayerController player, Color accent) {
    return GestureDetector(
      onTap: player.playPause,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: accent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: accent.withOpacityExt(0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          player.isPlaying ? Broken.pause : Broken.play,
          size: 32,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildExtraButtons(
    BuildContext context,
    PlayerController player,
    Color accent,
  ) {
    final onVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Broken.heart, size: 22),
            onPressed: () {},
            color: onVariant,
          ),
          IconButton(
            icon: Icon(
              Broken.document_code,
              size: 22,
              color: _showLyrics ? accent : onVariant,
            ),
            onPressed: () {
              setState(() {
                _showLyrics = !_showLyrics;
                _showQueue = false;
              });
            },
          ),
          IconButton(
            icon: Icon(
              Broken.play_circle,
              size: 22,
              color: _showQueue ? accent : onVariant,
            ),
            onPressed: () {
              setState(() {
                _showQueue = !_showQueue;
                _showLyrics = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQueueView(
    BuildContext context,
    ThemeData theme,
    PlayerController player,
    Color accent,
  ) {
    final queue = player.queue;
    if (queue.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Broken.play_circle,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'Cola vacía',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Text(
                'Queue',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${queue.length})',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Broken.trash,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () => player.clearQueue(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: queue.length,
            onReorderItem: (oldIndex, newIndex) {
              player.reorderQueue(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final track = queue[index];
              final isCurrent = index == player.queueIndex;

              return Dismissible(
                key: ValueKey('${track.filePath}_$index'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  color: Colors.red.withOpacityExt(0.8),
                  child: const Icon(
                    Broken.trash,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                onDismissed: (_) => player.removeFromQueue(index),
                child: ListTile(
                  leading: isCurrent
                      ? SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(Broken.play, color: accent),
                        )
                      : null,
                  title: Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrent ? accent : null,
                      fontWeight: isCurrent
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrent
                          ? accent.withOpacityExt(0.7)
                          : theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Broken.close_circle, size: 20),
                        onPressed: () => player.removeFromQueue(index),
                        color: theme.colorScheme.onSurfaceVariant
                            .withOpacityExt(0.5),
                      ),
                      Icon(
                        Broken.menu,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant
                            .withOpacityExt(0.3),
                      ),
                    ],
                  ),
                  onTap: () => player.playTrack(track, index: index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _repeatIcon(ArcRepeatMode mode) {
    switch (mode) {
      case ArcRepeatMode.off:
        return Broken.refresh;
      case ArcRepeatMode.all:
        return Broken.repeat;
      case ArcRepeatMode.one:
        return Broken.repeate_one;
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
