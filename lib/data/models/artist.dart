class ArcArtist {
  final int id;
  final String artist;
  final int? numOfAlbums;
  final int? numOfSongs;

  const ArcArtist({
    required this.id,
    required this.artist,
    this.numOfAlbums,
    this.numOfSongs,
  });

  factory ArcArtist.fromMap(Map<String, dynamic> m) {
    return ArcArtist(
      id: m['id'] as int,
      artist: m['artist'] as String? ?? 'Unknown Artist',
      numOfAlbums: m['numOfAlbums'] as int?,
      numOfSongs: m['numOfSongs'] as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArcArtist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
