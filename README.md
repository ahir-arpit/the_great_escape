<<<<<<< HEAD
# the_great_escape
 first flutter project
 
=======
# Rana Jii - Smart Car Controller

**Rana Jii** is a premium Flutter-based controller app designed for ESP8266/ESP32 based smart cars.

![Controller Preview](assets/futuristic_controller_ui.png)

## Features
-   **Dual Mode Control**: Joystick and D-Pad navigation.
-   **Live Telemetry**: Real-time sensor data from the car (Ultrasonic, IR, PIR).
-   **Safety Systems**: Auto-blocking of forward movement when obstacles are detected.
-   **Dynamic UI**: Beautiful dark mode interface with neon accents and animations.
-   **Speed Control**: Adjustable speed slider (0-100%).
>>>>>>> 74e834f (Renamed main.dart to arpit_controller.dart and updated README)

## Getting Started

### Prerequisites
-   Flutter SDK installed.
-   ESP8266/ESP32 robot car with compatible firmware.

### Installation
1.  Clone the repository:
    ```bash
    git clone https://github.com/ahir-arpit/the_great_escape.git
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Run the app:
    ```bash
    flutter run
    ```

## Usage
1.  Connect your phone to the car's Wi-Fi hotspot.
2.  Open the app.
3.  Enter the car's IP address (Default: `192.168.4.1`) in Settings.
4.  Tap **Reconnect** to start receiving sensor data.
5.  Use the arrow keys or joystick to drive!

## File Structure
-   `lib/arpit_controller.dart`: Main controller logic and UI.
-   `lib/main.dart`: App entry point.

## License
This project is licensed under the MIT License.
