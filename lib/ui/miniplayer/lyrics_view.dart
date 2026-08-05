import 'package:arx_canvas/arx_canvas.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controller/player_controller.dart';
import '../../core/broken_icons.dart';
import '../../core/extensions.dart';

class LyricsView extends StatefulWidget {
  const LyricsView({super.key});

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  String? _plainLyrics;
  bool _isLoading = false;
  String? _error;
  int? _fetchedTrackId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchLyrics());
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
      _plainLyrics = null;
    });

    try {
      final lyricsService = LyricsService();
      final result = await lyricsService.getLyrics(
        trackName: player.title,
        artistName: player.artist,
        duration: track.duration != null
            ? Duration(milliseconds: track.duration!)
            : null,
      );
      if (mounted && _fetchedTrackId == trackId) {
        setState(() {
          _plainLyrics = result.fullText;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final player = context.watch<PlayerController>();

    final currentId = player.currentTrack?.id;
    if (currentId != null && currentId != _fetchedTrackId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchLyrics());
    }

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Broken.document_code,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _fetchLyrics,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_plainLyrics == null || _plainLyrics!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Broken.document_code,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'Letra no disponible',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${player.title} - ${player.artist}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.4),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: SingleChildScrollView(
        child: Text(
          _plainLyrics!,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.8,
            color: theme.colorScheme.onSurface.withOpacityExt(0.8),
          ),
        ),
      ),
    );
  }
}
