import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controller/indexer_controller.dart';
import '../../controller/player_controller.dart';
import '../../core/broken_icons.dart';
import '../../core/dimensions.dart';
import '../../core/extensions.dart';
import '../../data/models/track.dart';
import '../../services/artwork_service.dart';
import '../widgets/track_context_menu.dart';

class TracksPage extends StatefulWidget {
  const TracksPage({super.key});

  @override
  State<TracksPage> createState() => _TracksPageState();
}

class _TracksPageState extends State<TracksPage> {
  String _searchQuery = '';
  bool _showSearch = false;
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<ArcTrack>? _cachedFilteredTracks;
  String _lastFilterQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = q;
        _cachedFilteredTracks = null;
      });
    });
  }

  List<ArcTrack> _filteredTracks(IndexerController indexer) {
    if (_searchQuery == _lastFilterQuery && _cachedFilteredTracks != null) {
      return _cachedFilteredTracks!;
    }
    final sw = Stopwatch()..start();
    _lastFilterQuery = _searchQuery;
    _cachedFilteredTracks = indexer.trackList.where((t) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return t.title.toLowerCase().contains(q) ||
          t.artist.toLowerCase().contains(q) ||
          t.album.toLowerCase().contains(q);
    }).toList();
    sw.stop();
    if (sw.elapsedMilliseconds > 5) {
      debugPrint(
        '[ARC] _filteredTracks: ${sw.elapsedMilliseconds}ms '
        '(${_cachedFilteredTracks!.length} results)',
      );
    }
    return _cachedFilteredTracks!;
  }

  @override
  Widget build(BuildContext context) {
    final sw = Stopwatch()..start();
    final indexer = context.watch<IndexerController>();
    final theme = Theme.of(context);

    if (!indexer.hasPermission) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Broken.warning_2,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.3),
            ),
            const SizedBox(height: 16),
            Text('Permission required', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Storage access is needed to scan music',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                final granted = await indexer.requestPermission();
                if (granted) {
                  indexer.scanDevice();
                }
              },
              icon: const Icon(Broken.refresh, size: 18),
              label: const Text('Grant Permission'),
            ),
          ],
        ),
      );
    }

    if (indexer.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Scanning device...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (indexer.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Broken.warning_2, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Error loading tracks', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              indexer.errorMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => indexer.scanDevice(),
              icon: const Icon(Broken.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final tracks = _filteredTracks(indexer);
    sw.stop();
    if (sw.elapsedMilliseconds > 16) {
      debugPrint(
        '[ARC] TracksPage build: ${sw.elapsedMilliseconds}ms '
        '(tracks=${tracks.length}, query="$_searchQuery")',
      );
    }

    return Column(
      children: [
        _Header(
          indexer: indexer,
          trackCount: tracks.length,
          tracks: tracks,
          showSearch: _showSearch,
          searchController: _searchController,
          onSearchChanged: _onSearchChanged,
          onToggleSearch: () {
            setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchQuery = '';
                _cachedFilteredTracks = null;
                _searchController.clear();
              }
            });
          },
        ),
        Expanded(
          child: tracks.isEmpty && !indexer.isLoadingMore
              ? _EmptyState(hasSearch: _searchQuery.isNotEmpty)
              : ListView.builder(
                  padding: const EdgeInsets.only(
                    bottom: kBottomPaddingMiniplayer,
                  ),
                  itemCount: tracks.length + (indexer.hasMoreTracks ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == tracks.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    return _TrackTile(
                      track: tracks[index],
                      allTracks: tracks,
                      index: index,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final IndexerController indexer;
  final int trackCount;
  final List<ArcTrack> tracks;
  final bool showSearch;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleSearch;

  const _Header({
    required this.indexer,
    required this.trackCount,
    required this.tracks,
    required this.showSearch,
    required this.searchController,
    required this.onSearchChanged,
    required this.onToggleSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              _SortButton(indexer: indexer),
              const SizedBox(width: 8),
              _PlayButton(trackCount: trackCount, tracks: tracks),
              const Spacer(),
              Text(
                '$trackCount tracks',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: indexer.scanDevice,
                icon: const Icon(Broken.refresh, size: 20),
                tooltip: 'Refresh',
              ),
              IconButton(
                onPressed: onToggleSearch,
                icon: Icon(
                  showSearch ? Broken.search_normal_1 : Broken.search_normal,
                  size: 20,
                ),
                tooltip: 'Search',
              ),
            ],
          ),
          if (showSearch) ...[
            const SizedBox(height: 8),
            TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search tracks...',
                prefixIcon: const Icon(Broken.search_normal, size: 18),
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
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withOpacityExt(0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final IndexerController indexer;

  const _SortButton({required this.indexer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<SortType>(
      onSelected: (type) => indexer.setSortType(type),
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Broken.sort, size: 18),
          const SizedBox(width: 4),
          Text(
            _sortLabel(indexer.currentSort),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          Icon(
            indexer.sortReverse ? Broken.arrow_up : Broken.arrow_up,
            size: 14,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
      itemBuilder: (context) => [
        _sortItem(SortType.name, 'Name'),
        _sortItem(SortType.date, 'Date Added'),
        _sortItem(SortType.duration, 'Duration'),
        _sortItem(SortType.artist, 'Artist'),
        _sortItem(SortType.album, 'Album'),
      ],
    );
  }

  PopupMenuItem<SortType> _sortItem(SortType type, String label) {
    return PopupMenuItem(
      value: type,
      child: Row(
        children: [
          if (type == indexer.currentSort)
            const Icon(Icons.check, size: 18)
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  String _sortLabel(SortType type) {
    switch (type) {
      case SortType.name:
        return 'Name';
      case SortType.date:
        return 'Date';
      case SortType.duration:
        return 'Duration';
      case SortType.artist:
        return 'Artist';
      case SortType.album:
        return 'Album';
    }
  }
}

class _PlayButton extends StatelessWidget {
  final int trackCount;
  final List<ArcTrack> tracks;

  const _PlayButton({required this.trackCount, required this.tracks});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      onPressed: trackCount > 0
          ? () {
              PlayerController.inst.playTrack(
                tracks.first,
                queue: tracks,
                index: 0,
              );
            }
          : null,
      icon: Icon(
        Broken.play,
        size: 24,
        color: trackCount > 0
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant.withOpacityExt(0.3),
      ),
      tooltip: 'Play all',
    );
  }
}

class _TrackTile extends StatelessWidget {
  final ArcTrack track;
  final List<ArcTrack> allTracks;
  final int index;

  const _TrackTile({
    required this.track,
    required this.allTracks,
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
          width: 48,
          height: 48,
          child: _ArtworkWidget(track: track),
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
        PlayerController.inst.playTrack(track, queue: allTracks, index: index);
      },
      onLongPress: () => TrackContextMenu.show(
        context,
        track: track,
        queue: allTracks,
        index: index,
      ),
    );
  }
}

class _ArtworkWidget extends StatefulWidget {
  final ArcTrack track;

  const _ArtworkWidget({required this.track});

  @override
  State<_ArtworkWidget> createState() => _ArtworkWidgetState();
}

class _ArtworkWidgetState extends State<_ArtworkWidget> {
  Uint8List? _cachedBytes;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  @override
  void didUpdateWidget(covariant _ArtworkWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track.id != widget.track.id) {
      _cachedBytes = null;
      _loadArtwork();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _loadArtwork() async {
    final sw = Stopwatch()..start();
    final bytes = await ArtworkService.inst.getTrackArtwork(widget.track);
    sw.stop();
    if (sw.elapsedMilliseconds > 50) {
      debugPrint(
        '[ARC] artwork slow load: ${sw.elapsedMilliseconds}ms for id=${widget.track.id}',
      );
    }
    if (!_disposed && mounted) {
      setState(() {
        _cachedBytes = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_cachedBytes != null) {
      return Image.memory(
        _cachedBytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }

    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Broken.musicnote,
        size: 22,
        color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.5),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;

  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasSearch ? Broken.search_normal : Broken.musicnote,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch ? 'No results found' : 'No tracks found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.5),
            ),
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 8),
            Text(
              'Add folders to scan in Settings',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
