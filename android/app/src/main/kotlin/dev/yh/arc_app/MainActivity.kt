package dev.yh.arc_app

import android.Manifest
import android.content.ContentUris
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val PERMISSION_CHANNEL = "arc_app/permissions"
    private val MEDIA_CHANNEL = "arc_app/media"
    private val REQUEST_CODE = 1001
    private var permissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission" -> requestAudioPermission(result)
                    "checkPermission" -> result.success(hasAudioPermission())
                    "openSettings" -> {
                        val intent = Intent(
                            android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.fromParts("package", packageName, null)
                        )
                        startActivity(intent)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "querySongs" -> result.success(querySongs())
                    "queryAlbums" -> result.success(queryAlbums())
                    "queryArtists" -> result.success(queryArtists())
                    "queryFolders" -> result.success(queryFolders())
                    "queryArtwork" -> {
                        val id = call.argument<Int>("id")!!
                        val type = call.argument<Int>("type")!!
                        result.success(queryArtwork(id, type))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasAudioPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                this, Manifest.permission.READ_MEDIA_AUDIO
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(
                this, Manifest.permission.READ_EXTERNAL_STORAGE
            ) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestAudioPermission(result: MethodChannel.Result) {
        if (hasAudioPermission()) {
            result.success(true)
            return
        }
        permissionResult = result
        val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Manifest.permission.READ_MEDIA_AUDIO
        } else {
            Manifest.permission.READ_EXTERNAL_STORAGE
        }
        ActivityCompat.requestPermissions(this, arrayOf(permission), REQUEST_CODE)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            permissionResult?.success(granted)
            permissionResult = null
        }
    }

    private fun querySongs(): List<Map<String, Any?>> {
        val songs = mutableListOf<Map<String, Any?>>()
        val uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATE_ADDED,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.TRACK
        )
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"
        val sortOrder = "${MediaStore.Audio.Media.DATE_ADDED} DESC"

        contentResolver.query(uri, projection, selection, null, sortOrder)?.use { cursor ->
            val idCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val albumIdCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)
            val durationCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val dateAddedCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)
            val dataCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            val sizeCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)
            val trackCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TRACK)

            while (cursor.moveToNext()) {
                val id = cursor.getLong(idCol)
                songs.add(mapOf(
                    "id" to id,
                    "title" to cursor.getString(titleCol),
                    "artist" to cursor.getString(artistCol),
                    "album" to cursor.getString(albumCol),
                    "albumId" to cursor.getLong(albumIdCol),
                    "duration" to cursor.getLong(durationCol),
                    "dateAdded" to cursor.getLong(dateAddedCol),
                    "filePath" to cursor.getString(dataCol),
                    "fileSize" to cursor.getLong(sizeCol),
                    "track" to cursor.getInt(trackCol),
                ))
            }
        }
        return songs
    }

    private fun queryAlbums(): List<Map<String, Any?>> {
        val albums = mutableListOf<Map<String, Any?>>()
        val uri = MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Audio.Albums._ID,
            MediaStore.Audio.Albums.ALBUM,
            MediaStore.Audio.Albums.ARTIST,
            MediaStore.Audio.Albums.NUMBER_OF_SONGS
        )
        val sortOrder = "${MediaStore.Audio.Albums.ALBUM} ASC"

        contentResolver.query(uri, projection, null, null, sortOrder)?.use { cursor ->
            val idCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Albums._ID)
            val albumCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Albums.ALBUM)
            val artistCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Albums.ARTIST)
            val numSongsCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Albums.NUMBER_OF_SONGS)

            while (cursor.moveToNext()) {
                albums.add(mapOf(
                    "id" to cursor.getLong(idCol),
                    "album" to cursor.getString(albumCol),
                    "artist" to cursor.getString(artistCol),
                    "numOfSongs" to cursor.getInt(numSongsCol),
                ))
            }
        }
        return albums
    }

    private fun queryArtists(): List<Map<String, Any?>> {
        val artists = mutableListOf<Map<String, Any?>>()
        val uri = MediaStore.Audio.Artists.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Audio.Artists._ID,
            MediaStore.Audio.Artists.ARTIST,
            MediaStore.Audio.Artists.NUMBER_OF_ALBUMS,
            MediaStore.Audio.Artists.NUMBER_OF_TRACKS
        )
        val sortOrder = "${MediaStore.Audio.Artists.ARTIST} ASC"

        contentResolver.query(uri, projection, null, null, sortOrder)?.use { cursor ->
            val idCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Artists._ID)
            val artistCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Artists.ARTIST)
            val numAlbumsCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Artists.NUMBER_OF_ALBUMS)
            val numTracksCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Artists.NUMBER_OF_TRACKS)

            while (cursor.moveToNext()) {
                artists.add(mapOf(
                    "id" to cursor.getLong(idCol),
                    "artist" to cursor.getString(artistCol),
                    "numOfAlbums" to cursor.getInt(numAlbumsCol),
                    "numOfSongs" to cursor.getInt(numTracksCol),
                ))
            }
        }
        return artists
    }

    private fun queryFolders(): List<Map<String, Any?>> {
        val folderMap = mutableMapOf<String, Int>()
        val uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(MediaStore.Audio.Media.DATA)
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"

        contentResolver.query(uri, projection, selection, null, null)?.use { cursor ->
            val dataCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            while (cursor.moveToNext()) {
                val path = cursor.getString(dataCol) ?: continue
                val dir = path.substringBeforeLast("/")
                folderMap[dir] = (folderMap[dir] ?: 0) + 1
            }
        }

        return folderMap.map { (path, count) ->
            mapOf(
                "path" to path,
                "name" to path.substringAfterLast("/"),
                "songCount" to count,
            )
        }.sortedBy { it["name"] as String }
    }

    private fun queryArtwork(id: Int, type: Int): ByteArray? {
        val contentUri = when (type) {
            0 -> MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
            1 -> MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI
            2 -> MediaStore.Audio.Artists.EXTERNAL_CONTENT_URI
            else -> return null
        }
        val uri = ContentUris.withAppendedId(contentUri, id.toLong())
        return try {
            val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() } ?: return null
            val options = BitmapFactory.Options().apply {
                inJustDecodeBounds = true
            }
            BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options)

            options.inSampleSize = calculateInSampleSize(options, 300, 300)
            options.inJustDecodeBounds = false

            val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options) ?: return null
            val output = ByteArrayOutputStream()
            bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG, 85, output)
            bitmap.recycle()
            output.toByteArray()
        } catch (_: Exception) {
            null
        }
    }

    private fun calculateInSampleSize(options: BitmapFactory.Options, reqWidth: Int, reqHeight: Int): Int {
        val height = options.outHeight
        val width = options.outWidth
        var inSampleSize = 1
        if (height > reqHeight || width > reqWidth) {
            val halfHeight = height / 2
            val halfWidth = width / 2
            while (halfHeight / inSampleSize >= reqHeight && halfWidth / inSampleSize >= reqWidth) {
                inSampleSize *= 2
            }
        }
        return inSampleSize
    }
}
