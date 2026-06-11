// Twister Mk1 — Phase 1 test bench firmware
//
// Reads orientation from the MPU-6050 (I2C: SDA=A4, SCL=A5) and sounds the
// buzzer on D2 when the board registers an orientation change beyond a
// threshold. Startup chirps confirm the system is armed and the sensor is
// responding. See plan.ignore.md, "Phase 1 Test Bench".

#include <Arduino.h>
#include <Wire.h>

// ---- Pins ----
constexpr uint8_t PIN_BUZZER = 2;

// ---- MPU-6050 registers ----
constexpr uint8_t MPU_ADDR        = 0x68; // AD0 low
constexpr uint8_t REG_PWR_MGMT_1  = 0x6B;
constexpr uint8_t REG_WHO_AM_I    = 0x75;
constexpr uint8_t REG_ACCEL_XOUT  = 0x3B;

// ---- Behavior tuning ----
constexpr float    TILT_TRIGGER_DEG   = 20.0; // orientation change that triggers the buzzer
constexpr uint16_t BUZZER_FREQ_HZ     = 2000;
constexpr uint32_t SAMPLE_INTERVAL_MS = 50;
constexpr uint32_t PRINT_INTERVAL_MS  = 250;

struct Orientation {
  float pitch; // degrees
  float roll;  // degrees
};

static Orientation reference;     // orientation captured at arming
static bool        mpuOk = false;

// ---------------------------------------------------------------------------

static bool mpuWrite(uint8_t reg, uint8_t value) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(reg);
  Wire.write(value);
  return Wire.endTransmission() == 0;
}

static bool mpuReadAccel(int16_t &ax, int16_t &ay, int16_t &az) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(REG_ACCEL_XOUT);
  if (Wire.endTransmission(false) != 0) return false;
  if (Wire.requestFrom(MPU_ADDR, (uint8_t)6) != 6) return false;
  ax = (Wire.read() << 8) | Wire.read();
  ay = (Wire.read() << 8) | Wire.read();
  az = (Wire.read() << 8) | Wire.read();
  return true;
}

// Pitch/roll from gravity vector (accelerometer only). Good enough for a
// static orientation-change test; the flight code will fuse the gyro later.
static bool readOrientation(Orientation &out) {
  int16_t ax, ay, az;
  if (!mpuReadAccel(ax, ay, az)) return false;
  out.pitch = atan2(-ax, sqrt((float)ay * ay + (float)az * az)) * 180.0 / PI;
  out.roll  = atan2(ay, az) * 180.0 / PI;
  return true;
}

static void beep(uint16_t freq, uint16_t durationMs) {
  tone(PIN_BUZZER, freq, durationMs);
  delay(durationMs + 30);
}

// Two rising chirps: armed and sensor OK.
static void armedChirp() {
  beep(1500, 100);
  beep(2500, 100);
}

// Repeating low triple-beep: sensor fault.
static void faultChirp() {
  for (uint8_t i = 0; i < 3; i++) beep(400, 150);
}

// ---------------------------------------------------------------------------

void setup() {
  pinMode(PIN_BUZZER, OUTPUT);
  Serial.begin(115200);
  Wire.begin();

  // Wake the MPU-6050 (it powers up in sleep mode) and verify it answers.
  mpuOk = mpuWrite(REG_PWR_MGMT_1, 0x00);
  if (mpuOk) {
    delay(100); // let the sensor stabilize
    mpuOk = readOrientation(reference);
  }

  if (mpuOk) {
    Serial.println(F("Phase 1: MPU online, system armed."));
    Serial.print(F("Reference pitch/roll: "));
    Serial.print(reference.pitch, 1);
    Serial.print(F(" / "));
    Serial.println(reference.roll, 1);
    armedChirp();
  } else {
    Serial.println(F("Phase 1: MPU not responding! Check SDA->A4, SCL->A5, VCC, GND."));
  }
}

void loop() {
  static uint32_t lastSample = 0;
  static uint32_t lastPrint  = 0;
  uint32_t now = millis();

  if (!mpuOk) {
    faultChirp();
    delay(1000);
    return;
  }

  if (now - lastSample < SAMPLE_INTERVAL_MS) return;
  lastSample = now;

  Orientation current;
  if (!readOrientation(current)) {
    Serial.println(F("MPU read failed!"));
    faultChirp();
    return;
  }

  float dPitch = current.pitch - reference.pitch;
  float dRoll  = current.roll - reference.roll;
  bool  tilted = fabs(dPitch) > TILT_TRIGGER_DEG || fabs(dRoll) > TILT_TRIGGER_DEG;

  if (tilted) {
    tone(PIN_BUZZER, BUZZER_FREQ_HZ);
  } else {
    noTone(PIN_BUZZER);
  }

  if (now - lastPrint >= PRINT_INTERVAL_MS) {
    lastPrint = now;
    Serial.print(F("pitch: "));
    Serial.print(current.pitch, 1);
    Serial.print(F("  roll: "));
    Serial.print(current.roll, 1);
    Serial.print(F("  d-pitch: "));
    Serial.print(dPitch, 1);
    Serial.print(F("  d-roll: "));
    Serial.print(dRoll, 1);
    Serial.println(tilted ? F("  [TILT!]") : F(""));
  }
}
