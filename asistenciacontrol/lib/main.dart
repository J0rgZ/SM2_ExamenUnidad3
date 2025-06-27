import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'admin_login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control de Asistencia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Indigo
          secondary: const Color(0xFF8B5CF6), // Violet
          tertiary: const Color(0xFFEC4899), // Pink
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: GoogleFonts.poppins().fontFamily,
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: const CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      // Add localization delegates for date formatting
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', ''),
        Locale('en', ''),
      ],
      locale: const Locale('es', ''),
      home: const HomePage(),
    );
  }
}

  class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                ],
              ),
            ),
            child: SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(height: 40),
                          _buildHeaderSection(context),
                          const Spacer(),
                          _buildOptionsSection(context),
                          const Spacer(),
                          _buildFooterSection(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildHeaderSection(BuildContext context) {
    return Column(
      children: [
        Hero(
          tag: 'app-logo',
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Icon(
              Icons.access_time_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Control de Asistencia',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: -1,
            shadows: [
              Shadow(
                blurRadius: 12.0,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                offset: const Offset(1.5, 1.5),
              ),
            ],
          ),
        ),
        Text(
          'Sistema Integral de Registro',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildOptionsSection(BuildContext context) {
    return Column(
      children: [
        _buildOptionCard(
          title: 'Registro de Usuario',
          subtitle: 'Registra tu entrada y salida',
          icon: Icons.person_rounded,
          color: Theme.of(context).colorScheme.primary,
          onTap: () => Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const AttendancePage())
          ),
          context: context, // Añadido aquí
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 16),
        _buildOptionCard(
          title: 'Acceso Admin',
          subtitle: 'Panel de administración',
          icon: Icons.admin_panel_settings_rounded,
          color: Theme.of(context).colorScheme.secondary,
          onTap: () => Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const AdminLoginPage())
          ),
          context: context, // Añadido aquí
        ).animate().fadeIn(duration: 500.ms).slideY(
          begin: 0.2, 
          end: 0, 
          delay: 250.ms
        ),
      ],
    );
  }

  Widget _buildFooterSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        children: [
          Text(
            '© ${DateTime.now().year} Control de Asistencia',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            'Desarrollado con seguridad y precisión',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 25,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: color.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.3),
                      color.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 22,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> with TickerProviderStateMixin {
  bool _isLoading = false;
  File? _imageFile;
  bool _isAtValidLocation = false;
  bool _hasCheckedIn = false;
  String _lastAction = '';
  String _message = 'Verificando ubicación...';
  
  // Coordenadas del lugar permitido (ejemplo)
  final double _targetLatitude = -17.997823835873643; 
  final double _targetLongitude = -70.23955157259915;
  final double _allowedDistance = 100; // Distancia permitida en metros
  
  late AnimationController _pulseController;
  late AnimationController _checkInController;

  final TextEditingController _dniController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _checkInController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    
    // Agregar listener al campo de DNI
    _dniController.addListener(() {
      if (_dniController.text.length >= 8) { // DNI peruano típico tiene 8 dígitos
        _checkAttendanceStatus(_dniController.text);
      }
    });
    
    _checkLocationPermission();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _checkInController.dispose();
    _dniController.dispose();
    super.dispose();
  }

  Future<void> _checkAttendanceStatus(String dni) async {
    if (dni.isEmpty) return;
    
    try {
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      QuerySnapshot attendanceSnapshot = await _firestore
        .collection('attendance')
        .where('dni', isEqualTo: dni)
        .where('date', isEqualTo: today)
        .get();
      
      if (attendanceSnapshot.docs.isNotEmpty) {
        Map<String, dynamic> data = attendanceSnapshot.docs.first.data() as Map<String, dynamic>;
        
        setState(() {
          // Si hay checkIn pero no checkOut, entonces ha marcado entrada pero no salida
          if (data['checkIn'] != null && data['checkOut'] == null) {
            _hasCheckedIn = true;
            _lastAction = 'Entrada registrada a las ${data['checkIn']['time']}';
          } 
          // Si tiene ambos, ya completó su ciclo de asistencia
          else if (data['checkIn'] != null && data['checkOut'] != null) {
            _hasCheckedIn = true;
            _lastAction = 'Salida registrada a las ${data['checkOut']['time']}';
          }
        });
      }
    } catch (e) {
      print('Error al verificar estado de asistencia: $e');
    }
  }
  
  Future<void> _checkLocationPermission() async {
    setState(() {
      _isLoading = true;
    });
    
    bool serviceEnabled;
    LocationPermission permission;
    
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _message = 'Los servicios de ubicación están desactivados';
        });
        return;
      }
      
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _message = 'Permisos de ubicación denegados';
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _message = 'Los permisos de ubicación están permanentemente denegados';
        });
        return;
      }
      
      _verifyLocation();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Error al obtener permisos: $e';
      });
    }
  }
  
  Future<void> _verifyLocation() async {
    setState(() {
      _isLoading = true;
      _message = 'Verificando ubicación...';
    });
    
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _targetLatitude,
        _targetLongitude
      );
      
      setState(() {
        _isLoading = false;
        _isAtValidLocation = distance <= _allowedDistance;
        _message = _isAtValidLocation 
          ? 'Ubicación verificada ✓\nEstás dentro del perímetro permitido.'
          : 'Fuera del perímetro permitido ✗\nDistancia: ${distance.toStringAsFixed(0)}m';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Error al obtener ubicación: $e';
      });
    }
  }
  
  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera, // Solo permite cámara, no galería
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
      );
      
      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
        });
        
        // Animación de éxito al tomar la foto
        _checkInController.reset();
        _checkInController.forward();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al capturar imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _canMarkAttendance(String dni, bool isCheckIn) async {
    try {
      // Check if employee exists
      QuerySnapshot employeeSnapshot = await _firestore
          .collection('employees')
          .where('dni', isEqualTo: dni)
          .get();
      
      if (employeeSnapshot.docs.isEmpty) {
        _showErrorDialog('DNI Inválido', 'El DNI no está registrado');
        return false;
      }

      // Check daily attendance
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      QuerySnapshot attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('dni', isEqualTo: dni)
          .where('date', isEqualTo: today)
          .get();

      if (attendanceSnapshot.docs.isNotEmpty) {
        for (var doc in attendanceSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          if (isCheckIn && data['checkIn'] != null) {
            _showErrorDialog('Error', 'Ya has marcado tu entrada hoy');
            return false;
          }
          
          if (!isCheckIn && data['checkOut'] != null) {
            _showErrorDialog('Error', 'Ya has marcado tu salida hoy');
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      print('Verification error: $e');
      return false;
    }
  }

  
  
  Future<void> _markAttendance(bool isCheckIn) async {
    if (!await _canMarkAttendance(_dniController.text, isCheckIn)) return;

    try {
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String now = DateFormat('HH:mm:ss').format(DateTime.now());

      // Find or create today's attendance record
      QuerySnapshot existingRecords = await _firestore
          .collection('attendance')
          .where('dni', isEqualTo: _dniController.text)
          .where('date', isEqualTo: today)
          .get();
      
      DocumentReference attendanceRef;
      
      if (existingRecords.docs.isNotEmpty && !isCheckIn) {
        // Update existing record for check-out
        attendanceRef = existingRecords.docs.first.reference;
        
        // Get check-in time from existing document
        String checkInTime = (existingRecords.docs.first.data() as Map<String, dynamic>)['checkIn']['time'];
        
        // Calculate total hours
        DateTime checkInDateTime = DateFormat('HH:mm:ss').parse(checkInTime);
        DateTime checkOutTime = DateFormat('HH:mm:ss').parse(now);
        
        double totalHours = checkOutTime.difference(checkInDateTime).inMinutes / 60.0;
        
        await attendanceRef.update({
          'checkOut': {
            'time': now,
            'location': {
              'latitude': _targetLatitude,
              'longitude': _targetLongitude
            },
            'photoTaken': true,  // Indicador de que se tomó la foto
          },
          'totalHoursWorked': totalHours.toStringAsFixed(2),
          'status': 'completed'
        });
      } else {
        // Create new record for check-in
        attendanceRef = _firestore.collection('attendance').doc();
        await attendanceRef.set({
          'dni': _dniController.text,
          'date': today,
          'checkIn': {
            'time': now,
            'location': {
              'latitude': _targetLatitude,
              'longitude': _targetLongitude
            },
            'photoTaken': true,  // Indicador de que se tomó la foto
          }
        });
      }

      setState(() {
        _hasCheckedIn = isCheckIn;
        _lastAction = isCheckIn 
          ? 'Entrada registrada a las $now' 
          : 'Salida registrada a las $now';
      });

      // Show success and update UI
      _showSuccessDialog(isCheckIn);
    } catch (e) {
      _showErrorDialog('Error', 'No se pudo registrar la asistencia: $e');
    }
  }

  

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }
  
  void _showSuccessDialog(bool isCheckIn) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isCheckIn ? '¡Entrada Registrada!' : '¡Salida Registrada!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isCheckIn 
                    ? 'Tu asistencia ha sido marcada correctamente.'
                    : 'Tu salida ha sido registrada correctamente.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Cierra el diálogo
                      // Regresa a la página de inicio
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomePage()
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fade(duration: 300.ms);
      },
    );
  }

  
  
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentTime = DateFormat('HH:mm').format(now);
    final currentDate = DateFormat('EEEE, d MMMM', 'es').format(now);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Glassmorphism Effect
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Control de Asistencia', 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                      Theme.of(context).colorScheme.tertiary,
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Enhanced Date and Time Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withOpacity(0.8),
                            Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                                size: 32,
                              ),
                              Text(
                                currentTime,
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentDate.capitalize(),
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade(duration: 300.ms).slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 16),

                  // Simplified Location Status
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: _isAtValidLocation 
                                ? Colors.green[50] 
                                : Colors.red[50],
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                _isAtValidLocation ? Icons.check_circle : Icons.error,
                                color: _isAtValidLocation ? Colors.green : Colors.red,
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isAtValidLocation ? 'Ubicación Verificada' : 'Ubicación No Válida',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _isAtValidLocation ? Colors.green[700] : Colors.red[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _message,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.refresh, 
                              color: _isAtValidLocation ? Colors.green : Colors.red,
                            ),
                            onPressed: _verifyLocation,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade(duration: 400.ms, delay: 100.ms).slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 16),
                  
                  // DNI Input Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Identificación',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _dniController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Ingrese su DNI',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.credit_card),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade(duration: 500.ms, delay: 200.ms).slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 16),
                  
                  // Photo Verification Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Foto de Verificación',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toma una selfie para verificar tu identidad',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: _takePicture,
                            child: Container(
                              height: 250,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _imageFile != null 
                                    ? Theme.of(context).colorScheme.primary 
                                    : Colors.grey[300]!,
                                  width: 2,
                                ),
                                boxShadow: _imageFile != null ? [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  )
                                ] : null,
                              ),
                              child: _imageFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.file(
                                          _imageFile!,
                                          fit: BoxFit.cover,
                                        ),
                                        // Verification Overlay
                                        AnimatedBuilder(
                                          animation: _checkInController,
                                          builder: (context, child) {
                                            return _checkInController.value > 0 
                                              ? Positioned(
                                                  bottom: 10,
                                                  right: 10,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context).colorScheme.primary,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                      size: 24,
                                                    ),
                                                  ),
                                                )
                                              : const SizedBox();
                                          },
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt_rounded,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        "Toca para tomar una foto",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _takePicture,
                              icon: const Icon(Icons.camera_alt_rounded),
                              label: const Text('Tomar Selfie Ahora'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade(duration: 600.ms, delay: 300.ms).slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 16),
                  
                  // Attendance Registration Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Registro de Asistencia',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_lastAction.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12, 
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _hasCheckedIn ? Icons.login : Icons.logout,
                                    size: 20,
                                    color: _hasCheckedIn ? Colors.green : Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _lastAction,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isAtValidLocation && _imageFile != null && !_hasCheckedIn && _dniController.text.isNotEmpty
                                    ? () => _markAttendance(true)
                                    : null,
                                  icon: const Icon(Icons.login_rounded),
                                  label: const Column(
                                    children: [
                                      Text('Marcar'),
                                      Text('Entrada'),
                                    ],
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    disabledBackgroundColor: Colors.grey[300],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isAtValidLocation && _imageFile != null && _hasCheckedIn && _dniController.text.isNotEmpty
                                    ? () => _markAttendance(false)
                                    : null,
                                  icon: const Icon(Icons.logout_rounded),
                                  label: const Column(
                                    children: [
                                      Text('Marcar'),
                                      Text('Salida'),
                                    ],
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    disabledBackgroundColor: Colors.grey[300],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade(duration: 700.ms, delay: 400.ms).slideY(begin: 0.3, end: 0),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      // Loading Indicator
      floatingActionButton: _isLoading
        ? Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          )
        : null,
    );
  }
}

// Extensión para capitalizar texto
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) {
      return this;
    }
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
