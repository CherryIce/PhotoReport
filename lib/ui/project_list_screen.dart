import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../app_controller.dart';
import '../models.dart';
import '../report/report_service.dart';
import 'app_theme.dart';
import 'create_flow_sheet.dart';
import 'issue_form_screen.dart';
import 'project_detail_screen.dart';
import 'project_form_sheet.dart';
import 'widgets/common.dart';

class ProjectListScreen extends StatelessWidget {
  const ProjectListScreen({
    required this.controller,
    required this.preferredLocale,
    required this.onLocaleChanged,
    super.key,
  });

  final PhotoReportController controller;
  final Locale? preferredLocale;
  final ValueChanged<Locale?> onLocaleChanged;

  Future<ProjectRecord?> _editProject(
    BuildContext context, {
    ProjectRecord? project,
    bool formalFlow = false,
  }) async {
    final result = await showAppBottomSheet<ProjectRecord>(
      context: context,
      builder: (context) => ProjectFormSheet(
        project: project,
        formalFlow: formalFlow,
        suggestedNames: controller.projects
            .map((overview) => overview.project.name)
            .where((name) => name != project?.name)
            .toSet()
            .toList(),
      ),
    );
    if (result == null || !context.mounted) return null;
    try {
      await controller.saveProject(result);
      return result;
    } catch (error) {
      if (context.mounted) showErrorSnackBar(context, error);
      return null;
    }
  }

  Future<void> _openCreateFlow(BuildContext context) async {
    final choice = await showAppBottomSheet<CreateFlowChoice>(
      context: context,
      builder: (context) => CreateFlowSheet(
        projects: controller.projects
            .map((overview) => overview.project)
            .toList(),
      ),
    );
    if (choice == null || !context.mounted) return;
    if (choice.kind == CreateFlowKind.formal) {
      final created = await _editProject(context, formalFlow: true);
      if (created == null || !context.mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (context) => ProjectDetailScreen(
            controller: controller,
            initialProject: created,
            formalFlow: true,
            autoStartIssue: true,
          ),
        ),
      );
      await controller.refreshProjects();
      return;
    }

    var target = choice.project;
    if (target == null) {
      final name = await showAppBottomSheet<String>(
        context: context,
        builder: (context) => const QuickProjectNameSheet(),
      );
      if (name == null || !context.mounted) return;
      final now = DateTime.now();
      target = ProjectRecord(
        id: const Uuid().v4(),
        name: name,
        address: '',
        companyName: '',
        inspectorName: '',
        clientName: '',
        codePrefix: 'A',
        inspectionDate: now,
        notes: '',
        createdAt: now,
        updatedAt: now,
      );
      try {
        await controller.saveProject(target);
      } catch (error) {
        if (context.mounted) showErrorSnackBar(context, error);
        return;
      }
    }
    if (!context.mounted) return;
    await _openQuickIssue(context, target);
  }

  Future<void> _openQuickIssue(
    BuildContext context,
    ProjectRecord project,
  ) async {
    var addAnother = true;
    while (addAnother && context.mounted) {
      addAnother = false;
      try {
        final issues = await controller.loadIssues(project.id);
        final sequence = await controller.nextIssueSequence(project.id);
        if (!context.mounted) return;
        final result = await Navigator.push<IssueFormResult>(
          context,
          MaterialPageRoute(
            builder: (context) => IssueFormScreen(
              controller: controller,
              project: project,
              sequence: sequence,
              existingIssues: issues,
              entryMode: IssueEntryMode.quick,
              offerPostSaveActions: true,
            ),
          ),
        );
        await controller.refreshProjects();
        if (!context.mounted || result == null) return;
        if (result == IssueFormResult.savedAndAddAnother) {
          addAnother = true;
        } else if (result == IssueFormResult.savedAndOpenProject) {
          await Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailScreen(
                controller: controller,
                initialProject: project,
              ),
            ),
          );
        }
      } catch (error) {
        if (context.mounted) showErrorSnackBar(context, error);
        return;
      }
    }
  }

  Future<void> _deleteProject(
    BuildContext context,
    ProjectRecord project,
  ) async {
    final confirmed = await confirmAction(
      context,
      title: '删除“${project.name}”？',
      message: '项目内的记录、照片和标注都会从本机删除，此操作无法撤销。',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await controller.deleteProject(project.id);
    } catch (error) {
      if (context.mounted) showErrorSnackBar(context, error);
    }
  }

  Future<void> _createBackup(BuildContext context) async {
    final languageCode = Localizations.localeOf(context).languageCode;
    try {
      final path = await controller.createBackup();
      await const ReportService().share(path, languageCode: languageCode);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: LText('本地备份已生成，可保存到“文件”或发送到其他设备')),
        );
      }
    } catch (error) {
      if (context.mounted) showErrorSnackBar(context, error);
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    try {
      final path = await const ReportService().pickBackup(
        languageCode: Localizations.localeOf(context).languageCode,
      );
      if (path == null || !context.mounted) return;
      final confirmed = await confirmAction(
        context,
        title: '恢复这份本地备份？',
        message: '当前项目、记录和照片会被备份内容替换。建议先导出一份当前备份。',
        confirmLabel: '确认恢复',
      );
      if (!confirmed || !context.mounted) return;
      await controller.restoreBackup(path);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: LText('备份已恢复')));
      }
    } catch (error) {
      if (context.mounted) showErrorSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 72,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LText(
                  '现场照片记录',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                LText(
                  '编号 · 标注 · 整理分享',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                tooltip: tr('更多操作'),
                icon: const Icon(Icons.more_horiz_rounded),
                onSelected: (value) {
                  if (value == 'backup') _createBackup(context);
                  if (value == 'restore') _restoreBackup(context);
                  if (value == 'system') onLocaleChanged(null);
                  if (value == 'zh') {
                    onLocaleChanged(const Locale('zh', 'CN'));
                  }
                  if (value == 'en') onLocaleChanged(const Locale('en'));
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'backup',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.save_alt_rounded),
                      title: LText('导出本地备份'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'restore',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.restore_rounded),
                      title: LText('从备份恢复'),
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    enabled: false,
                    height: 36,
                    child: LText(
                      '语言',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'system',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        preferredLocale == null
                            ? Icons.check_rounded
                            : Icons.settings_suggest_rounded,
                        color: preferredLocale == null
                            ? context.appColors.brand
                            : null,
                      ),
                      title: const LText('跟随系统'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'zh',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        preferredLocale?.languageCode == 'zh'
                            ? Icons.check_rounded
                            : Icons.language_rounded,
                        color: preferredLocale?.languageCode == 'zh'
                            ? context.appColors.brand
                            : null,
                      ),
                      title: const LText('简体中文'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'en',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        preferredLocale?.languageCode == 'en'
                            ? Icons.check_rounded
                            : Icons.language_rounded,
                        color: preferredLocale?.languageCode == 'en'
                            ? context.appColors.brand
                            : null,
                      ),
                      title: const LText('English'),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: FilledButton.icon(
                  onPressed: () => _openCreateFlow(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const LText('新建'),
                ),
              ),
            ],
          ),
          body: _body(context),
        );
      },
    );
  }

  Widget _body(BuildContext context) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: context.appColors.muted,
              ),
              const SizedBox(height: 16),
              const LText('暂时无法读取本地项目'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: controller.initialize,
                child: const LText('重新载入'),
              ),
            ],
          ),
        ),
      );
    }
    if (controller.projects.isEmpty) {
      return _EmptyProjects(onCreate: () => _openCreateFlow(context));
    }
    return RefreshIndicator(
      onRefresh: controller.refreshProjects,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          const SectionHeader(
            title: '记录项目',
            subtitle: '每个地点独立整理，可继续补充照片并再次分享。',
          ),
          const SizedBox(height: 16),
          for (final overview in controller.projects) ...[
            _ProjectCard(
              overview: overview,
              onOpen: () async {
                await Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProjectDetailScreen(
                      controller: controller,
                      initialProject: overview.project,
                      formalFlow: overview.project.formalFlowStep > 0,
                    ),
                  ),
                );
                await controller.refreshProjects();
              },
              onEdit: () => _editProject(context, project: overview.project),
              onDelete: () => _deleteProject(context, overview.project),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          const _UsageNotice(),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.overview,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final ProjectOverview overview;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final project = overview.project;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: context.appColors.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.apartment_rounded,
                      color: context.appColors.brand,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LText(
                          project.name,
                          translate: false,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.appColors.ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LText(
                          project.address.isEmpty ? '地点待补充' : project.address,
                          translate: project.address.isEmpty,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.appColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: tr('项目操作'),
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: LText('编辑项目')),
                      PopupMenuItem(value: 'delete', child: LText('删除项目')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 16,
                    color: context.appColors.muted,
                  ),
                  const SizedBox(width: 6),
                  LText(
                    DateFormat('yyyy-MM-dd').format(project.inspectionDate),
                    translate: false,
                    style: TextStyle(
                      color: context.appColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (project.formalFlowStep > 0 || overview.highSeverity > 0) ...[
                const SizedBox(height: 9),
                Wrap(
                  spacing: 8,
                  runSpacing: 7,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (project.formalFlowStep > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: context.appColors.brand.withValues(
                            alpha: 0.09,
                          ),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: LText(
                          '正式记录 · 第 ${project.formalFlowStep}/3 步',
                          style: TextStyle(
                            color: context.appColors.brand,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (overview.highSeverity > 0)
                      LText(
                        '${overview.highSeverity} 项高优先级',
                        style: TextStyle(
                          color: context.appColors.risk,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: MetricTile(
                      value: overview.total,
                      label: '全部记录',
                      color: context.appColors.ink,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricTile(
                      value: overview.pending + overview.inProgress,
                      label: '待处理',
                      color: context.appColors.pending,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricTile(
                      value: overview.completed,
                      label: '已完成',
                      color: context.appColors.completed,
                      compact: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  const _EmptyProjects({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: context.appColors.brand.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.fact_check_outlined,
                size: 44,
                color: context.appColors.brand,
              ),
            ),
            const SizedBox(height: 22),
            LText(
              '从一个记录项目开始',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: context.appColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: LText(
                '现场边拍边编号，补充位置与说明，整理后直接生成便于沟通的照片记录。',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.appColors.muted, height: 1.55),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const LText('开始新建'),
            ),
            const SizedBox(height: 28),
            const _UsageNotice(),
          ],
        ),
      ),
    );
  }
}

class _UsageNotice extends StatelessWidget {
  const _UsageNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appColors.brand.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: context.appColors.brand,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: LText(
              '内容仅用于现场沟通与情况记录，不构成专业鉴定、验收结论或法律意见。数据默认保存在本机，可从右上角导出备份。',
              style: TextStyle(
                color: context.appColors.muted,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
