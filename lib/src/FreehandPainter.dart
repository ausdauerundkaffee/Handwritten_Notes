
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

 /*final double distanceThreshold;

  FilteredPathPainter({this.distanceThreshold = 20.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final path = Path()
      ..moveTo(size.width / 4, size.height / 4)
      ..lineTo(size.width / 2, size.height / 2)
      ..lineTo(3 * size.width / 4, size.height / 4)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final points = _getPointsFromPath(path, size);

    final filteredPoints = _filterPoints(points, distanceThreshold);

    final filteredPath = Path();
    if (filteredPoints.isNotEmpty) {
      filteredPath.moveTo(filteredPoints.first.dx, filteredPoints.first.dy);
      for (var point in filteredPoints) {
        filteredPath.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(filteredPath, paint);
  }

  List<Offset> _getPointsFromPath(Path path, Size size) {
    final pathMetrics = path.computeMetrics();
    final points = <Offset>[];

    for (final metric in pathMetrics) {
      for (double i = 0; i < metric.length; i += 5.0) {
        final tangent = metric.getTangentForOffset(i);
        if (tangent != null) {
          points.add(tangent.position);
        }
      }
    }

    return points;
  }

  List<Offset> _filterPoints(List<Offset> points, double threshold) {
    if (points.isEmpty) return [];

    final filteredPoints = [points.first];
    for (int i = 1; i < points.length; i++) {
      final distance = _calculateDistance(filteredPoints.last, points[i]);
      if (distance <= threshold) {
        filteredPoints.add(points[i]);
      }
    }

    return filteredPoints;
  }

  double _calculateDistance(Offset p1, Offset p2) {
    return sqrt(pow(p2.dx - p1.dx, 2) + pow(p2.dy - p1.dy, 2));
  }*/
