/**
 * Sistema de Irrigação Automatizada - 4 Zonas (TCC)
 * Microcontrolador: ESP32
 * Lógica dos Relés: Active-High (HIGH = Liga, LOW = Desliga)
 */

// ==============================================================================
// 1. MAPEAMENTO DE PINOS (PREENCHA AQUI)
// ==============================================================================

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

// ==============================================================================
// 2. PARÂMETROS DE COMPORTAMENTO E LÓGICA
// ==============================================================================

// Lógica de Acionamento (Active-Low confirmada)
const int ESTADO_RELE_LIGADO    = LOW;
const int ESTADO_RELE_DESLIGADO = HIGH;

// NOVO LIMITE DE CALIBRAÇÃO (Ajustado para os seus sensores)
// Se no ar marca ~2600, qualquer valor acima de 2200 será considerado SECO.
const int LIMITE_TERRA_SECA = 2200; 

const unsigned long TEMPO_ESPERA_LOOP_MS = 5000;
const long BAUD_RATE_SERIAL = 115200;

// ==============================================================================
// 3. INICIALIZAÇÃO (SETUP)
// ==============================================================================

void setup() {
  Serial.begin(BAUD_RATE_SERIAL);
  Serial.println("Iniciando Sistema de Irrigação Sequencial...");

  pinMode(pinoSensorZone1, INPUT);
  pinMode(pinoSensorZone2, INPUT);
  pinMode(pinoSensorZone3, INPUT);
  pinMode(pinoSensorZone4, INPUT);

  pinMode(pinoReleZone1, OUTPUT);
  pinMode(pinoReleZone2, OUTPUT);
  pinMode(pinoReleZone3, OUTPUT);
  pinMode(pinoReleZone4, OUTPUT);

  // Garante que todas comecem desligadas
  digitalWrite(pinoReleZone1, ESTADO_RELE_DESLIGADO);
  digitalWrite(pinoReleZone2, ESTADO_RELE_DESLIGADO);
  digitalWrite(pinoReleZone3, ESTADO_RELE_DESLIGADO);
  digitalWrite(pinoReleZone4, ESTADO_RELE_DESLIGADO);
  
  Serial.println("Setup concluído.");
}

// ==============================================================================
// 4. CICLO PRINCIPAL (LOOP)
// ==============================================================================

void loop() {
  
  // --- LEITURA DOS SENSORES ---
  int leituraZone1 = analogRead(pinoSensorZone1);
  int leituraZone2 = analogRead(pinoSensorZone2);
  int leituraZone3 = analogRead(pinoSensorZone3);
  int leituraZone4 = analogRead(pinoSensorZone4);

  // --- LOG DE MONITORAMENTO ---
  Serial.println("--- Leituras de Umidade ---");
  Serial.print("Zona 1: "); Serial.println(leituraZone1);
  Serial.print("Zona 2: "); Serial.println(leituraZone2);
  Serial.print("Zona 3: "); Serial.println(leituraZone3);
  Serial.print("Zona 4: "); Serial.println(leituraZone4);
  Serial.println("---------------------------");

  // --- LÓGICA DE CONTROLE (SEQUENCIAL / UMA POR VEZ) ---
  
  if (leituraZone1 > LIMITE_TERRA_SECA) {
    // Zona 1 está seca: Liga a 1 e desliga TODAS as outras
    digitalWrite(pinoReleZone1, ESTADO_RELE_LIGADO);
    digitalWrite(pinoReleZone2, ESTADO_RELE_DESLIGADO);
    digitalWrite(pinoReleZone3, ESTADO_RELE_DESLIGADO);
    digitalWrite(pinoReleZone4, ESTADO_RELE_DESLIGADO);
    Serial.println("Status: IRRIGAÇÃO LIGADA na Zona 1 (Prioridade)");
  } 
  else if (leituraZone2 > LIMITE_TERRA_SECA) {
    // Zona 2 está seca (e a 1 já está OK): Liga a 2 e desliga as outras
    digitalWrite(pinoReleZone1, ESTADO_RELE_DESLIGADO);
    digitalWrite(pinoReleZone2, ESTADO_RELE_LIGADO);
    digitalWrite(pinoReleZone3, ESTADO_RELE_DESLIGADO);
    digitalWrite(pinoReleZone4, ESTADO_RELE_DESLIGADO);
    Serial.println("Status: IRRIGAÇÃO LIGADA na Zona 2");
  } 
  else if (leituraZone3 > LIMITE_TERRA_SECA) {
    // Zona 3 está seca (e a 1 e 2 estão OK): Liga a 3 e desliga as outras
    digitalWrite(pinoReleZone1, ESTADO_RELE_DESLIGADO);
    digitalWrite(pinoReleZone2, ESTADO_RELE_DESLIGADO);
    digitalWrite(pinoReleZone3, ESTADO_RELE_LIGADO);
    digitalWrite(pinoReleZone4, ESTADO_RELE_DESLIGADO);
    Serial.println("Status: IRRIGAÇÃO LIGADA na Zona 3");
  } 
  else if (leituraZone4 > LIMITE_TERRA_SECA) {
    // Zona 4 está seca (e as demais estão OK): Liga a 4 e desliga as outras
    digitalWrite(pinoReleZone1, ESTADO_RELE_DESLIGADO);
    digitalWrite(pinoReleZone2, ESTADO_RELE_DESLIGADO);
    digitalWrite(pinoReleZone3, ESTADO_RELE_DESLIGADO);
    digitalWrite(pinoReleZone4, ESTADO_RELE_LIGADO);
    Serial.println("Status: IRRIGAÇÃO LIGADA na Zona 4");
  } 
  else {
    // Todas as zonas estão úmidas: Desliga tudo
    digitalWrite(pinoReleZone1, ESTADO_RELE_DESLIGADO);
    digitalWrite(pinoReleZone2, ESTADO_RELE_DESLIGADO);
    digitalWrite(pinoReleZone3, ESTADO_RELE_DESLIGADO);
    digitalWrite(pinoReleZone4, ESTADO_RELE_DESLIGADO);
    Serial.println("Status: Todas as zonas com umidade ideal. Sistema em repouso.");
  }

  Serial.println(); 
  delay(TEMPO_ESPERA_LOOP_MS); 
}