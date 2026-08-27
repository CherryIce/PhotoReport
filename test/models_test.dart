import 'package:flutter_test/flutter_test.dart';
import 'package:photo_report/models.dart';
import 'package:photo_report/report/report_service.dart';
import 'package:photo_report/ui/create_flow_logic.dart';

void main() {
  group('现场照片记录模型', () {
    test('照片标注可完整写入并恢复', () {
      final photo = PhotoRecord(
        id: 'photo-1',
        issueId: 'issue-1',
        path: '/tmp/site.jpg',
        phase: PhotoPhase.before,
        createdAt: DateTime(2026, 8, 26, 9, 30),
        annotations: const [
          PhotoAnnotation(
            kind: AnnotationKind.rectangle,
            x1: 0.1,
            y1: 0.2,
            x2: 0.8,
            y2: 0.7,
          ),
          PhotoAnnotation(
            kind: AnnotationKind.text,
            x1: 0.15,
            y1: 0.22,
            x2: 0.15,
            y2: 0.22,
            text: '墙面开裂',
          ),
        ],
      );

      final restored = PhotoRecord.fromMap(photo.toMap());

      expect(restored.phase, PhotoPhase.before);
      expect(restored.annotations, hasLength(2));
      expect(restored.annotations.first.kind, AnnotationKind.rectangle);
      expect(restored.annotations.last.text, '墙面开裂');
      expect(restored.annotations.last.x1, 0.15);
    });

    test('记录字段和处理状态保持一致', () {
      final now = DateTime(2026, 8, 26);
      final issue = IssueRecord(
        id: 'issue-7',
        projectId: 'project-1',
        sequence: 7,
        code: 'A-007',
        room: '主卫',
        location: '东侧墙面',
        category: '瓷砖空鼓',
        severity: IssueSeverity.medium,
        description: '距地面约1.2米处检测到空鼓',
        status: IssueStatus.pending,
        assignee: '施工方',
        dueDate: DateTime(2026, 9, 5),
        createdAt: now,
        updatedAt: now,
      );

      final restored = IssueRecord.fromMap(issue.toMap());

      expect(restored.code, 'A-007');
      expect(restored.room, '主卫');
      expect(restored.severity.label, '中');
      expect(restored.status.label, '待处理');
      expect(restored.dueDate, DateTime(2026, 9, 5));
    });

    test('快速记录允许不设置优先级和状态', () {
      expect(IssueSeverity.unspecified.label, '未设置');
      expect(IssueStatus.unspecified.label, '未设置');
    });

    test('项目可持久化最近生成的 PDF', () {
      final project = ProjectRecord(
        id: 'project-1',
        name: '现场记录',
        address: '一层大厅',
        companyName: '',
        inspectorName: '',
        clientName: '',
        codePrefix: 'A',
        inspectionDate: DateTime(2026, 8, 27),
        notes: '',
        createdAt: DateTime(2026, 8, 27),
        updatedAt: DateTime(2026, 8, 27),
        lastReportPath: '/tmp/latest.pdf',
        lastReportAt: DateTime(2026, 8, 27, 11, 30),
        formalFlowStep: 2,
      );

      final restored = ProjectRecord.fromMap(project.toMap());

      expect(restored.lastReportPath, '/tmp/latest.pdf');
      expect(restored.lastReportAt, DateTime(2026, 8, 27, 11, 30));
      expect(restored.formalFlowStep, 2);
    });

    test('简洁导出默认不包含额外字段', () {
      const options = ReportOptions();

      expect(options.layout, ReportLayout.concise);
      expect(options.includePosition, isFalse);
      expect(options.includeStatus, isFalse);
      expect(options.includeProjectDetails, isFalse);
      expect(options.toMap()['layout'], 'concise');
    });

    test('快速记录从说明首行生成稳定标题', () {
      expect(quickRecordTitle('主卫天花板漏水\n需要检查管道'), '主卫天花板漏水');
      expect(quickRecordTitle('   '), '图文记录');
      expect(quickRecordTitle('这是一个超过二十四个字符并且需要自动截断的现场情况描述文本'), endsWith('…'));
    });

    test('正式复核只提醒缺失内容且不改变记录', () {
      final now = DateTime(2026, 8, 27);
      final project = ProjectRecord(
        id: 'project-quick',
        name: '快速项目',
        address: '',
        companyName: '',
        inspectorName: '',
        clientName: '',
        codePrefix: 'A',
        inspectionDate: now,
        notes: '',
        createdAt: now,
        updatedAt: now,
      );
      final issue = IssueRecord(
        id: 'issue-quick',
        projectId: project.id,
        sequence: 1,
        code: 'A-001',
        room: '',
        location: '',
        category: '天花板漏水',
        severity: IssueSeverity.unspecified,
        description: '天花板正在滴水',
        status: IssueStatus.unspecified,
        assignee: '',
        createdAt: now,
        updatedAt: now,
        photos: [
          PhotoRecord(
            id: 'photo-quick',
            issueId: 'issue-quick',
            path: '/tmp/quick.jpg',
            phase: PhotoPhase.before,
            createdAt: now,
          ),
        ],
      );

      final warnings = formalReadinessWarnings(project, [issue]);

      expect(warnings, contains('项目地点尚未填写'));
      expect(warnings, contains('A-001 尚未填写区域'));
      expect(warnings, isNot(contains('A-001 尚未添加现场照片')));
      expect(issueLocationLabel(issue), '未分类');
      expect(hasFormalCoreFields(issue), isFalse);
    });
  });
}
