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

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '确认删除',
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: LText(title),
          content: LText(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const LText('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
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
