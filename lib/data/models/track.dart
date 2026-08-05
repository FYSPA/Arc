class ArcTrack {
  final int id;
  final String title;
  final String artist;
  final String album;
  final int? albumId;
  final int? artistId;
  final int? duration;
  final String? filePath;
  final int? fileSize;
  final int? dateAdded;
  final int? track;
  final int? genreId;
  final String? genre;

  const ArcTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.albumId,
    this.artistId,
    this.duration,
    this.filePath,
    this.fileSize,
    this.dateAdded,
    this.track,
    this.genreId,
    this.genre,
  });

  factory ArcTrack.fromMap(Map<String, dynamic> m) {
    return ArcTrack(
      id: m['id'] as int,
      title: m['title'] as String? ?? 'Unknown',
      artist: m['artist'] as String? ?? 'Unknown Artist',
      album: m['album'] as String? ?? 'Unknown Album',
      albumId: m['albumId'] as int?,
      duration: m['duration'] as int?,
      filePath: m['filePath'] as String?,
      fileSize: m['fileSize'] as int?,
      dateAdded: m['dateAdded'] as int?,
      track: m['track'] as int?,
    );
  }

  String get durationText {
    if (duration == null) return '0:00';
    final d = Duration(milliseconds: duration!);
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArcTrack && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
