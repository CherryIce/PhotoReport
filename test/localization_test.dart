import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_report/app_controller.dart';
import 'package:photo_report/ui/app_theme.dart';
import 'package:photo_report/ui/create_flow_sheet.dart';
import 'package:photo_report/ui/onboarding_screen.dart';
import 'package:photo_report/ui/project_form_sheet.dart';
import 'package:photo_report/ui/project_list_screen.dart';

void main() {
  test('English copy covers static and interpolated product messages', () {
    const english = Locale('en');
    expect(
      AppLocalizations.text('现场照片记录', locale: english),
      'On-site Photo Records',
    );
    expect(
      AppLocalizations.text('删除“示例项目”？', locale: english),
      'Delete “示例项目”?',
    );
    expect(
      AppLocalizations.text('A-003 待跟进但未填写负责人', locale: english),
      'A-003 needs follow-up but has no assignee',
    );
    expect(
      AppLocalizations.text('3 项高优先级', locale: english),
      '3 high priority',
    );
    expect(
      AppLocalizations.errorText(
        'Exception: 照片文件缺失，无法完成备份：site.jpg',
        locale: english,
      ),
      'Exception: Photo file missing; backup cannot be completed: site.jpg',
    );
  });

  test('static Chinese product copy has an English translation', () {
    final files = <File>[
      File('lib/main.dart'),
      File('lib/models.dart'),
      File('lib/report/report_service.dart'),
      ...Directory('lib/data').listSync().whereType<File>().where(
        (file) => file.path.endsWith('.dart'),
      ),
      ...Directory('lib/ui')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
    ];
    final chineseLiteral = RegExp(r"'([^'\n]*[\u4e00-\u9fff][^'\n]*)'");
    final missing = <String>{};
    for (final file in files) {
      for (final match in chineseLiteral.allMatches(file.readAsStringSync())) {
        final source = match.group(1)!;
        if (source.contains(r'$')) continue;
        if (!AppLocalizations.hasEnglish(source) &&
            AppLocalizations.text(source, locale: const Locale('en')) ==
                source) {
          missing.add(source);
        }
      }
    }
    expect(missing, isEmpty, reason: 'Missing English copy: $missing');
  });

  testWidgets('language menu switches the visible app chrome', (tester) async {
    final controller = PhotoReportController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_LanguageHarness(controller: controller));
    expect(find.text('现场照片记录'), findsOneWidget);

    final menu = tester.widget<PopupMenuButton<String>>(
      find.byType(PopupMenuButton<String>),
    );
    menu.onSelected?.call('en');
    await tester.pump();

    expect(find.text('On-site Photo Records'), findsOneWidget);
    expect(find.byTooltip('More actions'), findsOneWidget);
  });

  testWidgets('English form fields stack at phone width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: ResponsiveFieldRow(
            children: [
              SizedBox(key: const Key('first-field'), height: 56),
              SizedBox(key: const Key('second-field'), height: 56),
            ],
          ),
        ),
      ),
    );

    final first = tester.getTopLeft(find.byKey(const Key('first-field')));
    final second = tester.getTopLeft(find.byKey(const Key('second-field')));
    expect(second.dy, greaterThan(first.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('user-entered text is never translated', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        home: LText('现场照片记录', translate: false),
      ),
    );
    expect(find.text('现场照片记录'), findsOneWidget);
    expect(find.text('On-site Photo Records'), findsNothing);
  });

  testWidgets('English create screens render on a narrow phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    AppLocalizations.activeLocale = const Locale('en');

    Widget app(Widget child) => MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildAppTheme(),
      home: Scaffold(body: child),
    );

    await tester.pumpWidget(app(const CreateFlowSheet(projects: [])));
    expect(find.text('How would you like to record this?'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(app(const ProjectFormSheet()));
    await tester.pump();
    expect(find.text('Project name *'), findsOneWidget);
    expect(find.text('Company / team'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding follows the effective locale and completes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var finished = false;
    Locale? preferredLocale;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildAppTheme(),
        home: OnboardingScreen(
          locale: const Locale('en'),
          preferredLocale: null,
          onLocaleChanged: (value) => preferredLocale = value,
          onFinished: () => finished = true,
        ),
      ),
    );

    expect(find.text('Site records start with a photo'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-language')));
    await tester.pumpAndSettle();
    expect(find.text('System default'), findsOneWidget);
    await tester.tap(find.text('简体中文').last);
    await tester.pumpAndSettle();
    expect(preferredLocale?.languageCode, 'zh');

    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Start recording'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    expect(finished, isTrue);
  });

  test(
    'language and onboarding preferences use one persisted startup state',
    () async {
      const channel = MethodChannel('com.starburst.photo_report/report');
      String? languageCode;
      var onboardingComplete = false;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            final arguments =
                call.arguments as Map<Object?, Object?>? ?? const {};
            switch (call.method) {
              case 'getPreferredLanguage':
                return languageCode;
              case 'setPreferredLanguage':
                languageCode = arguments['languageCode'] as String?;
                return null;
              case 'clearPreferredLanguage':
                languageCode = null;
                return null;
              case 'getOnboardingComplete':
                return onboardingComplete;
              case 'setOnboardingComplete':
                onboardingComplete = arguments['isComplete'] as bool? ?? false;
                return null;
            }
            throw PlatformException(code: 'unexpected_method');
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      expect(await LanguagePreference.load(), isNull);
      await LanguagePreference.save(const Locale('en'));
      expect((await LanguagePreference.load())?.languageCode, 'en');
      await LanguagePreference.clear();
      expect(await LanguagePreference.load(), isNull);

      expect(await OnboardingPreference.load(), isFalse);
      await OnboardingPreference.complete();
      expect(await OnboardingPreference.load(), isTrue);
    },
  );
}

class _LanguageHarness extends StatefulWidget {
  const _LanguageHarness({required this.controller});

  final PhotoReportController controller;

  @override
  State<_LanguageHarness> createState() => _LanguageHarnessState();
}

class _LanguageHarnessState extends State<_LanguageHarness> {
  Locale locale = const Locale('zh', 'CN');

  @override
  Widget build(BuildContext context) {
    AppLocalizations.activeLocale = locale;
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: ProjectListScreen(
        controller: widget.controller,
        preferredLocale: locale,
        onLocaleChanged: (value) {
          if (value != null) setState(() => locale = value);
        },
      ),
    );
  }
}
