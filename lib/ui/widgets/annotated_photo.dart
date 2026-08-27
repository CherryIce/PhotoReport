import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models.dart';
import '../app_theme.dart';

Future<Size> readImageSize(String path) async {
  final bytes = await File(path).readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final size = Size(
    frame.image.width.toDouble(),
    frame.image.height.toDouble(),
  );
  frame.image.dispose();
  codec.dispose();
  return size;
}

class AnnotatedPhoto extends StatefulWidget {
  const AnnotatedPhoto({
    required this.path,
    required this.annotations,
    this.backgroundColor = editorSurfaceColor,
    super.key,
  });

  final String path;
  final List<PhotoAnnotation> annotations;
  final Color backgroundColor;

  @override
  State<AnnotatedPhoto> createState() => _AnnotatedPhotoState();
}

class _AnnotatedPhotoState extends State<AnnotatedPhoto> {
  late Future<Size> imageSize;

  @override
  void initState() {
    super.initState();
    imageSize = readImageSize(widget.path);
  }

  @override
  void didUpdateWidget(covariant AnnotatedPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) imageSize = readImageSize(widget.path);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: widget.backgroundColor,
      child: FutureBuilder<Size>(
        future: imageSize,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final fitted = fitSize(snapshot.data!, constraints.biggest);
              return Center(
                child: SizedBox(
                  width: fitted.width,
                  height: fitted.height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(widget.path), fit: BoxFit.fill),
                      CustomPaint(
                        painter: AnnotationPainter(widget.annotations),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Size fitSize(Size source, Size bounds) {
  if (source.isEmpty || bounds.isEmpty) return Size.zero;
  final scale = math.min(
    bounds.width / source.width,
    bounds.height / source.height,
  );
  return Size(source.width * scale, source.height * scale);
}

class AnnotationPainter extends CustomPainter {
  const AnnotationPainter(this.annotations);

  final List<PhotoAnnotation> annotations;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = annotationColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.5, size.shortestSide * 0.009)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final annotation in annotations) {
      final start = Offset(
        annotation.x1 * size.width,
        annotation.y1 * size.height,
      );
      final end = Offset(
        annotation.x2 * size.width,
        annotation.y2 * size.height,
      );
      switch (annotation.kind) {
        case AnnotationKind.rectangle:
          canvas.drawRect(Rect.fromPoints(start, end), paint);
          break;
        case AnnotationKind.arrow:
          _drawArrow(canvas, start, end, paint);
          break;
        case AnnotationKind.text:
          _drawText(canvas, start, annotation.text, size);
          break;
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final length = paint.strokeWidth * 4.2;
    canvas.drawLine(
      end,
      end - Offset(math.cos(angle - 0.6), math.sin(angle - 0.6)) * length,
      paint,
    );
    canvas.drawLine(
      end,
      end - Offset(math.cos(angle + 0.6), math.sin(angle + 0.6)) * length,
      paint,
    );
  }

  void _drawText(Canvas canvas, Offset point, String text, Size size) {
    if (text.isEmpty) return;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: math.max(13, size.shortestSide * 0.045),
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: size.width * 0.55);
    final rect = Rect.fromLTWH(
      point.dx,
      point.dy,
      painter.width + 12,
      painter.height + 8,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()..color = annotationLabelColor,
    );
    painter.paint(canvas, point + const Offset(6, 4));
  }

  @override
  bool shouldRepaint(covariant AnnotationPainter oldDelegate) {
    return oldDelegate.annotations != annotations;
  }
}
