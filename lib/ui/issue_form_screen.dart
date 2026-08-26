import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../app_controller.dart';
import '../models.dart';
import 'annotation_editor_screen.dart';
import 'app_theme.dart';
import 'widgets/annotated_photo.dart';
import 'widgets/common.dart';

class IssueFormScreen extends StatefulWidget {
  const IssueFormScreen({
    required this.controller,
    required this.project,
    required this.sequence,
    this.issue,
    super.key,
  });

  final PhotoReportController controller;
  final ProjectRecord project;
  final int sequence;
  final IssueRecord? issue;

  @override
  State<IssueFormScreen> createState() => _IssueFormScreenState();
}

class _IssueFormScreenState extends State<IssueFormScreen> {
  final formKey = GlobalKey<FormState>();
  final picker = ImagePicker();
  late final String issueId;
  late final TextEditingController roomController;
  late final TextEditingController locationController;
  late final TextEditingController categoryController;
  late final TextEditingController descriptionController;
  late final TextEditingController assigneeController;
  late IssueSeverity severity;
  late IssueStatus status;
  late DateTime? dueDate;
  late List<PhotoRecord> photos;
  final Set<String> newPaths = {};
  bool committed = false;
  bool saving = false;

  String get issueCode =>
      widget.issue?.code ??
      '${widget.project.codePrefix}-${widget.sequence.toString().padLeft(3, '0')}';

  @override
  void initState() {
    super.initState();
    final issue = widget.issue;
    issueId = issue?.id ?? const Uuid().v4();
    roomController = TextEditingController(text: issue?.room ?? '');
    locationController = TextEditingController(text: issue?.location ?? '');
    categoryController = TextEditingController(text: issue?.category ?? '');
    descriptionController = TextEditingController(
      text: issue?.description ?? '',
    );
    assigneeController = TextEditingController(text: issue?.assignee ?? '施工方');
    severity = issue?.severity ?? IssueSeverity.medium;
    status = issue?.status ?? IssueStatus.pending;
    dueDate = issue?.dueDate;
    photos = [...?issue?.photos];
  }

  @override
  void dispose() {
    roomController.dispose();
    locationController.dispose();
    categoryController.dispose();
    descriptionController.dispose();
    assigneeController.dispose();
    if (!committed && newPaths.isNotEmpty) {
      unawaited(widget.controller.photoStorage.deletePaths(newPaths));
    }
    super.dispose();
  }

  Future<void> addPhoto(PhotoPhase phase) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('现场拍照'),
                subtitle: const Text('打开相机拍摄一张照片'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('从相册选择'),
                subtitle: const Text('导入已有的现场照片'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;
    try {
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 2400,
      );
      if (picked == null) return;
      final imported = await widget.controller.photoStorage.importPhoto(
        picked.path,
      );
      newPaths.add(imported);
      if (!mounted) return;
      setState(() {
        photos.add(
          PhotoRecord(
            id: const Uuid().v4(),
            issueId: issueId,
            path: imported,
            phase: phase,
            createdAt: DateTime.now(),
          ),
        );
      });
    } catch (error) {
      if (mounted) showErrorSnackBar(context, error);
    }
  }

  Future<void> editAnnotations(int index) async {
    final result = await Navigator.push<List<PhotoAnnotation>>(
      context,
      MaterialPageRoute(
        builder: (context) => AnnotationEditorScreen(photo: photos[index]),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => photos[index] = photos[index].copyWith(annotations: result));
  }

  Future<void> removePhoto(int index) async {
    final removed = photos[index];
    setState(() => photos.removeAt(index));
    if (newPaths.remove(removed.path)) {
      await widget.controller.photoStorage.deletePaths([removed.path]);
    }
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate() || saving) return;
    setState(() => saving = true);
    final now = DateTime.now();
    final original = widget.issue;
    final issue = IssueRecord(
      id: issueId,
      projectId: widget.project.id,
      sequence: original?.sequence ?? widget.sequence,
      code: issueCode,
      room: roomController.text.trim(),
      location: locationController.text.trim(),
      category: categoryController.text.trim(),
      severity: severity,
      description: descriptionController.text.trim(),
      status: status,
      assignee: assigneeController.text.trim(),
      dueDate: dueDate,
      createdAt: original?.createdAt ?? now,
      updatedAt: now,
      photos: photos.map((photo) => photo.copyWith(issueId: issueId)).toList(),
    );
    try {
      await widget.controller.saveIssue(issue);
      committed = true;
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => saving = false);
        showErrorSnackBar(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.issue == null ? '记录问题 $issueCode' : '编辑问题 $issueCode',
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : save,
            child: const Text(
              '保存',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: brandColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: brandColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      issueCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '编号由项目自动生成，删除问题后也不会重复使用。',
                      style: TextStyle(color: mutedColor, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const SectionHeader(title: '位置与问题', subtitle: '让施工方只看报告也能找到具体部位。'),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: roomController,
                    decoration: const InputDecoration(
                      labelText: '房间/区域 *',
                      hintText: '主卫',
                    ),
                    validator: _required,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: '具体位置 *',
                      hintText: '东侧墙面',
                    ),
                    validator: _required,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: '问题类型 *',
                hintText: '例如：瓷砖空鼓、墙面开裂、门窗安装',
              ),
              validator: _required,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descriptionController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: '问题描述 *',
                hintText: '描述现象、范围、尺寸或检测方式',
              ),
              validator: _required,
            ),
            const SizedBox(height: 22),
            const SectionHeader(title: '整改责任', subtitle: '明确优先级、当前进度和交付节点。'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<IssueSeverity>(
                    initialValue: severity,
                    decoration: const InputDecoration(labelText: '严重程度'),
                    items: IssueSeverity.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => severity = value!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<IssueStatus>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: '整改状态'),
                    items: IssueStatus.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => status = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: assigneeController,
                    decoration: const InputDecoration(labelText: '负责人/责任单位'),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                        initialDate:
                            dueDate ??
                            DateTime.now().add(const Duration(days: 7)),
                      );
                      if (picked != null) setState(() => dueDate = picked);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: '整改期限',
                        suffixIcon: dueDate == null
                            ? const Icon(
                                Icons.calendar_today_outlined,
                                size: 20,
                              )
                            : IconButton(
                                tooltip: '清除期限',
                                onPressed: () => setState(() => dueDate = null),
                                icon: const Icon(Icons.close_rounded, size: 18),
                              ),
                      ),
                      child: Text(
                        dueDate == null
                            ? '未设置'
                            : DateFormat('yyyy-MM-dd').format(dueDate!),
                        style: TextStyle(
                          color: dueDate == null ? mutedColor : inkColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _PhotoSection(
              phase: PhotoPhase.before,
              photos: photos,
              onAdd: () => addPhoto(PhotoPhase.before),
              onEdit: editAnnotations,
              onRemove: removePhoto,
            ),
            const SizedBox(height: 20),
            _PhotoSection(
              phase: PhotoPhase.after,
              photos: photos,
              onAdd: () => addPhoto(PhotoPhase.after),
              onEdit: editAnnotations,
              onRemove: removePhoto,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          onPressed: saving ? null : save,
          icon: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_rounded),
          label: Text(saving ? '正在保存…' : '保存问题记录'),
        ),
      ),
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? '此项必填' : null;
  }
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.phase,
    required this.photos,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  final PhotoPhase phase;
  final List<PhotoRecord> photos;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final indexed = <(int, PhotoRecord)>[
      for (var index = 0; index < photos.length; index++)
        if (photos[index].phase == phase) (index, photos[index]),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: '${phase.label}照片',
          subtitle: phase == PhotoPhase.before
              ? '保留问题原貌，可添加红框、箭头和文字。'
              : '关联处理结果，形成同一编号下的前后对比。',
          trailing: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_a_photo_outlined, size: 18),
            label: const Text('添加'),
          ),
        ),
        const SizedBox(height: 12),
        if (indexed.isEmpty)
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 108,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: lineColor),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: brandColor),
                  SizedBox(height: 7),
                  Text('拍照或从相册导入', style: TextStyle(color: mutedColor)),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 154,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: indexed.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, listIndex) {
                if (listIndex == indexed.length) {
                  return InkWell(
                    onTap: onAdd,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 88,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: lineColor),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, color: brandColor),
                          SizedBox(height: 5),
                          Text(
                            '继续添加',
                            style: TextStyle(color: mutedColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final (sourceIndex, photo) = indexed[listIndex];
                return SizedBox(
                  width: 176,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () => onEdit(sourceIndex),
                            child: AnnotatedPhoto(
                              path: photo.path,
                              annotations: photo.annotations,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.68),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              photo.annotations.isEmpty
                                  ? '点击标注'
                                  : '${photo.annotations.length} 个标注',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: IconButton.filled(
                            visualDensity: VisualDensity.compact,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(
                                alpha: 0.62,
                              ),
                              foregroundColor: Colors.white,
                            ),
                            tooltip: '移除照片',
                            onPressed: () => onRemove(sourceIndex),
                            icon: const Icon(Icons.close_rounded, size: 17),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
