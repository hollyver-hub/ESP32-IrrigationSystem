import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:irrigation_app/constants/globals.dart' as globals;

class ReservatoryScreen extends StatefulWidget {
  const ReservatoryScreen({super.key});

  @override
  State<ReservatoryScreen> createState() => _ReservatoryScreenState();
}

class _ReservatoryScreenState extends State<ReservatoryScreen> {
  double nivelPorcentagem = 0.5;
  int litrosDisponiveis = 10;
  int litrosConsumidos = 3;
  
  void _atualizarDadosTeste(double novaPorcentagem, int disponivel, int consumido) {
    setState(() {
      nivelPorcentagem = novaPorcentagem;
      litrosDisponiveis = disponivel;
      litrosConsumidos = consumido;
    });
  }

  Color _getCorPorcentagem(double porcentagem) {
    if (porcentagem < 0.20) {
      return globals.red_graphic;
    } else if (porcentagem < 0.50) {
      return globals.yellow_graphic; 
    } else {
      return globals.green_primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color corDinamica = _getCorPorcentagem(nivelPorcentagem);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: false,
        title:  Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            'Reservatório',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),

            Center(
              child: CircularPercentIndicator(
                radius: 110.0,
                lineWidth: 18.0,
                animation: true,
                animationDuration: 1000,
                percent: nivelPorcentagem, 
                circularStrokeCap: CircularStrokeCap.round,
                
                progressColor: corDinamica,
                
                backgroundColor: corDinamica.withOpacity(0.20),

                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(nivelPorcentagem * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.w900,
                        color:  Theme.of(context).textTheme.bodyLarge?.color,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                   Text(
                      'NÍVEL',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(flex: 1),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: globals.white_background_text.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '$litrosDisponiveis Litros',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: globals.green_primary, 
                            ),
                          ),
                          const SizedBox(height: 4),
                         Text(
                            'Disponível',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey.withOpacity(0.3),
                    ),

                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '$litrosConsumidos Litros',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF58C887),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Consumido',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(flex: 3),
          ],
        ),
      ),

    );
  }
}