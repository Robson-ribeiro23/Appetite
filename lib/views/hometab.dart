// lib/views/home_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appetite/controllers/homecontroller.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, child) {
        final theme = Theme.of(context);
        
        Color statusColor = Colors.grey;
        IconData statusIcon = Icons.sensors_off;

        switch (controller.status) {
          case ConnectionStatus.connecting:
            statusColor = Colors.yellow;
            statusIcon = Icons.loop;
            break;
          case ConnectionStatus.connected:
            statusColor = theme.primaryColor;
            statusIcon = Icons.sensors;
            break;
          case ConnectionStatus.error:
            statusColor = Colors.red;
            statusIcon = Icons.error_outline;
            break;
          case ConnectionStatus.disconnected:
            statusColor = Colors.grey;
            statusIcon = Icons.sensors_off;
            break;
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                statusIcon,
                size: 100,
                color: statusColor,
              ),
              const SizedBox(height: 20),
              Text(
                controller.message,
                style: theme.textTheme.titleMedium?.copyWith(color: statusColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              ElevatedButton(
                onPressed: controller.status == ConnectionStatus.connecting 
                    ? null 
                    : () {
                        if (controller.status == ConnectionStatus.connected) {
                          controller.disconnect();
                        } else {
                          // Simula a tentativa de conexão
                          controller.attemptConnection('simular_sucesso'); 
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor == Colors.grey ? theme.primaryColor : statusColor,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(
                  controller.status == ConnectionStatus.connected ? 'DESCONECTAR' : 'CONECTAR ESP32',
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}