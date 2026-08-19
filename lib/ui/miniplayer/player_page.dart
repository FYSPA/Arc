import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';

import '../../controller/current_color_controller.dart';
import '../../controller/player_controller.dart';
import '../../controller/settings_controller.dart';
import '../../core/broken_icons.dart';
import '../../core/extensions.dart';
import '../../data/models/track.dart';
import '../../services/artwork_service.dart';
import '../../services/canvas_service.dart';
import '../widgets/animated_artwork_widget.dart';
import '../widgets/canvas_background.dart';
import 'lyrics_view.dart';

import '../../core/utils.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  bool _showLyrics = false;
  bool _showQueue = false;
  int? _lastTrackId;

  @override
  void initState() {
    super.initState();
    PlayerController.inst.setFullPlayerOpen(true);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _extractColor();
      });
    });
  }

  @override
  void dispose() {
    PlayerController.inst.setFullPlayerOpen(false);
    super.dispose();
  }

  Future<void> _extractColor() async {
    if (!mounted) return;
    final sw = Stopwatch()..start();
    final player = context.read<PlayerController>();
    final colorCtrl = context.read<CurrentColorController>();
    if (player.currentTrack != null) {
      final bytesSw = Stopwatch()..start();
      // Use the cached local artwork for the palette; only fall back to an
      // online fetch when the local art is genuinely missing (no baja→alta).
      var bytes = await ArtworkService.inst.getLocalArtwork(
        player.currentTrack!,
      );
      if (bytes == null || bytes.isEmpty) {
        bytes = await ArtworkService.inst.getTrackArtwork(player.currentTrack!);
      }
      bytesSw.stop();
      logD(
        '[PERF] _extractColor artwork: ${bytesSw.elapsedMilliseconds}ms (null=${bytes == null})',
      );
      if (mounted) {
        final image = (bytes != null && bytes.isNotEmpty)
            ? MemoryImage(bytes)
            : null;
        final paletteSw = Stopwatch()..start();
        await colorCtrl.extractFromImage(image);
        paletteSw.stop();
        logD(
          '[PERF] _extractColor palette: ${paletteSw.elapsedMilliseconds}ms',
        );
      }
    }
    sw.stop();
    logD('[PERF] _extractColor TOTAL: ${sw.elapsedMilliseconds}ms');
  }

  int _buildCount = 0;
  final _buildSw = Stopwatch();

  @override
  Widget build(BuildContext context) {
    _buildSw
      ..reset()
      ..start();
    final buildNum = _buildCount++;
    final theme = Theme.of(context);
    final data = context
        .select<
          PlayerController,
          ({
            int? currentTrackId,
            ArcTrack? currentTrack,
            String title,
            String artist,
            String album,
            bool isPlaying,
            ArcRepeatMode repeatMode,
            bool shuffleMode,
          })
        >(
          (p) => (
            currentTrackId: p.currentTrack?.id,
            currentTrack: p.currentTrack,
            title: p.title,
            artist: p.artist,
            album: p.album,
            isPlaying: p.isPlaying,
            repeatMode: p.repeatMode,
            shuffleMode: p.shuffleMode,
          ),
        );
    final colorCtrl = context.watch<CurrentColorController>();
    final accent = colorCtrl.accentColor;
    final settings = context.watch<SettingsController>();
    final showCanvas =
        settings.enableSpotifyCanvas && settings.hasSpotifyCanvasCredentials;

    if (data.currentTrackId != _lastTrackId) {
      _lastTrackId = data.currentTrackId;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _extractColor();
      });
    }

    final player = context.read<PlayerController>();

    final result = AnnotatedRegion<SystemUiOverlayStyle>(
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
        body: Stack(
          fit: StackFit.expand,
          children: [
            // L1: Spotify Canvas background (full-screen, looping, muted).
            if (showCanvas)
              Positioned.fill(
                child: CanvasBackground(track: data.currentTrack),
              ),
            // Fallback gradient. When the canvas is shown this becomes a
            // translucent scrim so the video remains visible beneath the glass;
            // otherwise it is the opaque background (pre-canvas behavior).
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accent.withOpacityExt(showCanvas ? 0.05 : 0.15),
                    theme.scaffoldBackgroundColor.withValues(
                      alpha: showCanvas ? 0.55 : 1.0,
                    ),
                  ],
                ),
              ),
            ),
            // L2: glassmorphism over the canvas.
            if (showCanvas)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    color: settings.canvasGlassTint == CanvasGlassTint.neutral
                        ? Colors.black.withValues(alpha: 0.35)
                        : accent.withValues(alpha: 0.25),
                  ),
                ),
              ),
            // L3: existing content (app bar, artwork, controls).
            SafeArea(
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
          ],
        ),
      ),
    );

    _buildSw.stop();
    final ms = _buildSw.elapsedMilliseconds;
    if (ms > 16 || buildNum % 60 == 0) {
      logD('[PERF] PlayerPage.build #$buildNum — ${ms}ms');
    }
    return result;
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
        if (SettingsController.inst.enableSpotifyCanvas &&
            SettingsController.inst.hasSpotifyCanvasCredentials &&
            CanvasService.inst.hasNoCanvas(player.currentTrack?.id))
          _buildNoCanvasMark(theme),
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
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacityExt(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
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
            : track != null
            ? StaticArtworkWidget(
                key: ValueKey('static_artwork_${track.id}'),
                track: track,
                size: size,
              )
            : SizedBox(width: size, height: size),
      ),
    );
  }

  Widget _buildNoCanvasMark(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Broken.video_slash,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            'Sin Canvas',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
    return _ProgressBar(accent: accent);
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
}

class _ProgressBar extends StatefulWidget {
  final Color accent;
  const _ProgressBar({required this.accent});

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  double? _dragValue;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final player = context
        .select<PlayerController, ({Duration pos, Duration dur})>(
          (p) => (pos: p.position, dur: p.duration),
        );
    final position = player.pos;
    final duration = player.dur;
    final maxMs = duration.inMilliseconds > 0
        ? duration.inMilliseconds.toDouble()
        : 1.0;
    final currentMs = _isDragging && _dragValue != null
        ? _dragValue!
        : position.inMilliseconds.toDouble().clamp(0.0, maxMs);

    final displayPosition = _isDragging && _dragValue != null
        ? Duration(milliseconds: _dragValue!.toInt())
        : position;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: widget.accent,
              inactiveTrackColor: widget.accent.withOpacityExt(0.2),
              thumbColor: widget.accent,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              trackHeight: 3,
            ),
            child: Slider(
              value: currentMs.clamp(0.0, maxMs),
              max: maxMs,
              onChangeStart: (value) {
                _isDragging = true;
                _dragValue = value;
                setState(() {});
              },
              onChanged: (value) {
                _dragValue = value;
                setState(() {});
              },
              onChangeEnd: (value) {
                _isDragging = false;
                _dragValue = null;
                context.read<PlayerController>().seek(
                  Duration(milliseconds: value.toInt()),
                );
                setState(() {});
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(displayPosition),
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

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class StaticArtworkWidget extends StatefulWidget {
  final ArcTrack track;
  final double size;

  const StaticArtworkWidget({
    super.key,
    required this.track,
    required this.size,
  });

  @override
  State<StaticArtworkWidget> createState() => _StaticArtworkWidgetState();
}

class _StaticArtworkWidgetState extends State<StaticArtworkWidget> {
  ImageProvider? _image;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  @override
  void didUpdateWidget(covariant StaticArtworkWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track.id != widget.track.id) {
      _loadArtwork();
    }
  }

  void _loadArtwork() {
    final sw = Stopwatch()..start();
    logD('[PERF] StaticArtwork #${widget.track.id} — loading local/cached...');
    ArtworkService.inst.getLocalArtwork(widget.track).then((bytes) {
      if (!mounted) return;
      if (bytes != null && bytes.isNotEmpty) {
        final image = ResizeImage(
          MemoryImage(bytes),
          width: 1080,
          height: 1080,
        );
        ArtworkService.inst.cacheImageProvider(
          widget.track.id,
          image,
          namespace: 'player',
        );
        setState(() => _image = image);
        logD(
          '[PERF] StaticArtwork #${widget.track.id} — local loaded in ${sw.elapsedMilliseconds}ms',
        );
        return;
      }
      // Local art missing: fill from online (no flash — nothing shown yet).
      ArtworkService.inst.getTrackArtwork(widget.track).then((online) {
        if (!mounted) return;
        if (online != null && online.isNotEmpty) {
          final image = ResizeImage(
            MemoryImage(online),
            width: 1080,
            height: 1080,
          );
          ArtworkService.inst.cacheImageProvider(
            widget.track.id,
            image,
            namespace: 'player',
          );
          setState(() => _image = image);
        } else {
          setState(() => _image = null);
        }
        logD(
          '[PERF] StaticArtwork #${widget.track.id} — online fill in ${sw.elapsedMilliseconds}ms (null=${online == null})',
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _image;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: imageProvider != null
            ? Image(
                image: imageProvider,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              )
            : Container(
                color: Theme.of(context).cardColor,
                child: Icon(
                  Broken.musicnote,
                  size: widget.size * 0.29,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}
