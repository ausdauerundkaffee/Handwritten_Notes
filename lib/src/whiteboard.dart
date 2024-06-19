import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'FreehandPainter.dart';
import 'WhiteBoardController.dart';
import 'package:flutter_handwritten_notes/src/Model.dart';
import 'dart:developer';
import 'package:flutter/foundation.dart';

typedef OnRedoUndo = void Function(bool isUndoAvailable, bool isRedoAvailable);

/// Whiteboard widget for canvas
class WhiteBoard extends StatefulWidget {
  /// WhiteBoardController for actions.
  final WhiteBoardController? controller;

  /// [Color] for background of whiteboard.
  final Color backgroundColor;

  /// [Color] of strokes.
  final Color strokeColor;

  /// Width of strokes
  final double strokeWidth;

  /// Flag for erase mode
  final bool isErasing;

  /// Callback for [Canvas] when it converted to image data.
  /// Use [WhiteBoardController] to convert.
  final ValueChanged<Uint8List>? onConvertImage;

  /// This callback exposes if undo / redo is available and called successfully.
  final OnRedoUndo? onRedoUndo;

  const WhiteBoard({
    Key? key,
    this.controller,
    this.backgroundColor = Colors.white,
    this.strokeColor = Colors.blue,
    this.strokeWidth = 4,
    this.isErasing = false,
    this.onConvertImage,
    this.onRedoUndo,
  }) : super(key: key);

  @override
  _WhiteBoardState createState() => _WhiteBoardState();
}

class _WhiteBoardState extends State<WhiteBoard> {
  final _undoHistory = <RedoUndoHistory>[];
  final _redoStack = <RedoUndoHistory>[];
  final _strokes = <Stroke>[];
  // cached current canvas size
  late Size _canvasSize;

  // convert current canvas to image data.
  Future<void> _convertToImage(ImageByteFormat format) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    // Emulate painting using _FreehandPainter
    // recorder will record this painting
    FreehandPainter(
      _strokes,
      widget.backgroundColor,
    ).paint(canvas, _canvasSize);

    // Stop emulating and convert to Image
    final result = await recorder
        .endRecording()
        .toImage(_canvasSize.width.floor(), _canvasSize.height.floor());

    // Cast image data to byte array with converting to given format
    final converted =
        (await result.toByteData(format: format))!.buffer.asUint8List();

    widget.onConvertImage?.call(converted);
  }

  @override
  void initState() {
    widget.controller?.delegate = WhiteBoardControllerDelegate()
      ..saveAsImage = _convertToImage
      ..onUndo = () {
        if (_undoHistory.isEmpty) return false;

        _redoStack.add(_undoHistory.removeLast()..undo());
        widget.onRedoUndo?.call(_undoHistory.isNotEmpty, _redoStack.isNotEmpty);
        return true;
      }
      ..onRedo = () {
        if (_redoStack.isEmpty) return false;

        _undoHistory.add(_redoStack.removeLast()..redo());
        widget.onRedoUndo?.call(_undoHistory.isNotEmpty, _redoStack.isNotEmpty);
        return true;
      }
      ..onClear = () {
        if (_strokes.isEmpty) return;
        setState(() {
          final _removedStrokes = <Stroke>[]..addAll(_strokes);
          _undoHistory.add(
            RedoUndoHistory(
              undo: () {
                setState(() => _strokes.addAll(_removedStrokes));
              },
              redo: () {
                setState(() => _strokes.clear());
              },
            ),
          );
          setState(() {
            _strokes.clear();
            _redoStack.clear();
          });
        });
        widget.onRedoUndo?.call(_undoHistory.isNotEmpty, _redoStack.isNotEmpty);
      };
    super.initState();
  }
  void _start(double startX, double startY) {
    
    final newStroke = Stroke(
      color: widget.strokeColor,
      width: widget.strokeWidth,
      erase: widget.isErasing,
    );
    newStroke.path.moveTo(startX, startY);

    _strokes.add(newStroke);
    _undoHistory.add(
      RedoUndoHistory(
        undo: () {
          setState(() => _strokes.remove(newStroke));
        },
        redo: () {
          setState(() => _strokes.add(newStroke));
        },
      ),
    );
    _redoStack.clear();
    widget.onRedoUndo?.call(_undoHistory.isNotEmpty, _redoStack.isNotEmpty);  
  }

  void _add(double x, double y) {
      setState(() {
          _strokes.last.path.lineTo(x, y);
          
        });
     
    
  }
 bool _isStylusEvent(PointerEvent event) {
    return event.kind == PointerDeviceKind.stylus ||
           event.kind == PointerDeviceKind.mouse ||
           (event.radiusMajor < 27.0 &&
            event.tilt < (pi / 2) &&
            event.size <= 0.1 );
  }
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return
     Column(
      children: [
      Expanded(
      child:  Container(
      height: size.height,
      width: size.width,
      child: Listener(
        onPointerDown: (event) {        
          if(_isStylusEvent(event)){
            double radiusMajor = event.radiusMajor;
            debugPrint(radiusMajor.toString());
              _start(
                event.localPosition.dx,
                event.localPosition.dy,
              );
          }
        },   
        onPointerUp: (event) {
          
        },
        onPointerMove: (event){
         if(_isStylusEvent(event)){
            double radiusMajor = event.radiusMajor;
            debugPrint(radiusMajor.toString());
            _add(
              event.localPosition.dx,
              event.localPosition.dy,
            );
          }
        },     
        child: LayoutBuilder(
          builder: (context, constraints) {
            _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
            return CustomPaint(
              painter: FreehandPainter(_strokes, widget.backgroundColor),
             );
            },
          ),
        ),
      ),
    ),
    ],
    );
  }

}