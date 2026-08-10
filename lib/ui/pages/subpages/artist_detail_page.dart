import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controller/indexer_controller.dart';
import '../../../controller/player_controller.dart';
import '../../../core/broken_icons.dart';
import '../../../core/extensions.dart';
import '../../../data/models/artist.dart';
import '../../../data/models/track.dart';
import '../../../services/artwork_service.dart';
import '../../../services/artist_photo_service.dart';
import '../../../services/media_store_service.dart';
import '../../widgets/track_context_menu.dart';

class ArtistDetailPage extends StatelessWidget {
  final ArcArtist artist;

  const ArtistDetailPage({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    final indexer = context.read<IndexerController>();
    final tracks = indexer.getTracksByArtist(artist.artist);
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
                  _ArtistArtworkHeader(
                    artistId: artist.id,
                    artistName: artist.artist,
                  ),
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
                          artist.artist,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${artist.numOfAlbums ?? 0} albums · ${tracks.length} songs',
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
              return _ArtistTrackTile(
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

class _ArtistTrackTile extends StatelessWidget {
  final ArcTrack track;
  final List<ArcTrack> tracks;
  final int index;

  const _ArtistTrackTile({
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
        track.album,
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

class _ArtistArtworkHeader extends StatefulWidget {
  final int artistId;
  final String artistName;

  const _ArtistArtworkHeader({
    required this.artistId,
    required this.artistName,
  });

  @override
  State<_ArtistArtworkHeader> createState() => _ArtistArtworkHeaderState();
}

class _ArtistArtworkHeaderState extends State<_ArtistArtworkHeader> {
  Uint8List? _bytes;
  String? _networkUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ArtworkService.inst.getArtwork(
      widget.artistId,
      MediaType.artist,
    );
    if (data != null && data.isNotEmpty) {
      if (mounted) setState(() => _bytes = data);
      return;
    }

    final url = await ArtistPhotoServiceWrapper.inst.getArtistPhotoUrl(
      widget.artistName,
    );
    if (mounted && url != null) setState(() => _networkUrl = url);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_bytes != null) {
      return Image.memory(_bytes!, fit: BoxFit.cover, gaplessPlayback: true);
    }
    if (_networkUrl != null) {
      return Image.network(
        _networkUrl!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _buildPlaceholder(theme),
      );
    }
    return _buildPlaceholder(theme);
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Broken.user,
        size: 64,
        color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.3),
      ),
    );
  }
}
