import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Singleton - garante que só existe uma instância do gerenciador de notificações
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Configuração para Android
    // Você precisará adicionar um ícone chamado 'app_icon' na pasta android/app/src/main/res/drawable
    // Por enquanto, podemos usar o padrão '@mipmap/ic_launcher'
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuração Geral
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      // Opcional: o que acontece quando toca na notificação
      onDidReceiveNotificationResponse: (details) {
        // Lógica para abrir o app em uma tela específica se quiser
      },
    );
  }

  // Função para exibir a notificação imediatamente
  Future<void> showAlarmNotification({required String title, required String body}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'alarm_channel_id', // ID único do canal
      'Alarmes Appetite', // Nome visível nas configurações do Android
      channelDescription: 'Notificações para os horários de alimentação',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      // sound: RawResourceAndroidNotificationSound('alarm_sound'), // Se quiser um som personalizado depois
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0, // ID da notificação (0 porque podemos substituir a anterior se já tiver uma)
      title,
      body,
      platformChannelSpecifics,
    );
  }
}