import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_report/ui/app_theme.dart';

void main() {
  test('approved PhotoReport color tokens stay exact', () {
    expect(brandColor.toARGB32(), 0xFF0B6B63);
    expect(brandDeepColor.toARGB32(), 0xFF07544E);
    expect(inkColor.toARGB32(), 0xFF17312E);
    expect(mutedColor.toARGB32(), 0xFF5F716D);
    expect(canvasColor.toARGB32(), 0xFFF4F7F6);
    expect(surfaceColor.toARGB32(), 0xFFFFFFFF);
    expect(softSurfaceColor.toARGB32(), 0xFFE7F0EE);
    expect(lineColor.toARGB32(), 0xFFD8E3E0);
    expect(pendingColor.toARGB32(), 0xFFAD5417);
    expect(inProgressColor.toARGB32(), 0xFF2465A8);
    expect(completedColor.toARGB32(), 0xFF1F7650);
    expect(riskColor.toARGB32(), 0xFFB7353D);
    expect(annotationColor.toARGB32(), 0xFFFF2D2D);
    expect(annotationGreenColor.toARGB32(), 0xFF22C55E);
    expect(annotationBlueColor.toARGB32(), 0xFF2F80ED);
    expect(annotationBlackColor.toARGB32(), 0xFF111111);
    expect(annotationWhiteColor.toARGB32(), 0xFFFFFFFF);
  });

  test('app theme uses the approved primary surfaces', () {
    final theme = buildAppTheme();

    expect(theme.colorScheme.primary, brandColor);
    expect(theme.colorScheme.error, riskColor);
    expect(theme.colorScheme.surface, surfaceColor);
    expect(theme.scaffoldBackgroundColor, canvasColor);
    expect(theme.cardTheme.color, surfaceColor);
    expect(theme.inputDecorationTheme.fillColor, surfaceColor);
    expect(theme.dividerColor, lineColor);
    expect(theme.colorScheme.primaryContainer, softSurfaceColor);
    expect(theme.colorScheme.secondaryContainer, softSurfaceColor);
    expect(theme.floatingActionButtonTheme.backgroundColor, brandColor);
    expect(theme.chipTheme.selectedColor, softSurfaceColor);
    expect(theme.cupertinoOverrideTheme?.primaryColor, brandColor);
    expect(theme.cupertinoOverrideTheme?.barBackgroundColor, surfaceColor);
    expect(theme.popupMenuTheme.shape, isA<RoundedRectangleBorder>());
  });

  test('dark theme uses dark semantic surfaces and readable accents', () {
    final theme = buildAppTheme(brightness: Brightness.dark);
    final colors = theme.extension<AppThemeColors>()!;

    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.brightness, Brightness.dark);
    expect(colors.canvas, darkCanvasColor);
    expect(colors.surface, darkSurfaceColor);
    expect(colors.ink, darkInkColor);
    expect(colors.muted, darkMutedColor);
    expect(colors.line, darkLineColor);
    expect(theme.scaffoldBackgroundColor, darkCanvasColor);
    expect(theme.cardTheme.color, darkSurfaceColor);
    expect(theme.inputDecorationTheme.fillColor, darkSurfaceColor);
    expect(theme.colorScheme.primary, darkBrandColor);
    expect(theme.colorScheme.onPrimary, darkCanvasColor);
    expect(theme.cupertinoOverrideTheme?.primaryColor, darkBrandColor);
    expect(theme.cupertinoOverrideTheme?.barBackgroundColor, darkSurfaceColor);
  });

  testWidgets('system brightness selects the dark semantic theme', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    Brightness? effectiveBrightness;
    AppThemeColors? effectiveColors;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        darkTheme: buildAppTheme(brightness: Brightness.dark),
        themeMode: ThemeMode.system,
        home: Builder(
          builder: (context) {
            effectiveBrightness = Theme.of(context).brightness;
            effectiveColors = context.appColors;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(effectiveBrightness, Brightness.dark);
    expect(effectiveColors?.canvas, darkCanvasColor);
    expect(effectiveColors?.ink, darkInkColor);
  });
}
