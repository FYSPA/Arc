import 'package:flutter/material.dart';
import '../../services/media_store_service.dart';
import 'package:provider/provider.dart';

import '../../controller/indexer_controller.dart';
import '../../controller/player_controller.dart';
import '../../core/broken_icons.dart';
import '../../core/dimensions.dart';
import '../../core/extensions.dart';
import '../../data/models/artist.dart';

import '../../services/artwork_service.dart';

class ArtistsPage extends StatelessWidget {
  const ArtistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final indexer = context.watch<IndexerController>();
    final theme = Theme.of(context);

    if (indexer.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final artists = indexer.artistList;

    if (artists.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Broken.user,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No artists found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: kBottomPaddingMiniplayer),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        return _ArtistTile(artist: artists[index]);
      },
    );
  }
}

class _ArtistTile extends StatelessWidget {
  final ArcArtist artist;

  const _ArtistTile({required this.artist});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: () => _showArtistTracks(context, artist),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipOval(
        child: SizedBox(
          width: 48,
          height: 48,
          child: _ArtistArtwork(artistId: artist.id),
        ),
      ),
      title: Text(
        artist.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${artist.numOfAlbums ?? 0} albums · ${artist.numOfSongs ?? 0} songs',
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

void _showArtistTracks(BuildContext context, ArcArtist artist) {
  final indexer = context.read<IndexerController>();
  final tracks = indexer.getTracksByArtist(artist.artist);

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
                    ClipOval(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: _ArtistArtwork(artistId: artist.id),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            artist.artist,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${tracks.length} songs',
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
                        track.album,
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

class _ArtistArtwork extends StatefulWidget {
  final int artistId;

  const _ArtistArtwork({required this.artistId});

  @override
  State<_ArtistArtwork> createState() => _ArtistArtworkState();
}

class _ArtistArtworkState extends State<_ArtistArtwork> {
  late Future<dynamic> _artworkFuture;

  @override
  void initState() {
    super.initState();
    _artworkFuture = ArtworkService.inst.getArtwork(
      widget.artistId,
      MediaType.artist,
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
            Broken.user,
            size: 24,
            color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.5),
          ),
        );
      },
    );
  }
}
