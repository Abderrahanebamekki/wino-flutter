import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_colors.dart';

Future<BitmapDescriptor> createNameMarker(
  String name, {
  Color color = AppColors.info,
  int maxLines = 1,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  const double width = 260;
  final double height = maxLines > 1 ? 120 : 90;
  final double fontSize = maxLines > 1 ? 20 : 26;

  final markerPaint = Paint()..color = color;
  final shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.25)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

  final bubbleRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(8, 8, width - 16, height - 28),
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
    maxLines: maxLines,
    ellipsis: '...',
    textAlign: TextAlign.center,
    text: TextSpan(
      text: name,
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  textPainter.layout(maxWidth: width - 32);
  textPainter.paint(canvas, Offset((width - textPainter.width) / 2, maxLines > 1 ? 18 : 24));

  final picture = recorder.endRecording();
  final image = await picture.toImage(width.toInt(), height.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
}
