import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_report/models.dart';
import 'package:photo_report/ui/annotation_editor_screen.dart';
import 'package:photo_report/ui/app_theme.dart';
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

  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildAppTheme(),
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
  }

  Future<void> openTextAnnotationSheet(
    WidgetTester tester, {
    String? colorTooltip,
  }) async {
    await pumpEditor(tester);
    if (colorTooltip != null) {
      await tester.tap(find.byTooltip(colorTooltip));
      await tester.pump();
    }

    await tester.tap(find.text('文字'));
    await tester.pump();
    await tester.tapAt(tester.getCenter(find.byType(Image)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('添加文字标注'), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(CupertinoAlertDialog), findsNothing);
  }

  testWidgets('取消文字标注后底部面板可安全关闭', (tester) async {
    await openTextAnnotationSheet(tester);

    await tester.tap(find.text('取消'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(tester.takeException(), isNull);
    expect(find.text('添加文字标注'), findsNothing);
    expect(annotationPainter(tester).annotations, isEmpty);
  });

  testWidgets('确认文字标注后保留所选颜色', (tester) async {
    await openTextAnnotationSheet(tester, colorTooltip: '蓝色');

    await tester.enterText(find.byType(TextField), '墙面裂缝');
    await tester.pump();
    await tester.tap(find.text('添加'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(tester.takeException(), isNull);
    expect(find.text('添加文字标注'), findsNothing);
    expect(annotationPainter(tester).annotations, hasLength(1));
    expect(annotationPainter(tester).annotations.single.text, '墙面裂缝');
    expect(
      annotationPainter(tester).annotations.single.colorValue,
      annotationBlueColor.toARGB32(),
    );
  });

  testWidgets('方框使用当前选择的绿色', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpEditor(tester);

    for (final label in ['红色', '绿色', '蓝色', '黑色', '白色']) {
      expect(find.byTooltip(label), findsOneWidget);
    }
    await tester.tap(find.byTooltip('绿色'));
    await tester.pump();
    final center = tester.getCenter(find.byType(Image));
    await tester.dragFrom(center - const Offset(30, 30), const Offset(60, 60));
    await tester.pump();

    expect(annotationPainter(tester).annotations, hasLength(1));
    expect(
      annotationPainter(tester).annotations.single.colorValue,
      annotationGreenColor.toARGB32(),
    );
    expect(tester.takeException(), isNull);
  });

  test('文字标注会按背景亮度选择可读前景色', () {
    expect(annotationTextColor(annotationWhiteColor), Colors.black);
    expect(annotationTextColor(annotationGreenColor), Colors.black);
    expect(annotationTextColor(annotationColor), Colors.white);
    expect(annotationTextColor(annotationBlackColor), Colors.white);
  });
}

AnnotationPainter annotationPainter(WidgetTester tester) {
  return tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((widget) => widget.painter)
      .whereType<AnnotationPainter>()
      .single;
}
