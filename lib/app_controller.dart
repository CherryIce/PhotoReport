import 'package:flutter/foundation.dart';

import 'data/backup_service.dart';
import 'data/app_database.dart';
import 'data/photo_storage.dart';
import 'models.dart';

class PhotoReportController extends ChangeNotifier {
  PhotoReportController({
    AppDatabase? database,
    PhotoStorage? photoStorage,
    BackupService? backupService,
  }) : database = database ?? AppDatabase.instance,
       photoStorage = photoStorage ?? const PhotoStorage(),
       backupService = backupService ?? BackupService();

  final AppDatabase database;
  final PhotoStorage photoStorage;
  final BackupService backupService;

  bool isLoading = true;
  Object? loadError;
  List<ProjectOverview> projects = const [];

  Future<void> initialize() async {
    try {
      await refreshProjects();
    } catch (error) {
      loadError = error;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProjects() async {
    projects = await database.loadProjectOverviews();
    loadError = null;
    notifyListeners();
  }

  Future<void> saveProject(ProjectRecord project) async {
    await database.saveProject(project);
    await refreshProjects();
  }

  Future<void> setFormalFlowStep(String projectId, int step) async {
    await database.setFormalFlowStep(projectId, step);
    await refreshProjects();
  }

  Future<void> deleteProject(String id) async {
    final paths = await database.deleteProject(id);
    await photoStorage.deletePaths(paths);
    await refreshProjects();
  }

  Future<List<IssueRecord>> loadIssues(String projectId) {
    return database.loadIssues(projectId);
  }

  Future<int> nextIssueSequence(String projectId) {
    return database.nextIssueSequence(projectId);
  }

  Future<void> saveIssue(IssueRecord issue) async {
    final deletedPaths = await database.saveIssue(issue);
    await photoStorage.deletePaths(deletedPaths);
    await refreshProjects();
  }

  Future<void> deleteIssue(String id) async {
    final paths = await database.deleteIssue(id);
    await photoStorage.deletePaths(paths);
    await refreshProjects();
  }

  Future<void> rememberReport(
    String projectId,
    String path,
    DateTime generatedAt,
  ) async {
    final previous = await database.rememberReport(
      projectId,
      path,
      generatedAt,
    );
    if (previous.isNotEmpty && previous != path) {
      try {
        await photoStorage.deletePaths([previous]);
      } catch (_) {
        // 新报告已成功记录；旧孤立 PDF 清理失败不影响本次生成结果。
      }
    }
    await refreshProjects();
  }

  Future<String> createBackup() {
    return backupService.create(database);
  }

  Future<void> restoreBackup(String path) async {
    await backupService.restore(path, database, photoStorage);
    await refreshProjects();
  }
}
