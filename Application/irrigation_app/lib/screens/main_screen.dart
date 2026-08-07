import 'package:flutter/material.dart';
import 'package:irrigation_app/constants/globals.dart' as globals;
import 'package:irrigation_app/screens/reservatory.dart';
import 'package:irrigation_app/screens/monitor.dart';
import 'package:irrigation_app/screens/settings/settings.dart'; 

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _abaSelecionada = 0;

  final List<Widget> _telas = [
    const ReservatoryScreen(),
    const MonitorScreen(),
    const SettingsScreen(), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: IndexedStack(
        index: _abaSelecionada,
        children: _telas,
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.inventory_2_outlined, 'Reservatório'),
            _buildNavItem(1, Icons.bar_chart, 'Monitor'),
            _buildNavItem(2, Icons.settings_outlined, 'Ajustes'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _abaSelecionada == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _abaSelecionada = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).canvasColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? globals.white_background_secondary : globals.green_primary,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}