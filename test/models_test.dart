import 'package:flutter_test/flutter_test.dart';
import 'package:photo_report/models.dart';

void main() {
  group('现场问题模型', () {
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

    test('问题字段和整改状态保持一致', () {
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
      expect(restored.status.label, '待整改');
      expect(restored.dueDate, DateTime(2026, 9, 5));
    });
  });
}
