import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../models.dart';
import '../report/report_service.dart';
import 'app_theme.dart';
import 'widgets/common.dart';

class ReportPreviewScreen extends StatefulWidget {
  const ReportPreviewScreen({
    required this.project,
    required this.issues,
    super.key,
  });

  final ProjectRecord project;
  final List<IssueRecord> issues;

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  final service = const ReportService();
  String? path;
  Object? error;
  bool generating = true;

  @override
  void initState() {
    super.initState();
    generate();
  }

  Future<void> generate() async {
    setState(() {
      generating = true;
      error = null;
    });
    try {
      final generated = await service.generateReport(
        widget.project,
        widget.issues,
      );
      if (!mounted) return;
      setState(() {
        path = generated;
        generating = false;
      });
    } catch (caught) {
      if (!mounted) return;
      setState(() {
        error = caught;
        generating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.issues
        .where((issue) => issue.status != IssueStatus.completed)
        .length;
    return Scaffold(
      appBar: AppBar(title: const Text('生成正式报告')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B756B), Color(0xFF10564F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 22),
                Text(
                  widget.project.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.project.address,
                  style: const TextStyle(color: Color(0xFFD1E7E3)),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _ReportMetric(label: '问题总数', value: widget.issues.length),
                    const SizedBox(width: 10),
                    _ReportMetric(label: '待闭环', value: pending),
                    const SizedBox(width: 10),
                    _ReportMetric(
                      label: '涉及区域',
                      value: widget.issues
                          .map((issue) => issue.room)
                          .toSet()
                          .length,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(
            title: '报告内容',
            subtitle: '封面汇总、逐项问题、带标注照片、整改对比与签名页。',
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: generating
                  ? const Column(
                      children: [
                        SizedBox(height: 6),
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('正在排版现场照片与问题清单…'),
                        SizedBox(height: 6),
                        Text(
                          '全部在本机完成，无需上传照片。',
                          style: TextStyle(color: mutedColor, fontSize: 12),
                        ),
                        SizedBox(height: 6),
                      ],
                    )
                  : error != null
                  ? Column(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFC73A3A),
                          size: 38,
                        ),
                        const SizedBox(height: 12),
                        const Text('报告生成失败'),
                        const SizedBox(height: 6),
                        Text(
                          '$error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: mutedColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: generate,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('重新生成'),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF23855C),
                          size: 42,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'PDF 已生成',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.basename(path!),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: mutedColor,
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
                                label: const Text('预览 PDF'),
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
                                label: const Text('分享交付'),
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
              onPressed: generate,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('按最新记录重新生成'),
            ),
          ],
        ],
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(color: Color(0xFFD1E7E3), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
