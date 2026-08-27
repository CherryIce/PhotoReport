import 'package:flutter/material.dart';

export '../l10n/app_localizations.dart';

const brandColor = Color(0xFF0B6B63);
const brandDeepColor = Color(0xFF07544E);
const inkColor = Color(0xFF17312E);
const canvasColor = Color(0xFFF4F7F6);
const surfaceColor = Color(0xFFFFFFFF);
const softSurfaceColor = Color(0xFFE7F0EE);
const mutedColor = Color(0xFF5F716D);
const lineColor = Color(0xFFD8E3E0);
const pendingColor = Color(0xFFAD5417);
const inProgressColor = Color(0xFF2465A8);
const completedColor = Color(0xFF1F7650);
const riskColor = Color(0xFFB7353D);
const annotationColor = Color(0xFFFF2D2D);

const darkBrandColor = Color(0xFF58D2C4);
const darkBrandDeepColor = Color(0xFF123B37);
const darkInkColor = Color(0xFFE7F2EF);
const darkCanvasColor = Color(0xFF0E1514);
const darkSurfaceColor = Color(0xFF17201F);
const darkSoftSurfaceColor = Color(0xFF22302D);
const darkMutedColor = Color(0xFFA9BBB7);
const darkLineColor = Color(0xFF596D68);
const darkPendingColor = Color(0xFFFFB26F);
const darkInProgressColor = Color(0xFF7FBAFF);
const darkCompletedColor = Color(0xFF67D89C);
const darkRiskColor = Color(0xFFFF8B92);

const onBrandMutedColor = Color(0xFFD1E7E3);
const editorCanvasColor = Color(0xFF0E1514);
const editorSurfaceColor = Color(0xFF17201F);
const editorLineColor = Color(0xFF293532);
const editorMutedColor = Color(0xFF9FB0AC);
const editorInactiveColor = Color(0xFF25302E);
const editorAccentColor = Color(0xFF58D2C4);
const annotationLabelColor = Color.fromARGB(0xD9, 0xD7, 0x19, 0x20);

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.brand,
    required this.brandDeep,
    required this.onBrand,
    required this.onBrandDeep,
    required this.ink,
    required this.canvas,
    required this.surface,
    required this.softSurface,
    required this.muted,
    required this.line,
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.risk,
  });

  const AppThemeColors.light()
    : brand = brandColor,
      brandDeep = brandDeepColor,
      onBrand = surfaceColor,
      onBrandDeep = surfaceColor,
      ink = inkColor,
      canvas = canvasColor,
      surface = surfaceColor,
      softSurface = softSurfaceColor,
      muted = mutedColor,
      line = lineColor,
      pending = pendingColor,
      inProgress = inProgressColor,
      completed = completedColor,
      risk = riskColor;

  const AppThemeColors.dark()
    : brand = darkBrandColor,
      brandDeep = darkBrandDeepColor,
      onBrand = darkCanvasColor,
      onBrandDeep = darkInkColor,
      ink = darkInkColor,
      canvas = darkCanvasColor,
      surface = darkSurfaceColor,
      softSurface = darkSoftSurfaceColor,
      muted = darkMutedColor,
      line = darkLineColor,
      pending = darkPendingColor,
      inProgress = darkInProgressColor,
      completed = darkCompletedColor,
      risk = darkRiskColor;

  final Color brand;
  final Color brandDeep;
  final Color onBrand;
  final Color onBrandDeep;
  final Color ink;
  final Color canvas;
  final Color surface;
  final Color softSurface;
  final Color muted;
  final Color line;
  final Color pending;
  final Color inProgress;
  final Color completed;
  final Color risk;

  @override
  AppThemeColors copyWith({
    Color? brand,
    Color? brandDeep,
    Color? onBrand,
    Color? onBrandDeep,
    Color? ink,
    Color? canvas,
    Color? surface,
    Color? softSurface,
    Color? muted,
    Color? line,
    Color? pending,
    Color? inProgress,
    Color? completed,
    Color? risk,
  }) {
    return AppThemeColors(
      brand: brand ?? this.brand,
      brandDeep: brandDeep ?? this.brandDeep,
      onBrand: onBrand ?? this.onBrand,
      onBrandDeep: onBrandDeep ?? this.onBrandDeep,
      ink: ink ?? this.ink,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      softSurface: softSurface ?? this.softSurface,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      pending: pending ?? this.pending,
      inProgress: inProgress ?? this.inProgress,
      completed: completed ?? this.completed,
      risk: risk ?? this.risk,
    );
  }

  @override
  AppThemeColors lerp(AppThemeColors? other, double t) {
    if (other == null) return this;
    return AppThemeColors(
      brand: Color.lerp(brand, other.brand, t)!,
      brandDeep: Color.lerp(brandDeep, other.brandDeep, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      onBrandDeep: Color.lerp(onBrandDeep, other.onBrandDeep, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      softSurface: Color.lerp(softSurface, other.softSurface, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      pending: Color.lerp(pending, other.pending, t)!,
      inProgress: Color.lerp(inProgress, other.inProgress, t)!,
      completed: Color.lerp(completed, other.completed, t)!,
      risk: Color.lerp(risk, other.risk, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeColors get appColors {
    final theme = Theme.of(this);
    return theme.extension<AppThemeColors>() ??
        (theme.brightness == Brightness.dark
            ? const AppThemeColors.dark()
            : const AppThemeColors.light());
  }
}

ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  final colors = brightness == Brightness.dark
      ? const AppThemeColors.dark()
      : const AppThemeColors.light();
  final scheme =
      ColorScheme.fromSeed(
        seedColor: colors.brand,
        brightness: brightness,
        primary: colors.brand,
        error: colors.risk,
        surface: colors.surface,
        onSurface: colors.ink,
      ).copyWith(
        onPrimary: colors.onBrand,
        primaryContainer: colors.softSurface,
        onPrimaryContainer: colors.ink,
        secondary: colors.brand,
        onSecondary: colors.onBrand,
        secondaryContainer: colors.softSurface,
        onSecondaryContainer: colors.ink,
        error: colors.risk,
        onError: brightness == Brightness.dark ? darkCanvasColor : surfaceColor,
        surface: colors.surface,
        onSurface: colors.ink,
        onSurfaceVariant: colors.muted,
        surfaceContainerLowest: colors.canvas,
        surfaceContainerLow: colors.surface,
        surfaceContainer: colors.canvas,
        surfaceContainerHigh: colors.softSurface,
        surfaceContainerHighest: colors.softSurface,
        outline: colors.line,
        outlineVariant: colors.line,
      );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.canvas,
    fontFamilyFallback: const ['PingFang SC', 'Heiti SC'],
    extensions: [colors],
    appBarTheme: AppBarTheme(
      backgroundColor: colors.canvas,
      foregroundColor: colors.ink,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: colors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      labelStyle: TextStyle(color: colors.muted),
      hintStyle: TextStyle(color: colors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.brand, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: colors.line),
        foregroundColor: colors.ink,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colors.brand,
      foregroundColor: colors.onBrand,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colors.surface,
      selectedColor: colors.softSurface,
      checkmarkColor: colors.brand,
      side: BorderSide(color: colors.line),
      labelStyle: TextStyle(color: colors.ink, fontWeight: FontWeight.w600),
      secondaryLabelStyle: TextStyle(
        color: colors.ink,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerColor: colors.line,
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.ink,
      contentTextStyle: TextStyle(color: colors.canvas),
    ),
  );
}

/// Stacks form fields on phone-width layouts so longer English labels can use
/// their natural height; wider layouts keep the denser side-by-side treatment.
class ResponsiveFieldRow extends StatelessWidget {
  const ResponsiveFieldRow({
    required this.children,
    this.breakpoint = 480,
    this.spacing = 12,
    super.key,
  });

  final List<Widget> children;
  final double breakpoint;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1) SizedBox(height: spacing),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index != children.length - 1) SizedBox(width: spacing),
            ],
          ],
        );
      },
    );
  }
}
