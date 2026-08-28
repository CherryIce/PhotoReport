import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:photo_report/data/report_storage.dart';

void main() {
  test(
    'repairs a stored report path after the iOS container changes',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'photo-report-report-path-test-',
      );
      addTearDown(() => root.delete(recursive: true));
      final currentDocuments = Directory(p.join(root.path, 'Documents'));
      final currentReport = File(
        p.join(
          currentDocuments.path,
          'PhotoReport',
          'Reports',
          '001-20260828-104908.pdf',
        ),
      );
      await currentReport.create(recursive: true);
      await currentReport.writeAsBytes(const [0x25, 0x50, 0x44, 0x46]);

      final resolved = await const ReportStorage().resolveReportPath(
        '/old/container/Documents/PhotoReport/Reports/001-20260828-104908.pdf',
        documentsPath: currentDocuments.path,
      );

      expect(resolved, currentReport.path);
    },
  );

  test(
    'returns null when neither stored nor relocated report exists',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'photo-report-report-path-test-',
      );
      addTearDown(() => root.delete(recursive: true));

      final resolved = await const ReportStorage().resolveReportPath(
        '/old/container/Documents/PhotoReport/Reports/missing.pdf',
        documentsPath: root.path,
      );

      expect(resolved, isNull);
    },
  );
}
