import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:irrigation_app/constants/globals.dart' as globals;
import 'plant_config.dart';

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  String statusSistema = 'Suspenso'; // Pode ser 'Ativo', 'Suspenso' ou 'Offline'
  int nivelBateria = 73;
  String statusPlacaSolar = 'Carregando'; // Pode ser 'Carregando', 'Inativo' ou 'N/A'

  double umidadePlantaX = 0.75; // 75%
  double umidadePlantaY = 0.10; // 10%
  double umidadePlantaZ = 0.30; // 30%
  double umidadePlantaW = 0.50; // 50%


  Color _getCorUmidade(double porcentagem) {
    if (porcentagem < 0.20) {
      return globals.red_graphic;
    } else if (porcentagem < 0.50) {
      return globals.yellow_graphic;
    } else {
      return globals.green_primary;
    }
  }

  Color _getCorStatusSistema(String status) {
    if (status == 'Offline') return globals.red_graphic;
    if (status == 'Suspenso') return globals.yellow_graphic;
    return globals.green_primary; 
  }

  Color _getCorBateria(int nivel) {
    if (nivel < 20) return globals.red_graphic;
    if (nivel < 50) return globals.yellow_graphic;
    return globals.green_primary;
  }

  Color _getCorPlacaSolar(String status) {
    if (status == 'N/A') return globals.red_graphic;
    if (status == 'Inativo') return globals.yellow_graphic;
    return globals.green_primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: false,
        title: Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            'Monitor',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTelemetryColumn(
                        value: statusSistema,
                        label: 'Status do\nSistema',
                        valueColor: _getCorStatusSistema(statusSistema), 
                      ),
                    ),

                    _buildVerticalDivider(),

                    Expanded(
                      child: _buildTelemetryColumn(
                        value: '$nivelBateria%',
                        label: 'Nível da\nBateria',
                        valueColor: _getCorBateria(nivelBateria),
                      ),
                    ),

                    _buildVerticalDivider(),

                    Expanded(
                      child: _buildTelemetryColumn(
                        value: statusPlacaSolar,
                        label: 'Status da\nPlaca Solar',
                        valueColor: _getCorPlacaSolar(statusPlacaSolar),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Nível de Umidade',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.88,
                  children: [
                    _buildPlantCard('Planta X', umidadePlantaX),
                    _buildPlantCard('Planta Y', umidadePlantaY),
                    _buildPlantCard('Planta Z', umidadePlantaZ),
                    _buildPlantCard('Planta W', umidadePlantaW),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildPlantCard(String nomePlanta, double umidade) {
    final Color corAtiva = _getCorUmidade(umidade);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlantConfigScreen(
              nomeAtual: nomePlanta,
              umidadeAlvoAtual: umidade,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              nomePlanta,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            
            CircularPercentIndicator(
              radius: 54.0,
              lineWidth: 10.0,
              animation: true,
              animationDuration: 1000,
              percent: umidade,
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: corAtiva,
              backgroundColor: corAtiva.withOpacity(0.20),
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(umidade * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'NÍVEL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
  Widget _buildTelemetryColumn({
    required String value,
    required String label,
    required Color valueColor,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodyMedium?.color,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 35,
      width: 1,
      color: Colors.grey.withOpacity(0.25),
    );
  }
}