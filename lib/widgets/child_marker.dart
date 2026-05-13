import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<BitmapDescriptor> createNameMarker(
  String name, {
  Color color = Colors.blue,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  const double width = 260;
  const double height = 90;

  final markerPaint = Paint()..color = color;

  final shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.25)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

  final bubbleRect = RRect.fromRectAndRadius(
    const Rect.fromLTWH(8, 8, width - 16, height - 28),
    const Radius.circular(32),
  );

  canvas.drawRRect(bubbleRect.shift(const Offset(0, 3)), shadowPaint);
  canvas.drawRRect(bubbleRect, markerPaint);

  final trianglePath = Path()
    ..moveTo(width / 2 - 14, height - 22)
    ..lineTo(width / 2 + 14, height - 22)
    ..lineTo(width / 2, height - 4)
    ..close();

  canvas.drawPath(trianglePath.shift(const Offset(0, 3)), shadowPaint);
  canvas.drawPath(trianglePath, markerPaint);

  final textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '...',
    textAlign: TextAlign.center,
    text: TextSpan(
      text: name,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 26,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  textPainter.layout(maxWidth: width - 32);
  textPainter.paint(canvas, Offset((width - textPainter.width) / 2, 24));

  final picture = recorder.endRecording();
  final image = await picture.toImage(width.toInt(), height.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
}
