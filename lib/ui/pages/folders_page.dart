import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controller/indexer_controller.dart';
import '../../controller/player_controller.dart';
import '../../core/broken_icons.dart';
import '../../core/dimensions.dart';
import '../../core/extensions.dart';
import '../../data/models/track.dart';
import '../../services/media_store_service.dart';

class FoldersPage extends StatefulWidget {
  const FoldersPage({super.key});

  @override
  State<FoldersPage> createState() => _FoldersPageState();
}

class _FoldersPageState extends State<FoldersPage> {
  List<Map<String, dynamic>> _folders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final folders = await MediaStoreService.inst.queryFolders();
    if (mounted) {
      setState(() {
        _folders = folders;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_folders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Broken.folder_open,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No music folders found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add folders to scan in Settings',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.4),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: kBottomPaddingMiniplayer),
      itemCount: _folders.length,
      itemBuilder: (context, index) {
        final folder = _folders[index];
        final path = folder['path'] as String;
        final name = folder['name'] as String;
        final songCount = folder['songCount'] as int;

        return _FolderTile(path: path, name: name, songCount: songCount);
      },
    );
  }
}

class _FolderTile extends StatelessWidget {
  final String path;
  final String name;
  final int songCount;

  const _FolderTile({
    required this.path,
    required this.name,
    required this.songCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Broken.folder, color: theme.colorScheme.primary),
      ),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '$songCount songs',
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Broken.arrow_right_3,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant.withOpacityExt(0.5),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _FolderDetailPage(path: path, name: name),
          ),
        );
      },
    );
  }
}

class _FolderDetailPage extends StatelessWidget {
  final String path;
  final String name;

  const _FolderDetailPage({required this.path, required this.name});

  @override
  Widget build(BuildContext context) {
    final indexer = context.read<IndexerController>();
    final tracks = indexer.getTracksByFolder(path);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          if (tracks.isNotEmpty)
            IconButton(
              icon: Icon(Broken.play, color: theme.colorScheme.primary),
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
      body: tracks.isEmpty
          ? Center(
              child: Text(
                'No tracks in this folder',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: kBottomPaddingMiniplayer),
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];
                return _FolderTrackTile(
                  track: track,
                  tracks: tracks,
                  index: index,
                );
              },
            ),
    );
  }
}

class _FolderTrackTile extends StatelessWidget {
  final ArcTrack track;
  final List<ArcTrack> tracks;
  final int index;

  const _FolderTrackTile({
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
