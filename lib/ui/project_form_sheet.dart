import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models.dart';
import 'app_theme.dart';

class ProjectFormSheet extends StatefulWidget {
  const ProjectFormSheet({this.project, super.key});

  final ProjectRecord? project;

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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                      color: lineColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.project == null ? '新建检查项目' : '编辑项目信息',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: inkColor,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '项目资料会出现在正式报告封面与签名页。',
                  style: TextStyle(color: mutedColor),
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '项目名称 *',
                    hintText: '例如：云栖花园 8-1202 验收',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? '请输入项目名称' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: '项目地址 *',
                    hintText: '楼盘、楼栋及房号',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? '请输入项目地址' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDate: inspectionDate,
                    );
                    if (picked != null) setState(() => inspectionDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '检查日期',
                      suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                    ),
                    child: Text(
                      DateFormat('yyyy-MM-dd').format(inspectionDate),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: companyController,
                        decoration: const InputDecoration(labelText: '企业/团队名称'),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 104,
                      child: TextFormField(
                        controller: prefixController,
                        maxLength: 4,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: '编号前缀',
                          counterText: '',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? '必填' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: inspectorController,
                        decoration: const InputDecoration(labelText: '检查人'),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: clientController,
                        decoration: const InputDecoration(labelText: '业主/客户'),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: '补充说明',
                    hintText: '检查范围、交接约定或其他备注',
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: submit,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(widget.project == null ? '创建项目' : '保存修改'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
