import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controller/indexer_controller.dart';
import '../../core/broken_icons.dart';
import '../../core/dimensions.dart';
import '../../core/extensions.dart';
import '../../data/models/artist.dart';
import '../../services/artwork_service.dart';
import '../../services/media_store_service.dart';
import 'subpages/artist_detail_page.dart';

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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ArtistDetailPage(artist: artist)),
        );
      },
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
