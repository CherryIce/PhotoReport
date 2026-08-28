import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_report/app_controller.dart';
import 'package:photo_report/ui/app_theme.dart';
import 'package:photo_report/ui/privacy_policy_screen.dart';
import 'package:photo_report/ui/project_list_screen.dart';

void main() {
  testWidgets('settings privacy entry opens the local policy', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = PhotoReportController()..isLoading = false;
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(bottomSafeInset: 34, home: _HomeHarness(controller: controller)),
    );
    await tester.tap(find.byKey(const Key('home-settings-button')));
    await tester.pumpAndSettle();

    final settingsScroll = tester.widget<SingleChildScrollView>(
      find.byKey(const Key('home-settings-scroll')),
    );
    expect((settingsScroll.padding! as EdgeInsets).bottom, 42);
    expect(
      tester.getBottomRight(find.byKey(const Key('home-settings-sheet'))).dy,
      568,
    );

    final privacyEntry = find.byKey(const Key('settings-privacy-policy'));
    expect(privacyEntry, findsOneWidget);
    await tester.ensureVisible(privacyEntry);
    await tester.tap(privacyEntry);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('privacy-policy-screen')), findsOneWidget);
    expect(find.text('隐私政策'), findsOneWidget);
    expect(find.text('隐私概览'), findsOneWidget);
    expect(find.text('本地存储与传输'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('privacy policy follows the English app locale', (tester) async {
    await tester.pumpWidget(
      _app(locale: const Locale('en'), home: const PrivacyPolicyScreen()),
    );

    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Privacy overview'), findsOneWidget);
    expect(find.text('On-device storage and transmission'), findsOneWidget);
    expect(find.text('Last updated: August 28, 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('privacy page merges the bottom safe area into scroll padding', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _app(bottomSafeInset: 34, home: const PrivacyPolicyScreen()),
    );

    final content = tester.widget<ListView>(
      find.byKey(const Key('privacy-policy-content')),
    );
    expect((content.padding! as EdgeInsets).bottom, 58);
    expect(
      tester.getBottomRight(find.byKey(const Key('privacy-policy-content'))).dy,
      568,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _app({
  Locale locale = const Locale('zh', 'CN'),
  double bottomSafeInset = 0,
  required Widget home,
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: buildAppTheme(),
    builder: (context, child) {
      final mediaQuery = MediaQuery.of(context);
      final padding = mediaQuery.padding;
      final viewPadding = mediaQuery.viewPadding;
      return MediaQuery(
        data: mediaQuery.copyWith(
          padding: EdgeInsets.fromLTRB(
            padding.left,
            padding.top,
            padding.right,
            bottomSafeInset,
          ),
          viewPadding: EdgeInsets.fromLTRB(
            viewPadding.left,
            viewPadding.top,
            viewPadding.right,
            bottomSafeInset,
          ),
        ),
        child: child!,
      );
    },
    home: home,
  );
}

class _HomeHarness extends StatelessWidget {
  const _HomeHarness({required this.controller});

  final PhotoReportController controller;

  @override
  Widget build(BuildContext context) {
    return ProjectListScreen(
      controller: controller,
      preferredLocale: const Locale('zh', 'CN'),
      onLocaleChanged: (_) {},
    );
  }
}
