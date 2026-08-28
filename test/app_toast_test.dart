import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_report/ui/app_theme.dart';
import 'package:photo_report/ui/widgets/app_toast.dart';

void main() {
  Widget testApp(Widget child) {
    return MaterialApp(
      theme: buildAppTheme(),
      locale: const Locale('zh', 'CN'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        appBar: AppBar(title: const Text('项目')),
        body: child,
      ),
    );
  }

  testWidgets(
    'shows a root overlay error toast with a readable platform error',
    (tester) async {
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => AppToast.showError(
                context,
                PlatformException(code: 'missing_file', message: '找不到报告文件'),
                key: const Key('report-error-toast'),
              ),
              child: const Text('显示提示'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('显示提示'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));

      expect(find.byKey(const Key('report-error-toast')), findsOneWidget);
      expect(find.text('操作失败：找不到报告文件'), findsOneWidget);
      expect(find.textContaining('PlatformException'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);

      AppToast.dismiss();
      await tester.pump(const Duration(milliseconds: 180));
      expect(find.byKey(const Key('report-error-toast')), findsNothing);
    },
  );

  testWidgets('replaces the current toast instead of stacking messages', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) => Column(
            children: [
              TextButton(
                onPressed: () => AppToast.show(
                  context,
                  '第一条',
                  key: const Key('first-toast'),
                ),
                child: const Text('显示第一条'),
              ),
              TextButton(
                onPressed: () => AppToast.show(
                  context,
                  '第二条',
                  key: const Key('second-toast'),
                ),
                child: const Text('显示第二条'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('显示第一条'));
    await tester.pump();
    await tester.tap(find.text('显示第二条'));
    await tester.pump();

    expect(find.byKey(const Key('first-toast')), findsNothing);
    expect(find.byKey(const Key('second-toast')), findsOneWidget);

    AppToast.dismiss();
    await tester.pump(const Duration(milliseconds: 180));
  });
}
