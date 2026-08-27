import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../models.dart';
import '../app_theme.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LText(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.appColors.ink,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                LText(
                  subtitle!,
                  style: TextStyle(color: context.appColors.muted),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.value,
    required this.label,
    required this.color,
    this.compact = false,
    super.key,
  });

  final int value;
  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 68 : 78),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LText(
            '$value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 20 : 24,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          LText(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.appColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.status, super.key});

  final IssueStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      IssueStatus.unspecified => context.appColors.muted,
      IssueStatus.pending => context.appColors.pending,
      IssueStatus.inProgress => context.appColors.inProgress,
      IssueStatus.completed => context.appColors.completed,
    };
    return status == IssueStatus.unspecified
        ? const SizedBox.shrink()
        : _Badge(label: status.label, color: color);
  }
}

class SeverityBadge extends StatelessWidget {
  const SeverityBadge({required this.severity, super.key});

  final IssueSeverity severity;

  @override
  Widget build(BuildContext context) {
    final color = switch (severity) {
      IssueSeverity.unspecified => context.appColors.muted,
      IssueSeverity.low => context.appColors.muted,
      IssueSeverity.medium => context.appColors.pending,
      IssueSeverity.high => context.appColors.risk,
    };
    return severity == IssueSeverity.unspecified
        ? const SizedBox.shrink()
        : _Badge(label: '${severity.label}优先级', color: color);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: LText(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

const _appSheetBorderRadius = BorderRadius.vertical(top: Radius.circular(24));

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    semanticsDismissible: barrierDismissible,
    builder: (context) => ClipRRect(
      borderRadius: _appSheetBorderRadius,
      child: Material(color: context.appColors.canvas, child: builder(context)),
    ),
  );
}

@immutable
class AppActionSheetAction<T> {
  const AppActionSheetAction({
    required this.label,
    required this.value,
    this.icon,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
  });

  final String label;
  final T value;
  final IconData? icon;
  final bool isDefaultAction;
  final bool isDestructiveAction;
}

Future<T?> showAppActionSheet<T>({
  required BuildContext context,
  required List<AppActionSheetAction<T>> actions,
  String? title,
  String? message,
  String cancelLabel = '取消',
  T? cancelValue,
  bool barrierDismissible = true,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    semanticsDismissible: barrierDismissible,
    builder: (context) => CupertinoActionSheet(
      title: title == null ? null : LText(title),
      message: message == null ? null : LText(message),
      actions: [
        for (final action in actions)
          CupertinoActionSheetAction(
            isDefaultAction: action.isDefaultAction,
            isDestructiveAction: action.isDestructiveAction,
            onPressed: () => Navigator.pop(context, action.value),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (action.icon != null) ...[
                  Icon(action.icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(child: LText(action.label)),
              ],
            ),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(context, cancelValue),
        child: LText(cancelLabel),
      ),
    ),
  );
}

Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String title = '选择日期',
}) {
  assert(!lastDate.isBefore(firstDate));
  final minimumDate = DateUtils.dateOnly(firstDate);
  final maximumDate = DateUtils.dateOnly(lastDate);
  final requestedDate = DateUtils.dateOnly(initialDate);
  final safeInitialDate = requestedDate.isBefore(minimumDate)
      ? minimumDate
      : requestedDate.isAfter(maximumDate)
      ? maximumDate
      : requestedDate;
  return showAppBottomSheet<DateTime>(
    context: context,
    builder: (context) => _AppDatePickerSheet(
      initialDate: safeInitialDate,
      minimumDate: minimumDate,
      maximumDate: maximumDate,
      title: title,
    ),
  );
}

class _AppDatePickerSheet extends StatefulWidget {
  const _AppDatePickerSheet({
    required this.initialDate,
    required this.minimumDate,
    required this.maximumDate,
    required this.title,
  });

  final DateTime initialDate;
  final DateTime minimumDate;
  final DateTime maximumDate;
  final String title;

  @override
  State<_AppDatePickerSheet> createState() => _AppDatePickerSheetState();
}

class _AppDatePickerSheetState extends State<_AppDatePickerSheet> {
  late DateTime selectedDate = widget.initialDate;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 330,
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    onPressed: () => Navigator.pop(context),
                    child: const LText('取消'),
                  ),
                  Expanded(
                    child: LText(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.appColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    onPressed: () => Navigator.pop(context, selectedDate),
                    child: const LText(
                      '完成',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 0.5, color: context.appColors.line),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: widget.initialDate,
                minimumDate: widget.minimumDate,
                maximumDate: widget.maximumDate,
                backgroundColor: context.appColors.canvas,
                onDateTimeChanged: (value) => selectedDate = value,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '确认删除',
}) async {
  return await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: LText(title),
          content: LText(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: const LText('取消'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context, true),
              child: LText(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;
}

void showErrorSnackBar(BuildContext context, Object error) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: LText('操作失败：$error')));
}
