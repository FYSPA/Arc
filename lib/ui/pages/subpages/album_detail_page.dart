import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controller/indexer_controller.dart';
import '../../../controller/player_controller.dart';
import '../../../controller/settings_controller.dart';
import '../../../core/broken_icons.dart';
import '../../../core/extensions.dart';
import '../../../data/models/album.dart';
import '../../../data/models/track.dart';
import '../../../services/artwork_service.dart';
import '../../../services/media_store_service.dart';
import '../../widgets/animated_artwork_widget.dart';
import '../../widgets/track_context_menu.dart';

class AlbumDetailPage extends StatelessWidget {
  final ArcAlbum album;

  const AlbumDetailPage({super.key, required this.album});

  static Widget _buildArtworkHeader(BuildContext context, ArcAlbum album) {
    final settings = context.watch<SettingsController>();
    const isPlaying = true;
    final pseudoTrack = ArcTrack(
      id: album.id,
      title: album.album,
      artist: album.artist,
      album: album.album,
      albumId: album.id,
    );

    if (settings.enableAnimatedArtwork) {
      return AnimatedArtworkWidget(
        key: ValueKey('album_artwork_${album.id}'),
        track: pseudoTrack,
        isPlaying: isPlaying,
        size: 280,
        borderRadius: 0,
      );
    }

    return _StaticAlbumHeader(album: album);
  }

  @override
  Widget build(BuildContext context) {
    final indexer = context.read<IndexerController>();
    final tracks = indexer.getTracksByAlbum(album.album);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildArtworkHeader(context, album),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          album.album,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${album.artist} · ${tracks.length} songs',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (tracks.isNotEmpty)
                IconButton(
                  icon: const Icon(Broken.play, color: Colors.white),
                  onPressed: () {
                    PlayerController.inst.playTrack(
                      tracks.first,
                      queue: tracks,
                      index: 0,
                    );
                  },
                  tooltip: 'Play all',
                ),
            ],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final track = tracks[index];
              return _AlbumTrackTile(
                track: track,
                tracks: tracks,
                index: index,
              );
            }, childCount: tracks.length),
          ),
        ],
      ),
    );
  }
}

class _AlbumTrackTile extends StatelessWidget {
  final ArcTrack track;
  final List<ArcTrack> tracks;
  final int index;

  const _AlbumTrackTile({
    required this.track,
    required this.tracks,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Text(
        '${index + 1}',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Text(
        track.durationText,
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.7),
        ),
      ),
      onTap: () {
        PlayerController.inst.playTrack(track, queue: tracks, index: index);
      },
      onLongPress: () => TrackContextMenu.show(
        context,
        track: track,
        queue: tracks,
        index: index,
      ),
    );
  }
}

class _StaticAlbumHeader extends StatefulWidget {
  final ArcAlbum album;

  const _StaticAlbumHeader({required this.album});

  @override
  State<_StaticAlbumHeader> createState() => _StaticAlbumHeaderState();
}

class _StaticAlbumHeaderState extends State<_StaticAlbumHeader> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final local = await ArtworkService.inst.getArtwork(
      widget.album.id,
      MediaType.album,
    );
    if (local != null && local.isNotEmpty) {
      if (mounted) setState(() => _bytes = local);
      return;
    }

    final pseudoTrack = ArcTrack(
      id: widget.album.id,
      title: widget.album.album,
      artist: widget.album.artist,
      album: widget.album.album,
      albumId: widget.album.id,
    );
    final online = await ArtworkService.inst.getTrackArtwork(pseudoTrack);
    if (mounted) setState(() => _bytes = online);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_bytes != null) {
      return Image.memory(_bytes!, fit: BoxFit.cover, gaplessPlayback: true);
    }
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Broken.music_dashboard,
        size: 64,
        color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.3),
      ),
    );
  }
}
