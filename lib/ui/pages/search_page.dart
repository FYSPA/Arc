import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/broken_icons.dart';
import '../../core/dimensions.dart';
import '../../core/extensions.dart';
import '../../controller/indexer_controller.dart';
import '../../controller/player_controller.dart';
import '../../data/models/album.dart';
import '../../data/models/artist.dart';
import '../../data/models/track.dart';
import '../../services/artwork_service.dart';
import '../../services/media_store_service.dart';
import '../../controller/settings_controller.dart';
import '../widgets/track_context_menu.dart';
import 'subpages/album_detail_page.dart';
import 'subpages/artist_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = q);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indexer = context.watch<IndexerController>();

    final normalized = _query.toLowerCase().trim();
    final hasQuery = normalized.isNotEmpty;

    final tracks = hasQuery
        ? indexer.trackList.where((t) {
            return t.title.toLowerCase().contains(normalized) ||
                t.artist.toLowerCase().contains(normalized) ||
                t.album.toLowerCase().contains(normalized);
          }).toList()
        : <ArcTrack>[];

    final albums = hasQuery
        ? indexer.albumList.where((a) {
            return a.album.toLowerCase().contains(normalized) ||
                a.artist.toLowerCase().contains(normalized);
          }).toList()
        : <ArcAlbum>[];

    final artists = hasQuery
        ? indexer.artistList.where((a) {
            return a.artist.toLowerCase().contains(normalized);
          }).toList()
        : <ArcArtist>[];

    final noResults =
        hasQuery && tracks.isEmpty && albums.isEmpty && artists.isEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onChanged,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search tracks, albums, artists...',
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.5),
            ),
            prefixIcon: Icon(
              Broken.search_normal,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Broken.close_circle, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _onChanged('');
                    },
                  )
                : null,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacityExt(
              0.5,
            ),
          ),
        ),
        titleSpacing: 0,
      ),
      body: !hasQuery
          ? _buildEmptyState(theme)
          : noResults
          ? _buildNoResults(theme)
          : _buildResults(
              theme: theme,
              indexer: indexer,
              tracks: tracks,
              albums: albums,
              artists: artists,
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Broken.search_normal,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Search tracks, albums, artists...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Broken.search_status,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No results for "$_query"',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults({
    required ThemeData theme,
    required IndexerController indexer,
    required List<ArcTrack> tracks,
    required List<ArcAlbum> albums,
    required List<ArcArtist> artists,
  }) {
    return ListView(
      padding: const EdgeInsets.only(bottom: kBottomPaddingMiniplayer),
      children: [
        if (tracks.isNotEmpty)
          _Section(
            icon: Broken.musicnote,
            title: 'Tracks',
            count: tracks.length,
            child: Column(
              children: tracks.take(5).map((track) {
                final idx = indexer.trackList.indexOf(track);
                return _SearchTrackTile(
                  track: track,
                  queue: tracks,
                  index: idx >= 0 ? idx : 0,
                );
              }).toList(),
            ),
          ),
        if (albums.isNotEmpty)
          _Section(
            icon: Broken.music_dashboard,
            title: 'Albums',
            count: albums.length,
            child: Column(
              children: albums.take(5).map((album) {
                return _SearchAlbumTile(album: album);
              }).toList(),
            ),
          ),
        if (artists.isNotEmpty)
          _Section(
            icon: Broken.user,
            title: 'Artists',
            count: artists.length,
            child: Column(
              children: artists.take(5).map((artist) {
                return _SearchArtistTile(artist: artist);
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final Widget child;

  const _Section({
    required this.icon,
    required this.title,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(icon, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '$title ($count)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _SearchTrackTile extends StatelessWidget {
  final ArcTrack track;
  final List<ArcTrack> queue;
  final int index;

  const _SearchTrackTile({
    required this.track,
    required this.queue,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 44,
          height: 44,
          child: _SearchArtwork(
            id: track.albumId,
            type: MediaType.album,
            track: track,
          ),
        ),
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${track.artist} · ${track.album}',
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
        PlayerController.inst.playTrack(track, queue: queue, index: index);
      },
      onLongPress: () => TrackContextMenu.show(
        context,
        track: track,
        queue: queue,
        index: index,
      ),
    );
  }
}

class _SearchAlbumTile extends StatelessWidget {
  final ArcAlbum album;

  const _SearchAlbumTile({required this.album});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: _SearchArtwork(
            id: album.id,
            type: MediaType.album,
            albumName: album.album,
            artistName: album.artist,
          ),
        ),
      ),
      title: Text(
        album.album,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${album.artist} · ${album.numOfSongs ?? 0} songs',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: 'album'),
            builder: (_) => AlbumDetailPage(album: album),
          ),
        );
      },
    );
  }
}

class _SearchArtistTile extends StatelessWidget {
  final ArcArtist artist;

  const _SearchArtistTile({required this.artist});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: ClipOval(
        child: SizedBox(
          width: 48,
          height: 48,
          child: _SearchArtwork(
            id: artist.id,
            type: MediaType.artist,
            artistName: artist.artist,
          ),
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: 'artist'),
            builder: (_) => ArtistDetailPage(artist: artist),
          ),
        );
      },
    );
  }
}

class _SearchArtwork extends StatefulWidget {
  final int? id;
  final MediaType type;
  final ArcTrack? track;
  final String? albumName;
  final String? artistName;

  const _SearchArtwork({
    required this.id,
    required this.type,
    this.track,
    this.albumName,
    this.artistName,
  });

  @override
  State<_SearchArtwork> createState() => _SearchArtworkState();
}

class _SearchArtworkState extends State<_SearchArtwork> {
  late Future<ImageProvider?> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadArtwork();
  }

  Future<ImageProvider?> _loadArtwork() async {
    final size = SettingsController.inst.artworkQuality.listDecodeSize;
    final id = widget.id;
    if (id != null) {
      final cached = ArtworkService.inst.getCachedImageProvider(
        id,
        namespace: 'search',
      );
      if (cached != null) return cached;
    }

    Uint8List? bytes;
    if (widget.track != null) {
      bytes = await ArtworkService.inst.getHighResArtwork(widget.track!);
    } else if (widget.type == MediaType.artist && widget.artistName != null) {
      bytes = await ArtworkService.inst.getHighResArtistArt(
        widget.artistName!,
        id: widget.id,
      );
    } else if (widget.type == MediaType.album &&
        widget.albumName != null &&
        widget.artistName != null) {
      bytes = await ArtworkService.inst.getHighResAlbumArt(
        widget.albumName!,
        widget.artistName!,
        id: widget.id,
      );
    } else if (widget.id != null) {
      bytes = await ArtworkService.inst.getArtwork(widget.id!, widget.type);
    }

    if (bytes == null || bytes.isEmpty) return null;
    final provider = ResizeImage(MemoryImage(bytes), width: size, height: size);
    if (id != null) {
      ArtworkService.inst.cacheImageProvider(id, provider, namespace: 'search');
    }
    return provider;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<ImageProvider?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Image(
            image: snapshot.data!,
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
