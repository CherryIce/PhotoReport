import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async {
    return _database ??= await _open();
  }

  Future<Database> _open() async {
    final base = await getDatabasesPath();
    return openDatabase(
      p.join(base, 'photo_report.db'),
      version: 4,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE projects (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            address TEXT NOT NULL,
            company_name TEXT NOT NULL,
            inspector_name TEXT NOT NULL,
            client_name TEXT NOT NULL,
            code_prefix TEXT NOT NULL,
            inspection_date INTEGER NOT NULL,
            notes TEXT NOT NULL,
            last_sequence INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            last_report_path TEXT NOT NULL DEFAULT '',
            last_report_at INTEGER,
            formal_flow_step INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE issues (
            id TEXT PRIMARY KEY,
            project_id TEXT NOT NULL,
            sequence INTEGER NOT NULL,
            code TEXT NOT NULL,
            room TEXT NOT NULL,
            location TEXT NOT NULL,
            category TEXT NOT NULL,
            severity TEXT NOT NULL,
            description TEXT NOT NULL,
            status TEXT NOT NULL,
            assignee TEXT NOT NULL,
            due_date INTEGER,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            UNIQUE(project_id, sequence),
            FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE photos (
            id TEXT PRIMARY KEY,
            issue_id TEXT NOT NULL,
            path TEXT NOT NULL,
            phase TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            annotations TEXT NOT NULL,
            FOREIGN KEY(issue_id) REFERENCES issues(id) ON DELETE CASCADE
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_issues_project ON issues(project_id, sequence)',
        );
        await db.execute(
          'CREATE INDEX idx_photos_issue ON photos(issue_id, created_at)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE projects ADD COLUMN last_sequence INTEGER NOT NULL DEFAULT 0',
          );
          await db.execute('''
            UPDATE projects
            SET last_sequence = COALESCE(
              (SELECT MAX(sequence) FROM issues WHERE project_id = projects.id),
              0
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE projects ADD COLUMN last_report_path TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            'ALTER TABLE projects ADD COLUMN last_report_at INTEGER',
          );
        }
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE projects ADD COLUMN formal_flow_step INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );
  }

  Future<List<ProjectOverview>> loadProjectOverviews() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT p.*,
        COUNT(i.id) AS total,
        SUM(CASE WHEN i.status = 'pending' THEN 1 ELSE 0 END) AS pending,
        SUM(CASE WHEN i.status = 'inProgress' THEN 1 ELSE 0 END) AS in_progress,
        SUM(CASE WHEN i.status = 'completed' THEN 1 ELSE 0 END) AS completed,
        SUM(CASE WHEN i.severity = 'high' THEN 1 ELSE 0 END) AS high_severity
      FROM projects p
      LEFT JOIN issues i ON i.project_id = p.id
      GROUP BY p.id
      ORDER BY p.updated_at DESC
    ''');
    int count(Map<String, Object?> row, String key) =>
        (row[key] as num?)?.toInt() ?? 0;
    return rows
        .map(
          (row) => ProjectOverview(
            project: ProjectRecord.fromMap(row),
            total: count(row, 'total'),
            pending: count(row, 'pending'),
            inProgress: count(row, 'in_progress'),
            completed: count(row, 'completed'),
            highSeverity: count(row, 'high_severity'),
          ),
        )
        .toList();
  }

  Future<void> saveProject(ProjectRecord project) async {
    final db = await database;
    final updated = await db.update(
      'projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
    if (updated == 0) await db.insert('projects', project.toMap());
  }

  Future<void> setFormalFlowStep(String projectId, int step) async {
    final db = await database;
    await db.update(
      'projects',
      {
        'formal_flow_step': step,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [projectId],
    );
  }

  Future<String> rememberReport(
    String projectId,
    String path,
    DateTime generatedAt,
  ) async {
    final db = await database;
    final rows = await db.query(
      'projects',
      columns: ['last_report_path'],
      where: 'id = ?',
      whereArgs: [projectId],
    );
    final previous = rows.isEmpty
        ? ''
        : rows.first['last_report_path'] as String? ?? '';
    await db.update(
      'projects',
      {
        'last_report_path': path,
        'last_report_at': generatedAt.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [projectId],
    );
    return previous;
  }

  Future<Map<String, Object?>> exportSnapshot() async {
    final db = await database;
    return {
      'projects': await db.query('projects', orderBy: 'created_at ASC'),
      'issues': await db.query('issues', orderBy: 'created_at ASC'),
      'photos': await db.query('photos', orderBy: 'created_at ASC'),
    };
  }

  Future<List<String>> restoreSnapshot(
    List<Map<String, Object?>> projects,
    List<Map<String, Object?>> issues,
    List<Map<String, Object?>> photos,
  ) async {
    final db = await database;
    return db.transaction((transaction) async {
      final oldPhotoRows = await transaction.query('photos', columns: ['path']);
      await transaction.delete('projects');
      for (final project in projects) {
        await transaction.insert('projects', project);
      }
      for (final issue in issues) {
        await transaction.insert('issues', issue);
      }
      for (final photo in photos) {
        await transaction.insert('photos', photo);
      }
      return oldPhotoRows.map((row) => row['path']! as String).toList();
    });
  }

  Future<List<String>> deleteProject(String id) async {
    final db = await database;
    final projectRows = await db.query(
      'projects',
      columns: ['last_report_path'],
      where: 'id = ?',
      whereArgs: [id],
    );
    final paths = await db.rawQuery(
      '''
      SELECT p.path FROM photos p
      INNER JOIN issues i ON p.issue_id = i.id
      WHERE i.project_id = ?
    ''',
      [id],
    );
    await db.delete('projects', where: 'id = ?', whereArgs: [id]);
    final deletedPaths = paths.map((row) => row['path']! as String).toList();
    if (projectRows.isNotEmpty) {
      final reportPath = projectRows.first['last_report_path'] as String? ?? '';
      if (reportPath.isNotEmpty) deletedPaths.add(reportPath);
    }
    return deletedPaths;
  }

  Future<List<IssueRecord>> loadIssues(String projectId) async {
    final db = await database;
    final issueRows = await db.query(
      'issues',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'sequence ASC',
    );
    if (issueRows.isEmpty) return [];
    final issueIds = issueRows.map((row) => row['id']! as String).toList();
    final placeholders = List.filled(issueIds.length, '?').join(',');
    final photoRows = await db.query(
      'photos',
      where: 'issue_id IN ($placeholders)',
      whereArgs: issueIds,
      orderBy: 'created_at ASC',
    );
    final photosByIssue = <String, List<PhotoRecord>>{};
    for (final row in photoRows) {
      final photo = PhotoRecord.fromMap(row);
      photosByIssue.putIfAbsent(photo.issueId, () => []).add(photo);
    }
    return issueRows
        .map(
          (row) => IssueRecord.fromMap(
            row,
            photos: photosByIssue[row['id']] ?? const [],
          ),
        )
        .toList();
  }

  Future<int> nextIssueSequence(String projectId) async {
    final db = await database;
    return db.transaction((transaction) async {
      final projectRows = await transaction.query(
        'projects',
        columns: ['last_sequence'],
        where: 'id = ?',
        whereArgs: [projectId],
      );
      if (projectRows.isEmpty) {
        throw StateError('项目不存在，无法分配问题编号');
      }
      final issueRows = await transaction.rawQuery(
        'SELECT MAX(sequence) AS max_sequence FROM issues WHERE project_id = ?',
        [projectId],
      );
      final reserved =
          (projectRows.first['last_sequence'] as num?)?.toInt() ?? 0;
      final existing = (issueRows.first['max_sequence'] as num?)?.toInt() ?? 0;
      return (reserved > existing ? reserved : existing) + 1;
    });
  }

  Future<List<String>> saveIssue(IssueRecord issue) async {
    final db = await database;
    return db.transaction((transaction) async {
      final oldPhotoRows = await transaction.query(
        'photos',
        columns: ['path'],
        where: 'issue_id = ?',
        whereArgs: [issue.id],
      );
      final updated = await transaction.update(
        'issues',
        issue.toMap(),
        where: 'id = ?',
        whereArgs: [issue.id],
      );
      if (updated == 0) {
        await transaction.insert('issues', issue.toMap());
        await transaction.rawUpdate(
          '''
            UPDATE projects
            SET last_sequence = CASE
              WHEN last_sequence < ? THEN ?
              ELSE last_sequence
            END
            WHERE id = ?
          ''',
          [issue.sequence, issue.sequence, issue.projectId],
        );
      }
      await transaction.delete(
        'photos',
        where: 'issue_id = ?',
        whereArgs: [issue.id],
      );
      for (final photo in issue.photos) {
        await transaction.insert(
          'photos',
          photo.copyWith(issueId: issue.id).toMap(),
        );
      }
      await transaction.update(
        'projects',
        {'updated_at': issue.updatedAt.millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [issue.projectId],
      );
      final retained = issue.photos.map((photo) => photo.path).toSet();
      return oldPhotoRows
          .map((row) => row['path']! as String)
          .where((path) => !retained.contains(path))
          .toList();
    });
  }

  Future<List<String>> deleteIssue(String id) async {
    final db = await database;
    final rows = await db.query(
      'photos',
      columns: ['path'],
      where: 'issue_id = ?',
      whereArgs: [id],
    );
    await db.delete('issues', where: 'id = ?', whereArgs: [id]);
    return rows.map((row) => row['path']! as String).toList();
  }
}
