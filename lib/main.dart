import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:namaz_alert/core/routes/app_pages.dart';
import 'package:namaz_alert/core/routes/app_routes.dart';
import 'package:namaz_alert/core/services/notification_service.dart';
import 'package:namaz_alert/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await NotificationService.initialize();
  runApp(const NamazAlertApp());
}

class NamazAlertApp extends StatelessWidget {
  const NamazAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'NamazAlert',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
    );
  }
}
