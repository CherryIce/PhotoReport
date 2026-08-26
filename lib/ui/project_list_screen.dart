import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_controller.dart';
import '../models.dart';
import 'app_theme.dart';
import 'project_detail_screen.dart';
import 'project_form_sheet.dart';
import 'widgets/common.dart';

class ProjectListScreen extends StatelessWidget {
  const ProjectListScreen({required this.controller, super.key});

  final PhotoReportController controller;

  Future<void> _editProject(
    BuildContext context, {
    ProjectRecord? project,
  }) async {
    final result = await showModalBottomSheet<ProjectRecord>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: canvasColor,
      showDragHandle: false,
      builder: (context) => ProjectFormSheet(project: project),
    );
    if (result == null || !context.mounted) return;
    try {
      await controller.saveProject(result);
    } catch (error) {
      if (context.mounted) showErrorSnackBar(context, error);
    }
  }

  Future<void> _deleteProject(
    BuildContext context,
    ProjectRecord project,
  ) async {
    final confirmed = await confirmAction(
      context,
      title: '删除“${project.name}”？',
      message: '项目内的问题、照片和标注都会从本机删除，此操作无法撤销。',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await controller.deleteProject(project.id);
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
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('现场报告'),
                SizedBox(height: 2),
                Text(
                  '留证 · 整改 · 正式交付',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: FilledButton.icon(
                  onPressed: () => _editProject(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('新建项目'),
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
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: mutedColor,
              ),
              const SizedBox(height: 16),
              const Text('暂时无法读取本地项目'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: controller.initialize,
                child: const Text('重新载入'),
              ),
            ],
          ),
        ),
      );
    }
    if (controller.projects.isEmpty) {
      return _EmptyProjects(onCreate: () => _editProject(context));
    }
    return RefreshIndicator(
      onRefresh: controller.refreshProjects,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          const SectionHeader(
            title: '检查项目',
            subtitle: '每个项目独立归档，可随时补录整改结果并再次导出。',
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
                      color: brandColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: brandColor,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: inkColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          project.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: mutedColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: '项目操作',
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('编辑项目')),
                      PopupMenuItem(value: 'delete', child: Text('删除项目')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 16,
                    color: mutedColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('yyyy-MM-dd').format(project.inspectionDate),
                    style: const TextStyle(color: mutedColor, fontSize: 13),
                  ),
                  const Spacer(),
                  if (overview.highSeverity > 0)
                    Text(
                      '${overview.highSeverity} 项高风险',
                      style: const TextStyle(
                        color: Color(0xFFC73A3A),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: MetricTile(
                      value: overview.total,
                      label: '全部问题',
                      color: inkColor,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricTile(
                      value: overview.pending + overview.inProgress,
                      label: '待闭环',
                      color: const Color(0xFFCC6B22),
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricTile(
                      value: overview.completed,
                      label: '已完成',
                      color: const Color(0xFF23855C),
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
                color: brandColor.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.fact_check_outlined,
                size: 44,
                color: brandColor,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              '从一个检查项目开始',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: inkColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: const Text(
                '现场边拍边编号，记录位置、责任人和整改期限，结束后直接交付正式报告。',
                textAlign: TextAlign.center,
                style: TextStyle(color: mutedColor, height: 1.55),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('新建检查项目'),
            ),
          ],
        ),
      ),
    );
  }
}
