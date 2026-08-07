import 'package:flutter/material.dart';
import 'package:irrigation_app/constants/globals.dart' as globals;
import '../../main.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool pushEnabled = true;
  bool darkModeEnabled = false;
  bool alertsEnabled = true;
  bool operationsEnabled = false;

  Widget _buildSwitchCard(String title, String? subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey))
            : null,
        value: value,
        activeColor: globals.green_primary,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyLarge?.color, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notificações e Preferências',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, height: 1.2),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Tipos de Notificações',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            _buildSwitchCard('Notificações Push', null, pushEnabled, (val) => setState(() => pushEnabled = val)),
            _buildSwitchCard(
              'Modo Escuro', 
              null, 
              themeNotifier.value == ThemeMode.dark,
              (val) {
                setState(() {
                  themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                });
              }
            ),            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Tipos de Notificações',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            
            _buildSwitchCard('Alertas', 'Nível do Reservatório/Bateria', alertsEnabled, (val) => setState(() => alertsEnabled = val)),
            _buildSwitchCard('Operações', 'Alertas relacionados a irrigação', operationsEnabled, (val) => setState(() => operationsEnabled = val)),
            
            const Spacer(),
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'Limpar Histórico',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}