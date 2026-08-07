import 'package:flutter/material.dart';
import 'package:irrigation_app/constants/globals.dart' as globals;
import 'package:flutter_svg/flutter_svg.dart';
import 'manual.dart';
import 'telemetry.dart';
import 'notif.dart';
import 'registers.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _buildSettingsItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 4.0),
      leading: Icon(
        icon,
        color: globals.green_primary,
        size: 28,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          // Agora o context é reconhecido perfeitamente aqui!
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).textTheme.bodyLarge?.color,
        size: 24,
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 100),
            
               
           SvgPicture.asset(
            isDarkMode 
                ? 'assets/images/eve_logo_dark.svg'   // Se for modo escuro, carrega este
                : 'assets/images/eve_logo_light.svg', // Se for modo claro, carrega este
            width: size.width * 0.55,
            fit: BoxFit.contain,
          ),


            const SizedBox(height: 100),

            // 2. ADICIONADO: Passando o context para a função
            _buildSettingsItem(
              context: context, 
              icon: Icons.notifications_none,
              title: 'Notificações e Preferências',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(), // Lembre-se do const se a tela for Stateless
                  ),
                );
              },
            ),

            const SizedBox(height: 5),

            Padding(
              padding: const EdgeInsets.only(left: 76.0, top: 8.0, bottom: 8.0), 
              child: Text(
                'Opções de Desenvolvedor',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),

            const SizedBox(height: 10),

            _buildSettingsItem(
              context: context, // Passando o context
              icon: Icons.dashboard_customize_outlined, 
              title: 'Telemetria e Diagnóstico',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TelemetryScreen(),
                  ),
                );
              },
            ),

            _buildSettingsItem(
              context: context, // Passando o context
              icon: Icons.tag, 
              title: 'Controle Manual',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManualControlScreen(),
                  ),
                );
              },
            ),

            _buildSettingsItem(
              context: context, // Passando o context
              icon: Icons.storage_outlined, 
              title: 'Sistemas e Registros',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SystemsLogsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}