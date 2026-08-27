import 'package:flutter/material.dart';

import '../models.dart';
import 'app_theme.dart';

enum CreateFlowKind { quick, formal }

class CreateFlowChoice {
  const CreateFlowChoice({required this.kind, this.project});

  final CreateFlowKind kind;
  final ProjectRecord? project;
}

class CreateFlowSheet extends StatefulWidget {
  const CreateFlowSheet({required this.projects, super.key});

  final List<ProjectRecord> projects;

  @override
  State<CreateFlowSheet> createState() => _CreateFlowSheetState();
}

class _CreateFlowSheetState extends State<CreateFlowSheet> {
  late ProjectRecord? selectedProject;

  @override
  void initState() {
    super.initState();
    selectedProject = widget.projects.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            LText(
              '这次要怎样记录？',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: context.appColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            LText(
              '两种方式使用同一套项目和编号，快速记录以后也能随时补充完整。',
              style: TextStyle(color: context.appColors.muted),
            ),
            const SizedBox(height: 20),
            _FlowCard(
              icon: Icons.add_a_photo_outlined,
              title: '快速图文记录',
              subtitle: '照片加一句说明即可，适合现场连续记录。',
              badge: '约 1 分钟',
              emphasized: true,
              child: widget.projects.isEmpty
                  ? LText(
                      '首次使用时，再补一个简短的项目名称。',
                      style: TextStyle(
                        color: context.appColors.muted,
                        fontSize: 12,
                      ),
                    )
                  : DropdownButtonFormField<ProjectRecord>(
                      initialValue: selectedProject,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: tr('将保存到'),
                        isDense: true,
                      ),
                      items: widget.projects
                          .map(
                            (project) => DropdownMenuItem(
                              value: project,
                              child: LText(
                                project.name,
                                translate: false,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedProject = value),
                    ),
              onTap: () => Navigator.pop(
                context,
                CreateFlowChoice(
                  kind: CreateFlowKind.quick,
                  project: selectedProject,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _FlowCard(
              icon: Icons.fact_check_outlined,
              title: '正式记录',
              subtitle: '按项目资料、现场记录、整理复核三步完成。',
              badge: '3 个步骤',
              onTap: () => Navigator.pop(
                context,
                const CreateFlowChoice(kind: CreateFlowKind.formal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowCard extends StatelessWidget {
  const _FlowCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
    this.child,
    this.emphasized = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onTap;
  final Widget? child;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
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
                    color: context.appColors.brand.withValues(
                      alpha: emphasized ? 0.14 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: context.appColors.brand),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          LText(
                            title,
                            style: TextStyle(
                              color: context.appColors.ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: context.appColors.brand.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: LText(
                              badge,
                              style: TextStyle(
                                color: context.appColors.brand,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LText(
                        subtitle,
                        style: TextStyle(
                          color: context.appColors.muted,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (child != null) ...[const SizedBox(height: 15), child!],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: emphasized
                  ? FilledButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const LText('开始快速记录'),
                    )
                  : OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const LText('开始正式记录'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickProjectNameSheet extends StatefulWidget {
  const QuickProjectNameSheet({super.key});

  @override
  State<QuickProjectNameSheet> createState() => _QuickProjectNameSheetState();
}

class _QuickProjectNameSheetState extends State<QuickProjectNameSheet> {
  final formKey = GlobalKey<FormState>();
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void submit() {
    if (!formKey.currentState!.validate()) return;
    Navigator.pop(context, controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LText(
                  '先给这组记录起个名字',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: context.appColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                LText(
                  '其他项目资料可以稍后补充。',
                  style: TextStyle(color: context.appColors.muted),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: tr('项目名称 *'),
                    hintText: tr('例如：8 月 27 日现场记录'),
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => submit(),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? tr('请输入项目名称')
                      : null,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: submit,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const LText('继续添加照片'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
