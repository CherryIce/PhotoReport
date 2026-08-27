import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_report/ui/app_theme.dart';
import 'package:photo_report/ui/widgets/common.dart';

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
      home: Scaffold(body: child),
    );
  }

  testWidgets('confirmAction uses an iOS alert and returns confirmation', (
    tester,
  ) async {
    bool? result;

    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await confirmAction(
                context,
                title: '删除记录？',
                message: '此操作无法撤销。',
              );
            },
            child: const Text('打开'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    final confirmButton = tester.widget<CupertinoDialogAction>(
      find.widgetWithText(CupertinoDialogAction, '确认删除'),
    );
    expect(confirmButton.isDestructiveAction, isTrue);

    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('action sheet keeps iOS action semantics and returns selection', (
    tester,
  ) async {
    String? result;

    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showAppActionSheet<String>(
                context: context,
                title: '添加照片',
                actions: const [
                  AppActionSheetAction(
                    label: '现场拍照',
                    value: 'camera',
                    isDefaultAction: true,
                  ),
                  AppActionSheetAction(label: '从相册选择', value: 'gallery'),
                ],
              );
            },
            child: const Text('打开'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoActionSheet), findsOneWidget);
    final cameraAction = tester.widget<CupertinoActionSheetAction>(
      find.widgetWithText(CupertinoActionSheetAction, '现场拍照'),
    );
    expect(cameraAction.isDefaultAction, isTrue);

    await tester.tap(find.text('从相册选择'));
    await tester.pumpAndSettle();
    expect(result, 'gallery');
  });

  testWidgets('date picker uses an iOS wheel and clamps its initial date', (
    tester,
  ) async {
    DateTime? result;
    final firstDate = DateTime(2026, 1, 1);

    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showAppDatePicker(
                context: context,
                initialDate: DateTime(2025, 6, 1),
                firstDate: firstDate,
                lastDate: DateTime(2027, 1, 1),
              );
            },
            child: const Text('打开'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    final picker = tester.widget<CupertinoDatePicker>(
      find.byType(CupertinoDatePicker),
    );
    expect(picker.initialDateTime, firstDate);

    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    expect(result, firstDate);
  });
}
