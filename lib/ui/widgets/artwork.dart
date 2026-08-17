import 'dart:typed_data';

import 'package:flutter/material.dart';

ImageProvider resizeMemoryArtwork(Uint8List bytes, int pixelSize) =>
    ResizeImage(MemoryImage(bytes), width: pixelSize, height: pixelSize);

ImageProvider resizeNetworkArtwork(String url, int pixelSize) =>
    ResizeImage(NetworkImage(url), width: pixelSize, height: pixelSize);
