class ArcAlbum {
  final int id;
  final String album;
  final String artist;
  final int? artistId;
  final int? numOfSongs;
  final int? year;

  const ArcAlbum({
    required this.id,
    required this.album,
    required this.artist,
    this.artistId,
    this.numOfSongs,
    this.year,
  });

  factory ArcAlbum.fromMap(Map<String, dynamic> m) {
    return ArcAlbum(
      id: m['id'] as int,
      album: m['album'] as String? ?? 'Unknown Album',
      artist: m['artist'] as String? ?? 'Unknown Artist',
      numOfSongs: m['numOfSongs'] as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArcAlbum && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
