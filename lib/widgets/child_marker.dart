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

  return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
}

String _formatIdle(Duration d) {
  final minutes = d.inMinutes;
  if (minutes >= 1) return '${minutes}min';
  final seconds = d.inSeconds;
  return '${(seconds ~/ 30) * 30}s';
}

Future<BitmapDescriptor> createChildMarker({
  required String name,
  required double speed,
  required Duration idleDuration,
  Color color = AppColors.info,
  bool isInsideZone = true,
  bool isPulsing = false,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  const double width = 270;
  const double height = 100;
  const double avatarRadius = 18;
  const double padding = 12;

  final textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '...',
    text: TextSpan(
      text: name,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
  textPainter.layout(maxWidth: width - avatarRadius * 2 - padding * 4);

  final bubbleWidth = avatarRadius * 2 + padding * 3 + textPainter.width;
  final bubbleCenterOffset = (width - bubbleWidth) / 2;

  final shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: isPulsing ? 0.45 : 0.25)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, isPulsing ? 14 : 8);

  final bubbleRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(bubbleCenterOffset, 8, bubbleWidth, height - 32),
    const Radius.circular(28),
  );

  canvas.drawRRect(bubbleRect.shift(const Offset(0, 3)), shadowPaint);

  final lighter = Color.lerp(color, Colors.white, 0.2)!;
  final gradient = ui.Gradient.linear(
    Offset(bubbleCenterOffset, 8),
    Offset(bubbleCenterOffset, height - 32),
    [lighter, color],
  );
  final markerPaint = Paint()..shader = gradient;
  canvas.drawRRect(bubbleRect, markerPaint);

  final avatarCenterX = bubbleCenterOffset + padding + avatarRadius;
  final avatarCenterY = 8 + (height - 32) / 2;

  canvas.drawCircle(
    Offset(avatarCenterX, avatarCenterY),
    avatarRadius,
    Paint()..color = Colors.white.withValues(alpha: 0.35),
  );

  final circleLabel = idleDuration >= const Duration(seconds: 30)
      ? _formatIdle(idleDuration)
      : speed.toStringAsFixed(1);
  final labelPainter = TextPainter(
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: circleLabel,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
  labelPainter.layout();
  labelPainter.paint(
    canvas,
    Offset(
      avatarCenterX - labelPainter.width / 2,
      avatarCenterY - labelPainter.height / 2,
    ),
  );

  final textX = bubbleCenterOffset + padding + avatarRadius * 2 + padding;
  textPainter.paint(canvas, Offset(textX, 22));

  final statusDotColor = isInsideZone ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
  canvas.drawCircle(
    Offset(textX + 4, 60),
    5,
    Paint()..color = statusDotColor,
  );
  canvas.drawCircle(
    Offset(textX + 4, 60),
    5,
    Paint()
      ..color = statusDotColor.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
  );

  final statusText = TextPainter(
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: isInsideZone ? 'Inside zone' : 'Outside zone',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.8),
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
  statusText.layout();
  statusText.paint(canvas, Offset(textX + 14, 55));

  const double triangleY = height - 26;
  final trianglePath = Path()
    ..moveTo(width / 2 - 14, triangleY)
    ..lineTo(width / 2 + 14, triangleY)
    ..lineTo(width / 2, height - 6)
    ..close();

  canvas.drawPath(trianglePath.shift(const Offset(0, 3)), shadowPaint);

  final triGradient = ui.Gradient.linear(
    Offset(width / 2, triangleY),
    Offset(width / 2, height - 6),
    [color, lighter],
  );
  final trianglePaint = Paint()..shader = triGradient;
  canvas.drawPath(trianglePath, trianglePaint);

  final picture = recorder.endRecording();
  final image = await picture.toImage(width.toInt(), height.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
}
