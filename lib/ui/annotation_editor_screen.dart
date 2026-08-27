import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import 'app_theme.dart';
import 'widgets/annotated_photo.dart';

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
    final text = await showCupertinoDialog<String>(
      context: context,
      builder: (context) => const _TextAnnotationDialog(),
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

class _TextAnnotationDialog extends StatefulWidget {
  const _TextAnnotationDialog();

  @override
  State<_TextAnnotationDialog> createState() => _TextAnnotationDialogState();
}

class _TextAnnotationDialogState extends State<_TextAnnotationDialog> {
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

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const LText('添加文字标注'),
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: CupertinoTextField(
          controller: controller,
          autofocus: true,
          maxLength: 24,
          placeholder: tr('例如：开裂处'),
          clearButtonMode: OverlayVisibilityMode.editing,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          onSubmitted: (value) => close(value.trim()),
        ),
      ),
      actions: [
        CupertinoDialogAction(onPressed: close, child: const LText('取消')),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => close(controller.text.trim()),
          child: const LText('添加'),
        ),
      ],
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
