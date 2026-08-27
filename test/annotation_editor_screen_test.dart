import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_report/models.dart';
import 'package:photo_report/ui/annotation_editor_screen.dart';
import 'package:photo_report/ui/widgets/annotated_photo.dart';

void main() {
  late Directory temporaryDirectory;
  late String imagePath;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'annotation_editor_test_',
    );
    imagePath = '${temporaryDirectory.path}/photo.png';
    await File(imagePath).writeAsBytes(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );
    await readImageSize(imagePath);
  });

  tearDown(() async {
    await temporaryDirectory.delete(recursive: true);
  });

  Future<void> openTextAnnotationDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: AnnotationEditorScreen(
          photo: PhotoRecord(
            id: 'photo-1',
            issueId: 'issue-1',
            path: imagePath,
            phase: PhotoPhase.before,
            createdAt: DateTime(2026),
          ),
        ),
      ),
    );
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
      if (find.byType(Image).evaluate().isNotEmpty) break;
    }
    expect(find.byType(Image), findsOneWidget);

    await tester.tap(find.text('文字'));
    await tester.pump();
    await tester.tapAt(tester.getCenter(find.byType(Image)));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('添加文字标注'), findsOneWidget);
  }

  testWidgets('取消文字标注后弹窗可安全关闭', (tester) async {
    await openTextAnnotationDialog(tester);

    await tester.tap(find.text('取消'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('添加文字标注'), findsNothing);
    expect(annotationPainter(tester).annotations, isEmpty);
  });

  testWidgets('确认文字标注后弹窗可安全关闭', (tester) async {
    await openTextAnnotationDialog(tester);

    await tester.enterText(find.byType(TextField), '墙面裂缝');
    await tester.tap(find.text('添加'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('添加文字标注'), findsNothing);
    expect(annotationPainter(tester).annotations, hasLength(1));
    expect(annotationPainter(tester).annotations.single.text, '墙面裂缝');
  });
}

AnnotationPainter annotationPainter(WidgetTester tester) {
  return tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((widget) => widget.painter)
      .whereType<AnnotationPainter>()
      .single;
}
