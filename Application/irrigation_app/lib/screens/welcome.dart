import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:irrigation_app/constants/globals.dart' as globals;
import 'main_screen.dart'; // Mantivemos apenas a MainScreen, pois ela gerencia as outras

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // Função que executa a transição definitiva para o Painel Principal com as abas
  void _entrarNoApp(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MainScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: globals.white_background_primary,
      
      body: SafeArea(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                SvgPicture.asset(
                  'assets/images/eve_logo_light.svg',
                  width: size.width * 0.65,
                  fit: BoxFit.contain,
                ),

                const Spacer(flex: 2),

                // Botão de Entrada no App
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      _entrarNoApp(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: globals.white_background_terciary,
                      foregroundColor: globals.white_background_secondary, // Ajustado para contraste ideal
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Entrar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}