import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_report/app_controller.dart';
import 'package:photo_report/models.dart';
import 'package:photo_report/ui/app_theme.dart';
import 'package:photo_report/ui/project_detail_screen.dart';

void main() {
  Widget app({
    required PhotoReportController controller,
    required ProjectRecord project,
    bool formalFlow = false,
  }) {
    AppLocalizations.activeLocale = const Locale('zh', 'CN');
    return MaterialApp(
      locale: const Locale('zh', 'CN'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildAppTheme(),
      home: ProjectDetailScreen(
        controller: controller,
        initialProject: project,
        formalFlow: formalFlow,
      ),
    );
  }

  testWidgets('formal empty detail keeps one add action and hides list tools', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = _DetailController(const []);
    addTearDown(controller.dispose);
    final project = _project(formalFlowStep: 2);

    await tester.pumpWidget(
      app(controller: controller, project: project, formalFlow: true),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('formal-flow-banner')), findsOneWidget);
    expect(find.text('还没有现场记录'), findsOneWidget);
    expect(find.byKey(const Key('detail-empty-add-record')), findsOneWidget);
    expect(find.text('添加第一条记录'), findsOneWidget);
    expect(find.byKey(const Key('detail-add-record')), findsNothing);
    expect(find.byKey(const Key('detail-share-section')), findsNothing);
    expect(find.byKey(const Key('detail-filter-toggle')), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('single-record detail prioritizes record and secondary sharing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final project = _project();
    final controller = _DetailController([_issue(project.id)]);
    addTearDown(controller.dispose);

    await tester.pumpWidget(app(controller: controller, project: project));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detail-quick-mode')), findsOneWidget);
    expect(find.byKey(const Key('detail-add-record')), findsOneWidget);
    expect(find.text('A-001'), findsOneWidget);
    expect(find.text('需要处理这个位置'), findsOneWidget);
    expect(find.byKey(const Key('detail-share-section')), findsOneWidget);
    expect(find.byKey(const Key('detail-generate-pdf')), findsOneWidget);
    expect(find.byKey(const Key('detail-filter-toggle')), findsNothing);
    expect(find.byKey(const Key('detail-filters-panel')), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('issue actions stay pinned to the card right edge', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final project = _project();
    final controller = _DetailController([
      _issue(project.id, severity: IssueSeverity.high),
    ]);
    addTearDown(controller.dispose);

    await tester.pumpWidget(app(controller: controller, project: project));
    await tester.pumpAndSettle();

    final card = find.ancestor(
      of: find.text('A-001'),
      matching: find.byType(Card),
    );
    final actions = find.byKey(const Key('issue-actions-issue-1'));
    final badge = find.text('高优先级');
    expect(card, findsOneWidget);
    expect(actions, findsOneWidget);
    expect(badge, findsOneWidget);

    final cardRect = tester.getRect(card);
    final actionsRect = tester.getRect(actions);
    final badgeRect = tester.getRect(badge);
    expect(cardRect.right - actionsRect.right, closeTo(13, 0.1));
    expect(actionsRect.left, greaterThan(badgeRect.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiple records expose filters only after explicit request', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final project = _project();
    final controller = _DetailController([
      _issue(project.id),
      _issue(project.id, sequence: 2),
    ]);
    addTearDown(controller.dispose);

    await tester.pumpWidget(app(controller: controller, project: project));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detail-filter-toggle')), findsOneWidget);
    expect(find.byKey(const Key('detail-filters-panel')), findsNothing);
    await tester.tap(find.byKey(const Key('detail-filter-toggle')));
    await tester.pump();
    expect(find.byKey(const Key('detail-filters-panel')), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _DetailController extends PhotoReportController {
  _DetailController(this.issueRecords);

  final List<IssueRecord> issueRecords;

  @override
  Future<List<IssueRecord>> loadIssues(String projectId) async => issueRecords;
}

ProjectRecord _project({int formalFlowStep = 0}) {
  final now = DateTime(2026, 8, 28, 10, 31);
  return ProjectRecord(
    id: 'project-1',
    name: formalFlowStep > 0 ? '花卉公园 0828' : '001',
    address: formalFlowStep > 0 ? '0903' : '天河',
    companyName: '',
    inspectorName: '',
    clientName: '',
    codePrefix: 'A',
    inspectionDate: now,
    notes: '',
    createdAt: now,
    updatedAt: now,
    formalFlowStep: formalFlowStep,
  );
}

IssueRecord _issue(
  String projectId, {
  int sequence = 1,
  IssueSeverity severity = IssueSeverity.unspecified,
}) {
  final now = DateTime(2026, 8, 28, 10, 31);
  return IssueRecord(
    id: 'issue-$sequence',
    projectId: projectId,
    sequence: sequence,
    code: 'A-${sequence.toString().padLeft(3, '0')}',
    room: '未分类',
    location: '',
    category: '需要处理这个位置',
    severity: severity,
    description: '现场情况说明',
    status: IssueStatus.unspecified,
    assignee: '',
    createdAt: now,
    updatedAt: now,
  );
}
