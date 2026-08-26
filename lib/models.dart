import 'dart:convert';

enum IssueSeverity { low, medium, high }

enum IssueStatus { pending, inProgress, completed }

enum PhotoPhase { before, after }

enum AnnotationKind { rectangle, arrow, text }

extension IssueSeverityLabel on IssueSeverity {
  String get label => switch (this) {
    IssueSeverity.low => '低',
    IssueSeverity.medium => '中',
    IssueSeverity.high => '高',
  };
}

extension IssueStatusLabel on IssueStatus {
  String get label => switch (this) {
    IssueStatus.pending => '待整改',
    IssueStatus.inProgress => '处理中',
    IssueStatus.completed => '已完成',
  };
}

extension PhotoPhaseLabel on PhotoPhase {
  String get label => this == PhotoPhase.before ? '整改前' : '整改后';
}

class PhotoAnnotation {
  const PhotoAnnotation({
    required this.kind,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    this.text = '',
  });

  final AnnotationKind kind;
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final String text;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'x1': x1,
    'y1': y1,
    'x2': x2,
    'y2': y2,
    'text': text,
  };

  factory PhotoAnnotation.fromJson(Map<String, Object?> json) {
    return PhotoAnnotation(
      kind: AnnotationKind.values.byName(json['kind']! as String),
      x1: (json['x1']! as num).toDouble(),
      y1: (json['y1']! as num).toDouble(),
      x2: (json['x2']! as num).toDouble(),
      y2: (json['y2']! as num).toDouble(),
      text: json['text'] as String? ?? '',
    );
  }
}

class PhotoRecord {
  const PhotoRecord({
    required this.id,
    required this.issueId,
    required this.path,
    required this.phase,
    required this.createdAt,
    this.annotations = const [],
  });

  final String id;
  final String issueId;
  final String path;
  final PhotoPhase phase;
  final DateTime createdAt;
  final List<PhotoAnnotation> annotations;

  PhotoRecord copyWith({
    String? issueId,
    PhotoPhase? phase,
    List<PhotoAnnotation>? annotations,
  }) {
    return PhotoRecord(
      id: id,
      issueId: issueId ?? this.issueId,
      path: path,
      phase: phase ?? this.phase,
      createdAt: createdAt,
      annotations: annotations ?? this.annotations,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'issue_id': issueId,
    'path': path,
    'phase': phase.name,
    'created_at': createdAt.millisecondsSinceEpoch,
    'annotations': jsonEncode(
      annotations.map((annotation) => annotation.toJson()).toList(),
    ),
  };

  factory PhotoRecord.fromMap(Map<String, Object?> map) {
    final annotationJson =
        jsonDecode(map['annotations'] as String? ?? '[]') as List<dynamic>;
    return PhotoRecord(
      id: map['id']! as String,
      issueId: map['issue_id']! as String,
      path: map['path']! as String,
      phase: PhotoPhase.values.byName(map['phase']! as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
      annotations: annotationJson
          .map(
            (value) => PhotoAnnotation.fromJson(
              Map<String, Object?>.from(value as Map),
            ),
          )
          .toList(),
    );
  }
}

class IssueRecord {
  const IssueRecord({
    required this.id,
    required this.projectId,
    required this.sequence,
    required this.code,
    required this.room,
    required this.location,
    required this.category,
    required this.severity,
    required this.description,
    required this.status,
    required this.assignee,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.photos = const [],
  });

  final String id;
  final String projectId;
  final int sequence;
  final String code;
  final String room;
  final String location;
  final String category;
  final IssueSeverity severity;
  final String description;
  final IssueStatus status;
  final String assignee;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PhotoRecord> photos;

  IssueRecord copyWith({
    String? room,
    String? location,
    String? category,
    IssueSeverity? severity,
    String? description,
    IssueStatus? status,
    String? assignee,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? updatedAt,
    List<PhotoRecord>? photos,
  }) {
    return IssueRecord(
      id: id,
      projectId: projectId,
      sequence: sequence,
      code: code,
      room: room ?? this.room,
      location: location ?? this.location,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      status: status ?? this.status,
      assignee: assignee ?? this.assignee,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      photos: photos ?? this.photos,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'project_id': projectId,
    'sequence': sequence,
    'code': code,
    'room': room,
    'location': location,
    'category': category,
    'severity': severity.name,
    'description': description,
    'status': status.name,
    'assignee': assignee,
    'due_date': dueDate?.millisecondsSinceEpoch,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  factory IssueRecord.fromMap(
    Map<String, Object?> map, {
    List<PhotoRecord> photos = const [],
  }) {
    return IssueRecord(
      id: map['id']! as String,
      projectId: map['project_id']! as String,
      sequence: map['sequence']! as int,
      code: map['code']! as String,
      room: map['room']! as String,
      location: map['location']! as String,
      category: map['category']! as String,
      severity: IssueSeverity.values.byName(map['severity']! as String),
      description: map['description']! as String,
      status: IssueStatus.values.byName(map['status']! as String),
      assignee: map['assignee']! as String,
      dueDate: map['due_date'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['due_date']! as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
      photos: photos,
    );
  }
}

class ProjectRecord {
  const ProjectRecord({
    required this.id,
    required this.name,
    required this.address,
    required this.companyName,
    required this.inspectorName,
    required this.clientName,
    required this.codePrefix,
    required this.inspectionDate,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String address;
  final String companyName;
  final String inspectorName;
  final String clientName;
  final String codePrefix;
  final DateTime inspectionDate;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'address': address,
    'company_name': companyName,
    'inspector_name': inspectorName,
    'client_name': clientName,
    'code_prefix': codePrefix,
    'inspection_date': inspectionDate.millisecondsSinceEpoch,
    'notes': notes,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  factory ProjectRecord.fromMap(Map<String, Object?> map) {
    return ProjectRecord(
      id: map['id']! as String,
      name: map['name']! as String,
      address: map['address']! as String,
      companyName: map['company_name']! as String,
      inspectorName: map['inspector_name']! as String,
      clientName: map['client_name']! as String,
      codePrefix: map['code_prefix']! as String,
      inspectionDate: DateTime.fromMillisecondsSinceEpoch(
        map['inspection_date']! as int,
      ),
      notes: map['notes']! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
    );
  }
}

class ProjectOverview {
  const ProjectOverview({
    required this.project,
    required this.total,
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.highSeverity,
  });

  final ProjectRecord project;
  final int total;
  final int pending;
  final int inProgress;
  final int completed;
  final int highSeverity;
}
