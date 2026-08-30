import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:irrigation_app/constants/globals.dart' as globals;
import 'package:irrigation_app/services/mqtt_service.dart';
import 'plant_config.dart';

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  final MqttService _mqttService = MqttService();

  // Status da Rede e Energia
  bool _conectado = false;
  int _nivelBateria = 0;
  bool _carregandoSolar = false;

  // Umidade Atual (Recebida via MQTT: 0 a 100)
  int _umidadeZ1 = 0;
  int _umidadeZ2 = 0;
  int _umidadeZ3 = 0;
  int _umidadeZ4 = 0;

  // Nomes Personalizados (Lidos do SharedPreferences)
  String _nomeZ1 = 'Zona 1';
  String _nomeZ2 = 'Zona 2';
  String _nomeZ3 = 'Zona 3';
  String _nomeZ4 = 'Zona 4';

  @override
  void initState() {
    super.initState();
    _carregarNomes();
    _iniciarMQTT();
  }

  // 1. Carrega os nomes salvos no celular usando chaves padronizadas (1 a 4)
  Future<void> _carregarNomes() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _nomeZ1 = prefs.getString('nome_zona_1') ?? 'Planta X';
        _nomeZ2 = prefs.getString('nome_zona_2') ?? 'Planta Y';
        _nomeZ3 = prefs.getString('nome_zona_3') ?? 'Planta Z';
        _nomeZ4 = prefs.getString('nome_zona_4') ?? 'Planta W';
      });
    }
  }

  // Função dedicada para processar os dados recebidos em tempo real via lista de ouvintes
  void _aoReceberDadosMQTT(Map<String, dynamic> dados) {
    if (mounted) {
      setState(() {
        _umidadeZ1 = (dados["zona1"]?["umidade"] ?? 0).toInt();
        _umidadeZ2 = (dados["zona2"]?["umidade"] ?? 0).toInt();
        _umidadeZ3 = (dados["zona3"]?["umidade"] ?? 0).toInt();
        _umidadeZ4 = (dados["zona4"]?["umidade"] ?? 0).toInt();
        
        _nivelBateria = (dados["bateria_perc"] ?? 0).toInt();
        
        var carregandoVal = dados["carregando"];
        if (carregandoVal is bool) {
          _carregandoSolar = carregandoVal;
        } else {
          _carregandoSolar = (carregandoVal == 1 || carregandoVal.toString().toLowerCase() == 'true');
        }
      });
    }
  }

  // 2. Inicia a escuta adicionando o ouvinte sem conflitar com outras telas
  Future<void> _iniciarMQTT() async {
    _mqttService.adicionarOuvinte(_aoReceberDadosMQTT);

    bool conectou = await _mqttService.connect();
    if (mounted) setState(() => _conectado = conectou);
  }

  @override
  void dispose() {
    // Remove o ouvinte ao sair da tela para evitar vazamentos de memória
    _mqttService.removerOuvinte(_aoReceberDadosMQTT);
    super.dispose();
  }

  // Lógica de Cores
  Color _getCorUmidade(double porcentagem) {
    if (porcentagem < 0.30) return globals.red_graphic;
    if (porcentagem < 0.50) return globals.yellow_graphic;
    return globals.green_primary;
  }

  Color _getCorStatusSistema(bool conectado) {
    return conectado ? globals.green_primary : globals.red_graphic; 
  }

  Color _getCorBateria(int nivel) {
    if (nivel < 20) return globals.red_graphic;
    if (nivel < 50) return globals.yellow_graphic;
    return globals.green_primary;
  }

  Color _getCorPlacaSolar(bool carregando) {
    return carregando ? globals.green_primary : globals.yellow_graphic;
  }

  @override
  Widget build(BuildContext context) {
    String statusSistema = _conectado ? 'Ativo' : 'Offline';
    String statusPlacaSolar = _carregandoSolar ? 'Carregando' : 'Inativo';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
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

              // PAINEL DE TELEMETRIA SUPERIOR
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
                        valueColor: _getCorStatusSistema(_conectado), 
                      ),
                    ),
                    _buildVerticalDivider(),
                    Expanded(
                      child: _buildTelemetryColumn(
                        value: '$_nivelBateria%',
                        label: 'Nível da\nBateria',
                        valueColor: _getCorBateria(_nivelBateria),
                      ),
                    ),
                    _buildVerticalDivider(),
                    Expanded(
                      child: _buildTelemetryColumn(
                        value: statusPlacaSolar,
                        label: 'Status da\nPlaca Solar',
                        valueColor: _getCorPlacaSolar(_carregandoSolar),
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

              // GRIDS COM OS SENSORES
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.88,
                  children: [
                    _buildPlantCard(1, _nomeZ1, _umidadeZ1),
                    _buildPlantCard(2, _nomeZ2, _umidadeZ2),
                    _buildPlantCard(3, _nomeZ3, _umidadeZ3),
                    _buildPlantCard(4, _nomeZ4, _umidadeZ4),
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

  Widget _buildPlantCard(int zonaId, String nomePlanta, int umidadeInt) {
    double umidadeDecimal = (umidadeInt / 100.0).clamp(0.0, 1.0); 
    final Color corAtiva = _getCorUmidade(umidadeDecimal);

    return GestureDetector(
      onTap: () async {
        // Aguarda o retorno da tela de configuração passando o ID correto da zona
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlantConfigScreen(
              zonaId: zonaId,
              nomeAtual: nomePlanta,
              umidadeAlvoAtual: 0.3,
            ),
          ),
        );
        
        // Atualiza os nomes imediatamente ao retornar
        _carregarNomes();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            
            CircularPercentIndicator(
              radius: 54.0,
              lineWidth: 10.0,
              animation: false,
              percent: umidadeDecimal,
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: corAtiva,
              backgroundColor: corAtiva.withOpacity(0.20),
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$umidadeInt%',
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