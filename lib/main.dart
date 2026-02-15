import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const SmartCarBotApp());
}

class SmartCarBotApp extends StatelessWidget {
  const SmartCarBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rana Jii',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      home: const CarControlScreen(),
    );
  }
}

class CarControlScreen extends StatefulWidget {
  const CarControlScreen({super.key});

  @override
  State<CarControlScreen> createState() => _CarControlScreenState();
}

class _CarControlScreenState extends State<CarControlScreen> with TickerProviderStateMixin {
  // Connection settings
  String _ipAddress = '192.168.4.1';
  int _speed = 80;
  bool _isConnected = false;
  String _errorMessage = '';
  
  // Sensor data
  int _distance = 0;
  int _threshold = 10;
  bool _irDetected = false;
  bool _pirDetected = false;
  bool _powerOn = false;
  bool _ultrasonicBlocked = false;
  bool _irBlocked = false;
  int _timeUntilPowerOff = 30;
  
  // Control state
  String _currentDirection = 'stop';
  bool _isSendingCommand = false;
  Timer? _commandTimer;
  Timer? _pollingTimer;
  
  // Animation controllers
  late AnimationController _pulseAnimation;
  late AnimationController _spinAnimation;
  late Animation<double> _pulseValue;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _pulseAnimation = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    
    _spinAnimation = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _pulseValue = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseAnimation, curve: Curves.easeInOut),
    );
    
    // Start polling
    startPolling();
  }
  
  @override
  void dispose() {
    _pulseAnimation.dispose();
    _spinAnimation.dispose();
    _pollingTimer?.cancel();
    _commandTimer?.cancel();
    super.dispose();
  }
  
  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      fetchSensorData();
    });
  }
  
  Future<void> fetchSensorData() async {
    try {
      final response = await http
          .get(Uri.parse('http://$_ipAddress/sensors'))
          .timeout(const Duration(seconds: 2));
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          _distance = jsonData['distance'] ?? 0;
          _threshold = jsonData['threshold'] ?? 10;
          _irDetected = jsonData['ir'] ?? false;
          _pirDetected = jsonData['pir'] ?? false;
          _powerOn = jsonData['power'] ?? false;
          _ultrasonicBlocked = jsonData['ultrasonicBlocked'] ?? false;
          _irBlocked = jsonData['irBlocked'] ?? false;
          _timeUntilPowerOff = jsonData['timeUntilPowerOff'] ?? 0;
          _isConnected = true;
          _errorMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
        _errorMessage = 'Connection failed';
      });
    }
  }
  
  Future<void> sendCommand(String command) async {
    if (!_isConnected || _isSendingCommand) return;
    
    setState(() => _isSendingCommand = true);
    
    try {
      await http.get(
        Uri.parse('http://$_ipAddress/cmd?c=$command&s=$_speed'),
      ).timeout(const Duration(seconds: 1));
      
      setState(() => _currentDirection = command);
      
      // Reset direction after stop
      if (command == 'stop') {
        _commandTimer?.cancel();
      } else {
        _commandTimer?.cancel();
        _commandTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _currentDirection = 'stop');
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Command failed';
        _isConnected = false;
      });
    } finally {
      setState(() => _isSendingCommand = false);
    }
  }
  
  bool get canMoveForward => _powerOn && !_ultrasonicBlocked && !_irBlocked;
  
  Color get _powerColor {
    if (!_isConnected) return Colors.grey;
    return _powerOn ? Colors.green : Colors.red;
  }
  
  String get _powerStatus {
    if (!_isConnected) return 'OFFLINE';
    return _powerOn ? 'ON' : 'OFF';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A2E).withOpacity(0.95),
              const Color(0xFF16213E).withOpacity(0.98),
              const Color(0xFF0F3460),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildConnectionStatus(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSensorCard(),
                        const SizedBox(height: 20),
                        _buildControlCard(),
                        const SizedBox(height: 20),
                        _buildSpeedControl(),
                        const SizedBox(height: 20),
                        _buildSettingsCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo with animation
          AnimatedBuilder(
            animation: _spinAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _spinAnimation.value * 2 * 3.14159,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667eea).withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.rocket_launch,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Title
          const Column(
            children: [
              Text(
                'RANA JII',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),

            ],
          ),
          
          // Power indicator with pulse
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _powerOn ? _pulseValue.value : 1.0,
                child: Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: _powerColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _powerColor.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: _powerOn ? 5 : 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _powerStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: _isConnected 
            ? Colors.green.withOpacity(0.15)
            : Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _isConnected ? Colors.green : Colors.red,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isConnected ? Icons.wifi : Icons.wifi_off,
            color: _isConnected ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isConnected
                  ? 'Connected to Car Bot'
                  : _errorMessage.isNotEmpty ? _errorMessage : 'Disconnected',
              style: TextStyle(
                color: _isConnected ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (!_isConnected)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
              onPressed: fetchSensorData,
            ),
        ],
      ),
    );
  }

  Widget _buildSensorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _buildCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sensors, color: Color(0xFF667eea), size: 24),
              SizedBox(width: 10),
              Text(
                'Live Sensor Data',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildSensorItem(
            icon: Icons.square_foot,
            label: 'Ultrasonic',
            value: '$_distance cm',
            status: _getDistanceStatus(),
            statusColor: _getDistanceColor(),
            iconColor: Colors.cyan,
          ),
          
          const SizedBox(height: 15),
          
          _buildSensorItem(
            icon: Icons.color_lens,
            label: 'IR Sensor',
            value: _irDetected ? '⚠️ Object' : '✅ Clear',
            status: _irDetected ? 'Blocked' : 'Clear',
            statusColor: _irDetected ? Colors.red : Colors.green,
            iconColor: Colors.orange,
          ),
          
          const SizedBox(height: 15),
          
          _buildSensorItem(
            icon: Icons.person,
            label: 'PIR Motion',
            value: _pirDetected ? '🔴 Detected' : '⚫ None',
            status: _pirDetected ? 'Active' : 'Inactive',
            statusColor: _pirDetected ? Colors.green : Colors.grey,
            iconColor: Colors.purple,
          ),
          
          const SizedBox(height: 20),
          
          // Power timer
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade900.withOpacity(0.5),
                  Colors.purple.shade900.withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.timer, color: Colors.white70),
                    SizedBox(width: 10),
                    Text(
                      'Power Off In',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_timeUntilPowerOff}s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorItem({
    required IconData icon,
    required String label,
    required String value,
    required String status,
    required Color statusColor,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _buildCardDecoration(),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.gamepad, color: Color(0xFF667eea), size: 24),
              SizedBox(width: 10),
              Text(
                'Joystick Control',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Direction indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _getDirectionColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: _getDirectionColor(),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getDirectionIcon(),
                  color: _getDirectionColor(),
                  size: 30,
                ),
                const SizedBox(width: 10),
                Text(
                  _currentDirection.toUpperCase(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getDirectionColor(),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // D-pad controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                icon: Icons.arrow_back,
                onPressed: () => sendCommand('left'),
                color: Colors.blue,
                enabled: _isConnected,
              ),
              const SizedBox(width: 10),
              Column(
                children: [
                  _buildControlButton(
                    icon: Icons.arrow_upward,
                    onPressed: canMoveForward ? () => sendCommand('forward') : null,
                    color: canMoveForward ? Colors.blue : Colors.grey,
                    enabled: canMoveForward,
                    showDisabled: !canMoveForward,
                  ),
                  const SizedBox(height: 10),
                  _buildControlButton(
                    icon: Icons.arrow_downward,
                    onPressed: () => sendCommand('backward'),
                    color: Colors.blue,
                    enabled: _isConnected,
                  ),
                ],
              ),
              const SizedBox(width: 10),
              _buildControlButton(
                icon: Icons.arrow_forward,
                onPressed: () => sendCommand('right'),
                color: Colors.blue,
                enabled: _isConnected,
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Emergency stop
          _buildEmergencyStop(),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
    required bool enabled,
    bool showDisabled = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(25),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.7),
                  color,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: enabled ? 2 : 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
                if (showDisabled)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.block,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyStop() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => sendCommand('stop'),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stop_circle, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text(
                'EMERGENCY STOP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedControl() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _buildCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.speed, color: Color(0xFF667eea), size: 24),
              SizedBox(width: 10),
              Text(
                'Speed Control',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.slow_motion_video, color: Colors.white70),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                    activeTrackColor: const Color(0xFF667eea),
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    overlayColor: const Color(0xFF667eea).withOpacity(0.3),
                  ),
                  child: Slider(
                    value: _speed.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 10,
                    onChanged: (value) {
                      setState(() => _speed = value.toInt());
                    },
                  ),
                ),
              ),
              const Icon(Icons.flash_on, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF667eea).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_speed}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _buildCardDecoration(),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.settings, color: Color(0xFF667eea), size: 24),
              SizedBox(width: 10),
              Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'ESP8266 IP Address',
              hintText: '192.168.4.1',
              prefixIcon: const Icon(Icons.router, color: Colors.white70),
              labelStyle: const TextStyle(color: Colors.white70),
              hintStyle: const TextStyle(color: Colors.white38),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
            ),
            style: const TextStyle(color: Colors.white),
            initialValue: _ipAddress,
            onChanged: (value) => _ipAddress = value,
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  startPolling();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Reconnecting...'),
                      backgroundColor: Colors.blue,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(
                    child: Text(
                      'Reconnect',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  String _getDistanceStatus() {
    if (_distance <= 0) return 'No reading';
    if (_distance <= _threshold) return '⚠️ Obstacle';
    return '✅ Clear';
  }

  Color _getDistanceColor() {
    if (_distance <= 0) return Colors.grey;
    if (_distance <= _threshold) return Colors.red;
    return Colors.green;
  }

  IconData _getDirectionIcon() {
    switch (_currentDirection) {
      case 'forward':
        return Icons.arrow_upward;
      case 'backward':
        return Icons.arrow_downward;
      case 'left':
        return Icons.arrow_back;
      case 'right':
        return Icons.arrow_forward;
      default:
        return Icons.stop_circle;
    }
  }

  Color _getDirectionColor() {
    switch (_currentDirection) {
      case 'forward':
        return Colors.blue;
      case 'backward':
        return Colors.blue;
      case 'left':
      case 'right':
        return Colors.blue;
      default:
        return Colors.red;
    }
  }
}