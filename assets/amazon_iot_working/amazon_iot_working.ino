#include <ESP8266WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

// ========== WiFi Credentials ==========
const char* ssid = "Priyanshu";
const char* password = "12345678";

// ========== AWS IoT Core Details ==========
const char* mqtt_server = "a1uik643utyg4s-ats.iot.ap-south-1.amazonaws.com";  // <-- Change this
const int mqtt_port = 8883;
const char* thingName = "esp8266_3";

// ========== AWS Certificates ==========
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
MIIDWTCCAkGgAwIBAgIUeFvDTW7xKBQSW7w65vIe3TD4E6swDQYJKoZIhvcNAQEL
BQAwTTFLMEkGA1UECwxCQW1hem9uIFdlYiBTZXJ2aWNlcyBPPUFtYXpvbi5jb20g
SW5jLiBMPVNlYXR0bGUgU1Q9V2FzaGluZ3RvbiBDPVVTMB4XDTI1MTEwMTIwMzI0
NFoXDTQ5MTIzMTIzNTk1OVowHjEcMBoGA1UEAwwTQVdTIElvVCBDZXJ0aWZpY2F0
ZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMuAo1TTinRLNYtNpFOH
cW9DdtVartHwgTTWObMeDxTtKQ3zlUmdgBjdV4PuAxQbk0kITVxL5btTDBGHU7dK
KTUVTQyMtxiJ6V/ZqoFztjOvClIcoUUDaE/X52qxt8bjmiA/i+sm68vM4RnQMxZY
bVKle4r/iq/JU3Yd9ZSUFtD4KV2sREWV7uslEncfcPXHW4bXG1QEVR0zWYE5RRkq
JM8bPdVk1DLM5EPXcK7l2C12Y5MLIHieVc0JBZa9EWDBsWBFYZx05fzjcSYLVXYt
qqPhoA2XjYLnecositAIH2E/OtMwqV7uJ0o8QMuy3gkABcRSIf+t2Y1ZPVbFiw96
rIECAwEAAaNgMF4wHwYDVR0jBBgwFoAUo1ehoDYeSSjVJZHCI9Zgk1YydugwHQYD
VR0OBBYEFLzNfx3w9jY4mlbDFT5BUlyG+pQaMAwGA1UdEwEB/wQCMAAwDgYDVR0P
AQH/BAQDAgeAMA0GCSqGSIb3DQEBCwUAA4IBAQBWsJfKIgK/6oM8FouMe3PHkwh1
DhwLMSjYdQkhGtmZsT5uYDwN2d4zY2JtIP4rM6HNGnv4kdgnXy0yUBI7TmlwZFlC
VHkw67s9Yhz9oqiMZelBSZIu4LTW/KraEQIJ8yIA22kRErIlqhi8eLI8gw0e5vs9
SR+jy10V7dLXddoO9jTn2XUbTYFnKGIZbdgDzNrNW1+n48DPhdqNR+zaa/godf4O
ZoVfwvMQeMXbTyq3zUSF26cpjLk/4lgpZ7lI2sdU+FL9hMnV8uXnSHYp/lHrDlGV
rdnj13g+jWj/3t2bvxkIttHR78CHCwhaexBvvvk7UndwCXj8Yu35hLKA8rTB
-----END CERTIFICATE-----
)KEY";

static const char priv_key[] PROGMEM = R"KEY(
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAy4CjVNOKdEs1i02kU4dxb0N21Vqu0fCBNNY5sx4PFO0pDfOV
SZ2AGN1Xg+4DFBuTSQhNXEvlu1MMEYdTt0opNRVNDIy3GInpX9mqgXO2M68KUhyh
RQNoT9fnarG3xuOaID+L6ybry8zhGdAzFlhtUqV7iv+Kr8lTdh31lJQW0PgpXaxE
RZXu6yUSdx9w9cdbhtcbVARVHTNZgTlFGSokzxs91WTUMszkQ9dwruXYLXZjkwsg
eJ5VzQkFlr0RYMGxYEVhnHTl/ONxJgtVdi2qo+GgDZeNgud5yiyK0AgfYT860zCp
Xu4nSjxAy7LeCQAFxFIh/63ZjVk9VsWLD3qsgQIDAQABAoIBAAoGy4VZat/x+LBl
YexPpxIhU9CNSEHFxMfyqiMeHwYb7ULntnpLDU2sUiyI5JPwC+C0TQN4JdiF7flL
Hp/QQpl/9CzjHf5ShTIYymLYbai8Phjvmi6JTXFppNhH61McUbK3DtDGOSXwcULR
VEMMlk5VIvIlRxMEK12NelUYussO6Hi4YftleuNQ1hfhNrMzzC9ZZ3JSVOgAl/u5
c6CKb0jIHROaahAia4yi1dHqLtAl0AL/BV0Oe/BpyMHbx3UWr2uAUnDU5K+i5pqa
lR11oxG3U9U5OP4s7xl5Xr3xxD0h1icfpjC/vRFQdBBJL9CnqPQ81XT7F0scrS8X
Pak5asECgYEA/ADMlmrhmf1vxVeg0WfEwHLhNmEDtW4O8jwsk+ZQdTB/7oK6Ij41
TgeymTNhJ7i6pTfdYY2Zw9ihcO79gZGZitb+Hh71Dq43fyD2oEuSEcTzOeK+4PeU
Lx67A1kUHwuybucroMfeJkLN46gfhDW8gtYmnv/vNzbv7pjR54s3sckCgYEAzrrp
xX9qLlWrCqDbkxMVmkYFDaRzuPLPGP5gEYa5q48dgFdifwNhJUEbsC2+MKDDqLo8
ETTDATHepeM/BXk0Uc8lVfNdUALU/oGeC6jDq/Md2F5Lsb7I7HNu+ZroGDS4siib
P0NEgL9SqiRZOsJrGpqfwztSJ8CSWhkDMpU4wPkCgYEAwynPSBLAY2TuYfQKXQKz
UqPlnRqnJ6RzuNA3addtqkSEX3AovQpWd/boL1OmQ4ACNKA+OCXU1uL3rKG5/NWJ
BwiXxzYMbXEpE7Cwr9W260IPaF4dm9bBkXiINwCO37hMWS15EUyY1CLalxwGRHrl
YqJ9SJhHaAiI6sy5i0u7N1kCgYA0kj/Eo6RC6DI437M28ZF6y/eZAosTK1wTBQ01
J8eroxdjfdVka12W9bmu0dMd1qQrEkEYNwyoDyCJmwJ5x9rQOxdJhjvijvXPSvMA
EAjCf27FiSVCrDu4NZqxCv2eujmFxOHF8rtG6mCBOAEg+jP2bf/WzA0WYthU5St0
/5GRMQKBgQCtbp9c5qkGrZ9vOzPl92OTyzZNEZ+kzXJheM1Y6bNbO0PdtKsgLgu/
WvdA1RBp7CD3ujJc7dB47C40puiTW/ohWiKPwNHs7jQHY16e0RHrzc49yBKMyyoX
vlWsuPrGfneDLmQSxGNGSnwIZpE5RmG6vZCuegbJvRF5mzDvk97QpA==
-----END RSA PRIVATE KEY-----

)KEY";

// ========== MQTT Setup ==========
// WiFiClientSecure wifiClient;
// PubSubClient client(wifiClient);
BearSSL::X509List cert(ca_cert);
BearSSL::X509List client_crt(client_cert);
BearSSL::PrivateKey key(priv_key);
WiFiClientSecure wifiClient;
PubSubClient client(wifiClient);

void syncTime() {
  configTime(0, 0, "pool.ntp.org", "time.nist.gov");
  Serial.print("Syncing NTP time");
  time_t now = time(nullptr);
  while (now < 8 * 3600 * 2) {   // wait until >1970
    delay(500);
    Serial.print(".");
    now = time(nullptr);
  }
  Serial.println();
  Serial.printf("✅ Time synced: %s", ctime(&now));
}
// ========== Helper Functions (Updated for Multi-Device MQTT) ==========
bool connectAWS() {
  Serial.print("🔌 Connecting to AWS IoT...");

  int retries = 0;

  // Create device-specific topics dynamically
  String statusTopic = "esp8266/" + String(thingName) + "/status";
  String willPayload = "{\"device\":\"" + String(thingName) + "\",\"status\":\"disconnected\"}";

  while (!client.connected() && retries < 10) {
    if (client.connect(
          thingName,                   // Unique client ID
          NULL, NULL,                  // Username & Password (not used)
          statusTopic.c_str(),         // LWT topic (device-specific)
          0,                           // QoS 0
          false,                       // Retain = false
          willPayload.c_str()          // LWT payload
        )) 
    {
      Serial.println("\n✅ Connected to AWS IoT!");
      
      // Subscribe to all ESP topics using wildcards
      client.subscribe("esp8266/+/data");
      client.subscribe("esp8266/+/status");

      // Publish “connected” status for this device
      publishStatus("connected");
      return true;
    } 
    else {
      Serial.print(".");
      Serial.print(" state="); Serial.println(client.state());
      Serial.print(" sslErr="); Serial.println(wifiClient.getLastSSLError());
      delay(2000);
      retries++;
    }
  }

  Serial.println("\n❌ Failed to connect to AWS IoT after 10 retries.");
  return false;
}


/// --- Publish Sensor Data (Temperature & Humidity) ---
void publishData() {
  // Create dynamic topic for this device
  String dataTopic = "esp8266/" + String(thingName) + "/data";

  StaticJsonDocument<200> doc;
  doc["device"] = thingName;
  doc["temperature"] = random(25, 35);  // Replace with your real sensor
  doc["humidity"] = random(50, 70);     // Replace with your real sensor
  doc["timestamp"] = millis();

  char payload[256];
  serializeJson(doc, payload);

  client.publish(dataTopic.c_str(), payload);
  Serial.print("📤 Data published → ");
  Serial.println(dataTopic);
  Serial.println(payload);
}


/// --- Publish Connection Status (connected / disconnected) ---
void publishStatus(const char* state) {
  // Create dynamic status topic for this device
  String statusTopic = "esp8266/" + String(thingName) + "/status";

  StaticJsonDocument<100> statusDoc;
  statusDoc["device"] = thingName;
  statusDoc["status"] = state;

  char statusPayload[128];
  serializeJson(statusDoc, statusPayload);

  client.publish(statusTopic.c_str(), statusPayload);
  Serial.print("📡 Status published → ");
  Serial.println(statusTopic);
  Serial.println(statusPayload);
}


// ========== Setup ==========
void setup() {
  Serial.begin(9600);
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n✅ WiFi Connected!");
syncTime();
  // Attach certificates (BearSSL version)
  wifiClient.setTrustAnchors(&cert);
  wifiClient.setClientRSACert(&client_crt, &key);

  client.setServer(mqtt_server, mqtt_port);
  connectAWS();
}

// ========== Loop ==========
void loop() {
  if (!client.connected()) {
    publishStatus("disconnected");
    connectAWS();
  }
  client.loop();

  publishData();
  delay(10000);  // Send data every 10s
}
