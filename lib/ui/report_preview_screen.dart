import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../app_controller.dart';
import '../models.dart';
import '../report/report_service.dart';
import 'app_theme.dart';
import 'create_flow_logic.dart';
import 'widgets/common.dart';

class ReportPreviewScreen extends StatefulWidget {
  const ReportPreviewScreen({
    required this.controller,
    required this.project,
    required this.issues,
    this.initialLayout = ReportLayout.concise,
    this.reviewMode = false,
    super.key,
  });

  final PhotoReportController controller;
  final ProjectRecord project;
  final List<IssueRecord> issues;
  final ReportLayout initialLayout;
  final bool reviewMode;

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  final service = const ReportService();
  String? path;
  Object? error;
  bool generationInFlight = false;
  late bool generating;
  late ReportLayout layout;
  late bool includePosition;
  late bool includeStatus;
  late bool includeSeverity;
  late bool includeAssignee;
  late bool includeDueDate;
  late bool includeProjectDetails;
  late bool includeNotes;

  ReportOptions get options => ReportOptions(
    layout: layout,
    includePosition: includePosition,
    includeStatus: includeStatus,
    includeSeverity: includeSeverity,
    includeAssignee: includeAssignee,
    includeDueDate: includeDueDate,
    includeProjectDetails: includeProjectDetails,
    includeNotes: includeNotes,
  );

  @override
  void initState() {
    super.initState();
    layout = widget.initialLayout;
    final detailed = layout == ReportLayout.detailed;
    includePosition = detailed;
    includeStatus = detailed;
    includeSeverity = detailed;
    includeAssignee = detailed;
    includeDueDate = detailed;
    includeProjectDetails = detailed;
    includeNotes = detailed;
    generating = !widget.reviewMode;
    if (!widget.reviewMode) generate();
  }

  Future<void> generate() async {
    if (generationInFlight) return;
    generationInFlight = true;
    setState(() {
      generating = true;
      error = null;
    });
    try {
      final generated = await service.generateReport(
        widget.project,
        widget.issues,
        options,
      );
      await widget.controller.rememberReport(
        widget.project.id,
        generated,
        DateTime.now(),
      );
      if (widget.reviewMode) {
        await widget.controller.setFormalFlowStep(widget.project.id, 0);
      }
      generationInFlight = false;
      if (!mounted) return;
      setState(() {
        path = generated;
        generating = false;
      });
    } catch (caught) {
      generationInFlight = false;
      if (!mounted) return;
      setState(() {
        error = caught;
        generating = false;
      });
    }
  }

  void setLayout(ReportLayout value) {
    setState(() {
      layout = value;
      final detailed = value == ReportLayout.detailed;
      includePosition = detailed;
      includeStatus = detailed;
      includeSeverity = detailed;
      includeAssignee = detailed;
      includeDueDate = detailed;
      includeProjectDetails = detailed;
      includeNotes = detailed;
      path = null;
      error = null;
    });
  }

  void updateOption(VoidCallback update) {
    setState(() {
      update();
      path = null;
      error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.issues
        .where(
          (issue) =>
              issue.status == IssueStatus.pending ||
              issue.status == IssueStatus.inProgress,
        )
        .length;
    return Scaffold(
      appBar: AppBar(
        title: LText(widget.reviewMode ? '步骤 3/3 · 整理复核' : '整理分享'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.appColors.brandDeep,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.picture_as_pdf_outlined,
                  color: context.appColors.onBrandDeep,
                  size: 32,
                ),
                const SizedBox(height: 22),
                LText(
                  widget.project.name,
                  translate: false,
                  style: TextStyle(
                    color: context.appColors.onBrandDeep,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                LText(
                  widget.project.address.isEmpty
                      ? '地点尚未补充'
                      : widget.project.address,
                  translate: widget.project.address.isEmpty,
                  style: const TextStyle(color: onBrandMutedColor),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _ReportMetric(label: '记录总数', value: widget.issues.length),
                    const SizedBox(width: 10),
                    _ReportMetric(label: '待处理', value: pending),
                    const SizedBox(width: 10),
                    _ReportMetric(
                      label: '涉及区域',
                      value: widget.issues
                          .map((issue) => issue.room)
                          .where((room) => room.trim().isNotEmpty)
                          .toSet()
                          .length,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (widget.reviewMode) ...[
            _buildCompletenessCard(),
            const SizedBox(height: 20),
          ],
          SectionHeader(
            title: widget.reviewMode ? '选择正式输出' : '分享内容',
            subtitle: widget.reviewMode
                ? '默认使用完整记录；缺失项不会阻止生成，可返回继续补充。'
                : '默认只保留照片和说明，也可按需增加沟通字段。',
          ),
          const SizedBox(height: 14),
          _buildOptionsCard(),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: generating
                  ? Column(
                      children: [
                        const SizedBox(height: 6),
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        const LText('正在整理现场照片与说明…'),
                        const SizedBox(height: 6),
                        LText(
                          '全部在本机完成，无需上传照片。',
                          style: TextStyle(
                            color: context.appColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    )
                  : error != null
                  ? Column(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: context.appColors.risk,
                          size: 38,
                        ),
                        const SizedBox(height: 12),
                        const LText('PDF 生成失败'),
                        const SizedBox(height: 6),
                        LText(
                          AppLocalizations.errorText('$error'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.appColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: generate,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const LText('重新生成'),
                        ),
                      ],
                    )
                  : path == null
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            color: context.appColors.brand,
                            size: 34,
                          ),
                          const SizedBox(height: 10),
                          LText(
                            widget.reviewMode
                                ? '确认内容后生成 PDF'
                                : '选项已更新，请重新生成 PDF',
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: context.appColors.completed,
                          size: 42,
                        ),
                        const SizedBox(height: 12),
                        const LText(
                          'PDF 已生成',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 6),
                        LText(
                          p.basename(path!),
                          translate: false,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.appColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  try {
                                    await service.preview(path!);
                                  } catch (caught) {
                                    if (context.mounted) {
                                      showErrorSnackBar(context, caught);
                                    }
                                  }
                                },
                                icon: const Icon(Icons.visibility_outlined),
                                label: const LText('预览 PDF'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () async {
                                  try {
                                    await service.share(path!);
                                  } catch (caught) {
                                    if (context.mounted) {
                                      showErrorSnackBar(context, caught);
                                    }
                                  }
                                },
                                icon: const Icon(Icons.ios_share_rounded),
                                label: const LText('分享'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
          if (path != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: generating ? null : generate,
              icon: const Icon(Icons.refresh_rounded),
              label: const LText('按当前选项重新生成'),
            ),
          ],
          const SizedBox(height: 18),
          LText(
            '内容仅用于现场沟通与情况记录，不构成专业鉴定、验收结论或法律意见。',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appColors.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletenessCard() {
    final warnings = formalReadinessWarnings(widget.project, widget.issues);
    final ready = warnings.isEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  ready
                      ? Icons.check_circle_outline_rounded
                      : Icons.fact_check_outlined,
                  color: ready
                      ? context.appColors.completed
                      : context.appColors.brand,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: LText(
                    ready ? '资料完整，可以整理' : '${warnings.length} 项待确认',
                    style: TextStyle(
                      color: context.appColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LText(
              ready ? '项目资料和现场记录已具备完整输出条件。' : '这些是补充提醒，不会阻止继续生成：',
              style: TextStyle(color: context.appColors.muted, fontSize: 12),
            ),
            if (!ready) ...[
              const SizedBox(height: 10),
              for (final warning in warnings.take(6))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LText(
                        '• ',
                        style: TextStyle(color: context.appColors.brand),
                      ),
                      Expanded(
                        child: LText(
                          warning,
                          style: TextStyle(
                            color: context.appColors.ink,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (warnings.length > 6)
                LText(
                  '另有 ${warnings.length - 6} 项，可返回项目继续补充。',
                  style: TextStyle(
                    color: context.appColors.muted,
                    fontSize: 12,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LText(
              '版式',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: context.appColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  avatar: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const LText('简洁记录'),
                  selected: layout == ReportLayout.concise,
                  onSelected: generating
                      ? null
                      : (_) => setLayout(ReportLayout.concise),
                ),
                ChoiceChip(
                  avatar: const Icon(Icons.description_outlined, size: 18),
                  label: const LText('完整记录'),
                  selected: layout == ReportLayout.detailed,
                  onSelected: generating
                      ? null
                      : (_) => setLayout(ReportLayout.detailed),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LText(
              '包含字段',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: context.appColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _optionChip(
                  label: '位置',
                  selected: includePosition,
                  onChanged: (value) =>
                      updateOption(() => includePosition = value),
                ),
                _optionChip(
                  label: '状态',
                  selected: includeStatus,
                  onChanged: (value) =>
                      updateOption(() => includeStatus = value),
                ),
                _optionChip(
                  label: '优先级',
                  selected: includeSeverity,
                  onChanged: (value) =>
                      updateOption(() => includeSeverity = value),
                ),
                if (layout == ReportLayout.detailed) ...[
                  _optionChip(
                    label: '负责人',
                    selected: includeAssignee,
                    onChanged: (value) =>
                        updateOption(() => includeAssignee = value),
                  ),
                  _optionChip(
                    label: '期限',
                    selected: includeDueDate,
                    onChanged: (value) =>
                        updateOption(() => includeDueDate = value),
                  ),
                  _optionChip(
                    label: '项目资料',
                    selected: includeProjectDetails,
                    onChanged: (value) =>
                        updateOption(() => includeProjectDetails = value),
                  ),
                  _optionChip(
                    label: '补充说明',
                    selected: includeNotes,
                    onChanged: (value) =>
                        updateOption(() => includeNotes = value),
                  ),
                ],
              ],
            ),
            if (!generating && path == null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: generate,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const LText('按当前选项生成 PDF'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _optionChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onChanged,
  }) {
    return FilterChip(
      label: LText(label),
      selected: selected,
      onSelected: generating ? null : onChanged,
    );
  }
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 70),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: context.appColors.onBrandDeep.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LText(
              '$value',
              style: TextStyle(
                color: context.appColors.onBrandDeep,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 3),
            LText(
              label,
              maxLines: 2,
              style: const TextStyle(color: onBrandMutedColor, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
