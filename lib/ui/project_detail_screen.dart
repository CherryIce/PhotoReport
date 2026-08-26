import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_controller.dart';
import '../models.dart';
import 'app_theme.dart';
import 'issue_form_screen.dart';
import 'project_form_sheet.dart';
import 'report_preview_screen.dart';
import 'widgets/annotated_photo.dart';
import 'widgets/common.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({
    required this.controller,
    required this.initialProject,
    super.key,
  });

  final PhotoReportController controller;
  final ProjectRecord initialProject;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late ProjectRecord project;
  List<IssueRecord> issues = const [];
  bool loading = true;
  Object? error;
  IssueStatus? statusFilter;
  String roomFilter = '全部区域';
  String searchText = '';

  @override
  void initState() {
    super.initState();
    project = widget.initialProject;
    refresh();
  }

  Future<void> refresh() async {
    try {
      final loaded = await widget.controller.loadIssues(project.id);
      if (!mounted) return;
      setState(() {
        issues = loaded;
        loading = false;
        error = null;
        if (roomFilter != '全部区域' &&
            !loaded.any((issue) => issue.room == roomFilter)) {
          roomFilter = '全部区域';
        }
      });
    } catch (caught) {
      if (!mounted) return;
      setState(() {
        error = caught;
        loading = false;
      });
    }
  }

  List<IssueRecord> get filteredIssues {
    final query = searchText.trim().toLowerCase();
    return issues.where((issue) {
      if (statusFilter != null && issue.status != statusFilter) return false;
      if (roomFilter != '全部区域' && issue.room != roomFilter) return false;
      if (query.isEmpty) return true;
      return [
        issue.code,
        issue.room,
        issue.location,
        issue.category,
        issue.description,
        issue.assignee,
      ].any((value) => value.toLowerCase().contains(query));
    }).toList();
  }

  Future<void> editProject() async {
    final result = await showModalBottomSheet<ProjectRecord>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: canvasColor,
      showDragHandle: false,
      builder: (context) => ProjectFormSheet(project: project),
    );
    if (result == null || !mounted) return;
    try {
      await widget.controller.saveProject(result);
      if (mounted) setState(() => project = result);
    } catch (caught) {
      if (mounted) showErrorSnackBar(context, caught);
    }
  }

  Future<void> openIssue([IssueRecord? issue]) async {
    try {
      final sequence =
          issue?.sequence ??
          await widget.controller.nextIssueSequence(project.id);
      if (!mounted) return;
      final changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => IssueFormScreen(
            controller: widget.controller,
            project: project,
            sequence: sequence,
            issue: issue,
          ),
        ),
      );
      if (changed == true) await refresh();
    } catch (caught) {
      if (mounted) showErrorSnackBar(context, caught);
    }
  }

  Future<void> deleteIssue(IssueRecord issue) async {
    final confirmed = await confirmAction(
      context,
      title: '删除问题 ${issue.code}？',
      message: '对应的整改前后照片和全部标注也会从本机删除。',
    );
    if (!confirmed || !mounted) return;
    try {
      await widget.controller.deleteIssue(issue.id);
      await refresh();
    } catch (caught) {
      if (mounted) showErrorSnackBar(context, caught);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = issues
        .where((issue) => issue.status == IssueStatus.pending)
        .length;
    final inProgress = issues
        .where((issue) => issue.status == IssueStatus.inProgress)
        .length;
    final completed = issues
        .where((issue) => issue.status == IssueStatus.completed)
        .length;
    final rooms = issues.map((issue) => issue.room).toSet().toList()..sort();
    return Scaffold(
      appBar: AppBar(
        title: Text(project.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: '编辑项目',
            onPressed: editProject,
            icon: const Icon(Icons.edit_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? _LoadError(error: error!, onRetry: refresh)
          : RefreshIndicator(
              onRefresh: refresh,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProjectHeader(project: project),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: MetricTile(
                                  value: issues.length,
                                  label: '全部',
                                  color: inkColor,
                                  compact: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: MetricTile(
                                  value: pending,
                                  label: '待整改',
                                  color: const Color(0xFFCC6B22),
                                  compact: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: MetricTile(
                                  value: inProgress,
                                  label: '处理中',
                                  color: const Color(0xFF2C69B8),
                                  compact: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: MetricTile(
                                  value: completed,
                                  label: '已完成',
                                  color: const Color(0xFF23855C),
                                  compact: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: issues.isEmpty
                                  ? null
                                  : () => Navigator.push<void>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ReportPreviewScreen(
                                              project: project,
                                              issues: issues,
                                            ),
                                      ),
                                    ),
                              icon: const Icon(Icons.picture_as_pdf_outlined),
                              label: Text(
                                issues.isEmpty ? '记录问题后可生成报告' : '生成正式 PDF 报告',
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const SectionHeader(
                            title: '问题清单',
                            subtitle: '按编号追踪，每项都能回到具体位置与整改证据。',
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            onChanged: (value) =>
                                setState(() => searchText = value),
                            decoration: const InputDecoration(
                              hintText: '搜索编号、房间、问题或负责人',
                              prefixIcon: Icon(Icons.search_rounded),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ChoiceChip(
                                  label: const Text('全部状态'),
                                  selected: statusFilter == null,
                                  onSelected: (_) =>
                                      setState(() => statusFilter = null),
                                ),
                                const SizedBox(width: 7),
                                for (final status in IssueStatus.values) ...[
                                  ChoiceChip(
                                    label: Text(status.label),
                                    selected: statusFilter == status,
                                    onSelected: (_) => setState(
                                      () =>
                                          statusFilter = statusFilter == status
                                          ? null
                                          : status,
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                ],
                              ],
                            ),
                          ),
                          if (rooms.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final room in ['全部区域', ...rooms]) ...[
                                    FilterChip(
                                      label: Text(room),
                                      selected: roomFilter == room,
                                      onSelected: (_) =>
                                          setState(() => roomFilter = room),
                                    ),
                                    const SizedBox(width: 7),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                  if (issues.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyIssues(onCreate: openIssue),
                    )
                  else if (filteredIssues.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(34),
                        child: Column(
                          children: [
                            Icon(
                              Icons.filter_alt_off_outlined,
                              color: mutedColor,
                              size: 38,
                            ),
                            SizedBox(height: 10),
                            Text(
                              '当前筛选下没有问题',
                              style: TextStyle(color: mutedColor),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                      sliver: SliverList.separated(
                        itemCount: filteredIssues.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final issue = filteredIssues[index];
                          return _IssueCard(
                            issue: issue,
                            onOpen: () => openIssue(issue),
                            onDelete: () => deleteIssue(issue),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: loading || error != null
          ? null
          : FloatingActionButton.extended(
              onPressed: openIssue,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('记录问题'),
            ),
    );
  }
}

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({required this.project});

  final ProjectRecord project;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: brandColor,
                  size: 20,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    project.address,
                    style: const TextStyle(
                      color: inkColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 7,
              children: [
                _Meta(
                  icon: Icons.calendar_month_outlined,
                  text: DateFormat('yyyy-MM-dd').format(project.inspectionDate),
                ),
                if (project.inspectorName.isNotEmpty)
                  _Meta(
                    icon: Icons.badge_outlined,
                    text: '检查人：${project.inspectorName}',
                  ),
                if (project.clientName.isNotEmpty)
                  _Meta(
                    icon: Icons.person_outline_rounded,
                    text: '客户：${project.clientName}',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: mutedColor),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: mutedColor, fontSize: 12)),
      ],
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({
    required this.issue,
    required this.onOpen,
    required this.onDelete,
  });

  final IssueRecord issue;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final before = issue.photos
        .where((photo) => photo.phase == PhotoPhase.before)
        .firstOrNull;
    final afterCount = issue.photos
        .where((photo) => photo.phase == PhotoPhase.after)
        .length;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 104,
                height: 112,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: before == null
                      ? Container(
                          color: const Color(0xFFEAF0EE),
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: mutedColor,
                          ),
                        )
                      : AnnotatedPhoto(
                          path: before.path,
                          annotations: before.annotations,
                        ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: inkColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            issue.code,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        SeverityBadge(severity: issue.severity),
                        const Spacer(),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          tooltip: '问题操作',
                          onSelected: (value) {
                            if (value == 'edit') onOpen();
                            if (value == 'delete') onDelete();
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('编辑问题')),
                            PopupMenuItem(value: 'delete', child: Text('删除问题')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      issue.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: inkColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${issue.room} / ${issue.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: mutedColor, fontSize: 12),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        StatusBadge(status: issue.status),
                        if (afterCount > 0) ...[
                          const SizedBox(width: 7),
                          Text(
                            '$afterCount 张整改后',
                            style: const TextStyle(
                              color: Color(0xFF23855C),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyIssues extends StatelessWidget {
  const _EmptyIssues({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 30, 32, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.add_photo_alternate_outlined,
            color: brandColor,
            size: 48,
          ),
          const SizedBox(height: 14),
          const Text(
            '还没有现场问题',
            style: TextStyle(
              color: inkColor,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            '发现问题时立即记录位置、照片与整改责任。',
            textAlign: TextAlign.center,
            style: TextStyle(color: mutedColor),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('记录第一个问题'),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: mutedColor,
            ),
            const SizedBox(height: 12),
            Text('读取问题清单失败：$error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('重新载入')),
          ],
        ),
      ),
    );
  }
}
