import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_report/app_controller.dart';
import 'package:photo_report/models.dart';
import 'package:photo_report/ui/app_theme.dart';
import 'package:photo_report/ui/issue_form_screen.dart';

void main() {
  late Directory temporaryDirectory;
  late String imagePath;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'issue_form_annotation_test_',
    );
    imagePath = '${temporaryDirectory.path}/photo.png';
    await File(imagePath).writeAsBytes(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );
  });

  tearDown(() async {
    await temporaryDirectory.delete(recursive: true);
  });

  testWidgets('点击照片上的标注入口会打开标注编辑页', (tester) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = PhotoReportController();
    addTearDown(controller.dispose);
    final now = DateTime(2026, 8, 28);
    final project = ProjectRecord(
      id: 'project-1',
      name: '现场项目',
      address: '',
      companyName: '',
      inspectorName: '',
      clientName: '',
      codePrefix: 'PR',
      inspectionDate: now,
      notes: '',
      createdAt: now,
      updatedAt: now,
    );
    final issue = IssueRecord(
      id: 'issue-1',
      projectId: project.id,
      sequence: 1,
      code: 'PR-001',
      room: '',
      location: '',
      category: '现场记录',
      severity: IssueSeverity.unspecified,
      description: '现场情况说明',
      status: IssueStatus.unspecified,
      assignee: '',
      createdAt: now,
      updatedAt: now,
      photos: [
        PhotoRecord(
          id: 'photo-1',
          issueId: 'issue-1',
          path: imagePath,
          phase: PhotoPhase.before,
          createdAt: now,
        ),
      ],
    );

    AppLocalizations.activeLocale = const Locale('zh', 'CN');
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'CN'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildAppTheme(),
        home: IssueFormScreen(
          controller: controller,
          project: project,
          sequence: 1,
          issue: issue,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('点击标注'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('标注照片重点'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
