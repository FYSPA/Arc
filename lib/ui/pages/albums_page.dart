import 'package:flutter/material.dart';
import '../../services/media_store_service.dart';
import 'package:provider/provider.dart';

import '../../controller/indexer_controller.dart';
import '../../controller/player_controller.dart';
import '../../core/broken_icons.dart';
import '../../core/dimensions.dart';
import '../../core/extensions.dart';
import '../../data/models/album.dart';

import '../../services/artwork_service.dart';

class AlbumsPage extends StatelessWidget {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final indexer = context.watch<IndexerController>();
    final theme = Theme.of(context);

    if (indexer.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final albums = indexer.albumList;

    if (albums.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Broken.music_dashboard,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No albums found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(
        12,
      ).copyWith(bottom: kBottomPaddingMiniplayer),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        return _AlbumCard(album: albums[index]);
      },
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final ArcAlbum album;

  const _AlbumCard({required this.album});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showAlbumTracks(context, album),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: double.infinity,
                child: _AlbumArtwork(albumId: album.id),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            album.album,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            album.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

void _showAlbumTracks(BuildContext context, ArcAlbum album) {
  final indexer = context.read<IndexerController>();
  final tracks = indexer.getTracksByAlbum(album.album);

  if (tracks.isEmpty) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(60),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: _AlbumArtwork(albumId: album.id),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            album.album,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${album.artist} · ${tracks.length} songs',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Broken.play, color: theme.colorScheme.primary),
                      onPressed: () {
                        PlayerController.inst.playTrack(
                          tracks.first,
                          queue: tracks,
                          index: 0,
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return ListTile(
                      dense: true,
                      leading: Text(
                        '${index + 1}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      title: Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Text(
                        track.durationText,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onTap: () {
                        PlayerController.inst.playTrack(
                          track,
                          queue: tracks,
                          index: index,
                        );
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

class _AlbumArtwork extends StatefulWidget {
  final int albumId;

  const _AlbumArtwork({required this.albumId});

  @override
  State<_AlbumArtwork> createState() => _AlbumArtworkState();
}

class _AlbumArtworkState extends State<_AlbumArtwork> {
  late Future<dynamic> _artworkFuture;

  @override
  void initState() {
    super.initState();
    _artworkFuture = ArtworkService.inst.getArtwork(
      widget.albumId,
      MediaType.album,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<dynamic>(
      future: _artworkFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          );
        }

        return Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Broken.music_dashboard,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.5),
          ),
        );
      },
    );
  }
}
