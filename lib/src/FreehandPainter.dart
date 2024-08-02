import 'package:flutter_handwritten_notes/src/Model.dart';
import 'package:flutter/material.dart';



/// Subclass of [CustomPainter] to paint strokes
class FreehandPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Color backgroundColor;
  final paintDarkgrey = Paint()
    ..color = Colors.blueGrey
    ..strokeWidth = 1.0;
  final paintPink = Paint()
  ..color = Colors.pinkAccent
  ..strokeWidth = 2.5;
  FreehandPainter(
    this.strokes,
    this.backgroundColor,
  );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );
    
    canvas.drawLine(Offset(size.width * .05, 0),
      Offset(size.width * .05, size.height), paintPink);

    for(double i = 0.05; i<1.0; i = i+0.05 )
    {
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}