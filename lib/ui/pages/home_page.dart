import 'package:flutter/material.dart';
import '../../services/media_store_service.dart';
import 'package:provider/provider.dart';

import '../../controller/indexer_controller.dart';
import '../../controller/player_controller.dart';
import '../../core/broken_icons.dart';
import '../../core/extensions.dart';
import '../../data/models/track.dart';
import '../../services/artwork_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final indexer = context.watch<IndexerController>();
    final theme = Theme.of(context);

    if (indexer.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final recentTracks = indexer.recentlyAdded(limit: 5);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      children: [
        _SectionTitle(title: 'Recently Added', theme: theme),
        const SizedBox(height: 8.0),
        if (recentTracks.isEmpty)
          _EmptyState(
            icon: Broken.musicnote,
            message: 'No tracks yet',
            theme: theme,
          )
        else
          ...recentTracks.map(
            (track) =>
                _HomeTrackTile(track: track, allTracks: indexer.trackList),
          ),
        const SizedBox(height: 24.0),
        _SectionTitle(title: 'Recently Played', theme: theme),
        const SizedBox(height: 8.0),
        _EmptyState(
          icon: Broken.play_circle,
          message: 'Nothing played yet',
          theme: theme,
        ),
        const SizedBox(height: 24.0),
        _SectionTitle(title: 'Top Artists', theme: theme),
        const SizedBox(height: 8.0),
        if (indexer.artistList.isEmpty)
          _EmptyState(
            icon: Broken.user,
            message: 'No artists found',
            theme: theme,
          )
        else
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: indexer.artistList.length.clamp(0, 10),
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final artist = indexer.artistList[index];
                return _HomeArtistChip(artist: artist);
              },
            ),
          ),
        const SizedBox(height: 24.0),
        _SectionTitle(title: 'Top Albums', theme: theme),
        const SizedBox(height: 8.0),
        if (indexer.albumList.isEmpty)
          _EmptyState(
            icon: Broken.music_dashboard,
            message: 'No albums found',
            theme: theme,
          )
        else
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: indexer.albumList.length.clamp(0, 10),
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final album = indexer.albumList[index];
                return _HomeAlbumCard(album: album);
              },
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const _SectionTitle({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final ThemeData theme;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100.0,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14.0),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28.0,
              color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.4),
            ),
            const SizedBox(height: 8.0),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTrackTile extends StatelessWidget {
  final ArcTrack track;
  final List<ArcTrack> allTracks;

  const _HomeTrackTile({required this.track, required this.allTracks});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final index = allTracks.indexOf(track);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: () {
          PlayerController.inst.playTrack(
            track,
            queue: allTracks,
            index: index >= 0 ? index : 0,
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 44,
            height: 44,
            child: _ArtworkWidget(id: track.id, type: MediaType.audio),
          ),
        ),
        title: Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
            color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.7),
          ),
        ),
      ),
    );
  }
}

class _HomeArtistChip extends StatelessWidget {
  final dynamic artist;

  const _HomeArtistChip({required this.artist});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 80,
      child: Column(
        children: [
          ClipOval(
            child: SizedBox(
              width: 64,
              height: 64,
              child: _ArtworkWidget(id: artist.id, type: MediaType.artist),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            artist.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HomeAlbumCard extends StatelessWidget {
  final dynamic album;

  const _HomeAlbumCard({required this.album});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 110,
              height: 110,
              child: _ArtworkWidget(id: album.id, type: MediaType.album),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            album.album,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
          Text(
            album.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtworkWidget extends StatefulWidget {
  final int id;
  final MediaType type;

  const _ArtworkWidget({required this.id, required this.type});

  @override
  State<_ArtworkWidget> createState() => _ArtworkWidgetState();
}

class _ArtworkWidgetState extends State<_ArtworkWidget> {
  late Future<dynamic> _artworkFuture;

  @override
  void initState() {
    super.initState();
    _artworkFuture = ArtworkService.inst.getArtwork(widget.id, widget.type);
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
            widget.type == MediaType.artist ? Broken.user : Broken.musicnote,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.5),
          ),
        );
      },
    );
  }
}
