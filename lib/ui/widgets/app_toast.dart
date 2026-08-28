import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_theme.dart';

enum AppToastStyle { info, success, error }

/// Window-level transient feedback that does not resize the current page.
abstract final class AppToast {
  static const Duration _transitionDuration = Duration(milliseconds: 180);
  static _AppToastHandle? _current;

  static void show(
    BuildContext context,
    String message, {
    AppToastStyle style = AppToastStyle.info,
    Duration duration = const Duration(seconds: 4),
    Key? key,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _current?.removeImmediately();
    late final _AppToastHandle handle;
    final overlayKey = GlobalKey<_AppToastOverlayState>();
    final entry = OverlayEntry(
      builder: (context) => _AppToastOverlay(
        key: overlayKey,
        message: message,
        style: style,
        duration: duration,
        toastKey: key,
        onFinished: handle.removeImmediately,
      ),
    );
    handle = _AppToastHandle(
      entry: entry,
      overlayKey: overlayKey,
      onRemoved: () {
        if (identical(_current, handle)) _current = null;
      },
    );
    _current = handle;
    overlay.insert(entry);
  }

  static void showError(BuildContext context, Object error, {Key? key}) {
    final detail = switch (error) {
      PlatformException(message: final message?)
          when message.trim().isNotEmpty =>
        message.trim(),
      _ => error.toString().replaceFirst(RegExp(r'^(Exception|Error):\s*'), ''),
    };
    show(
      context,
      '${tr('操作失败：')}$detail',
      style: AppToastStyle.error,
      key: key,
    );
  }

  static void dismiss() => _current?.dismiss();
}

final class _AppToastHandle {
  _AppToastHandle({
    required this.entry,
    required this.overlayKey,
    required this.onRemoved,
  });

  final OverlayEntry entry;
  final GlobalKey<_AppToastOverlayState> overlayKey;
  final VoidCallback onRemoved;
  bool _removed = false;

  void dismiss() {
    if (_removed) return;
    final state = overlayKey.currentState;
    if (state == null) {
      removeImmediately();
    } else {
      state.dismiss();
    }
  }

  void removeImmediately() {
    if (_removed) return;
    _removed = true;
    if (entry.mounted) entry.remove();
    onRemoved();
  }
}

class _AppToastOverlay extends StatefulWidget {
  const _AppToastOverlay({
    required this.message,
    required this.style,
    required this.duration,
    required this.toastKey,
    required this.onFinished,
    super.key,
  });

  final String message;
  final AppToastStyle style;
  final Duration duration;
  final Key? toastKey;
  final VoidCallback onFinished;

  @override
  State<_AppToastOverlay> createState() => _AppToastOverlayState();
}

class _AppToastOverlayState extends State<_AppToastOverlay> {
  Timer? _dismissTimer;
  Timer? _removeTimer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    _dismissTimer = Timer(widget.duration, dismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _removeTimer?.cancel();
    super.dispose();
  }

  void dismiss() {
    if (!mounted || !_visible) {
      widget.onFinished();
      return;
    }
    _dismissTimer?.cancel();
    setState(() => _visible = false);
    _removeTimer = Timer(AppToast._transitionDuration, widget.onFinished);
  }

  @override
  Widget build(BuildContext context) => PositionedDirectional(
    top: MediaQuery.viewPaddingOf(context).top + kToolbarHeight + 8,
    start: 20,
    end: 20,
    child: IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: AnimatedSlide(
          duration: AppToast._transitionDuration,
          curve: Curves.easeOutCubic,
          offset: _visible ? Offset.zero : const Offset(0, -0.18),
          child: AnimatedOpacity(
            duration: AppToast._transitionDuration,
            curve: Curves.easeOut,
            opacity: _visible ? 1 : 0,
            child: _AppToastCard(
              key: widget.toastKey,
              message: widget.message,
              style: widget.style,
            ),
          ),
        ),
      ),
    ),
  );
}

class _AppToastCard extends StatelessWidget {
  const _AppToastCard({required this.message, required this.style, super.key});

  final String message;
  final AppToastStyle style;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (foreground, icon) = switch (style) {
      AppToastStyle.error => (colors.risk, Icons.error_outline_rounded),
      AppToastStyle.success => (
        colors.completed,
        Icons.check_circle_outline_rounded,
      ),
      AppToastStyle.info => (colors.brand, Icons.info_outline_rounded),
    };
    final background = Color.alphaBlend(
      foreground.withValues(alpha: 0.1),
      colors.surface,
    );
    return Semantics(
      liveRegion: true,
      container: true,
      label: message,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 362),
        child: Material(
          color: background,
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: foreground.withValues(alpha: 0.28)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: foreground, size: 22),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.ink,
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
