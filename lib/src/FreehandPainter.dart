import 'dart:async';
import 'dart:ffi';
import 'dart:io';
//import 'dart:ffi';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_handwritten_notes/src/Model.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'package:pdf_render/pdf_render.dart';
import 'package:image/image.dart' as imglib;

/// Subclass of [CustomPainter] to paint strokes
class FreehandPainter extends CustomPainter {
  String? imageFilePath;
  ui.Image? image;
  var currentfile = null;
  final List<Stroke> strokes;
  final Color backgroundColor;
  final paintDarkgrey = Paint()
    ..color = Colors.blueGrey
    ..strokeWidth = 1.0;
  final paintPink = Paint()
    ..color = Colors.pinkAccent
    ..strokeWidth = 2.5;
  FreehandPainter(this.strokes, this.backgroundColor, this.currentfile,
      {this.image, this.imageFilePath});

  Future<ui.Image> convertToImage(
      Uint8List bytes, double width, double height) async {
    /*Directory directory = await getApplicationDocumentsDirectory();
      String path = '${directory.path}/$fileName';

      // Write the image bytes to the file
      File file = File(path);
      await file.writeAsBytes(bytes);

      print('Image saved at $path');
      return path;*/
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  Future<File> loadPdf(currFile) async {
    debugPrint(" start loadPdf $currFile ");
    final doc = await PdfDocument.openFile(currFile);
    final pages = doc.pageCount;
    List<imglib.Image> images = [];

// get images from all the pages
    for (int i = 1; i <= pages; i++) {
      var page = await doc.getPage(i);
      var imgPDF = await page.render();
      var img = await imgPDF.createImageDetached();
      var imgBytes = await img.toByteData(format: ui.ImageByteFormat.png);
      var libImage = imglib.decodeImage(imgBytes!.buffer
          .asUint8List(imgBytes.offsetInBytes, imgBytes.lengthInBytes));
      images.add(libImage!);
    }

// stitch images
/*int totalHeight = 0;
images.forEach((e) {
  totalHeight += e.height;
});
int totalWidth = 0;
images.forEach((element) {
  totalWidth = totalWidth < element.width ? element.width : totalWidth;
});
final mergedImage = imglib.Image(width : totalWidth, height :totalHeight);
int mergedHeight = 0;
images.forEach((element) {
  imglib.(mergedImage, element, dstX: 0, dstY: mergedHeight, blend: false);
  mergedHeight += element.height;
});*/

// Save image as a file
    imageFilePath = currFile.toString().replaceAll(RegExp(r'pdf'), 'png');
    File newFile = await File(imageFilePath!).writeAsBytes(imglib.encodeJpg(images[0]));
    debugPrint("image file path $imageFilePath");
    /*final data = await File(imageFilePath!).readAsBytes();
    final image = await decodeImageFromList(data);*/
    return newFile;
    /*late PdfDocument document;
    late PdfPage page;
    late PdfPageImage? pageImage;
    // Load the PDF document using the passed pdfPath from the widget
    document = await PdfDocument.openFile(currentfile); // Use the variable here

    // Convert the first page of the PDF to an image
    page = await document.getPage(1);
    pageImage = await page.render(width: page.width, height: page.height);
    if (pageImage == null) {
      debugPrint("pageImage = null after await");
    }*/
    // ui.Image pdfImage = await convertToImage(pageImage!.bytes, page.width, page.height);

    //   debugPrint("pdfImage after await");

    // return images;
  }

  @override
  void paint(Canvas canvas, ui.Size size) {
    if (currentfile == null) {
      debugPrint("currentfile doesn't exist");
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = backgroundColor,
      );

      canvas.drawLine(Offset(size.width * .05, 0),
          Offset(size.width * .05, size.height), paintPink);

      for (double i = 0.05; i < 1.0; i = i + 0.05) {
        canvas.drawLine(Offset(0, size.height * i),
            Offset(size.width, size.height * i), paintDarkgrey);
      }
      canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
      for (final stroke in strokes) {
        final paint = Paint()
          ..strokeWidth = stroke.width
          ..color = stroke.erase ? Colors.transparent : stroke.color
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..blendMode = stroke.erase ? BlendMode.clear : BlendMode.srcOver;
        canvas.drawPath(stroke.path, paint);
      }
      canvas.restore();
    } else {
      debugPrint("currentfile exists $currentfile");
      //ui.Image  currentImage = await _loadPdf();
     /* debugPrint("Start draw with image path $imageFilePath");
      () async {
       
     canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = backgroundColor,
      );

        await loadPdf();
        debugPrint("after loadPdf image path is $imageFilePath");
        File currentImageFile = File(imageFilePath!);
        final data = await currentImageFile.readAsBytes();
        ui.Image? decodedImage;
        decodedImage = await decodeImageFromList(data);
         canvas.drawImage(decodedImage, const Offset(0.0, 0.0), Paint());
      }();
      canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    
      //canvas.drawImage(currentImage, Offset(0, 0), Paint());*/
        for (final stroke in strokes) {
          final paint = Paint()
            ..strokeWidth = stroke.width
            ..color = stroke.erase ? Colors.transparent : stroke.color
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke
            ..blendMode = stroke.erase ? BlendMode.clear : BlendMode.srcOver;
          canvas.drawPath(stroke.path, paint);
        }

        //canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
