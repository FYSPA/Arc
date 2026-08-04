enum LibraryTab { home, songs, albums, artists, folders }

extension LibraryTabExtension on LibraryTab {
  String get label {
    switch (this) {
      case LibraryTab.home:
        return 'Home';
      case LibraryTab.songs:
        return 'Songs';
      case LibraryTab.albums:
        return 'Albums';
      case LibraryTab.artists:
        return 'Artists';
      case LibraryTab.folders:
        return 'Folders';
    }
  }
}
