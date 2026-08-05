import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controller/indexer_controller.dart';
import '../../../controller/settings_controller.dart';
import '../../../core/broken_icons.dart';
import '../../../core/extensions.dart';
import '../../../services/media_store_service.dart';
import '../../widgets/animated_check_mark.dart';
import '../../widgets/onboarding_page_header.dart';

class OnboardingPermissionsPage extends StatefulWidget {
  const OnboardingPermissionsPage({super.key});

  @override
  State<OnboardingPermissionsPage> createState() =>
      _OnboardingPermissionsPageState();
}

class _OnboardingPermissionsPageState extends State<OnboardingPermissionsPage> {
  List<Map<String, dynamic>> _folders = [];
  Set<String> _selectedPaths = {};
  bool _isLoadingFolders = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final hasPermission = context.read<IndexerController>().hasPermission;
    if (hasPermission && _folders.isEmpty && !_isLoadingFolders) {
      _loadFolders();
    }
  }

  Future<void> _loadFolders() async {
    setState(() => _isLoadingFolders = true);
    final folders = await MediaStoreService.inst.queryFolders();
    if (!mounted) return;
    final savedFolders = context.read<SettingsController>().foldersToScan;
    setState(() {
      _folders = folders;
      _selectedPaths = savedFolders.isEmpty
          ? folders.map((f) => f['path'] as String).toSet()
          : savedFolders.toSet();
      _isLoadingFolders = false;
    });
  }

  void _toggleFolder(String path) {
    setState(() {
      if (_selectedPaths.contains(path)) {
        _selectedPaths.remove(path);
      } else {
        _selectedPaths.add(path);
      }
      context.read<SettingsController>().setFoldersToScan(
        _selectedPaths.toList(),
      );
    });
  }

  void _selectAll() {
    setState(() {
      _selectedPaths = _folders.map((f) => f['path'] as String).toSet();
      context.read<SettingsController>().setFoldersToScan(
        _selectedPaths.toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final indexer = context.watch<IndexerController>();
    final hasPermission = indexer.hasPermission;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      children: [
        const OnboardingPageHeader(
          icon: Broken.shield_cross,
          title: 'Permissions',
          subtitle: 'Grant access to your music',
        ),
        const SizedBox(height: 16.0),
        ListTile(
          onTap: hasPermission ? null : () => indexer.requestPermission(),
          leading: Icon(
            hasPermission ? Broken.tick_circle : Broken.folder_open,
            size: 18.0,
          ),
          title: Text(
            hasPermission ? 'Storage Granted' : 'Grant Storage Access',
            style: theme.textTheme.bodyMedium,
          ),
          subtitle: Text(
            hasPermission
                ? 'Arc can access your music files'
                : 'Required to scan and play music',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: AnimatedCheckMark(size: 20.0, active: hasPermission),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4.0,
            vertical: 2.0,
          ),
          visualDensity: const VisualDensity(vertical: -4),
        ),
        const SizedBox(height: 12.0),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacityExt(0.5),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Row(
            children: [
              Icon(Broken.info_circle, size: 20.0, color: colorScheme.primary),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why do we need this?',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Arc needs storage access to scan your device for FLAC, WAV, and MP3 files, read metadata, and display album artwork.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (hasPermission) ...[
          const SizedBox(height: 24.0),
          Row(
            children: [
              Icon(Broken.folder, size: 18.0, color: colorScheme.primary),
              const SizedBox(width: 8.0),
              Text(
                'Folders to Scan',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _selectAll,
                child: const Text('Select All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          if (_isLoadingFolders)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_folders.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No music folders found',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ..._folders.map((folder) {
              final path = folder['path'] as String;
              final name = folder['name'] as String;
              final songCount = folder['songCount'] as int;
              final isSelected = _selectedPaths.contains(path);

              return Container(
                margin: const EdgeInsets.only(bottom: 4.0),
                child: ListTile(
                  onTap: () => _toggleFolder(path),
                  leading: Icon(
                    isSelected ? Broken.tick_circle : Broken.folder,
                    size: 18.0,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    '$songCount songs',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: AnimatedCheckMark(size: 16.0, active: isSelected),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  visualDensity: const VisualDensity(vertical: -2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              );
            }),
        ],
      ],
    );
  }
}
