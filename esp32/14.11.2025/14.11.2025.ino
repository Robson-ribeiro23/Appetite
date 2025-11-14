#include <PubSubClient.h> // REMOVA se não for usar MQTT
#include <WebServer.h>      
#include <ArduinoJson.h>
#include <time.h> 
#include <Preferences.h>    
#include <WiFi.h> // CORREÇÃO: Removido o '/' extra

// --- CONFIGURAÇÕES DE REDE ---
const char* AP_SSID = "Appetite_SETUP"; 
const char* AP_PASSWORD = ""; 

// --- PINOS ---
const int MOTOR_PIN = 23; 
const int FACTORY_RESET_PIN = 0; 

// --- VARIÁVEIS DE ESTADO DO DISPOSITIVO ---
bool motorIsRunning = false;
unsigned long motorStopTime = 0;
String user_ssid = "";
String user_password = ""; 
bool provisioned = false; 
IPAddress esp32LocalIP; 

// --- OBJETOS GLOBAIS ---
Preferences preferences; 
WebServer server(80); 

// --- CONFIGURAÇÕES DE TEMPO (NTP) ---
const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = -10800; // Brasil GMT-3
const int   daylightOffset_sec = 0;

// --- FUNÇÕES DE UTILIDADE ---
void dispenseFood(double grams);
void saveCredentials(String ssid, String password);
void clearCredentials();
void handleRoot();
void handleConfig();
void handleStatus();
void handleManualFeed();
void handleAlarms();
void startProvisioningMode();
void loadCredentials();
void checkFactoryReset();
void setup_system_mode();
void syncTime();
void setup(); // Precisa ser definida
void loop();  // Precisa ser definida

// --- IMPLEMENTAÇÃO DAS FUNÇÕES ---

void dispenseFood(double grams) {
    if (motorIsRunning) {
        Serial.println("Motor já está em funcionamento, comando ignorado.");
        server.send(409, "application/json", "{\"success\":false,\"message\":\"Motor ocupado\"}");
        return;
    }
  
    Serial.printf("Comando recebido: Dispensar %.1f gramas.\n", grams);
    
    // Aumentei o fator para um teste mais longo, ajuste conforme seu motor
    // 1 grama = 100 ms é um valor de exemplo, precisa calibrar.
    long dispenseTimeMs = (long)(grams * 100); 

    Serial.printf("Motor será ligado por %ld milissegundos.\n", dispenseTimeMs);

    motorIsRunning = true;
    motorStopTime = millis() + dispenseTimeMs; 
    digitalWrite(MOTOR_PIN, HIGH); 

    DynamicJsonDocument doc(128);
    doc["grams"] = grams;
    doc["success"] = true;
    doc["message"] = "Dispensando comida.";

    String response;
    serializeJson(doc, response);
    server.send(200, "application/json", response);
    Serial.println("Confirmação de dispensa enviada via HTTP.");
}

void saveCredentials(String ssid, String password) {
    preferences.begin("appetite-creds", false); 
    preferences.putString("user_ssid", ssid);
    preferences.putString("user_password", password);
    preferences.end();
    Serial.println("Credenciais salvas na Flash.");
}

void clearCredentials() {
    Serial.println("LIMPANDO CREDENCIAIS (FACTORY RESET)...");
    preferences.begin("appetite-creds", false);
    preferences.remove("user_ssid");
    preferences.remove("user_password");
    preferences.end();
}

void handleRoot() {
    server.send(200, "text/plain", "Appetite Provisioning Mode - ESP32 AP");
}

void handleConfig() {
    if (server.method() != HTTP_POST) {
        server.send(405, "text/plain", "Method Not Allowed");
        return;
    }
    if (server.hasArg("ssid") && server.hasArg("password")) {
        user_ssid = server.arg("ssid");
        user_password = server.arg("password");
        saveCredentials(user_ssid, user_password);
        server.send(200, "text/plain", "Credenciais recebidas. Reiniciando...");
        Serial.printf("Credenciais recebidas e salvas: SSID=%s\n", user_ssid.c_str());
        delay(100);
        ESP.restart(); 
    } else {
        server.send(400, "text/plain", "Faltando parâmetros de SSID/Senha.");
    }
}

void handleStatus() {
    DynamicJsonDocument doc(256);
    doc["status"] = WiFi.status() == WL_CONNECTED ? "online" : "offline";
    doc["motorIsRunning"] = motorIsRunning;
    doc["localIP"] = WiFi.localIP().toString();

    String response;
    serializeJson(doc, response);
    server.send(200, "application/json", response);
}

void handleManualFeed() {
    if (server.method() != HTTP_POST) {
        server.send(405, "application/json", "{\"success\":false,\"message\":\"Method Not Allowed\"}");
        return;
    }
    if (!server.hasArg("plain")) {
        server.send(400, "application/json", "{\"success\":false,\"message\":\"Missing JSON body\"}");
        return;
    }

    String requestBody = server.arg("plain");
    DynamicJsonDocument doc(256);
    DeserializationError error = deserializeJson(doc, requestBody);

    if (error) {
        Serial.println("Falha ao analisar JSON para alimentação manual.");
        server.send(400, "application/json", "{\"success\":false,\"message\":\"Invalid JSON\"}");
        return;
    }

    if (doc.containsKey("grams")) {
        double grams = doc["grams"].as<double>();
        if (grams <= 0) {
            server.send(400, "application/json", "{\"success\":false,\"message\":\"Grams must be positive\"}");
            return;
        }
        dispenseFood(grams);
    } else {
        server.send(400, "application/json", "{\"success\":false,\"message\":\"Missing 'grams' parameter\"}");
    }
}

void handleAlarms() {
    if (server.method() == HTTP_POST) {
        if (!server.hasArg("plain")) {
            server.send(400, "application/json", "{\"success\":false,\"message\":\"Missing JSON body\"}");
            return;
        }
        String alarmsJson = server.arg("plain");
        // Futuramente: Salve alarmsJson em Preferences ou SPIFFS
        Serial.printf("Alarmes recebidos via HTTP POST: %s\n", alarmsJson.c_str());
        server.send(200, "application/json", "{\"success\":true,\"message\":\"Alarms updated\"}");
    } else if (server.method() == HTTP_GET) {
        // Futuramente: Leia alarmes salvos e retorne
        Serial.println("Requisição GET para alarmes.");
        server.send(200, "application/json", "[]");
    } else {
        server.send(405, "application/json", "{\"success\":false,\"message\":\"Method Not Allowed\"}");
    }
}

void startProvisioningMode() {
    Serial.println("Entrando em MODO DE CONFIGURAÇÃO (Access Point)");
    WiFi.mode(WIFI_AP);
    WiFi.softAP(AP_SSID, AP_PASSWORD);
    Serial.print("AP IP address: ");
    Serial.println(WiFi.softAPIP());
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
    Serial.print("Verificando Factory Reset (GPIO 0)...");
    delay(1000); 
    
    if (digitalRead(FACTORY_RESET_PIN) == LOW) { 
        Serial.println("\nBotão de Reset detectado! Mantenha pressionado por 5 segundos.");
        long startTime = millis();
        while(digitalRead(FACTORY_RESET_PIN) == LOW && (millis() - startTime < 5000)) {
            Serial.print(".");
            delay(500);
        }
        
        if (millis() - startTime >= 5000) {
            Serial.println("\nReset de Fábrica ativado!");
            clearCredentials(); 
            Serial.println("Credenciais apagadas. Reiniciando em modo AP.");
            delay(1000);
            ESP.restart();
        } else {
            Serial.println("\nReset cancelado (botão solto cedo demais).");
        }
    } else {
        Serial.println("OK.");
    }
}

void setup_system_mode() {
    Serial.println("--- INICIANDO MODO DE DECISÃO ---");
    loadCredentials();
    
    if (user_ssid.length() == 0 || user_password.length() == 0) {
        Serial.println("Credenciais não encontradas. Entrando em Provisionamento.");
        provisioned = false;
        return; 
    }
    
    Serial.printf("Tentando conectar a: %s\n", user_ssid.c_str());
    WiFi.mode(WIFI_STA); 
    WiFi.begin(user_ssid.c_str(), user_password.c_str());
    
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 40) {
        delay(500);
        Serial.print(".");
        attempts++;
    }

    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("\nWiFi conectado! Entrando em MODO OPERACIONAL.");
        provisioned = true;
        esp32LocalIP = WiFi.localIP(); 
        Serial.print("ESP32 IP address: ");
        Serial.println(esp32LocalIP);

        server.on("/status", HTTP_GET, handleStatus);
        server.on("/feed/manual", HTTP_POST, handleManualFeed);
        server.on("/alarms", HTTP_GET, handleAlarms);
        server.on("/alarms", HTTP_POST, handleAlarms);
        server.begin();
        syncTime();
    } else {
        Serial.println("\nFalha ao conectar ao Wi-Fi (Senha/Rede errada?). Entrando em MODO PROVISIONAMENTO.");
        provisioned = false;
    }
}

void syncTime() {
    configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
    struct tm timeinfo;
    if(!getLocalTime(&timeinfo)){
      Serial.println("Falha ao obter tempo do NTP");
      return;
    }
    Serial.print("Tempo atual: ");
    // CORREÇÃO: String de formato completa para Serial.println
    Serial.println(&timeinfo, "%A, %B %d %Y %H:%M:%S"); 
}

void setup() {
    Serial.begin(115200);
    pinMode(MOTOR_PIN, OUTPUT);
    digitalWrite(MOTOR_PIN, LOW); // Garante que o motor começa desligado

    checkFactoryReset(); // Verifica se o botão de reset está pressionado
    setup_system_mode(); // Decide se vai para AP ou STA

    if (!provisioned) {
        startProvisioningMode(); // Se não provisionado, inicia o AP
    }
}

void loop() {
    server.handleClient(); // Processa requisições HTTP

    // Lógica para desligar o motor após o tempo de dispensa
    if (motorIsRunning && millis() >= motorStopTime) {
        digitalWrite(MOTOR_PIN, LOW);
        motorIsRunning = false;
        Serial.println("Motor desligado. Dispensa concluída.");
    }
}