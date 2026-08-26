import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models.dart';

class ReportService {
  const ReportService();

  static const channel = MethodChannel('com.starburst.photo_report/report');

  Future<String> generateReport(
    ProjectRecord project,
    List<IssueRecord> issues,
  ) async {
    final path = await channel.invokeMethod<String>('generateReport', {
      'project': {
        'name': project.name,
        'address': project.address,
        'companyName': project.companyName,
        'inspectorName': project.inspectorName,
        'clientName': project.clientName,
        'inspectionDate': DateFormat(
          'yyyy-MM-dd',
        ).format(project.inspectionDate),
        'notes': project.notes,
      },
      'issues': issues
          .map(
            (issue) => {
              'code': issue.code,
              'room': issue.room,
              'location': issue.location,
              'category': issue.category,
              'severity': issue.severity.label,
              'status': issue.status.label,
              'description': issue.description,
              'assignee': issue.assignee,
              'dueDate': issue.dueDate == null
                  ? ''
                  : DateFormat('yyyy-MM-dd').format(issue.dueDate!),
              'photos': issue.photos
                  .map(
                    (photo) => {
                      'path': photo.path,
                      'phase': photo.phase.label,
                      'annotations': photo.annotations
                          .map(
                            (annotation) => {
                              'kind': annotation.kind.name,
                              'x1': annotation.x1,
                              'y1': annotation.y1,
                              'x2': annotation.x2,
                              'y2': annotation.y2,
                              'text': annotation.text,
                            },
                          )
                          .toList(),
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
    });
    if (path == null || path.isEmpty) {
      throw PlatformException(code: 'empty_path', message: '报告生成成功但未返回文件地址');
    }
    return path;
  }

  Future<void> preview(String path) {
    return channel.invokeMethod<void>('previewReport', {'path': path});
  }

  Future<void> share(String path) {
    return channel.invokeMethod<void>('shareReport', {'path': path});
  }
}
