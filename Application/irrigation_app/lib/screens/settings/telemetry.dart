import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:irrigation_app/constants/globals.dart' as globals;
import 'package:irrigation_app/services/mqtt_service.dart';

class TelemetryScreen extends StatefulWidget {
  const TelemetryScreen({super.key});

  @override
  State<TelemetryScreen> createState() => _TelemetryScreenState();
}

class _TelemetryScreenState extends State<TelemetryScreen> {
  final MqttService _mqttService = MqttService();

  // Variáveis para armazenar os dados recebidos
  int _umidadeZ1 = 0;
  int _umidadeZ2 = 0;
  int _umidadeZ3 = 0;
  int _umidadeZ4 = 0;
  int _bateriaPerc = 0;
  bool _carregandoSolar = false;
  double _profundidade = 0.0;
  bool _conectado = false;

  // Variáveis de Diagnóstico da Rede
  String _nomeRede = 'Aguardando ESP32...';
  String _ipRede = 'Aguardando ESP32...';
  String _macAddress = 'Aguardando ESP32...';

  // Nomes Personalizados das Zonas
  String _nomeZ1 = 'Zona 1';
  String _nomeZ2 = 'Zona 2';
  String _nomeZ3 = 'Zona 3';
  String _nomeZ4 = 'Zona 4';

  @override
  void initState() {
    super.initState();
    _carregarNomesSalvos();
    
    // Se já houver dados salvos em cache no serviço, carrega instantaneamente ao abrir a tela
    if (_mqttService.ultimoJsonRecebido != null) {
      _aoReceberTelemetriaMQTT(_mqttService.ultimoJsonRecebido!);
    }

    _iniciarTelemetria();
  }

  // Carrega os nomes salvos no celular via SharedPreferences
  Future<void> _carregarNomesSalvos() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _nomeZ1 = prefs.getString('nome_zona_1') ?? 'Zona 1';
        _nomeZ2 = prefs.getString('nome_zona_2') ?? 'Zona 2';
        _nomeZ3 = prefs.getString('nome_zona_3') ?? 'Zona 3';
        _nomeZ4 = prefs.getString('nome_zona_4') ?? 'Zona 4';
      });
    }
  }

  // Função dedicada para processar a telemetria via lista de ouvintes
  void _aoReceberTelemetriaMQTT(Map<String, dynamic> dados) {
    if (mounted) {
      setState(() {
        _umidadeZ1 = (dados["zona1"]?["umidade"] ?? 0).toInt();
        _umidadeZ2 = (dados["zona2"]?["umidade"] ?? 0).toInt();
        _umidadeZ3 = (dados["zona3"]?["umidade"] ?? 0).toInt();
        _umidadeZ4 = (dados["zona4"]?["umidade"] ?? 0).toInt();
        _bateriaPerc = (dados["bateria_perc"] ?? 0).toInt();
        _carregandoSolar = dados["carregando"] ?? false;
        _profundidade = (dados["profundidade_cm"] ?? 0).toDouble();

        // Leitura dos dados de rede enviados pelo ESP32
        _nomeRede = dados["ssid"]?.toString() ?? _nomeRede;
        _ipRede = dados["ip"]?.toString() ?? _ipRede;
        _macAddress = dados["mac"]?.toString() ?? _macAddress;
      });
    }
  }

  Future<void> _iniciarTelemetria() async {
    // Adiciona o ouvinte sem sobrescrever o das outras telas
    _mqttService.adicionarOuvinte(_aoReceberTelemetriaMQTT);

    // Conecta ao servidor e atualiza o status de conexão
    bool conectou = await _mqttService.connect();
    if (mounted) {
      setState(() {
        _conectado = conectou;
      });
    }
  }

  @override
  void dispose() {
    // Remove o ouvinte ao sair da tela para evitar vazamento de memória
    _mqttService.removerOuvinte(_aoReceberTelemetriaMQTT);
    super.dispose();
  }

  Widget _buildDataRow(BuildContext context, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label, 
              style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value, 
            style: TextStyle(
              fontSize: 16, 
              color: valueColor ?? Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
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
          'Telemetria e Diagnóstico',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, height: 1.2),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Sensores de Umidade'),
            // Nomes personalizados exibidos entre parênteses
            _buildDataRow(context, 'Zona 1 ($_nomeZ1):', '$_umidadeZ1%'),
            _buildDataRow(context, 'Zona 2 ($_nomeZ2):', '$_umidadeZ2%'),
            _buildDataRow(context, 'Zona 3 ($_nomeZ3):', '$_umidadeZ3%'),
            _buildDataRow(context, 'Zona 4 ($_nomeZ4):', '$_umidadeZ4%'),
            
            _buildSectionTitle(context, 'Reservatório'),
            _buildDataRow(context, 'Profundidade:', '${_profundidade.toStringAsFixed(1)} cm'),

            _buildSectionTitle(context, 'Energia'),
            _buildDataRow(context, 'Nível da Bateria:', '$_bateriaPerc%'),
            _buildDataRow(
              context, 
              'Painel Solar:', 
              _carregandoSolar ? 'Carregando ☀️' : 'Sem Sol / Inativo',
              valueColor: _carregandoSolar ? Colors.orange : Colors.grey,
            ),

            _buildSectionTitle(context, 'Diagnóstico da Rede'),
            _buildDataRow(
              context, 
              'STATUS MQTT:', 
              _conectado ? 'ONLINE' : 'OFFLINE',
              valueColor: _conectado ? globals.green_primary : Colors.red,
            ),
            _buildDataRow(context, 'NOME DA REDE:', _nomeRede),
            _buildDataRow(context, 'IP:', _ipRede),
            _buildDataRow(context, 'MAC:', _macAddress),
          ],
        ),
      ),
    );
  }
}