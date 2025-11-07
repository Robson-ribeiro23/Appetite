import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Services
import 'package:appetite/services/notification_service.dart';

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
  // 1. Garante que o binding do Flutter esteja inicializado antes de serviços nativos
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializa o serviço de notificações antes do app rodar
  // Isso garante que os canais de notificação do Android estejam prontos
  await NotificationService().init();

  runApp(
    MultiProvider(
      providers: [
        // --- CONTROLLERS INDEPENDENTES ---
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => HistoryController()),

        // --- CONTROLLERS DEPENDENTES (Usam ProxyProvider) ---
        
        // AlarmController precisa de HomeController (para enviar comando) 
        // e HistoryController (para registrar sucesso/falha)
        ChangeNotifierProxyProvider2<HomeController, HistoryController, AlarmController>(
          create: (context) => AlarmController(
            homeController: Provider.of<HomeController>(context, listen: false),
            historyController: Provider.of<HistoryController>(context, listen: false),
          ),
          update: (context, homeCtrl, historyCtrl, previousAlarmCtrl) {
            // Mantém a instância existente se possível, apenas atualizando as dependências
            return previousAlarmCtrl ?? AlarmController(
              homeController: homeCtrl, 
              historyController: historyCtrl
            );
          },
        ),

        // ProvisioningController precisa de HomeController (para conectar após o setup)
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
    // 3. Escuta as mudanças de tema e tamanho para reconstruir o app todo se mudar
    final themeController = Provider.of<ThemeController>(context);

    return MaterialApp(
      title: 'Appetite',
      debugShowCheckedModeBanner: false,

      // 4. Aplica o tema dinâmico (cor e fator de tamanho da fonte)
      theme: buildAppTheme(
        themeController.primaryColor,
        themeController.fontSizeFactor,
      ),

      // 5. Define a tela inicial
      home: const MainScreen(),
    );
  }
}