import 'package:flutter/material.dart';

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

enum GlowPosition { topLeft, topRight, bottomLeft, bottomRight }

extension GlowPositionExtension on GlowPosition {
  String get label {
    switch (this) {
      case GlowPosition.topLeft:
        return 'Top Left';
      case GlowPosition.topRight:
        return 'Top Right';
      case GlowPosition.bottomLeft:
        return 'Bottom Left';
      case GlowPosition.bottomRight:
        return 'Bottom Right';
    }
  }

  Alignment get alignment {
    switch (this) {
      case GlowPosition.topLeft:
        return Alignment.topLeft;
      case GlowPosition.topRight:
        return Alignment.topRight;
      case GlowPosition.bottomLeft:
        return Alignment.bottomLeft;
      case GlowPosition.bottomRight:
        return Alignment.bottomRight;
    }
  }
}
