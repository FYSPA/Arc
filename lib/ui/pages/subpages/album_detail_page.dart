import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controller/indexer_controller.dart';
import '../../../controller/player_controller.dart';
import '../../../core/broken_icons.dart';
import '../../../core/extensions.dart';
import '../../../data/models/album.dart';
import '../../../data/models/track.dart';
import '../../../services/artwork_service.dart';
import '../../../services/media_store_service.dart';

class AlbumDetailPage extends StatelessWidget {
  final ArcAlbum album;

  const AlbumDetailPage({super.key, required this.album});

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
                  _AlbumArtworkHeader(albumId: album.id),
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
    );
  }
}

class _AlbumArtworkHeader extends StatefulWidget {
  final int albumId;

  const _AlbumArtworkHeader({required this.albumId});

  @override
  State<_AlbumArtworkHeader> createState() => _AlbumArtworkHeaderState();
}

class _AlbumArtworkHeaderState extends State<_AlbumArtworkHeader> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ArtworkService.inst.getArtwork(
      widget.albumId,
      MediaType.album,
    );
    if (mounted) setState(() => _bytes = data);
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
