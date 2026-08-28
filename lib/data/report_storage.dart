import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ReportStorage {
  const ReportStorage();

  /// Resolves a report saved under a previous iOS app-container UUID.
  ///
  /// iOS can move an app's Documents directory between installs or simulator
  /// rebuilds. The report filename remains stable, so it can be recovered from
  /// the current Documents/PhotoReport/Reports directory.
  Future<String?> resolveReportPath(
    String storedPath, {
    String? documentsPath,
  }) async {
    if (storedPath.isEmpty) return null;
    if (await File(storedPath).exists()) return storedPath;
    final documents = documentsPath == null
        ? await getApplicationDocumentsDirectory()
        : Directory(documentsPath);
    final relocated = p.join(
      documents.path,
      'PhotoReport',
      'Reports',
      p.basename(storedPath),
    );
    return await File(relocated).exists() ? relocated : null;
  }
}
