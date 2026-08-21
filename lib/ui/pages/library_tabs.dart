import 'package:flutter/material.dart';

import '../../core/broken_icons.dart';
import 'albums_page.dart';
import 'artists_page.dart';
import 'folders_page.dart';
import 'home_page.dart';
import 'tracks_page.dart';

/// Canonical library tabs with their icon and destination page. Both the main
/// page's tab body and the persistent navigation bar are built from this single
/// source so their order, icons and labels can never diverge.
const Map<String, ({IconData icon, Widget page})> kLibraryTabs = {
  'Home': (icon: Broken.home_2, page: HomePage()),
  'Songs': (icon: Broken.musicnote, page: TracksPage()),
  'Albums': (icon: Broken.music_dashboard, page: AlbumsPage()),
  'Artists': (icon: Broken.user, page: ArtistsPage()),
  'Folders': (icon: Broken.folder_open, page: FoldersPage()),
};

/// Returns the tabs in the order dictated by [desired], dropping any name that
/// has no known destination. Falls back to all known tabs when [desired] yields
/// nothing (e.g. empty or all-filtered settings).
List<({String name, IconData icon, Widget page})> orderedLibraryTabs(
  List<String> desired,
) {
  final result = <({String name, IconData icon, Widget page})>[];
  for (final name in desired) {
    final t = kLibraryTabs[name];
    if (t != null) result.add((name: name, icon: t.icon, page: t.page));
  }
  if (result.isEmpty) {
    for (final e in kLibraryTabs.entries) {
      result.add((name: e.key, icon: e.value.icon, page: e.value.page));
    }
  }
  return result;
}
