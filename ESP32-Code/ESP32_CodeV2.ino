#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Preferences.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>

// --- CONFIGURAÇÕES DE BLUETOOTH E WIFI ---

#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define READ_NETWORKS_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define WRITE_CREDS_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a9"
#define TEMPO_DORMINDO_MINUTOS 60

Preferences preferences;
BLEServer *pServer = NULL;
BLECharacteristic *pReadCharacteristic = NULL; 
String scannedNetworksList = "";
bool credentialsReceived = false;
bool deviceConnected = false;
bool isConfigMode = false; 

// --- CONFIGURAÇÕES DO HIVEMQ CLOUD ---

const char* mqtt_server = "1b654873ea014ebd9c60a776226b7d09.s1.eu.hivemq.cloud"; 
const int mqtt_port = 8883; 
const char* mqtt_user = "esp32";
const char* mqtt_password = "jbwg1234";

WiFiClientSecure espClient;
PubSubClient mqttClient(espClient);

// =========================================================================
// MAPEAMENTO DOS PINOS DO ESP32
// =========================================================================

// Pinos dos Sensores de Umidade do Solo (ADC1: 32, 33, 34, 35, 36 ou 39)
const int pinoSensorZone1 = 36; 
const int pinoSensorZone2 = 39; 
const int pinoSensorZone3 = 34; 
const int pinoSensorZone4 = 35; 

// Pinos de Controle dos Relés (Pinos Seguros: 13, 14, 26, 27)
const int pinoReleZone1 = 26; 
const int pinoReleZone2 = 27; 
const int pinoReleZone3 = 14; 
const int pinoReleZone4 = 13; 

// Pino de Medição da Tensão da Bateria

const int pinoBateria = 32;

// Pinos do Sensor de Profundidade

const int pinoProfundidadeTrig = 5;
const int pinoProfundidadeEcho = 18;

// Varíaveis globais

const int ESTADO_RELE_LIGADO    = LOW;
const int ESTADO_RELE_DESLIGADO = HIGH;

const int MAXIMO_SECO = 2700; 
const int MAXIMO_UMIDO = 1100; 

int limiteZ1 = 30;
int limiteZ2 = 30;
int limiteZ3 = 30;
int limiteZ4 = 30;

const unsigned long TEMPO_ESPERA_LOOP_MS = 5000;
const long BAUD_RATE_SERIAL = 115200;

// =========================================================================
// FUNÇÕES DO BLUETOOTH E WI-FI (MANTIDAS INTACTAS)
// =========================================================================

void scanWiFiNetworks() {
  Serial.println("[WiFi] Escaneando redes...");
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  delay(20);

  int n = WiFi.scanNetworks(false, true);
  scannedNetworksList = "";

  if (n <= 0) {
    Serial.println("[WiFi] Nenhuma rede encontrada.");
    scannedNetworksList = "Nenhuma rede encontrada";
  } else {
    Serial.print("[WiFi] Redes encontradas: ");
    Serial.println(n);
    for (int i = 0; i < n; ++i) {
      String netName = WiFi.SSID(i);
      if (netName.length() > 0 && scannedNetworksList.indexOf(netName) == -1) {
        scannedNetworksList += netName;
        if (i < n - 1) {
          scannedNetworksList += ",";
        }
      }
    }
  }
  Serial.println("[WiFi] Lista pronta: " + scannedNetworksList);
}

class CredsCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    String rxValue = pCharacteristic->getValue().c_str();

    if (rxValue.length() > 0) {
      Serial.println("\n[BLE] Credenciais recebidas: " + rxValue);
      int separatorIndex = rxValue.indexOf('|');
      if (separatorIndex != -1) {
        String ssid = rxValue.substring(0, separatorIndex);
        String password = rxValue.substring(separatorIndex + 1);

        Serial.println("[WiFi] Testando conexão...");
        WiFi.begin(ssid.c_str(), password.c_str());

        int timeout = 0;
        while (WiFi.status() != WL_CONNECTED && timeout < 20) {
          delay(500); Serial.print("."); timeout++;
        }

        if (WiFi.status() == WL_CONNECTED) {
          Serial.println("\n[WiFi] ✅ Conexão bem-sucedida!");
          preferences.begin("eve_config", false);
          preferences.putString("ssid", ssid);
          preferences.putString("password", password);
          preferences.end();

          if (pReadCharacteristic != NULL) pReadCharacteristic->setValue("OK");
          credentialsReceived = true; 
        } else {
          Serial.println("\n[WiFi] ❌ Falha na conexão!");
          WiFi.disconnect();
          if (pReadCharacteristic != NULL) pReadCharacteristic->setValue("ERRO");
        }
      }
    }
  }
};

class NetworksReadCallbacks : public BLECharacteristicCallbacks {
  void onRead(BLECharacteristic *pCharacteristic) {
    String currentValue = pCharacteristic->getValue().c_str();
    if (currentValue == "OK" || currentValue == "ERRO") {
      if (currentValue == "ERRO") pCharacteristic->setValue(scannedNetworksList.c_str());
      return; 
    }
    pCharacteristic->setValue(scannedNetworksList.c_str());
  }
};

class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *pServer) {
    deviceConnected = true;
    Serial.println("\n[BLE] 🎉 Celular conectado!");
    if (pReadCharacteristic != NULL) {
      String val = pReadCharacteristic->getValue().c_str();
      if (val != "OK" && val != "ERRO") {
        scanWiFiNetworks();
        pReadCharacteristic->setValue(scannedNetworksList.c_str());
      }
    }
  }
  void onDisconnect(BLEServer *pServer) {
    deviceConnected = false;
    Serial.println("\n[BLE] ⚠️ Celular desconectado.");
    pServer->startAdvertising();
  }
};

// =========================================================================
// FUNÇÕES MQTT
// =========================================================================
void reconnectMQTT() {
  while (!mqttClient.connected()) {
    Serial.print("[MQTT] Tentando conexao com HiveMQ Cloud...");
    String clientId = "EVE_Station_";
    clientId += String(random(0xffff), HEX);
    
    // Conecta usando usuário e senha do HiveMQ
    if (mqttClient.connect(clientId.c_str(), mqtt_user, mqtt_password)) {
      Serial.println(" ✅ Conectado!");
      // mqttClient.subscribe("eve/comando"); // Aqui vamos assinar tópicos futuros

      mqttClient.subscribe("eve/estacao/config/z1"); 
      mqttClient.subscribe("eve/estacao/config/z2"); 
      mqttClient.subscribe("eve/estacao/config/z3"); 
      mqttClient.subscribe("eve/estacao/config/z4");

    } else {
      Serial.print(" ❌ Falhou, rc=");
      Serial.print(mqttClient.state());
      Serial.println(" Tentando novamente em 5 segundos...");
      delay(5000);
    }
  }
}

void mqttCallback(char* topic, byte* payload, unsigned int length) {
  String mensagem = "";
  for (int i = 0; i < length; i++) {
    mensagem += (char)payload[i];
  }
  
  int novoLimite = mensagem.toInt();
  
  if (novoLimite > 0 && novoLimite <= 100) {
    preferences.begin("eve_config", false);
    
    // Identifica qual zona o app está configurando pelo nome do tópico
    if (String(topic) == "eve/estacao/config/z1") {
      limiteZ1 = novoLimite;
      preferences.putInt("limite_z1", limiteZ1);
      Serial.println("[Config] Novo limite Zona 1: " + String(limiteZ1) + "%");
    } 
    else if (String(topic) == "eve/estacao/config/z2") {
      limiteZ2 = novoLimite;
      preferences.putInt("limite_z2", limiteZ2);
      Serial.println("[Config] Novo limite Zona 2: " + String(limiteZ2) + "%");
    }
    else if (String(topic) == "eve/estacao/config/z3") {
      limiteZ3 = novoLimite;
      preferences.putInt("limite_z3", limiteZ3);
      Serial.println("[Config] Novo limite Zona 3: " + String(limiteZ3) + "%");
    }
    else if (String(topic) == "eve/estacao/config/z4") {
      limiteZ4 = novoLimite;
      preferences.putInt("limite_z4", limiteZ4);
      Serial.println("[Config] Novo limite Zona 4: " + String(limiteZ4) + "%");
    }
    
    preferences.end();
  }
}

// =========================================================================
// SETUP
// =========================================================================
void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("\n=========================================");
  Serial.println("       E.V.E. - Inicializando Hardware   ");
  Serial.println("=========================================");

  preferences.begin("eve_config", true);
  String savedSSID = preferences.getString("ssid", "");
  String savedPass = preferences.getString("password", "");
  preferences.end();

  if (savedSSID != "") {
    Serial.print("[WiFi] Tentando conectar à rede salva: ");
    Serial.println(savedSSID);
    WiFi.begin(savedSSID.c_str(), savedPass.c_str());

    int timeout = 0;
    while (WiFi.status() != WL_CONNECTED && timeout < 20) {
      delay(500); Serial.print("."); timeout++;
    }
  }

  // Se conseguiu conectar no Wi-Fi, vai para o MODO OPERAÇÃO (MQTT + Irrigação)
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[WiFi] ✅ Conectado! IP: " + WiFi.localIP().toString());
    isConfigMode = false;

    // Configura o MQTT seguro
    espClient.setInsecure(); // Ignora validação de certificado para facilitar conexão com o HiveMQ
    mqttClient.setServer(mqtt_server, mqtt_port);

    // =========================================================
    // [ESPAÇO 1] INTEGRAÇÃO DA IRRIGAÇÃO (SETUP)
    // Aqui configuraremos pinMode das bombas, iniciaremos os 
    // sensores de solo/profundidade, etc.

  pinMode(pinoSensorZone1, INPUT);
  pinMode(pinoSensorZone2, INPUT);
  pinMode(pinoSensorZone3, INPUT);
  pinMode(pinoSensorZone4, INPUT);

  pinMode(pinoReleZone1, OUTPUT);
  pinMode(pinoReleZone2, OUTPUT);
  pinMode(pinoReleZone3, OUTPUT);
  pinMode(pinoReleZone4, OUTPUT);

  pinMode(pinoProfundidadeTrig, OUTPUT);
  pinMode(pinoProfundidadeEcho, INPUT);

  digitalWrite(pinoReleZone1, ESTADO_RELE_DESLIGADO);
  digitalWrite(pinoReleZone2, ESTADO_RELE_DESLIGADO);
  digitalWrite(pinoReleZone3, ESTADO_RELE_DESLIGADO);
  digitalWrite(pinoReleZone4, ESTADO_RELE_DESLIGADO);
  digitalWrite(pinoProfundidadeTrig, LOW);

    // =========================================================


  } 
  // Se falhou ou não tem rede, vai para o MODO CONFIGURAÇÃO (Bluetooth)
  else {
    Serial.println("\n[WiFi] ❌ Falha. Entrando em modo de configuração BLE...");
    isConfigMode = true;
    
    scanWiFiNetworks();
    BLEDevice::init("EVE_Config");
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());
    BLEService *pService = pServer->createService(SERVICE_UUID);

    pReadCharacteristic = pService->createCharacteristic(READ_NETWORKS_UUID, BLECharacteristic::PROPERTY_READ);
    pReadCharacteristic->setCallbacks(new NetworksReadCallbacks());
    pReadCharacteristic->setValue(scannedNetworksList.c_str());

    BLECharacteristic *pWriteCharacteristic = pService->createCharacteristic(WRITE_CREDS_UUID, BLECharacteristic::PROPERTY_WRITE);
    pWriteCharacteristic->setCallbacks(new CredsCallbacks());

    pService->start();
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    BLEDevice::startAdvertising();

    Serial.println("[BLE] Anunciando como 'EVE_Config'.");
  }
}

// =========================================================================
// LOOP PRINCIPAL
// =========================================================================
void loop() {
  if (isConfigMode) {
    // ---- MODO CONFIGURAÇÃO ----
    if (credentialsReceived) {
      Serial.println("[Sistema] Reiniciando placa para aplicar a nova rede Wi-Fi...");
      delay(1000);
      ESP.restart();
    }
    delay(100);
  } else {
    // ---- MODO OPERAÇÃO (IRRIGAÇÃO E NUVEM) ----
    
    // Resgata os limites antes de mais nada
    preferences.begin("eve_config", true);
    limiteZ1 = preferences.getInt("limite_z1", 30);
    limiteZ2 = preferences.getInt("limite_z2", 30);
    limiteZ3 = preferences.getInt("limite_z3", 30);
    limiteZ4 = preferences.getInt("limite_z4", 30);
    preferences.end();
    
    // Dá uma chance para o MQTT conectar e receber as mensagens novas (se houver)
    if (!mqttClient.connected()) {
      reconnectMQTT();
    }
    // Faz o MQTT rodar um pouquinho para processar os limites que acabaram de chegar
    for(int i = 0; i < 20; i++) {
      mqttClient.loop();
      delay(50); 
    }

    // =========================================================
    // INTEGRAÇÃO DA IRRIGAÇÃO E DEEP SLEEP
    // =========================================================
    const int TEMPO_REGA_MS = 10000;

    Serial.println("\n [Sistema] Iniciando leitura dos sensores de umidade...");

    int umidadeZ1 = analogRead(pinoSensorZone1);
    int umidadeZ2 = analogRead(pinoSensorZone2);
    int umidadeZ3 = analogRead(pinoSensorZone3);
    int umidadeZ4 = analogRead(pinoSensorZone4);

    // CORREÇÃO 1 e 2: Converte e restringe os valores para porcentagem ANTES de usar nos if's
    int percZ1 = constrain(map(umidadeZ1, 2700, 1100, 0, 100), 0, 100);
    int percZ2 = constrain(map(umidadeZ2, 2700, 1100, 0, 100), 0, 100);
    int percZ3 = constrain(map(umidadeZ3, 2700, 1100, 0, 100), 0, 100);
    int percZ4 = constrain(map(umidadeZ4, 2700, 1100, 0, 100), 0, 100);

    // Leitura da Profundidade
    digitalWrite(pinoProfundidadeTrig, LOW);
    delayMicroseconds(2);
    digitalWrite(pinoProfundidadeTrig, HIGH);
    delayMicroseconds(10);
    digitalWrite(pinoProfundidadeTrig, LOW);
    long duracao = pulseIn(pinoProfundidadeEcho, HIGH);
    float distancia_cm = (duracao * 0.0343) / 2.0;

    bool regouZ1 = false, regouZ2 = false, regouZ3 = false, regouZ4 = false;

    Serial.println("[Sistema] Analisando necessidades de rega...");

    if (percZ1 < limiteZ1) {
      Serial.println("[Irrigação] Zona 1 seca (" + String(percZ1) + "% < " + String(limiteZ1) + "%). Ligando...");
      digitalWrite(pinoReleZone1, ESTADO_RELE_LIGADO);
      delay(TEMPO_REGA_MS);
      digitalWrite(pinoReleZone1, ESTADO_RELE_DESLIGADO);
      regouZ1 = true;
      delay(1000); // Pausa pra bateria respirar
    }
    
    if (percZ2 < limiteZ2) {
      Serial.println("[Irrigação] Zona 2 seca (" + String(percZ2) + "% < " + String(limiteZ2) + "%). Ligando...");
      digitalWrite(pinoReleZone2, ESTADO_RELE_LIGADO);
      delay(TEMPO_REGA_MS);
      digitalWrite(pinoReleZone2, ESTADO_RELE_DESLIGADO);
      regouZ2 = true;
      delay(1000);
    }

    if (percZ3 < limiteZ3) {
      Serial.println("[Irrigação] Zona 3 seca (" + String(percZ3) + "% < " + String(limiteZ3) + "%). Ligando...");
      digitalWrite(pinoReleZone3, ESTADO_RELE_LIGADO);
      delay(TEMPO_REGA_MS);
      digitalWrite(pinoReleZone3, ESTADO_RELE_DESLIGADO);
      regouZ3 = true;
      delay(1000);
    }

    if (percZ4 < limiteZ4) {
      Serial.println("[Irrigação] Zona 4 seca (" + String(percZ4) + "% < " + String(limiteZ4) + "%). Ligando...");
      digitalWrite(pinoReleZone4, ESTADO_RELE_LIGADO);
      delay(TEMPO_REGA_MS);
      digitalWrite(pinoReleZone4, ESTADO_RELE_DESLIGADO);
      regouZ4 = true; // CORREÇÃO 3: Aqui estava regouZ2
      delay(1000);
    }

    // =========================================================
    // ENVIO PARA O HIVEMQ
    // =========================================================
    String payload = "{";
    payload += "\"zona1\":{\"umidade\":" + String(percZ1) + ",\"regou\":" + String(regouZ1) + "},";
    payload += "\"zona2\":{\"umidade\":" + String(percZ2) + ",\"regou\":" + String(regouZ2) + "},";
    payload += "\"zona3\":{\"umidade\":" + String(percZ3) + ",\"regou\":" + String(regouZ3) + "},";
    payload += "\"zona4\":{\"umidade\":" + String(percZ4) + ",\"regou\":" + String(regouZ4) + "},";
    payload += "\"profundidade_cm\":" + String(distancia_cm, 2);
    payload += "}";

    Serial.println("[MQTT] Enviando telemetria: " + payload);
    
    if (mqttClient.publish("eve/estacao/telemetria", payload.c_str())) {
      Serial.println("[MQTT] ✅ Dados enviados com sucesso!");
    } else {
      Serial.println("[MQTT] ❌ Falha ao enviar dados.");
    }

    delay(2000); // Dá tempo do rádio Wi-Fi transmitir o pacote antes de "capotar"

    // =========================================================
    // DORMIR (DEEP SLEEP)
    // =========================================================
    Serial.print("[Sistema] Missão cumprida. Entrando em Deep Sleep por ");
    Serial.print(TEMPO_DORMINDO_MINUTOS);
    Serial.println(" minutos...");
    
    uint64_t tempoDormir = TEMPO_DORMINDO_MINUTOS * 60ULL * 1000000ULL;
    esp_sleep_enable_timer_wakeup(tempoDormir);
    
    esp_deep_sleep_start();
  }
}