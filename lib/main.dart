// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Services
import 'package:appetite/services/notification_service.dart';
// import 'package:appetite/services/esp32service.dart'; // REMOVA (se ainda existir)
import 'package:appetite/services/localesp32service.dart'; // ADICIONE

// Controllers (Lógica)
import 'package:appetite/controllers/themecontroller.dart';
import 'package:appetite/controllers/alarmcontroller.dart';
import 'package:appetite/controllers/homecontroller.dart';
import 'package:appetite/controllers/historycontroller.dart';
import 'package:appetite/controllers/provisioningcontroller.dart';

// Core (Tema)
import 'package:appetite/core/theme/apptheme.dart';

// Views (Interface)
import 'package:appetite/views/mainscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => HistoryController()),

        // AlarmController agora depende apenas de HomeController e HistoryController
        ChangeNotifierProxyProvider2<HomeController, HistoryController, AlarmController>(
          create: (context) => AlarmController(
            homeController: Provider.of<HomeController>(context, listen: false),
            historyController: Provider.of<HistoryController>(context, listen: false),
          ),
          update: (context, homeCtrl, historyCtrl, previousAlarmCtrl) {
            return previousAlarmCtrl ?? AlarmController(
              homeController: homeCtrl,
              historyController: historyCtrl,
            );
          },
        ),

        // ProvisioningController depende de HomeController
        ChangeNotifierProxyProvider<HomeController, ProvisioningController>(
          create: (context) => ProvisioningController(
            homeController: Provider.of<HomeController>(context, listen: false),
          ),
          update: (context, homeCtrl, previousProvCtrl) {
            return previousProvCtrl ?? ProvisioningController(homeController: homeCtrl);
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);

    return MaterialApp(
      title: 'Appetite',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(
        themeController.primaryColor,
        themeController.fontSizeFactor,
        Brightness.light,
      ),
      darkTheme: buildAppTheme(
        themeController.primaryColor,
        themeController.fontSizeFactor,
        Brightness.dark,
      ),
      themeMode: themeController.themeMode,
      home: const MainScreen(),
    );
  }
}