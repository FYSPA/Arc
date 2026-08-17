import 'package:flutter/material.dart';

import '../../core/broken_icons.dart';
import '../../core/extensions.dart';
import '../../controller/player_controller.dart';
import '../../data/models/track.dart';
import '../../services/artwork_service.dart';
import '../../controller/settings_controller.dart';
import 'artwork.dart';

class TrackContextMenu {
  TrackContextMenu._();

  static void show(
    BuildContext context, {
    required ArcTrack track,
    List<ArcTrack>? queue,
    int? index,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _TrackContextMenuSheet(track: track, queue: queue, index: index),
    );
  }
}

class _TrackContextMenuSheet extends StatelessWidget {
  final ArcTrack track;
  final List<ArcTrack>? queue;
  final int? index;

  const _TrackContextMenuSheet({required this.track, this.queue, this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final player = PlayerController.inst;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(theme),
          const Divider(height: 1),
          _MenuItem(
            icon: Broken.play,
            title: 'Play next',
            onTap: () {
              Navigator.pop(context);
              player.playNext(track);
              _showSnackBar(context, 'Playing next');
            },
          ),
          _MenuItem(
            icon: Broken.play_add,
            title: 'Add to queue',
            onTap: () {
              Navigator.pop(context);
              player.addToQueue(track);
              _showSnackBar(context, 'Added to queue');
            },
          ),
          _MenuItem(
            icon: Broken.information,
            title: 'Track info',
            onTap: () {
              Navigator.pop(context);
              _showTrackInfo(context, theme);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: _ContextMenuArtwork(track: track),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${track.artist} · ${track.album}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showTrackInfo(BuildContext context, ThemeData theme) {
    final sizeText = track.fileSize != null
        ? _formatFileSize(track.fileSize!)
        : 'Unknown';
    final dateText = track.dateAdded != null
        ? DateTime.fromMillisecondsSinceEpoch(
            track.dateAdded! * 1000,
          ).toString().substring(0, 16)
        : 'Unknown';
    final format = track.filePath != null
        ? track.filePath!.split('.').last.toUpperCase()
        : 'Unknown';
    final player = PlayerController.inst;
    final meta = player.currentTrack?.id == track.id ? player.metadata : null;
    final bitrateText = meta != null && meta.bitrate > 0
        ? '${meta.bitrate} kbps'
        : null;
    final sampleRateText = meta != null && meta.sampleRate > 0
        ? '${meta.sampleRate} Hz'
        : null;
    final bitDepthText = meta != null && meta.bitDepth > 0
        ? '${meta.bitDepth} bit'
        : null;
    final channelsText = meta != null && meta.channels > 0
        ? '${meta.channels} ${meta.channels == 1 ? 'ch' : 'chs'}'
        : null;
    final isrcText = meta != null && meta.isrc.isNotEmpty ? meta.isrc : null;
    final yearText = meta != null && meta.year != null && meta.year! > 0
        ? '${meta.year}'
        : null;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          'Track Info',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1.0,
          ),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
        contentPadding: const EdgeInsets.all(20.0),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _InfoRow(label: 'Title', value: track.title),
              _InfoRow(label: 'Artist', value: track.artist),
              _InfoRow(label: 'Album', value: track.album),
              _InfoRow(label: 'Format', value: format),
              if (track.genre != null)
                _InfoRow(label: 'Genre', value: track.genre!),
              _InfoRow(label: 'Duration', value: track.durationText),
              _InfoRow(label: 'Size', value: sizeText),
              if (bitrateText != null)
                _InfoRow(label: 'Bitrate', value: bitrateText),
              if (sampleRateText != null)
                _InfoRow(label: 'Sample Rate', value: sampleRateText),
              if (bitDepthText != null)
                _InfoRow(label: 'Bit Depth', value: bitDepthText),
              if (channelsText != null)
                _InfoRow(label: 'Channels', value: channelsText),
              if (yearText != null) _InfoRow(label: 'Year', value: yearText),
              if (track.track != null)
                _InfoRow(label: 'Track #', value: '${track.track}'),
              if (isrcText != null) _InfoRow(label: 'ISRC', value: isrcText),
              _InfoRow(label: 'Added', value: dateText),
              if (track.filePath != null)
                _InfoRow(label: 'Path', value: track.filePath!, maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, size: 22, color: theme.colorScheme.onSurface),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      minLeadingWidth: 0,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final int maxLines;

  const _InfoRow({required this.label, required this.value, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextMenuArtwork extends StatefulWidget {
  final ArcTrack track;

  const _ContextMenuArtwork({required this.track});

  @override
  State<_ContextMenuArtwork> createState() => _ContextMenuArtworkState();
}

class _ContextMenuArtworkState extends State<_ContextMenuArtwork> {
  late Future<dynamic> _future;

  @override
  void initState() {
    super.initState();
    final track = widget.track;
    _future = ArtworkService.inst.getHighResAlbumArt(
      track.album,
      track.artist,
      id: track.albumId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<dynamic>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Image(
            image: resizeMemoryArtwork(
              snapshot.data!,
              SettingsController.inst.artworkQuality.listDecodeSize,
            ),
            fit: BoxFit.cover,
            gaplessPlayback: true,
          );
        }
        return Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Broken.musicnote,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.5),
          ),
        );
      },
    );
  }
}
