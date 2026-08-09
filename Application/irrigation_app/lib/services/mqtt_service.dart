import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  // Use as mesmas credenciais que você colocou no código do ESP32!
  final String server = '1b654873ea014ebd9c60a776226b7d09.s1.eu.hivemq.cloud';
  final int port = 8883;
  final String username = 'esp32';
  final String password = 'jbwg1234';

  late MqttServerClient client;

  // Função para conectar ao HiveMQ Cloud
  Future<bool> connect() async {
    client = MqttServerClient.withPort(server, 'flutter_client_${DateTime.now().millisecondsSinceEpoch}', port);
    
    client.secure = true;
    client.securityContext = SecurityContext.defaultContext; // Necessário para SSL/TLS na porta 8883
    client.logging(on: false); // Mude para true se quiser ver os logs no console
    client.keepAlivePeriod = 60;
    
    final MqttConnectMessage connMess = MqttConnectMessage()
        .authenticateAs(username, password)
        .withClientIdentifier('flutter_client_${DateTime.now().millisecondsSinceEpoch}')
        .startClean();
        
    client.connectionMessage = connMess;

    try {
      print('[MQTT] Conectando ao HiveMQ Cloud...');
      await client.connect();
    } catch (e) {
      print('[MQTT] Erro ao conectar: $e');
      client.disconnect();
      return false;
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('[MQTT] ✅ Conectado com sucesso!');
      return true;
    } else {
      print('[MQTT] ❌ Falha. Status: ${client.connectionStatus!.state}');
      client.disconnect();
      return false;
    }
  }

  // Função para publicar o limite de rega
  void publicarLimite(String topico, int porcentagem) {
    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      print('[MQTT] Erro: Cliente não está conectado.');
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(porcentagem.toString()); // Envia apenas o número, ex: "45"

    // O "retain: true" é o pulo do gato! 
    // Ele faz o servidor guardar a mensagem até a placa acordar do Deep Sleep.
    client.publishMessage(topico, MqttQos.atLeastOnce, builder.payload!, retain: true);
    print('[MQTT] Publicado $porcentagem% no tópico $topico');
  }
}