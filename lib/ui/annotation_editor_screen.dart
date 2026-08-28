import 'dart:io';

import 'package:flutter/material.dart';

import '../models.dart';
import 'app_theme.dart';
import 'widgets/annotated_photo.dart';
import 'widgets/common.dart';

class AnnotationEditorScreen extends StatefulWidget {
  const AnnotationEditorScreen({required this.photo, super.key});

  final PhotoRecord photo;

  @override
  State<AnnotationEditorScreen> createState() => _AnnotationEditorScreenState();
}

class _AnnotationEditorScreenState extends State<AnnotationEditorScreen> {
  late final Future<Size> imageSize;
  late List<PhotoAnnotation> annotations;
  AnnotationKind selectedKind = AnnotationKind.rectangle;
  int selectedColorValue = defaultPhotoAnnotationColorValue;
  Offset? dragStart;
  Offset? dragCurrent;

  @override
  void initState() {
    super.initState();
    annotations = [...widget.photo.annotations];
    imageSize = readImageSize(widget.photo.path);
  }

  Offset _normalized(Offset position, Size size) {
    return Offset(
      (position.dx / size.width).clamp(0, 1),
      (position.dy / size.height).clamp(0, 1),
    );
  }

  Future<void> _addText(Offset position, Size size) async {
    final colorValue = selectedColorValue;
    final text = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: false,
      builder: (context) => const _TextAnnotationSheet(),
    );
    if (!mounted || text == null || text.isEmpty) return;
    final point = _normalized(position, size);
    setState(() {
      annotations.add(
        PhotoAnnotation(
          kind: AnnotationKind.text,
          x1: point.dx,
          y1: point.dy,
          x2: point.dx,
          y2: point.dy,
          text: text,
          colorValue: colorValue,
        ),
      );
    });
  }

  void _finishDrag(Size size) {
    if (dragStart == null || dragCurrent == null) return;
    if ((dragCurrent! - dragStart!).distance < 12) {
      setState(() {
        dragStart = null;
        dragCurrent = null;
      });
      return;
    }
    final start = _normalized(dragStart!, size);
    final end = _normalized(dragCurrent!, size);
    setState(() {
      annotations.add(
        PhotoAnnotation(
          kind: selectedKind,
          x1: start.dx,
          y1: start.dy,
          x2: end.dx,
          y2: end.dy,
          colorValue: selectedColorValue,
        ),
      );
      dragStart = null;
      dragCurrent = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: editorCanvasColor,
      appBar: AppBar(
        backgroundColor: editorCanvasColor,
        foregroundColor: Colors.white,
        title: const LText('标注照片重点'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, annotations),
            child: const LText(
              '完成',
              style: TextStyle(
                color: editorAccentColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<Size>(
                future: imageSize,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final fitted = fitSize(
                        snapshot.data!,
                        constraints.biggest,
                      );
                      final draft = dragStart == null || dragCurrent == null
                          ? null
                          : PhotoAnnotation(
                              kind: selectedKind,
                              x1: dragStart!.dx / fitted.width,
                              y1: dragStart!.dy / fitted.height,
                              x2: dragCurrent!.dx / fitted.width,
                              y2: dragCurrent!.dy / fitted.height,
                              colorValue: selectedColorValue,
                            );
                      return Center(
                        child: SizedBox(
                          width: fitted.width,
                          height: fitted.height,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: selectedKind == AnnotationKind.text
                                ? (details) =>
                                      _addText(details.localPosition, fitted)
                                : null,
                            onPanStart: selectedKind == AnnotationKind.text
                                ? null
                                : (details) => setState(() {
                                    dragStart = details.localPosition;
                                    dragCurrent = details.localPosition;
                                  }),
                            onPanUpdate: selectedKind == AnnotationKind.text
                                ? null
                                : (details) => setState(
                                    () => dragCurrent = details.localPosition,
                                  ),
                            onPanEnd: selectedKind == AnnotationKind.text
                                ? null
                                : (_) => _finishDrag(fitted),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  File(widget.photo.path),
                                  fit: BoxFit.fill,
                                ),
                                CustomPaint(
                                  painter: AnnotationPainter([
                                    ...annotations,
                                    if (draft != null) draft,
                                  ]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              decoration: const BoxDecoration(
                color: editorSurfaceColor,
                border: Border(top: BorderSide(color: editorLineColor)),
              ),
              child: Column(
                children: [
                  const LText(
                    '拖动绘制方框或箭头；文字模式下点击照片定位。',
                    style: TextStyle(color: editorMutedColor, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const LText(
                        '颜色',
                        style: TextStyle(
                          color: editorMutedColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      for (
                        var index = 0;
                        index < _annotationColors.length;
                        index++
                      ) ...[
                        if (index > 0) const SizedBox(width: 6),
                        _ColorButton(
                          label: _annotationColors[index].label,
                          color: _annotationColors[index].color,
                          selected:
                              selectedColorValue ==
                              _annotationColors[index].color.toARGB32(),
                          onTap: () => setState(
                            () => selectedColorValue = _annotationColors[index]
                                .color
                                .toARGB32(),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _ToolButton(
                          icon: Icons.crop_square_rounded,
                          label: '方框',
                          selected: selectedKind == AnnotationKind.rectangle,
                          onTap: () => setState(
                            () => selectedKind = AnnotationKind.rectangle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ToolButton(
                          icon: Icons.north_east_rounded,
                          label: '箭头',
                          selected: selectedKind == AnnotationKind.arrow,
                          onTap: () => setState(
                            () => selectedKind = AnnotationKind.arrow,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ToolButton(
                          icon: Icons.text_fields_rounded,
                          label: '文字',
                          selected: selectedKind == AnnotationKind.text,
                          onTap: () => setState(
                            () => selectedKind = AnnotationKind.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: tr('撤销'),
                        onPressed: annotations.isEmpty
                            ? null
                            : () => setState(() => annotations.removeLast()),
                        icon: const Icon(Icons.undo_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _annotationColors = <({String label, Color color})>[
  (label: '红色', color: annotationColor),
  (label: '绿色', color: annotationGreenColor),
  (label: '蓝色', color: annotationBlueColor),
  (label: '黑色', color: annotationBlackColor),
  (label: '白色', color: annotationWhiteColor),
];

class _TextAnnotationSheet extends StatefulWidget {
  const _TextAnnotationSheet();

  @override
  State<_TextAnnotationSheet> createState() => _TextAnnotationSheetState();
}

class _TextAnnotationSheetState extends State<_TextAnnotationSheet> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void close([String? text]) {
    FocusScope.of(context).unfocus();
    Navigator.pop(context, text);
  }

  void submit() {
    final text = controller.text.trim();
    if (text.isNotEmpty) close(text);
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = controller.text.trim().isNotEmpty;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final availableHeight =
        (MediaQuery.sizeOf(context).height - keyboardInset - 12)
            .clamp(0.0, double.infinity)
            .toDouble();
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Material(
        color: editorSurfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: availableHeight),
          child: SingleChildScrollView(
            key: const Key('text-annotation-sheet-scroll'),
            padding: AppInsets.scrollable(
              context,
              left: 20,
              top: 14,
              right: 20,
              bottom: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: editorLineColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const LText(
                  '添加文字标注',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const LText(
                  '文字会添加在刚才点击的位置。',
                  style: TextStyle(color: editorMutedColor, fontSize: 12),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 24,
                  style: const TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => submit(),
                  decoration: InputDecoration(
                    hintText: tr('例如：开裂处'),
                    hintStyle: const TextStyle(color: editorMutedColor),
                    counterStyle: const TextStyle(color: editorMutedColor),
                    filled: true,
                    fillColor: editorInactiveColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: editorLineColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: editorAccentColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: close,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: editorAccentColor,
                          side: const BorderSide(color: editorLineColor),
                        ),
                        child: const LText('取消'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: canSubmit ? submit : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: editorAccentColor,
                          foregroundColor: editorCanvasColor,
                        ),
                        child: const LText('添加'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  const _ColorButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: tr(label),
      child: Tooltip(
        message: tr(label),
        excludeFromSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? editorAccentColor : editorLineColor,
                  width: selected ? 3 : 1,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: color == annotationWhiteColor
                      ? Border.all(color: editorMutedColor)
                      : null,
                ),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        size: 17,
                        color: annotationTextColor(color),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? brandColor : editorInactiveColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 19),
              const SizedBox(width: 5),
              LText(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
