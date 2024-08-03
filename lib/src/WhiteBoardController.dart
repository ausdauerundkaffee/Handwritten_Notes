import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'FreehandPainter.dart';
import 'whiteboard.dart';
import 'Model.dart';
/// Whiteboard controller for Undo, Redo, clear and saveAsImage
class WhiteBoardController {
  late WhiteBoardControllerDelegate delegate;

  /// Convert [Whiteboard] into image data with given format.
  /// You can obtain converted image data via [onConvert] property of [Crop].
  void convertToImage({ImageByteFormat format = ImageByteFormat.png , String fileName = "hg"}) =>
      delegate.saveAsImage(format,fileName);

  /// Undo last stroke
  /// Return [false] if there is no stroke to undo, otherwise return [true].
  bool undo() => delegate.onUndo();

  /// Redo last undo stroke
  /// Return [false] if there is no stroke to redo, otherwise return [true].
  bool redo() => delegate.onRedo();

  /// Clear all the strokes
  void clear() => delegate.onClear();
}

class WhiteBoardControllerDelegate {
  late Future<void> Function(ImageByteFormat format, String fileName) saveAsImage;

  late bool Function() onUndo;

  late bool Function() onRedo;

  late VoidCallback onClear;
}
