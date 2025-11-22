#include <WiFi.h>
#include <PubSubClient.h>
#include <WebServer.h>      
#include <ArduinoJson.h>
#include <time.h> 
#include <Preferences.h>
#include <vector> // Necessário para lista dinâmica de alarmes

// --- CONFIGURAÇÕES MQTT ---
const char* mqttServer = "test.mosquitto.org"; 
const int mqttPort = 1883; 
const char* mqttClientID = "ESP32_Appetite_Device";

const char* COMMAND_MANUAL_TOPIC = "appetite/comando/manual";
const char* COMMAND_ALARME_TOPIC = "appetite/comando/alarme";
const char* STATUS_TOPIC = "appetite/status/conexao";
const char* DISPENSE_STATUS_TOPIC = "appetite/status/dispensa";

// --- HARDWARE ---
const int MOTOR_PIN = 23; 
const int FACTORY_RESET_PIN = 0; 

// --- OBJETOS ---
WiFiClient espClient;
PubSubClient client(espClient);
Preferences preferences; 
WebServer server(80);

// --- VARIÁVEIS DE REDE ---
const char* AP_SSID = "Appetite_SETUP"; 
const char* AP_PASSWORD = "";          
String user_ssid = "";
String user_password = ""; 
bool provisioned = false; 

// --- RELÓGIO NTP ---
const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = -10800; // GMT-3 (Brasil)
const int   daylightOffset_sec = 0;

// --- ESTADO DO MOTOR ---
bool motorIsRunning = false;
unsigned long motorStopTime = 0;

// --- ESTRUTURA DE ALARMES (NOVO) ---
struct Alarm {
    int hour;
    int minute;
    double grams;
    bool active;
    // Nota: Simplificamos para não checar dias da semana por enquanto no ESP
    // para garantir que funcione a lógica básica primeiro.
};
std::vector<Alarm> scheduledAlarms; // Lista de alarmes na memória
int lastCheckedMinute = -1; // Para evitar disparar várias vezes no mesmo minuto

// --- FUNÇÕES ---

void dispenseFood(double grams) {
    if (motorIsRunning) {
        Serial.println("Motor já está em funcionamento, comando ignorado.");
        return;
    }
  
    Serial.printf("Comando recebido: Dispensar %.1f gramas.\n", grams);
    
    // Fator de calibração: 250ms por grama (Ajuste solicitado)
    long dispenseTimeMs = (long)(grams * 250); 

    Serial.printf("Motor será ligado por %ld milissegundos.\n", dispenseTimeMs);

    motorIsRunning = true;
    motorStopTime = millis() + dispenseTimeMs; 
    digitalWrite(MOTOR_PIN, HIGH); 

    char statusPayload[60];
    sprintf(statusPayload, "{\"grams\": %.1f, \"success\": true}", grams);
    client.publish(DISPENSE_STATUS_TOPIC, statusPayload);
    Serial.println("Confirmação de dispensa enviada ao Broker.");
}

// --- VERIFICAÇÃO DE ALARMES (NOVO) ---
void checkAlarms() {
    struct tm timeinfo;
    if(!getLocalTime(&timeinfo)){
        return; // Ainda não sincronizou o relógio
    }

    // Verifica apenas uma vez por minuto
    if (timeinfo.tm_min == lastCheckedMinute) return;
    lastCheckedMinute = timeinfo.tm_min;

    Serial.printf("Verificando alarmes para: %02d:%02d\n", timeinfo.tm_hour, timeinfo.tm_min);

    for (const auto& alarm : scheduledAlarms) {
        if (alarm.active && alarm.hour == timeinfo.tm_hour && alarm.minute == timeinfo.tm_min) {
            Serial.println("ALARME DISPARADO PELO ESP32!");
            dispenseFood(alarm.grams);
        }
    }
}

// --- MQTT CALLBACK ---
void callback(char* topic, byte* payload, unsigned int length) {
    String message;
    for (int i = 0; i < length; i++) {
        message += (char)payload[i];
    }
    Serial.printf("Mensagem no topico: %s\n", topic);
    
    DynamicJsonDocument doc(2048); // Aumentei o buffer para caber a lista de alarmes
    DeserializationError error = deserializeJson(doc, message);

    if (error) {
        Serial.print("Erro JSON: ");
        Serial.println(error.c_str());
        return;
    }

    // 1. COMANDO MANUAL
    if (strcmp(topic, COMMAND_MANUAL_TOPIC) == 0) {
        if (doc.containsKey("grams")) {
            double grams = doc["grams"].as<double>();
            dispenseFood(grams);
        }
    } 
    // 2. ATUALIZAÇÃO DE ALARMES (NOVO)
    else if (strcmp(topic, COMMAND_ALARME_TOPIC) == 0) {
        Serial.println("Recebendo nova lista de alarmes...");
        scheduledAlarms.clear(); // Limpa a lista antiga

        JsonArray arr = doc.as<JsonArray>();
        for (JsonObject v : arr) {
            Alarm newAlarm;
            newAlarm.hour = v["hour"];
            newAlarm.minute = v["minute"];
            newAlarm.grams = v["grams"];
            newAlarm.active = v["isActive"];
            // Adiciona na lista
            scheduledAlarms.push_back(newAlarm);
            Serial.printf("Alarme salvo: %02d:%02d - %.1fg\n", newAlarm.hour, newAlarm.minute, newAlarm.grams);
        }
        Serial.println("Lista de alarmes atualizada no ESP32.");
    }
}

void reconnect_mqtt() {
    while (!client.connected()) {
        Serial.print("Conectando MQTT...");
        String lwtPayload = "offline";
        if (client.connect(mqttClientID, STATUS_TOPIC, 1, true, lwtPayload.c_str())) {
            Serial.println("OK!");
            client.publish(STATUS_TOPIC, "online", true); 
            client.subscribe(COMMAND_MANUAL_TOPIC);
            client.subscribe(COMMAND_ALARME_TOPIC);
        } else {
            Serial.print("falha rc=");
            Serial.print(client.state());
            Serial.println(" tentando em 5s");
            delay(5000);
        }
    }
}

// --- FUNÇÕES AUXILIARES ---
void saveCredentials(String ssid, String password) {
    preferences.begin("appetite-creds", false); 
    preferences.putString("user_ssid", ssid);
    preferences.putString("user_password", password);
    preferences.end();
}

void clearCredentials() {
    preferences.begin("appetite-creds", false);
    preferences.clear();
    preferences.end();
}

void handleRoot() { server.send(200, "text/plain", "Appetite Provisioning Mode"); }

void handleConfig() {
    if (server.hasArg("ssid") && server.hasArg("password")) {
        user_ssid = server.arg("ssid");
        user_password = server.arg("password");
        saveCredentials(user_ssid, user_password);
        server.send(200, "text/plain", "Salvo. Reiniciando...");
        delay(1000);
        ESP.restart(); 
    } else {
        server.send(400, "text/plain", "Faltam dados.");
    }
}

void startProvisioningMode() {
    WiFi.mode(WIFI_AP);
    WiFi.softAP(AP_SSID, AP_PASSWORD);
    server.on("/", HTTP_GET, handleRoot); 
    server.on("/config", HTTP_POST, handleConfig); 
    server.begin();
}

void loadCredentials() {
    preferences.begin("appetite-creds", true); 
    user_ssid = preferences.getString("user_ssid", "");
    user_password = preferences.getString("user_password", "");
    preferences.end();
}

void checkFactoryReset() {
    pinMode(FACTORY_RESET_PIN, INPUT_PULLUP); 
    if (digitalRead(FACTORY_RESET_PIN) == LOW) { 
        delay(100);
        if (digitalRead(FACTORY_RESET_PIN) == LOW) {
             Serial.println("Resetando...");
             long start = millis();
             while(digitalRead(FACTORY_RESET_PIN) == LOW && millis() - start < 5000) delay(100);
             if(millis() - start >= 5000) {
                 clearCredentials();
                 ESP.restart();
             }
        }
    }
}

void setup_system_mode() {
    loadCredentials();
    if (user_ssid == "" || user_password == "") {
        provisioned = false;
        return; 
    }
    WiFi.mode(WIFI_STA); 
    WiFi.begin(user_ssid.c_str(), user_password.c_str());
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20) { 
        delay(500);
        attempts++;
    }
    provisioned = (WiFi.status() == WL_CONNECTED);
}

// --- SETUP & LOOP ---

void setup() {
    Serial.begin(115200);
    pinMode(MOTOR_PIN, OUTPUT);
    digitalWrite(MOTOR_PIN, LOW);
    
    checkFactoryReset(); 
    setup_system_mode(); 
    
    if (provisioned) {
        configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
        client.setServer(mqttServer, mqttPort);
        client.setBufferSize(2048);
        client.setCallback(callback);
    } else {
        startProvisioningMode();
    }
}

void loop() {
    if (provisioned) {
        if (WiFi.status() != WL_CONNECTED) ESP.restart();
        
        if (!client.connected()) reconnect_mqtt();
        client.loop(); 
        
        checkAlarms(); // <--- O ESP32 AGORA CHECA OS ALARMES SOZINHO!

        if (motorIsRunning && (millis() >= motorStopTime)) {
            digitalWrite(MOTOR_PIN, LOW);
            motorIsRunning = false;
            Serial.println("Motor desligado.");
        }
    } else {
        server.handleClient(); 
    }
}