// Face utilities for camera and image processing
// Copied from double auth project

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

class FaceUtils {
  FaceUtils._();

  static Future<CameraDescription> getCamera(CameraLensDirection direction) async {
    try {
      final cameras = await availableCameras();
      // Try to find the requested camera direction
      try {
        return cameras.firstWhere(
          (camera) => camera.lensDirection == direction,
        );
      } catch (e) {
        // If requested direction not found, return any available camera
        if (cameras.isNotEmpty) {
          return cameras.first;
        } else {
          throw Exception('No cameras available on this device');
        }
      }
    } catch (e) {
      throw Exception('Failed to access cameras: $e');
    }
  }

  static InputImage buildInputImage(CameraImage image, InputImageRotation rotation) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) {
      throw Exception('Unsupported image format: ${image.format.raw}');
    }
    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );
    Uint8List bytes;
    if (image.format.group == ImageFormatGroup.yuv420) {
      bytes = _concatenatePlanes(image.planes);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      bytes = image.planes.first.bytes;
    } else {
      bytes = _concatenatePlanes(image.planes);
    }
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: metadata,
    );
  }

  static Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  static InputImageRotation getImageRotation(CameraLensDirection direction) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return InputImageRotation.rotation90deg;
    }
    switch (direction) {
      case CameraLensDirection.front:
        return InputImageRotation.rotation270deg;
      case CameraLensDirection.back:
      case CameraLensDirection.external:
        return InputImageRotation.rotation90deg;
    }
  }
}
