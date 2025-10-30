// lib/views/settings_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:appetite/controllers/themecontroller.dart';
import 'package:appetite/core/constants/appcolors.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Título da Seção
        Text(
          'Personalização da Interface',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(color: Colors.white12),

        // --- 1. PAINEL DE CORES RGB (MUDANÇA DE TEMA) ---
        _buildColorThemeSection(context, themeController),
        const SizedBox(height: 30),

        // --- 2. TAMANHO DOS COMPONENTES/TEXTO ---
        _buildFontSizeSection(themeController, theme),
        const SizedBox(height: 30),

        // --- 3. OUTRAS CONFIGURAÇÕES (Linguagem) ---
        Text(
          'Outras Configurações',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(color: Colors.white12),
        
        _buildLanguageSetting(theme),
      ],
    );
  }

  Widget _buildColorThemeSection(BuildContext context, ThemeController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cor Principal do Tema:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        
        ListTile(
          title: const Text('Cor Atual'),
          trailing: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: controller.primaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white54, width: 2),
            ),
          ),
          onTap: () {
            _showColorPickerDialog(context, controller);
          },
        ),
      ],
    );
  }
  
  void _showColorPickerDialog(BuildContext context, ThemeController controller) {
    Color pickerColor = controller.primaryColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBackground,
        title: const Text('Selecione a Cor Principal'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) {
              pickerColor = color;
            },
            colorPickerWidth: 300.0,
            pickerAreaHeightPercent: 0.7,
            enableAlpha: false,
            displayThumbColor: true,
            paletteType: PaletteType.hsv,
            labelTypes: const [],
            pickerAreaBorderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2.0),
              topRight: Radius.circular(2.0),
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('SALVAR', style: TextStyle(color: Colors.white)),
            onPressed: () {
              controller.setPrimaryColor(pickerColor);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeSection(ThemeController controller, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tamanho dos Componentes/Texto (Fator: ${controller.fontSizeFactor.toStringAsFixed(1)}x)',
          style: theme.textTheme.titleMedium,
        ),
        Slider(
          value: controller.fontSizeFactor,
          min: 0.8,
          max: 1.5,
          divisions: 7,
          label: controller.fontSizeFactor.toStringAsFixed(1),
          onChanged: (double value) {
            controller.setFontSizeFactor(value);
          },
          activeColor: theme.primaryColor,
          inactiveColor: Colors.white30,
        ),
        Text(
          'Exemplo de texto.',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) * controller.fontSizeFactor,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSetting(ThemeData theme) {
    return ListTile(
      leading: Icon(Icons.language, color: theme.primaryColor),
      title: const Text('Idioma'),
      trailing: DropdownButton<String>(
        value: 'Português',
        dropdownColor: AppColors.darkBackground,
        style: theme.textTheme.bodyLarge,
        items: <String>['Português', 'English']
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          // Lógica de mudança de idioma
        },
      ),
    );
  }
}