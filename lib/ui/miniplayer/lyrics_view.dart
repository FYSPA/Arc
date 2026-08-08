import 'package:arx_canvas/arx_canvas.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controller/current_color_controller.dart';
import '../../controller/player_controller.dart';
import '../../core/broken_icons.dart';
import '../../core/extensions.dart';

class LyricsView extends StatefulWidget {
  const LyricsView({super.key});

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  List<LyricLine>? _syncedLyrics;
  String? _plainLyrics;
  bool _isLoading = false;
  String? _error;
  int? _fetchedTrackId;

  final ScrollController _scrollController = ScrollController();
  int _activeIndex = -1;
  bool _userScrolling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchLyrics());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchLyrics() async {
    final player = context.read<PlayerController>();
    final track = player.currentTrack;
    if (track == null) return;

    final trackId = track.id;
    _fetchedTrackId = trackId;

    setState(() {
      _isLoading = true;
      _error = null;
      _syncedLyrics = null;
      _plainLyrics = null;
      _activeIndex = -1;
    });

    try {
      final lyricsService = LyricsService();
      final result = await lyricsService.getLyrics(
        trackName: player.title,
        artistName: player.artist,
        duration: track.duration != null
            ? Duration(milliseconds: track.duration!)
            : null,
        trackFilePath: track.filePath,
      );
      if (mounted && _fetchedTrackId == trackId) {
        setState(() {
          if (result.syncedLyrics != null && result.syncedLyrics!.isNotEmpty) {
            _syncedLyrics = result.syncedLyrics;
          } else {
            _plainLyrics = result.plainLyrics ?? result.fullText;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && _fetchedTrackId == trackId) {
        setState(() {
          _error = 'Error al obtener letras';
          _isLoading = false;
        });
      }
    }
  }

  int _findActiveLine(Duration position) {
    if (_syncedLyrics == null || _syncedLyrics!.isEmpty) return -1;
    final adjusted = position - const Duration(milliseconds: 300);
    int result = -1;
    for (int i = 0; i < _syncedLyrics!.length; i++) {
      final ts = _syncedLyrics![i].timestamp;
      if (ts != null && ts <= adjusted) {
        result = i;
      } else if (ts != null && ts > adjusted) {
        break;
      }
    }
    return result;
  }

  void _scrollToLine(int index) {
    if (!_scrollController.hasClients) return;
    if (index < 0 || index >= (_syncedLyrics?.length ?? 0)) return;

    final viewportHeight = _scrollController.position.viewportDimension;
    final targetOffset = (index * 56.0) - (viewportHeight / 2) + 28.0;
    final maxOffset = _scrollController.position.maxScrollExtent;
    final offset = targetOffset.clamp(0.0, maxOffset);

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final player = context.watch<PlayerController>();
    final accent = context.read<CurrentColorController>().accentColor;

    final currentId = player.currentTrack?.id;
    if (currentId != null && currentId != _fetchedTrackId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchLyrics());
    }

    if (_isLoading) {
      return _buildLoading(theme, accent);
    }

    if (_error != null) {
      return _buildError(theme, accent);
    }

    if (_syncedLyrics != null && _syncedLyrics!.isNotEmpty) {
      return _buildSyncedView(theme, player, accent);
    }

    if (_plainLyrics != null && _plainLyrics!.isNotEmpty) {
      return _buildPlainView(theme, accent);
    }

    return _buildEmpty(player, theme, accent);
  }

  Widget _buildLoading(ThemeData theme, Color accent) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: accent.withOpacityExt(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Buscando letras...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncedView(
    ThemeData theme,
    PlayerController player,
    Color accent,
  ) {
    final position = player.position;
    final newIndex = _findActiveLine(position);

    if (newIndex != _activeIndex) {
      _activeIndex = newIndex;
      if (!_userScrolling && _activeIndex >= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToLine(_activeIndex);
        });
      }
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is UserScrollNotification) {
          _userScrolling = true;
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) _userScrolling = false;
          });
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        itemCount: _syncedLyrics!.length,
        itemBuilder: (context, index) {
          final line = _syncedLyrics![index];
          final isActive = index == _activeIndex;

          return GestureDetector(
            onTap: () {
              if (line.timestamp != null) {
                player.seek(line.timestamp!);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              margin: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isActive
                    ? accent.withOpacityExt(0.12)
                    : Colors.transparent,
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isActive ? 22 : 15,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w400,
                  height: 1.5,
                  letterSpacing: isActive ? 0.3 : 0.0,
                  color: isActive
                      ? accent
                      : theme.colorScheme.onSurface.withOpacityExt(0.3),
                ),
                child: Text(line.text.isEmpty ? '♪' : line.text),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlainView(ThemeData theme, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
      child: SingleChildScrollView(
        child: Text(
          _plainLyrics!,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 2.0,
            fontSize: 16,
            color: theme.colorScheme.onSurface.withOpacityExt(0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme, Color accent) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacityExt(0.08),
            ),
            child: Icon(
              Broken.document_code,
              size: 28,
              color: accent.withOpacityExt(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.7),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _fetchLyrics,
            icon: Icon(Broken.refresh, size: 16, color: accent),
            label: Text('Reintentar', style: TextStyle(color: accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(PlayerController player, ThemeData theme, Color accent) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacityExt(0.08),
            ),
            child: Icon(
              Broken.document_code,
              size: 28,
              color: accent.withOpacityExt(0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Letra no disponible',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacityExt(0.45),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${player.title} - ${player.artist}',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacityExt(0.3),
            ),
          ),
        ],
      ),
    );
  }
}
