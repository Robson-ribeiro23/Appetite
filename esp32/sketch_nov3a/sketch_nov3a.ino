

#include <WiFi.h>
#include <PubSubClient.h>
#include <WebServer.h>
#include <ArduinoJson.h>
#include <time.h> 

// ==========================================================
// 1. CONFIGURAÇÕES FIXAS DO DISPOSITIVO E BROKER
// ==========================================================
const char* mqttServer = "test.mosquitto.org"; 
const int mqttPort = 1883;
const char* mqttClientID = "ESP32_Appetite_Device";

// PINO DE CONTROLE DO MOTOR
const int MOTOR_PIN = 23; // Pino GPIO 2 é comum no ESP32, AJUSTE CONFORME SEU HARDWARE!

// TÓPICOS MQTT (Devem coincidir com os do Flutter)
const char* COMMAND_MANUAL_TOPIC = "appetite/comando/manual";
const char* COMMAND_ALARME_TOPIC = "appetite/comando/alarme";
const char* STATUS_TOPIC = "appetite/status/conexao";
const char* DISPENSE_STATUS_TOPIC = "appetite/status/dispensa";

// Variáveis globais de conexão
WiFiClient espClient;
PubSubClient client(espClient);

// Variáveis para a rede do USUÁRIO (FIXAS PARA O TESTE MANUAL)
const char* user_ssid = "WECLIX";     
const char* user_password = "weclix6755";  

// Variáveis de estado e NTP
const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = -10800; // -3 horas (GMT-3)
const int   daylightOffset_sec = 0;


// ==========================================================
// 2. FUNÇÕES DE ALIMENTAÇÃO E PUBLICAÇÃO
// ==========================================================

void dispenseFood(double grams) {
    Serial.printf("Comando recebido: Dispensar %.1f gramas.\n", grams);
    
    // Calcula o tempo de motor ligado (em milissegundos)
    // 100g = 10s (10000ms). Relação: 100ms por grama
    long dispenseTimeMs = (long)(grams * 100); 

    Serial.printf("Motor ligado por %ld milissegundos.\n", dispenseTimeMs);

    // === LÓGICA DE ATIVAÇÃO DO MOTOR ===
    digitalWrite(MOTOR_PIN, HIGH);
    delay(dispenseTimeMs); // Espera o tempo necessário
    digitalWrite(MOTOR_PIN, LOW); // Desliga o motor
    // =======================================

    char statusPayload[60];
    sprintf(statusPayload, "{\"grams\": %.1f, \"success\": true}", grams);
    client.publish(DISPENSE_STATUS_TOPIC, statusPayload);
    Serial.println("Confirmação de dispensa enviada ao Broker.");
}


// ==========================================================
// 3. FUNÇÃO QUE RECEBE COMANDOS DO APP FLUTTER (CALLBACK)
// ==========================================================

void callback(char* topic, byte* payload, unsigned int length) {
    String message;
    for (int i = 0; i < length; i++) {
        message += (char)payload[i];
    }
    Serial.printf("Mensagem recebida no topico: %s\n", topic);
    
    DynamicJsonDocument doc(1024); 
    DeserializationError error = deserializeJson(doc, message);

    if (error) {
        Serial.println("Falha ao analisar JSON!");
        return;
    }

    // A. COMANDO DE ALIMENTAÇÃO MANUAL
    if (strcmp(topic, COMMAND_MANUAL_TOPIC) == 0) {
        if (doc.containsKey("grams")) {
            double grams = doc["grams"].as<double>();
            dispenseFood(grams);
        }
    } 
    
    // B. COMANDO DE LISTA DE ALARMES
    else if (strcmp(topic, COMMAND_ALARME_TOPIC) == 0) {
        Serial.println("Nova lista de alarmes recebida. Salvando...");
        // [ADICIONE A LÓGICA DE SALVAR ALARMES EEPORM AQUI]
    }
}


// ==========================================================
// 4. CONEXÃO WI-FI MANUAL E MQTT
// ==========================================================

bool setup_wifi() { 
    delay(10);
    Serial.printf("Conectando-se a: %s\n", user_ssid);
    
    WiFi.disconnect(true);
    delay(100);
    
    WiFi.begin(user_ssid, user_password);

    int attempts = 0;
    const int maxAttempts = 40; // 20 segundos
    
    while (WiFi.status() != WL_CONNECTED && attempts < maxAttempts) {
        delay(500);
        Serial.print(".");
        attempts++;
    }

    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("\nWiFi conectado!");
        Serial.print("Endereco IP: ");
        Serial.println(WiFi.localIP());
        return true; 
    } else {
        Serial.println("\nFalha na conexao WiFi. Verifique SSID/Senha.");
        return false; 
    }
}

void reconnect_mqtt() {
    // Se o Wi-Fi não está conectado, não tente o MQTT
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("WiFi desconectado. Tentando restabelecer Wi-Fi...");
        delay(2000); 
        if (!setup_wifi()) {
            return; // Sai se o Wi-Fi ainda falhar
        }
    }
    
    while (!client.connected()) {
        Serial.print("Tentando conexao MQTT...");
        
        if (client.connect(mqttClientID)) {
            Serial.println("conectado ao Broker!");
            
            bool published = client.publish(STATUS_TOPIC, "online"); 
            
            if (published) {
                Serial.println("Status 'online' enviado ao Flutter.");
            } else {
                Serial.println("ERRO: Falha ao publicar status 'online'.");
            }
            
            client.subscribe(COMMAND_MANUAL_TOPIC);
            client.subscribe(COMMAND_ALARME_TOPIC);
            return; 
        } else {
            Serial.print("falhou, rc=");
            Serial.print(client.state());
            Serial.println(" Tentando em 5 segundos.");
            delay(5000);
        }
    }
}


// ==========================================================
// 5. SETUP E LOOP PRINCIPAL 
// ==========================================================

void setup() {
    Serial.begin(115200);
    
    // DEFINIÇÃO DO PINO DO MOTOR
    pinMode(MOTOR_PIN, OUTPUT); 
    digitalWrite(MOTOR_PIN, LOW); // Garante que o motor começa desligado
    
    if (setup_wifi()) { 
        // Se o Wi-Fi estiver OK, configura MQTT e NTP
        configTime(gmtOffset_sec, daylightOffset_sec, ntpServer); 
        
        client.setServer(mqttServer, mqttPort);
        client.setCallback(callback);
        
        // Tenta a primeira conexão MQTT
        reconnect_mqtt(); 
    } else {
        Serial.println("Sistema rodando sem conectividade MQTT.");
    }
}

void loop() {
    // Tenta manter o cliente MQTT conectado APENAS se o Wi-Fi estiver ativo
    if (WiFi.status() == WL_CONNECTED) { 
        if (!client.connected()) {
            reconnect_mqtt();
        }
        client.loop(); // Processa mensagens MQTT
    }
}
