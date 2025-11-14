import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart'; // Importe para usar kIsWeb ou condicionais de plataforma, se necessário

class NotificationService {
  // Singleton - garante que só existe uma instância do gerenciador de notificações
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // --- Configuração Android ---
    // Você precisará adicionar um ícone chamado 'app_icon' na pasta android/app/src/main/res/drawable
    // Por enquanto, podemos usar o padrão '@mipmap/ic_launcher'
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // --- Configuração Linux (NOVO) ---
    // 'defaultActionName' é o que aparece se a notificação tiver um botão padrão
    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Abrir notificação');

    // --- Configuração Geral (ATUALIZADA) ---
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            linux: initializationSettingsLinux, // <--- Adicionado para Linux
            // Se for rodar no iOS no futuro, precisará adicionar aqui também:
            // iOS: DarwinInitializationSettings(...),
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Lógica opcional: o que acontece quando o usuário toca na notificação
        // Por exemplo, navegar para uma tela específica do app
      },
    );

    // --- SOLICITAÇÃO DE PERMISSÃO PARA NOTIFICAÇÕES (APENAS ANDROID 13+) ---
    // Esta parte é crucial para que as notificações apareçam em versões recentes do Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // requestNotificationsPermission() retorna true se o usuário concedeu a permissão
        final bool? granted = await androidImplementation.requestNotificationsPermission();
        if (granted == true) {
          print('Permissão de notificação concedida no Android.');
        } else {
          print('Permissão de notificação NEGADA no Android.');
          // Considere mostrar um diálogo ou instruir o usuário a ativar manualmente
        }
      }
    }
    // ---------------------------------------------------------------------
  }

  // Função para exibir a notificação imediatamente
  Future<void> showAlarmNotification({required String title, required String body}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'alarm_channel_id', // ID único do canal
      'Alarmes Appetite', // Nome visível nas configurações do Android
      channelDescription: 'Notificações para os horários de alimentação',
      importance: Importance.max, // Garante que a notificação seja proeminente
      priority: Priority.high,   // Define a prioridade alta
      playSound: true,           // Toca um som padrão
      // sound: RawResourceAndroidNotificationSound('alarm_sound'), // Se quiser um som personalizado depois
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(
            android: androidPlatformChannelSpecifics,
            // Para Linux, podemos usar as configurações padrão ou definir algo específico:
            linux: LinuxNotificationDetails(),
        );

    await flutterLocalNotificationsPlugin.show(
      0, // ID da notificação (0 porque podemos substituir a anterior se já tiver uma)
      title,
      body,
      platformChannelSpecifics,
    );
  }
}