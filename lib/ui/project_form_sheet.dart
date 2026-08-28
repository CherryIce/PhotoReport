import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models.dart';
import 'app_theme.dart';
import 'widgets/common.dart';

class ProjectFormSheet extends StatefulWidget {
  const ProjectFormSheet({
    this.project,
    this.suggestedNames = const [],
    this.formalFlow = false,
    super.key,
  });

  final ProjectRecord? project;
  final List<String> suggestedNames;
  final bool formalFlow;

  @override
  State<ProjectFormSheet> createState() => _ProjectFormSheetState();
}

class _ProjectFormSheetState extends State<ProjectFormSheet> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController addressController;
  late final TextEditingController companyController;
  late final TextEditingController inspectorController;
  late final TextEditingController clientController;
  late final TextEditingController prefixController;
  late final TextEditingController notesController;
  late DateTime inspectionDate;

  @override
  void initState() {
    super.initState();
    final project = widget.project;
    nameController = TextEditingController(text: project?.name ?? '');
    addressController = TextEditingController(text: project?.address ?? '');
    companyController = TextEditingController(text: project?.companyName ?? '');
    inspectorController = TextEditingController(
      text: project?.inspectorName ?? '',
    );
    clientController = TextEditingController(text: project?.clientName ?? '');
    prefixController = TextEditingController(text: project?.codePrefix ?? 'A');
    notesController = TextEditingController(text: project?.notes ?? '');
    inspectionDate = project?.inspectionDate ?? DateTime.now();
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    companyController.dispose();
    inspectorController.dispose();
    clientController.dispose();
    prefixController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void submit() {
    if (!formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final original = widget.project;
    Navigator.pop(
      context,
      ProjectRecord(
        id: original?.id ?? const Uuid().v4(),
        name: nameController.text.trim(),
        address: addressController.text.trim(),
        companyName: companyController.text.trim(),
        inspectorName: inspectorController.text.trim(),
        clientName: clientController.text.trim(),
        codePrefix: prefixController.text.trim().toUpperCase(),
        inspectionDate: inspectionDate,
        notes: notesController.text.trim(),
        createdAt: original?.createdAt ?? now,
        updatedAt: now,
        lastReportPath: original?.lastReportPath ?? '',
        lastReportAt: original?.lastReportAt,
        formalFlowStep: original?.formalFlowStep ?? (widget.formalFlow ? 2 : 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        key: const Key('project-form-scroll'),
        padding: AppInsets.scrollable(context, left: 20, top: 12, right: 20),
        child: Form(
          key: formKey,
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
                widget.project == null
                    ? widget.formalFlow
                          ? '步骤 1/3 · 项目资料'
                          : '新建记录项目'
                    : '编辑项目信息',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.appColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              LText(
                widget.formalFlow
                    ? '先确认项目基本资料，保存后继续添加现场记录。'
                    : '先填写名称和地点，其余资料可按实际沟通需要补充。',
                style: TextStyle(color: context.appColors.muted),
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: tr('项目名称 *'),
                  hintText: tr('例如：云栖花园 8-1202 现场记录'),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? tr('请输入项目名称')
                    : null,
                textInputAction: TextInputAction.next,
              ),
              if (widget.suggestedNames.isNotEmpty) ...[
                const SizedBox(height: 8),
                _ProjectNameSuggestions(
                  names: widget.suggestedNames,
                  onSelected: (value) => nameController.text = value,
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: tr('项目地址 *'),
                  hintText: tr('楼盘、楼栋及房号'),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? tr('请输入项目地址')
                    : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final picked = await showAppDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    initialDate: inspectionDate,
                    title: '选择记录日期',
                  );
                  if (picked != null) setState(() => inspectionDate = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: tr('记录日期'),
                    suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                  ),
                  child: LText(
                    DateFormat('yyyy-MM-dd').format(inspectionDate),
                    translate: false,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ResponsiveFieldRow(
                children: [
                  TextFormField(
                    controller: companyController,
                    decoration: InputDecoration(labelText: tr('企业/团队名称')),
                    textInputAction: TextInputAction.next,
                  ),
                  TextFormField(
                    controller: prefixController,
                    maxLength: 4,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: tr('编号前缀'),
                      counterText: '',
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? tr('必填') : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ResponsiveFieldRow(
                children: [
                  TextFormField(
                    controller: inspectorController,
                    decoration: InputDecoration(labelText: tr('记录人')),
                    textInputAction: TextInputAction.next,
                  ),
                  TextFormField(
                    controller: clientController,
                    decoration: InputDecoration(labelText: tr('业主/客户')),
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: tr('补充说明'),
                  hintText: tr('沟通范围、背景或其他备注'),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: submit,
                icon: const Icon(Icons.check_rounded),
                label: LText(
                  widget.project == null
                      ? widget.formalFlow
                            ? '保存并继续'
                            : '创建项目'
                      : '保存修改',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectNameSuggestions extends StatelessWidget {
  const _ProjectNameSuggestions({
    required this.names,
    required this.onSelected,
  });

  final List<String> names;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          LText(
            '复用标题',
            style: TextStyle(color: context.appColors.muted, fontSize: 12),
          ),
          const SizedBox(width: 8),
          for (final name in names.take(5)) ...[
            ActionChip(
              label: LText(name, translate: false),
              onPressed: () => onSelected(name),
            ),
            const SizedBox(width: 7),
          ],
        ],
      ),
    );
  }
}
