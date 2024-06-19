
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

class Stroke {
  final path = Path();
  final Color color;
  final double width;
  final bool erase;

  Stroke({
    this.color = Colors.black,
    this.width = 4,
    this.erase = false,
  });
}

class RedoUndoHistory {
  final VoidCallback undo;
  final VoidCallback redo;

  RedoUndoHistory({
    required this.undo,
    required this.redo,
  });
}
