import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_handwritten_notes/src/Home.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'FreehandPainter.dart';
import 'WhiteBoardController.dart';
import 'package:flutter_handwritten_notes/src/Model.dart';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter_handwritten_notes/src/NavBar.dart';
import 'package:flutter_handwritten_notes/src/GoogleDrive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as path;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:open_filex/open_filex.dart' as off;
import 'dart:async' as ass;

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
  final _authClient;
  final _googleDrive;

  var currentfile = null;
  WhiteBoard(
    this._authClient,
    this._googleDrive, {
    Key? key,
    this.controller,
    this.backgroundColor = Colors.white,
    this.strokeColor = Colors.blue,
    this.strokeWidth = 4,
    this.isErasing = false,
    this.onConvertImage,
    this.onRedoUndo,
    this.currentfile,
  }) : super(key: key);

  @override
  _WhiteBoardState createState() => _WhiteBoardState();
}

class _WhiteBoardState extends State<WhiteBoard> {
  final _undoHistory = <RedoUndoHistory>[];
  final _redoStack = <RedoUndoHistory>[];
  final _strokes = <Stroke>[];
  String fileName = '';
  // cached current canvas size
  late Size _canvasSize;
  final _key = GlobalKey();
  late Widget _newWidget;
  File? newFile = null;
  // convert current canvas to image data.
  Future<ui.Image> _loadImageFromProvider(ImageProvider provider) async {
    final completer = Completer<ui.Image>();
    final imageStream = provider.resolve(ImageConfiguration());
    final listener = ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info.image);
    });
    imageStream.addListener(listener);
    return completer.future;
  }

  Future<File> _convertToImage(
      ui.ImageByteFormat format, String fileName) async {
    debugPrint(fileName);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final image = await decodeImageFromList(await newFile!.readAsBytes());
    canvas.drawImage(image, Offset(0, 0), Paint());
    // Emulate painting using _FreehandPainter
    // recorder will record this painting
    FreehandPainter(_strokes, widget.backgroundColor, widget.currentfile)
        .paint(canvas, _canvasSize);

    // Stop emulating and convert to Image
    final result = await recorder
        .endRecording()
        .toImage(_canvasSize.width.floor(), _canvasSize.height.floor());

    // Cast image data to byte array with converting to given format
    final converted =
        (await result.toByteData(format: format))!.buffer.asUint8List();
    final pdf = pw.Document();
    final imageProvider = pw.MemoryImage(converted);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Image(imageProvider),
        ),
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final filePath = path.join(output.path, "$fileName.pdf");
    final file = File(filePath);
    //final file = File("freehandpainter/drawing.pdf");
    await file.writeAsBytes(await pdf.save());

    widget.onConvertImage?.call(converted);
    //debugPrint("${output.path}/drawing.pdf");
    return file;
  }

  @override
  void initState() {
    FreehandPainter freehandPainter =
        FreehandPainter(_strokes, widget.backgroundColor, widget.currentfile);
    Widget newWidget = CustomPaint(
      painter: freehandPainter,
    );
    setState(() {
      _newWidget = newWidget;
    });
    mainFUn(freehandPainter);
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

  double _calculateDistance(Offset p1, Offset p2) {
    return sqrt(pow(p2.dx - p1.dx, 2) + pow(p2.dy - p1.dy, 2));
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

  /*Future<ui.Image> OpenDownloadedFile(FreehandPainter freehandPainter) async {
    String imagePath = await freehandPainter.loadPdf();
    final data = await File(imagePath).readAsBytes();
    final image = await decodeImageFromList(data);
    return image;
  }*/

  bool _isStylusEvent(PointerEvent event) {
    return event.kind == ui.PointerDeviceKind.stylus ||
        event.kind == ui.PointerDeviceKind.mouse ||
        (event.radiusMajor < 27.0 &&
            event.tilt < (pi / 2) &&
            event.size <= 0.1);
  }

  Widget buildWidget(FreehandPainter freehandPainter) {
    debugPrint("buildWidget");
    if (newFile != null) {
      debugPrint("buildWidget file is not null");
      Widget newWidget = Stack(
        children: [
          // Display the image from the file
          Image.file(
            newFile!,
          ),
          // Overlay custom drawings using CustomPaint
          CustomPaint(
            painter: freehandPainter,
          ),
        ],
      );
      debugPrint("finished assigning new widget");
      return newWidget;
    } else {
      debugPrint("buildWidget file is null");
      FreehandPainter freehandPainter =
          FreehandPainter(_strokes, widget.backgroundColor, widget.currentfile);
      return CustomPaint(
        painter: freehandPainter,
      );
    }
  }

  Future<void> mainFUn(FreehandPainter freehandPainter) async {
    if (widget.currentfile != null) {
      newFile = await freehandPainter.loadPdf(widget.currentfile);
      debugPrint("will assign new widget");
      setState(() {
        _newWidget = Stack(
          children: [
            // Display the image from the file
            Image.file(
              newFile!,
            ),
            // Overlay custom drawings using CustomPaint
            CustomPaint(
              painter: freehandPainter,
            ),
          ],
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: IconTheme.of(context).size ?? 24,
          leading: Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                padding: EdgeInsets.zero,
              );
            },
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                height: size.height,
                width: size.width,
                child: Listener(
                  onPointerDown: (event) {
                    if (_isStylusEvent(event)) {
                      double radiusMajor = event.radiusMajor;
                      debugPrint(radiusMajor.toString());
                      _start(
                        event.localPosition.dx,
                        event.localPosition.dy,
                      );
                    }
                  },
                  onPointerUp: (event) {},
                  onPointerMove: (event) {
                    if (_isStylusEvent(event)) {
                      double radiusMajor = event.radiusMajor;
                      debugPrint(radiusMajor.toString());
                      _add(
                        event.localPosition.dx,
                        event.localPosition.dy,
                      );
                    }
                  },
                  child: LayoutBuilder(builder: (context, constraints) {
                    _canvasSize =
                        Size(constraints.maxWidth, constraints.maxHeight);

                    /* debugPrint("goto custom paint");
                   Widget newWidget = CustomPaint(
                        painter: freehandPainter,
                      );
                    if (widget.currentfile != null) {
                     
                      ()async{newWidget = await mainFUn(freehandPainter);
                        debugPrint("got newWidget");
                       return newWidget;
                       }();
                     
                    } 
                    else{
                      return newWidget;
                    }*/
                    /* Future.delayed(Duration(seconds:30));
                    debugPrint("goto return");
                    return newWidget;*/
                    //FreehandPainter freehandPainter = FreehandPainter(
                     //   _strokes, widget.backgroundColor, widget.currentfile);
                    //buildWidget(freehandPainter);
                    debugPrint("will return newWidget");
                    return _newWidget;
                  }),
                ),
              ),
            ),
          ],
        ),
        drawer: Drawer(
          // Add a ListView to the drawer. This ensures the user can scroll
          // through the options in the drawer if there isn't enough vertical
          // space to fit everything.
          child: ListView(
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text('Drawer Header'),
              ),
              ListTile(
                title: const Text('Rename'),
                onTap:
                    // Update the state of the app
                    //_onItemTapped(0);
                    // Then close the drawer
                    () async {
                  // Show the dialog and wait for the entered text
                  final newName = await showDialog<String>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Enter new name'),
                        content: TextField(
                          onChanged: (value) {
                            fileName = value;
                          },
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: Text('Cancel'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: Text('Save'),
                            onPressed: () {
                              Navigator.of(context).pop(fileName);
                            },
                          ),
                        ],
                      );
                    },
                  );
                  setState(() {
                    if (newName != null && newName.isNotEmpty) {
                      fileName = newName;
                    }
                  });
                  debugPrint(newName);
                  debugPrint(fileName);
                  // Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Home'),
                onTap: () {
                  // Update the state of the app
                  //_onItemTapped(0);
                  // Then close the drawer

                  // Home home = Home();
                  // home.authenticate();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Home()),
                  );
                },
              ),
              ListTile(
                title: const Text('Upload'),
                onTap: () async {
                  // Update the state of the app
                  //_onItemTapped(0);
                  // Then close the drawer
                  debugPrint(fileName);
                  File savedFile =
                      await _convertToImage(ui.ImageByteFormat.png, fileName);
                  widget._googleDrive.uploadFile(widget._authClient, savedFile);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

