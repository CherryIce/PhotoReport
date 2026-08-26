import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_controller.dart';
import 'ui/app_theme.dart';
import 'ui/project_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PhotoReportApp());
}

class PhotoReportApp extends StatefulWidget {
  const PhotoReportApp({super.key});

  @override
  State<PhotoReportApp> createState() => _PhotoReportAppState();
}

class _PhotoReportAppState extends State<PhotoReportApp> {
  late final PhotoReportController controller;

  @override
  void initState() {
    super.initState();
    controller = PhotoReportController()..initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '现场照片报告',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: ProjectListScreen(controller: controller),
    );
  }
}
