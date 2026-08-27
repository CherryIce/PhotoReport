import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_controller.dart';
import '../models.dart';
import '../report/report_service.dart';
import 'app_theme.dart';
import 'create_flow_logic.dart';
import 'issue_form_screen.dart';
import 'project_form_sheet.dart';
import 'report_preview_screen.dart';
import 'widgets/annotated_photo.dart';
import 'widgets/common.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({
    required this.controller,
    required this.initialProject,
    this.formalFlow = false,
    this.autoStartIssue = false,
    super.key,
  });

  final PhotoReportController controller;
  final ProjectRecord initialProject;
  final bool formalFlow;
  final bool autoStartIssue;

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
  bool didAutoStartIssue = false;
  late bool formalFlowActive;

  @override
  void initState() {
    super.initState();
    project = widget.initialProject;
    formalFlowActive = widget.formalFlow || project.formalFlowStep > 0;
    _initialize();
  }

  Future<void> _initialize() async {
    await refresh();
    if (!mounted || !widget.autoStartIssue || didAutoStartIssue) return;
    didAutoStartIssue = true;
    await openIssue(entryMode: IssueEntryMode.formal);
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
    final result = await showAppBottomSheet<ProjectRecord>(
      context: context,
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

  Future<void> openIssue({
    IssueRecord? issue,
    IssueEntryMode? entryMode,
  }) async {
    try {
      final sequence =
          issue?.sequence ??
          await widget.controller.nextIssueSequence(project.id);
      if (!mounted) return;
      final mode =
          entryMode ??
          (issue != null && hasFormalCoreFields(issue)
              ? IssueEntryMode.formal
              : formalFlowActive
              ? IssueEntryMode.formal
              : IssueEntryMode.quick);
      final result = await Navigator.push<IssueFormResult>(
        context,
        MaterialPageRoute(
          builder: (context) => IssueFormScreen(
            controller: widget.controller,
            project: project,
            sequence: sequence,
            existingIssues: issues,
            issue: issue,
            entryMode: mode,
            offerPostSaveActions: issue == null && mode == IssueEntryMode.quick,
          ),
        ),
      );
      if (result != null) await refresh();
      if (mounted && result == IssueFormResult.savedAndAddAnother) {
        await openIssue(entryMode: mode);
      }
    } catch (caught) {
      if (mounted) showErrorSnackBar(context, caught);
    }
  }

  Future<void> deleteIssue(IssueRecord issue) async {
    final confirmed = await confirmAction(
      context,
      title: '删除记录 ${issue.code}？',
      message: '对应的前后照片和全部标注也会从本机删除。',
    );
    if (!confirmed || !mounted) return;
    try {
      await widget.controller.deleteIssue(issue.id);
      await refresh();
    } catch (caught) {
      if (mounted) showErrorSnackBar(context, caught);
    }
  }

  Future<void> openReport() async {
    final formal = formalFlowActive;
    if (formal && project.formalFlowStep != 3) {
      await widget.controller.setFormalFlowStep(project.id, 3);
      project = project.copyWith(formalFlowStep: 3);
    }
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPreviewScreen(
          controller: widget.controller,
          project: project,
          issues: issues,
          initialLayout: formal ? ReportLayout.detailed : ReportLayout.concise,
          reviewMode: formal,
        ),
      ),
    );
    if (!mounted) return;
    final latest = widget.controller.projects
        .where((overview) => overview.project.id == project.id)
        .firstOrNull;
    if (latest != null) {
      setState(() {
        project = latest.project;
        formalFlowActive = latest.project.formalFlowStep > 0;
      });
    }
  }

  Future<void> useRecentReport({required bool share}) async {
    try {
      final service = const ReportService();
      if (share) {
        await service.share(project.lastReportPath);
      } else {
        await service.preview(project.lastReportPath);
      }
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
    final rooms =
        issues
            .map((issue) => issue.room.trim())
            .where((room) => room.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return Scaffold(
      appBar: AppBar(
        title: LText(
          project.name,
          translate: false,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: tr('编辑项目'),
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
                          if (formalFlowActive) ...[
                            _FormalFlowBanner(
                              step: project.formalFlowStep == 3 ? 3 : 2,
                              issueCount: issues.length,
                            ),
                            const SizedBox(height: 12),
                          ],
                          _ProjectHeader(project: project),
                          const SizedBox(height: 14),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final columns =
                                  AppLocalizations.isEnglish() &&
                                      constraints.maxWidth < 520
                                  ? 2
                                  : 4;
                              final width =
                                  (constraints.maxWidth - (columns - 1) * 8) /
                                  columns;
                              final metrics = [
                                (
                                  value: issues.length,
                                  label: '全部',
                                  color: context.appColors.ink,
                                ),
                                (
                                  value: pending,
                                  label: '待处理',
                                  color: context.appColors.pending,
                                ),
                                (
                                  value: inProgress,
                                  label: '处理中',
                                  color: context.appColors.inProgress,
                                ),
                                (
                                  value: completed,
                                  label: '已完成',
                                  color: context.appColors.completed,
                                ),
                              ];
                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final metric in metrics)
                                    SizedBox(
                                      width: width,
                                      child: MetricTile(
                                        value: metric.value,
                                        label: metric.label,
                                        color: metric.color,
                                        compact: true,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: issues.isEmpty ? null : openReport,
                              icon: const Icon(Icons.picture_as_pdf_outlined),
                              label: LText(
                                issues.isEmpty
                                    ? '添加记录后可整理分享'
                                    : formalFlowActive
                                    ? '步骤 3：整理复核'
                                    : '整理并生成 PDF',
                              ),
                            ),
                          ),
                          if (project.lastReportPath.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Card(
                              child: ListTile(
                                leading: Icon(
                                  Icons.history_rounded,
                                  color: context.appColors.brand,
                                ),
                                title: const LText('最近生成的沟通记录'),
                                subtitle: LText(
                                  project.lastReportAt == null
                                      ? '可直接再次预览或分享'
                                      : '${DateFormat('yyyy-MM-dd HH:mm').format(project.lastReportAt!)} 生成',
                                ),
                                trailing: Wrap(
                                  spacing: 2,
                                  children: [
                                    IconButton(
                                      tooltip: tr('预览最近 PDF'),
                                      onPressed: () =>
                                          useRecentReport(share: false),
                                      icon: const Icon(
                                        Icons.visibility_outlined,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: tr('再次分享'),
                                      onPressed: () =>
                                          useRecentReport(share: true),
                                      icon: const Icon(Icons.ios_share_rounded),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          const SectionHeader(
                            title: '照片记录',
                            subtitle: '按编号整理，每项都能回到具体位置与前后照片。',
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            onChanged: (value) =>
                                setState(() => searchText = value),
                            decoration: InputDecoration(
                              hintText: tr('搜索编号、区域、标题或负责人'),
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
                                  label: const LText('全部状态'),
                                  selected: statusFilter == null,
                                  onSelected: (_) =>
                                      setState(() => statusFilter = null),
                                ),
                                const SizedBox(width: 7),
                                for (final status in IssueStatus.values) ...[
                                  ChoiceChip(
                                    label: LText(status.label),
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
                                      label: LText(
                                        room,
                                        translate: room == '全部区域',
                                      ),
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
                      child: _EmptyIssues(
                        onCreate: () => openIssue(
                          entryMode: formalFlowActive
                              ? IssueEntryMode.formal
                              : IssueEntryMode.quick,
                        ),
                      ),
                    )
                  else if (filteredIssues.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(34),
                        child: Column(
                          children: [
                            Icon(
                              Icons.filter_alt_off_outlined,
                              color: context.appColors.muted,
                              size: 38,
                            ),
                            SizedBox(height: 10),
                            LText(
                              '当前筛选下没有记录',
                              style: TextStyle(color: context.appColors.muted),
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
                            onOpen: () => openIssue(issue: issue),
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
              onPressed: () => openIssue(
                entryMode: formalFlowActive
                    ? IssueEntryMode.formal
                    : IssueEntryMode.quick,
              ),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: LText(formalFlowActive ? '添加记录' : '快速记录'),
            ),
    );
  }
}

class _FormalFlowBanner extends StatelessWidget {
  const _FormalFlowBanner({required this.step, required this.issueCount});

  final int step;
  final int issueCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: context.appColors.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.appColors.brand,
              borderRadius: BorderRadius.circular(13),
            ),
            child: LText(
              '$step/3',
              style: TextStyle(
                color: context.appColors.onBrand,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LText(
                  step == 3 ? '整理复核' : '添加现场记录',
                  style: TextStyle(
                    color: context.appColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                LText(
                  step == 3
                      ? '检查缺失项后生成完整记录。'
                      : issueCount == 0
                      ? '先添加第一条记录，可随时暂存退出。'
                      : '已添加 $issueCount 条，可继续添加或进入整理复核。',
                  style: TextStyle(
                    color: context.appColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                Icon(
                  Icons.location_on_outlined,
                  color: context.appColors.brand,
                  size: 20,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: LText(
                    project.address.isEmpty ? '地点待补充' : project.address,
                    translate: project.address.isEmpty,
                    style: TextStyle(
                      color: context.appColors.ink,
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
                    text: '记录人：${project.inspectorName}',
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
        Icon(icon, size: 16, color: context.appColors.muted),
        const SizedBox(width: 5),
        LText(
          text,
          style: TextStyle(color: context.appColors.muted, fontSize: 12),
        ),
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
                          color: context.appColors.softSurface,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: context.appColors.muted,
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
                            color: context.appColors.ink,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: LText(
                            issue.code,
                            translate: false,
                            style: TextStyle(
                              color: context.appColors.canvas,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: SeverityBadge(severity: issue.severity),
                        ),
                        const SizedBox(width: 2),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          tooltip: tr('记录操作'),
                          onSelected: (value) {
                            if (value == 'edit') onOpen();
                            if (value == 'delete') onDelete();
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: LText('编辑记录')),
                            PopupMenuItem(
                              value: 'delete',
                              child: LText('删除记录'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LText(
                      issue.category.isEmpty ? '图文记录' : issue.category,
                      translate: issue.category.isEmpty,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    LText(
                      issueLocationLabel(issue),
                      translate:
                          issue.room.trim().isEmpty &&
                          issue.location.trim().isEmpty,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 7,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusBadge(status: issue.status),
                        if (afterCount > 0)
                          LText(
                            '$afterCount 张处理后',
                            style: TextStyle(
                              color: context.appColors.completed,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
          Icon(
            Icons.add_photo_alternate_outlined,
            color: context.appColors.brand,
            size: 48,
          ),
          const SizedBox(height: 14),
          LText(
            '还没有现场记录',
            style: TextStyle(
              color: context.appColors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 7),
          LText(
            '拍照、写下位置与说明，需要时再补充负责人和期限。',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appColors.muted),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const LText('添加第一条记录'),
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
            Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: context.appColors.muted,
            ),
            const SizedBox(height: 12),
            LText('读取照片记录失败：$error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const LText('重新载入')),
          ],
        ),
      ),
    );
  }
}
