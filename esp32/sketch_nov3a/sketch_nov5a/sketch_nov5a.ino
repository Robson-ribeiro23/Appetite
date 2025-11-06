#include <WiFi.h>
#include <PubSubClient.h>
#include <WebServer.h>      
#include <ArduinoJson.h>
#include <time.h> 
#include <Preferences.h>    

//06_11_2025

const char* mqttServer = "test.mosquitto.org"; 
const int mqttPort = 1883; 
const char* mqttClientID = "ESP32_Appetite_Device";

const int MOTOR_PIN = 23; /
const int FACTORY_RESET_PIN = 0; 


const char* COMMAND_MANUAL_TOPIC = "appetite/comando/manual";
const char* COMMAND_ALARME_TOPIC = "appetite/comando/alarme";
const char* STATUS_TOPIC = "appetite/status/conexao";
const char* DISPENSE_STATUS_TOPIC = "appetite/status/dispensa";


WiFiClient espClient;
PubSubClient client(espClient);
Preferences preferences; 
WebServer server(80);
const char* AP_SSID = "Appetite_SETUP"; 
const char* AP_PASSWORD = "";          
String user_ssid = "";
String user_password = ""; 
bool provisioned = false; 
const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = -10800; 
const int   daylightOffset_sec = 0;


bool motorIsRunning = false;
unsigned long motorStopTime = 0;




void dispenseFood(double grams) {
   
    if (motorIsRunning) {
        Serial.println("Motor já está em funcionamento, comando ignorado.");
        return;
    }
  
    Serial.printf("Comando recebido: Dispensar %.1f gramas.\n", grams);
    
    
    long dispenseTimeMs = (long)(grams * 100); 

    Serial.printf("Motor será ligado por %ld milissegundos.\n", dispenseTimeMs);

  
    motorIsRunning = true;
    motorStopTime = millis() + dispenseTimeMs; 
    digitalWrite(MOTOR_PIN, HIGH); 

    /
    char statusPayload[60];
    sprintf(statusPayload, "{\"grams\": %.1f, \"success\": true}", grams);
    client.publish(DISPENSE_STATUS_TOPIC, statusPayload);
    Serial.println("Confirmação de dispensa (comando recebido) enviada ao Broker.");
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

    if (strcmp(topic, COMMAND_MANUAL_TOPIC) == 0) {
        if (doc.containsKey("grams")) {
            double grams = doc["grams"].as<double>();
            dispenseFood(grams);
        }
    } 
    else if (strcmp(topic, COMMAND_ALARME_TOPIC) == 0) {
        Serial.println("Nova lista de alarmes recebida. Salvando...");
        
    }
}


void reconnect_mqtt() {
    while (!client.connected()) {
        Serial.print("Tentando conexao MQTT...");
        
        String lwtPayload = "offline";
        
        if (client.connect(mqttClientID, 
                           STATUS_TOPIC,    
                           1,               
                           true,           
                           lwtPayload.c_str() 
                          )) {
            Serial.println("conectado ao Broker!");
            client.publish(STATUS_TOPIC, "online", true); 
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
    while (WiFi.status() != WL_CONNECTED && attempts < 20) { 
        delay(500);
        Serial.print(".");
        attempts++;
    }

    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("\nWiFi conectado! Entrando em MODO OPERACIONAL.");
        provisioned = true;
    } else {
        Serial.println("\nFalha ao conectar ao Wi-Fi (Senha/Rede errada?). Entrando em MODO PROVISIONAMENTO.");
        provisioned = false;
    }
}


void setup() {
    Serial.begin(115200);
    delay(100); 
    
    pinMode(MOTOR_PIN, OUTPUT);
    digitalWrite(MOTOR_PIN, LOW);
    
    checkFactoryReset(); 
    setup_system_mode(); 
    
    if (provisioned) {
        delay(1000); 
        configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
        client.setServer(mqttServer, mqttPort);
        client.setCallback(callback);
    } else {
        startProvisioningMode();
    }
}

void loop() {
    if (provisioned) {
     
        
        if (WiFi.status() != WL_CONNECTED) {
            Serial.println("Conexão Wi-Fi perdida. Reiniciando para modo AP...");
            delay(1000);
            ESP.restart(); 
        }
        
        if (client.connected()) {
            client.loop(); 
        } else {
            reconnect_mqtt(); 
        }
        
      
        if (motorIsRunning && (millis() >= motorStopTime)) {
            Serial.println("Motor desligado (timer).");
            digitalWrite(MOTOR_PIN, LOW);
            motorIsRunning = false;
        }
        
        
        
    } else {
        
        server.handleClient(); 
    }
}