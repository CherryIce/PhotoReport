import 'package:flutter/foundation.dart';

import 'data/app_database.dart';
import 'data/photo_storage.dart';
import 'models.dart';

class PhotoReportController extends ChangeNotifier {
  PhotoReportController({AppDatabase? database, PhotoStorage? photoStorage})
    : database = database ?? AppDatabase.instance,
      photoStorage = photoStorage ?? const PhotoStorage();

  final AppDatabase database;
  final PhotoStorage photoStorage;

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
}
