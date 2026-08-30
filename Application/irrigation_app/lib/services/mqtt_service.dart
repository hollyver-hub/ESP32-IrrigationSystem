import 'dart:io';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  // --- PADRÃO SINGLETON ---
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal();

  final String server = '308e743625204379bcaeaba9a8256715.s1.eu.hivemq.cloud';
  final int port = 8883;
  final String username = 'esp32';
  final String password = 'jbwg1234';

  MqttServerClient? _client;
  bool _isListening = false;
  
  // Armazena o último JSON recebido para consulta imediata ao abrir telas
  Map<String, dynamic>? ultimoJsonRecebido;

  // Lista de callbacks para suportar várias telas ouvindo ao mesmo tempo
  final List<Function(Map<String, dynamic> dadosJson)> _listeners = [];

  // Adiciona um ouvinte sem perder os outros
  void adicionarOuvinte(Function(Map<String, dynamic> dadosJson) callback) {
    if (!_listeners.contains(callback)) {
      _listeners.add(callback);
    }
  }

  // Remove o ouvinte quando a tela é fechada (dispose)
  void removerOuvinte(Function(Map<String, dynamic> dadosJson) callback) {
    _listeners.remove(callback);
  }

  Future<bool> connect() async {
    if (_client != null) {
      try {
        if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
          return true;
        } else {
          _client!.disconnect();
        }
      } catch (_) {}
    }

    _client = MqttServerClient.withPort(
      server, 
      'flutter_client_${DateTime.now().millisecondsSinceEpoch}', 
      port
    );
    
    _client!.secure = true;
    _client!.securityContext = SecurityContext.defaultContext; 
    _client!.logging(on: false); 
    _client!.keepAlivePeriod = 60;
    
    final MqttConnectMessage connMess = MqttConnectMessage()
        .authenticateAs(username, password)
        .withClientIdentifier('flutter_client_${DateTime.now().millisecondsSinceEpoch}')
        .startClean();
        
    _client!.connectionMessage = connMess;

    try {
      print('[MQTT] Conectando ao HiveMQ Cloud...');
      await _client!.connect();
    } catch (e) {
      print('[MQTT] Erro ao conectar: $e');
      _client?.disconnect();
      return false;
    }

    if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
      print('[MQTT] ✅ Conectado com sucesso!');
      
      _client!.subscribe("eve/estacao/telemetria", MqttQos.atLeastOnce);
      
      // Ouve as mensagens do broker e dispara para TODOS os ouvintes cadastrados
      if (!_isListening) {
        _isListening = true;
        _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? mensagens) {
          final recMess = mensagens![0].payload as MqttPublishMessage;
          final String payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
          final String topico = mensagens[0].topic;
          
          print('[MQTT-RX] Chegou em $topico: $payload');

          if (topico == "eve/estacao/telemetria") {
            try {
              Map<String, dynamic> jsonDecodificado = jsonDecode(payload);
              
              // Guarda o último pacote recebido em cache no serviço
              ultimoJsonRecebido = jsonDecodificado;

              // Notifica todas as telas abertas que estão ouvindo
              for (var listener in _listeners) {
                listener(jsonDecodificado);
              }
            } catch (e) {
              print('[MQTT] Erro ao decodificar JSON: $e');
            }
          }
        });
      }

      return true;
    } else {
      print('[MQTT] ❌ Falha. Status: ${_client!.connectionStatus?.state}');
      _client?.disconnect();
      return false;
    }
  }

  Future<void> publicarLimite(String topico, int porcentagem) async {
    if (_client == null || _client!.connectionStatus?.state != MqttConnectionState.connected) {
      print('[MQTT] ⚠️ Cliente desconectado. Reconectando para publicar...');
      bool conectado = await connect();
      if (!conectado) return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(porcentagem.toString()); 

    _client!.publishMessage(topico, MqttQos.atLeastOnce, builder.payload!, retain: true);
    print('[MQTT-TX] Publicado $porcentagem% no tópico $topico');
  }
}