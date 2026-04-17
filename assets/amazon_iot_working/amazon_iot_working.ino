#include <ESP8266WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <EEPROM.h>
#include <time.h>

/* ================= DEFAULT FALLBACKS ================= */
const char* DEFAULT_SSID = "Priyanshu";
const char* DEFAULT_PASS = "12345678";
const char* DEFAULT_THING = "elevate";
const char* DEFAULT_TOPIC = "asus"; 

/* ================= AWS IOT FIXED CONFIG ================= */
const char* mqtt_server = "a1uik643utyg4s-ats.iot.ap-south-1.amazonaws.com";
const int mqtt_port = 8883;

/* ================= EEPROM STRUCTURE ================= */
struct Config {
  uint32_t magic; 
  char ssid[32];
  char pass[32];
  char thingName[32];
  char baseTopic[32];
  char did[20];
  char loc[20];
  char bid[20];
  char fid[20];
};
Config config;

/* ================= SECURITY CERTIFICATES ================= */
static const char ca_cert[] PROGMEM = R"EOF(
-----BEGIN CERTIFICATE-----
MIIDQTCCAimgAwIBAgITBmyfz5m/jAo54vB4ikPmljZbyjANBgkqhkiG9w0BAQsF
ADA5MQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRkwFwYDVQQDExBBbWF6
b24gUm9vdCBDQSAxMB4XDTE1MDUyNjAwMDAwMFoXDTM4MDExNzAwMDAwMFowOTEL
MAkGA1UEBhMCVVMxDzANBgNVBAoTBkFtYXpvbjEZMBcGA1UEAxMQQW1hem9uIFJv
b3QgQ0EgMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALJ4gHHKeNXj
ca9HgFB0fW7Y14h29Jlo91ghYPl0hAEvrAIthtOgQ3pOsqTQNroBvo3bSMgHFzZM
9O6II8c+6zf1tRn4SWiw3te5djgdYZ6k/oI2peVKVuRF4fn9tBb6dNqcmzU5L/qw
IFAGbHrQgLKm+a/sRxmPUDgH3KKHOVj4utWp+UhnMJbulHheb4mjUcAwhmahRWa6
VOujw5H5SNz/0egwLX0tdHA114gk957EWW67c4cX8jJGKLhD+rcdqsq08p8kDi1L
93FcXmn/6pUCyziKrlA4b9v7LWIbxcceVOF34GfID5yHI9Y/QCB/IIDEgEw+OyQm
jgSubJrIqg0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMC
AYYwHQYDVR0OBBYEFIQYzIU07LwMlJQuCFmcx7IQTgoIMA0GCSqGSIb3DQEBCwUA
A4IBAQCY8jdaQZChGsV2USggNiMOruYou6r4lK5IpDB/G/wkjUu0yKGX9rbxenDI
U5PMCCjjmCXPI6T53iHTfIUJrU6adTrCC2qJeHZERxhlbI1Bjjt/msv0tadQ1wUs
N+gDS63pYaACbvXy8MWy7Vu33PqUXHeeE6V/Uq2V8viTO96LXFvKWlJbYK8U90vv
o/ufQJVtMVT8QtPHRh8jrdkPSHCa2XV4cdFyQzR1bldZwgJcJmApzyMZFo6IQ6XU
5MsI+yMRQ+hDKXJioaldXgjUkK642M4UwtBV8ob2xJNDd2ZhwLnoQdeXeGADbkpy
rqXRfboQnoZsG4q5WTP468SQvvG5
-----END CERTIFICATE-----
)EOF";

static const char client_cert[] PROGMEM = R"KEY(
-----BEGIN CERTIFICATE-----
MIIDWTCCAkGgAwIBAgIUcMFKx4TCXKJL530ydY+3Lcx34T8wDQYJKoZIhvcNAQEL
BQAwTTFLMEkGA1UECwxCQW1hem9uIFdlYiBTZXJ2aWNlcyBPPUFtYXpvbi5jb20g
SW5jLiBMPVNlYXR0bGUgU1Q9V2FzaGluZ3RvbiBDPVVTMB4XDTI2MDQxNjEwNTkw
NFoXDTQ5MTIzMTIzNTk1OVowHjEcMBoGA1UEAwwTQVdTIElvVCBDZXJ0aWZpY2F0
ZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMyYvw8+BGa9Tmab4Ut+
bGxUKkwpa51Eo4+t5VkjSbjJxau8xlcOR6E+HA1MluN/qlSZ0M9RY4GNluKOUjT0
3lauZUfBnUnI7lTFemJnrR47TSvmR9pyWi3JeO7HMCLnXczD9cdoInx1YcCzx5f8
FPW7jAsZH1eO9aT8q7IyOcdR9xOS3WwGAdzkP4E6G0Iocr4kDwvOhoenahjqNZom
ZKxlbGZUt90lGmrka2NLf4qrBoIpvNWsDuTw4NmHrG7R0MwQtpKioZImaYzpxU1B
DkI/mOC0ZIPN4UB+tk7edNGEgn5WGog3wuybTCe+458R//WW3eq+avKREY/st79E
97MCAwEAAaNgMF4wHwYDVR0jBBgwFoAUcBsRYUxyIir3DKdjqkuLo/+c/XMwHQYD
VR0OBBYEFJkoQOkbYvmt51+Tch0wfawcabUJMAwGA1UdEwEB/wQCMAAwDgYDVR0P
AQH/BAQDAgeAMA0GCSqGSIb3DQEBCwUAA4IBAQBOLjY7MGkoOCi7QdMJlO+PdeYI
onsdejnB0+5wgRhP8u/N133ZmfIwc6WVd7UDeXgeYskrdINW1Ppqtc2rP9kUR2sw
rteMRc7B+GL9rUQuCjSiYJKWbthl/CSxCYGLpOYiKvOZMnQZG5L5lSH+C4BpPZKf
afzDYSDlc13HyoydrbmQ0EIddtO71p2OQTOfPVnrUzYagr263dVLwKjA8BZ1KTp2
c+L8ljKOfhCkXRA3plMgrct81i2CeyM627Uat1+gkDwGdoz+qrN69GmlTpU8d63N
8G1bnaBspuY+j99TZXcq41gA7SbWrYbmEecpe8ESiAu9oJ1TiHr28UawcZXV
-----END CERTIFICATE-----
)KEY";

static const char priv_key[] PROGMEM = R"KEY(
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAzJi/Dz4EZr1OZpvhS35sbFQqTClrnUSjj63lWSNJuMnFq7zG
Vw5HoT4cDUyW43+qVJnQz1FjgY2W4o5SNPTeVq5lR8GdScjuVMV6YmetHjtNK+ZH
2nJaLcl47scwIuddzMP1x2gifHVhwLPHl/wU9buMCxkfV471pPyrsjI5x1H3E5Ld
bAYB3OQ/gTobQihyviQPC86Gh6dqGOo1miZkrGVsZlS33SUaauRrY0t/iqsGgim8
1awO5PDg2YesbtHQzBC2kqKhkiZpjOnFTUEOQj+Y4LRkg83hQH62Tt500YSCflYa
iDfC7JtMJ77jnxH/9Zbd6r5q8pERj+y3v0T3swIDAQABAoIBAGZX9iLaw/rcsW40
hZNtDzF1PJ9SjOljn2nM9BANzd/o1r+cs55ynzQyTHf+mu/8OakONFywetUgjZyQ
0uB4qQu1OyaU3Gg/YbD4A8tbz0ZzJZxTGhhU4XVL9fmDnDmpgMtgLv7rwWx+j0KE
68/EInv1sA0RKRN0iL5aQkzmQO7J1MCjfVbr7lSpN0bFoYWpjTASp+Je50y1vBf5
mwRZ0qQOiKQ3hUUHKR3eFIKhabtXBkfe9rJxxZVG/fyrxth8nhLsQodNGzh0q8bu
i3Sh2DEqt/INbAnA0dfsEZCMF2Ofe23rLzB3W8NMtUw/+DO6rgHvPjnljugUoG0S
wpuJeLkCgYEA+UOyDf1rtWE/nEpRoAIhUSeQp8LLcxF9Ev2Ge0652eojZBMCNgtS
eY5Gp8KTuiI5krPy3bNXTbXK8tueqromw4kzcPNc5K8OIGwcE2RATeIEI1MqYL0W
3PLpfQSxi1ItHjI2rgH8Rm+7MHERS57q2YLaODPZvB05pmP91Eo05C8CgYEA0iAO
7hIwll3NCprQ9Wsf7vtB6uuIdH2RZ2wO4EEQE5x2HNNrK/TJq59MjmOJGCc9lKST
QyvKtU5xHKcdpoDUM1FS6O8DH6ZlnZmy4kb7I2KbXBb7LFWcjjXwK6iKiqcG/50e
tGSCV7neBMNzj+W0fGlvPHbym5hRgNn+Hk+ST70CgYBjnYE4BBIab53rSOwsBQ3p
j+VIlhmWh+OzRiyLdN/jTaYNJWeZz5aLS6fC/YjqNylJDq89mKGIReGwgsJ7Ol+p
f1hWiHuUTL1ZibsCqOrl9TBwKZljBc5wSIe1Vb3ajuHHEow1qEd4oshtSJJ/5Se3
+4pYMaiPfCKA868KOwm+MwKBgQCKnS1cLdGxkAVwJnsMOvPg8g0lDOWCe0dNY4JY
u3MAjOl50JpVb/EN71NQZycMMO61vO+Mkznw6uNBVJkBuuDBTbeVA/8ahOlp0ven
v81yJV15nYtqTrutMLXUByYFm3PJcfvMYrV9a5ajq8/zMEQlAmSoDYuzywKRLr0t
f650PQKBgGM+Oy7ka/hHD2ursn+0Cxek2vdILNK0iDsQO6wDYLC5MULhB2Iq+Mys
whjMOLBqZ9avKXjvvykuVeDn6xINRp85hINFpwksta1gczztPpSyxpWXY+bKdyOF
rTISiazqytoXxxfY+/ZwHCM2HTCBovcHDtv4QRuVSDNV4S2MFY0X
-----END RSA PRIVATE KEY-----
)KEY";

BearSSL::X509List cert(ca_cert);
BearSSL::X509List client_crt(client_cert);
BearSSL::PrivateKey key(priv_key);

WiFiClientSecure wifiClient;
PubSubClient client(wifiClient);

unsigned long lastPublish = 0;
unsigned long lastReconnectAttempt = 0;
unsigned long reconnectDelay = 5000;
const unsigned long publishInterval = 10000;

char serialBuffer[128]; 
uint8_t serialIndex = 0;

/* ================= HELPERS ================= */
void loadConfig() { 
  EEPROM.get(0, config); 
  if (config.magic != 0xABCD1234) {
    config.magic = 0xABCD1234;
    strncpy(config.ssid, DEFAULT_SSID, sizeof(config.ssid));
    strncpy(config.pass, DEFAULT_PASS, sizeof(config.pass));
    strncpy(config.thingName, DEFAULT_THING, sizeof(config.thingName));
    strncpy(config.baseTopic, DEFAULT_TOPIC, sizeof(config.baseTopic));
    memset(config.did, 0, sizeof(config.did));
    memset(config.loc, 0, sizeof(config.loc));
    EEPROM.put(0, config);
    EEPROM.commit();
  }
}

void saveConfig() { 
  EEPROM.put(0, config); 
  EEPROM.commit(); 
}

/* ================= WIFI ================= */
void connectWiFi() {
  if (WiFi.status() == WL_CONNECTED) return;
  
  WiFi.mode(WIFI_STA);
  WiFi.begin(config.ssid, config.pass);

  int counter = 0;
  while (WiFi.status() != WL_CONNECTED && counter < 30) {
    delay(500);
    counter++;
    handleSerial(); 
  }
}

/* ================= MQTT AWS ================= */
void publishStatus(const char* status) {
  char topic[100];
  snprintf(topic, sizeof(topic), "%s/%s/status", config.baseTopic, config.thingName);

  StaticJsonDocument<128> doc;
  doc["device"] = config.thingName;
  doc["status"] = status;

  char payload[128];
  serializeJson(doc, payload);
  client.publish(topic, payload);
}

bool connectAWS() {
  char statusTopic[100];
  snprintf(statusTopic, sizeof(statusTopic), "%s/%s/status", config.baseTopic, config.thingName);

  char willPayload[128];
  snprintf(willPayload, sizeof(willPayload), "{\"device\":\"%s\",\"status\":\"disconnected\"}", config.thingName);

  if (client.connect(config.thingName, NULL, NULL, statusTopic, 0, false, willPayload)) {
    publishStatus("connected"); 
    char subTopic[100];
    snprintf(subTopic, sizeof(subTopic), "%s/+/data", config.baseTopic);
    client.subscribe(subTopic);
    return true;
  }
  return false;
}

void publishTelemetry() {
  char topic[100];
  snprintf(topic, sizeof(topic), "%s/%s/data", config.baseTopic, config.thingName);

  StaticJsonDocument<256> doc;
  doc["device"] = config.thingName;
  doc["temperature"] = random(22, 30);
  doc["humidity"] = random(40, 60);
  doc["turbidity"] = random(0, 100); 
  doc["uptime"] = millis() / 1000;
  doc["loc"] = config.loc;

  char payload[256];
  serializeJson(doc, payload);
  client.publish(topic, payload);
}

/* ================= SERIAL COMMAND HANDLING ================= */

void processCommand(char *cmd) {
  // 1. Handle SET commands (strncmp checks if it starts with SET_)
  if (strncmp(cmd, "SET_", 4) == 0) {
    char *sep = strchr(cmd, ':');
    if (!sep) return;

    *sep = 0; // Split string at the colon
    char *val = sep + 1;

    if (strcmp(cmd, "SET_SSID") == 0) 
      strncpy(config.ssid, val, sizeof(config.ssid));
    else if (strcmp(cmd, "SET_PASS") == 0) 
      strncpy(config.pass, val, sizeof(config.pass));
    else if (strcmp(cmd, "SET_THING") == 0) 
      strncpy(config.thingName, val, sizeof(config.thingName));
    else if (strcmp(cmd, "SET_TOPIC") == 0) 
      strncpy(config.baseTopic, val, sizeof(config.baseTopic));
    else if (strcmp(cmd, "SET_DID") == 0) 
      strncpy(config.did, val, sizeof(config.did));
    else if (strcmp(cmd, "SET_LOC") == 0) 
      strncpy(config.loc, val, sizeof(config.loc));
    else if (strcmp(cmd, "SET_BID") == 0) 
      strncpy(config.bid, val, sizeof(config.bid));
    else if (strcmp(cmd, "SET_FID") == 0) 
      strncpy(config.fid, val, sizeof(config.fid));

    saveConfig();
    delay(50);
    // Acknowledgement for the Flutter Service
    Serial.println("OK"); 
  }

  // 2. Handle GET commands
  else if (strncmp(cmd, "GET_", 4) == 0) {
    if (strcmp(cmd, "GET_SSID") == 0) 
      Serial.println(config.ssid);
    else if (strcmp(cmd, "GET_THING") == 0) 
      Serial.println(config.thingName);
    else if (strcmp(cmd, "GET_DID") == 0) 
      Serial.println(config.did);
    else if (strcmp(cmd, "GET_LOC") == 0) 
      Serial.println(config.loc);
    else if (strcmp(cmd, "GET_BID") == 0) 
      Serial.println(config.bid);
    else if (strcmp(cmd, "GET_FID") == 0) 
      Serial.println(config.fid);
    else if (strcmp(cmd, "GET_TOPIC") == 0) 
      Serial.println(config.baseTopic);
  }
}

void handleSerial() {
  while (Serial.available()) {
    char c = Serial.read();

    // Check for newline or carriage return to process command
    if (c == '\n' || c == '\r') {
      serialBuffer[serialIndex] = '\0';

      if (serialIndex > 0) {
        processCommand(serialBuffer);
      }
      serialIndex = 0;
    } 
    else {
      // Buffer the characters
      if (serialIndex < sizeof(serialBuffer) - 1) {
        serialBuffer[serialIndex++] = c;
      }
    }
  }
}


/* ================= SETUP & LOOP ================= */
void syncTime(){
  configTime(0, 0, "pool.ntp.org", "time.nist.gov");
  time_t now = time(nullptr);
  while (now < 1000) { delay(500); now = time(nullptr); }
}

void setup() {
  Serial.begin(115200);  // ← fixed baud
  EEPROM.begin(512);
  loadConfig();

  // Start WiFi but DON'T block waiting for it
  WiFi.mode(WIFI_STA);
  WiFi.begin(config.ssid, config.pass);

  wifiClient.setTrustAnchors(&cert);
  wifiClient.setClientRSACert(&client_crt, &key);
  wifiClient.setBufferSizes(2048, 1024);
  client.setServer(mqtt_server, mqtt_port);
}

bool timeSynced = false;

void loop() {
  handleSerial();  // ← ALWAYS runs first, no blocking

  if (WiFi.status() != WL_CONNECTED) return;

  if (!timeSynced) {
    configTime(0, 0, "pool.ntp.org", "time.nist.gov");
    timeSynced = true;
  }

  if (!client.connected()) {
    if (millis() - lastReconnectAttempt > reconnectDelay) {
      lastReconnectAttempt = millis();
      connectAWS();
    }
  } else {
    client.loop();
    if (millis() - lastPublish > publishInterval) {
      lastPublish = millis();
      publishTelemetry();
    }
  }

  yield();
}