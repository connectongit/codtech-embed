/*
 * Project: Autonomous Obstacle Avoiding Robot
 * Description: 2WD/4WD Robot using HC-SR04 mounted on SG90 Servo and L298N Motor Driver
 * Hardware: Arduino Uno, L298N Motor Driver, 2x DC Motors, HC-SR04 Ultrasonic Sensor, SG90 Servo Motor
 */

#include <Servo.h>

// L298N Motor Driver Pins (ENA/ENB on Timer0 PWM pins 5 & 6 to avoid Servo Timer1 conflict)
const int ENA = 5;
const int ENB = 6;
const int IN1 = 2;
const int IN2 = 3;
const int IN3 = 4;
const int IN4 = 7;

// Ultrasonic Sensor & Servo Pins
const int SERVO_PIN = 9;
const int TRIG_PIN  = 12;
const int ECHO_PIN  = 13;

// Movement & Detection Parameters
const int MOTOR_SPEED      = 180; // PWM speed (0 - 255)
const int OBSTACLE_DIST_CM = 20;  // Minimum safe distance in cm

Servo scanServo;

int getDistance() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  long duration = pulseIn(ECHO_PIN, HIGH, 25000);
  if (duration == 0) return 200; // Clear path if timeout
  return (int)(duration * 0.034 / 2);
}

void moveForward() {
  analogWrite(ENA, MOTOR_SPEED);
  analogWrite(ENB, MOTOR_SPEED);
  digitalWrite(IN1, HIGH); digitalWrite(IN2, LOW);
  digitalWrite(IN3, HIGH); digitalWrite(IN4, LOW);
}

void moveBackward() {
  analogWrite(ENA, MOTOR_SPEED);
  analogWrite(ENB, MOTOR_SPEED);
  digitalWrite(IN1, LOW);  digitalWrite(IN2, HIGH);
  digitalWrite(IN3, LOW);  digitalWrite(IN4, HIGH);
}

void turnLeft() {
  analogWrite(ENA, MOTOR_SPEED);
  analogWrite(ENB, MOTOR_SPEED);
  digitalWrite(IN1, LOW);  digitalWrite(IN2, HIGH);
  digitalWrite(IN3, HIGH); digitalWrite(IN4, LOW);
}

void turnRight() {
  analogWrite(ENA, MOTOR_SPEED);
  analogWrite(ENB, MOTOR_SPEED);
  digitalWrite(IN1, HIGH); digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);  digitalWrite(IN4, HIGH);
}

void stopMotors() {
  analogWrite(ENA, 0);
  analogWrite(ENB, 0);
  digitalWrite(IN1, LOW); digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW); digitalWrite(IN4, LOW);
}

// Sweeps servo to given angle and reads distance
int scanDirection(int angle) {
  scanServo.write(angle);
  delay(450);
  return getDistance();
}

void setup() {
  Serial.begin(9600);

  int motorPins[] = {ENA, ENB, IN1, IN2, IN3, IN4};
  for (int i = 0; i < 6; i++) {
    pinMode(motorPins[i], OUTPUT);
  }

  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

  scanServo.attach(SERVO_PIN);
  scanServo.write(90); // Face straight ahead
  delay(500);

  Serial.println("Obstacle Avoiding Robot Ready...");
}

void loop() {
  int frontDist = getDistance();
  Serial.print("Front Distance: "); Serial.print(frontDist); Serial.println(" cm");

  if (frontDist > OBSTACLE_DIST_CM) {
    moveForward();
  } else {
    Serial.println("Obstacle detected! Stopping and scanning...");
    stopMotors();
    delay(200);

    // Back up slightly for turning clearance
    moveBackward();
    delay(350);
    stopMotors();
    delay(200);

    // Scan Left (160 deg) and Right (20 deg)
    int leftDist  = scanDirection(160);
    int rightDist = scanDirection(20);
    scanServo.write(90); // Re-center sensor
    delay(250);

    Serial.print("Left: "); Serial.print(leftDist);
    Serial.print(" cm | Right: "); Serial.print(rightDist); Serial.println(" cm");

    if (leftDist >= rightDist && leftDist > OBSTACLE_DIST_CM) {
      Serial.println("Turning Left...");
      turnLeft();
      delay(450);
    } else if (rightDist > OBSTACLE_DIST_CM) {
      Serial.println("Turning Right...");
      turnRight();
      delay(450);
    } else {
      Serial.println("Dead End -> Performing 180-degree Turn...");
      turnRight();
      delay(900);
    }
    stopMotors();
  }

  delay(100);
}
