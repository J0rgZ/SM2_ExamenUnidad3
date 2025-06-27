import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:data_table_2/data_table_2.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Panel Administrativo - Control de Asistencia',
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
          centerTitle: false,
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
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Check if the user is an admin
      final userDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(credential.user?.uid)
          .get();

      if (!userDoc.exists) {
        // Not an admin, sign out
        await FirebaseAuth.instance.signOut();
        setState(() {
          _errorMessage = 'No tienes permisos de administrador';
          _isLoading = false;
        });
        return;
      }

      // Successfully logged in as admin
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'No se encontró usuario con ese correo';
      } else if (e.code == 'wrong-password') {
        message = 'Contraseña incorrecta';
      } else {
        message = 'Error: ${e.message}';
      }
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
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
              const Color(0xFF6366F1).withOpacity(0.8),
              const Color(0xFF8B5CF6).withOpacity(0.9),
              const Color(0xFFEC4899),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    color: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.black.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Icon(
                              Icons.admin_panel_settings,
                              size: 64,
                              color: Color(0xFF6366F1),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Acceso Administrativo',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF6366F1),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Control de Asistencia',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            if (_errorMessage.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red[200]!),
                                ),
                                child: Text(
                                  _errorMessage,
                                  style: TextStyle(color: Colors.red[800]),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            if (_errorMessage.isNotEmpty) const SizedBox(height: 16),
                            TextField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Correo Electrónico',
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: Icon(Icons.lock_outline),
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                              onSubmitted: (_) => _login(),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Text('Iniciar Sesión'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fade(duration: 500.ms).scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1, 1),
                        duration: 500.ms,
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar navigation
          if (kIsWeb && MediaQuery.of(context).size.width > 768)
            NavigationDrawer(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                  _pageController.jumpToPage(index);
                });
              },
              children: const [
                SizedBox(height: 16),
                NavigationDrawerDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationDrawerDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('Trabajadores'),
                ),
                NavigationDrawerDestination(
                  icon: Icon(Icons.location_on_outlined),
                  selectedIcon: Icon(Icons.location_on),
                  label: Text('Ubicaciones'),
                ),
                NavigationDrawerDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: Text('Asistencias'),
                ),
                NavigationDrawerDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Configuración'),
                ),
                Divider(),
                NavigationDrawerDestination(
                  icon: Icon(Icons.logout_outlined),
                  selectedIcon: Icon(Icons.logout),
                  label: Text('Cerrar Sesión'),
                ),
              ],
            ),
          // Main content
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Panel Administrativo'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      }
                    },
                    tooltip: 'Cerrar Sesión',
                  ),
                  const SizedBox(width: 16),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    color: Colors.grey[300],
                    height: 1,
                  ),
                ),
              ),
              body: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  DashboardPage(),
                  WorkersPage(),
                  LocationsPage(),
                  //AttendancePage(),
                  //SettingsPage(),
                ],
              ),
              bottomNavigationBar: kIsWeb && MediaQuery.of(context).size.width > 768
                  ? null
                  : NavigationBar(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (index) {
                        if (index == 5) {
                          // Logout option
                          FirebaseAuth.instance.signOut();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                          return;
                        }
                        setState(() {
                          _selectedIndex = index;
                          _pageController.jumpToPage(index);
                        });
                      },
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          selectedIcon: Icon(Icons.dashboard),
                          label: 'Dashboard',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.person_outline),
                          selectedIcon: Icon(Icons.person),
                          label: 'Trabajadores',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.location_on_outlined),
                          selectedIcon: Icon(Icons.location_on),
                          label: 'Ubicaciones',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.history_outlined),
                          selectedIcon: Icon(Icons.history),
                          label: 'Asistencias',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.settings_outlined),
                          selectedIcon: Icon(Icons.settings),
                          label: 'Configuración',
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// Dashboard Page
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _totalEmployees = 0;
  int _todayAttendance = 0;
  int _lateCount = 0;
  int _absentCount = 0;
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Get total employees
      final employeesSnapshot = await FirebaseFirestore.instance.collection('employees').get();
      _totalEmployees = employeesSnapshot.docs.length;

      // Get today's date in the format yyyy-MM-dd
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Get today's attendance
      final attendanceSnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('date', isEqualTo: today)
          .get();

      _todayAttendance = attendanceSnapshot.docs.length;

      // Count late attendances
      _lateCount = attendanceSnapshot.docs
          .where((doc) {
            final data = doc.data();
            final checkInTime = data['checkInTime'] as String?;
            if (checkInTime == null) return false;

            // Parse check-in time and compare with expected time (e.g., 9:00 AM)
            final format = DateFormat('HH:mm');
            final checkIn = format.parse(checkInTime);
            final expectedTime = format.parse('09:00');
            return checkIn.isAfter(expectedTime);
          })
          .length;

      // Calculate absent employees
      _absentCount = _totalEmployees - _todayAttendance;
      if (_absentCount < 0) _absentCount = 0;

      // Get recent activity
      final activitySnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      _recentActivity = await Future.wait(activitySnapshot.docs.map((doc) async {
        final data = doc.data();
        final employeeId = data['employeeId'] as String?;
        String employeeName = 'Desconocido';

        if (employeeId != null) {
          final employeeDoc = await FirebaseFirestore.instance
              .collection('employees')
              .doc(employeeId)
              .get();
          if (employeeDoc.exists) {
            final employeeData = employeeDoc.data();
            employeeName = '${employeeData?['firstName']} ${employeeData?['lastName']}';
          }
        }

        return {
          'id': doc.id,
          'employeeId': employeeId,
          'employeeName': employeeName,
          'action': data['type'] == 'checkIn' ? 'Entrada' : 'Salida',
          'time': data['checkInTime'] ?? data['checkOutTime'] ?? '',
          'date': data['date'] ?? '',
          'status': data['status'] ?? 'Normal',
          'locationName': data['locationName'] ?? 'Desconocida',
        };
      }));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panel de Control',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Resumen de asistencia y estadísticas',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Stats cards
                    GridView.count(
                      crossAxisCount: isWideScreen ? 4 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStatsCard(
                          context,
                          title: 'Total Trabajadores',
                          value: _totalEmployees.toString(),
                          icon: Icons.people,
                          color: Colors.blue,
                        ),
                        _buildStatsCard(
                          context,
                          title: 'Asistencias Hoy',
                          value: _todayAttendance.toString(),
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                        _buildStatsCard(
                          context,
                          title: 'Tardanzas',
                          value: _lateCount.toString(),
                          icon: Icons.watch_later,
                          color: Colors.orange,
                        ),
                        _buildStatsCard(
                          context,
                          title: 'Ausencias',
                          value: _absentCount.toString(),
                          icon: Icons.do_not_disturb,
                          color: Colors.red,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    Text(
                      'Actividad Reciente',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Recent activity list
                    if (_recentActivity.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.history,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay actividad reciente',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Card(
                        margin: EdgeInsets.zero,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentActivity.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: Colors.grey[200],
                          ),
                          itemBuilder: (context, index) {
                            final activity = _recentActivity[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: activity['action'] == 'Entrada'
                                    ? Colors.green[100]
                                    : Colors.blue[100],
                                child: Icon(
                                  activity['action'] == 'Entrada'
                                      ? Icons.login
                                      : Icons.logout,
                                  color: activity['action'] == 'Entrada'
                                      ? Colors.green[800]
                                      : Colors.blue[800],
                                ),
                              ),
                              title: Text(activity['employeeName']),
                              subtitle: Text(
                                '${activity['action']} - ${activity['locationName']}',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    activity['time'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    activity['date'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }
}

// Workers Page
class WorkersPage extends StatefulWidget {
  const WorkersPage({super.key});

  @override
  State<WorkersPage> createState() => _WorkersPageState();
}

class _WorkersPageState extends State<WorkersPage> {
  final _employeesCollection = FirebaseFirestore.instance.collection('employees');
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _dniController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _positionController = TextEditingController();
  
  String? _selectedEmployeeId;
  bool _processingForm = false;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dniController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await _employeesCollection.get();
      
      final employees = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'dni': data['dni'] ?? '',
          'firstName': data['firstName'] ?? '',
          'lastName': data['lastName'] ?? '',
          'email': data['email'] ?? '',
          'phone': data['phone'] ?? '',
          'department': data['department'] ?? '',
          'position': data['position'] ?? '',
          'status': data['status'] ?? 'Activo',
          'profilePicUrl': data['profilePicUrl'],
        };
      }).toList();

      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading employees: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredEmployees {
    if (_searchQuery.isEmpty) {
      return _employees;
    }
    
    final query = _searchQuery.toLowerCase();
    return _employees.where((employee) {
      return employee['dni'].toString().toLowerCase().contains(query) ||
          employee['firstName'].toString().toLowerCase().contains(query) ||
          employee['lastName'].toString().toLowerCase().contains(query) ||
          employee['department'].toString().toLowerCase().contains(query) ||
          employee['position'].toString().toLowerCase().contains(query);
    }).toList();
  }

  void _resetForm() {
    _selectedEmployeeId = null;
    _dniController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _departmentController.clear();
    _positionController.clear();
  }

  void _editEmployee(Map<String, dynamic> employee) {
    setState(() {
      _selectedEmployeeId = employee['id'];
      _dniController.text = employee['dni'] ?? '';
      _firstNameController.text = employee['firstName'] ?? '';
      _lastNameController.text = employee['lastName'] ?? '';
      _emailController.text = employee['email'] ?? '';
      _phoneController.text = employee['phone'] ?? '';
      _departmentController.text = employee['department'] ?? '';
      _positionController.text = employee['position'] ?? '';
    });

    _showEmployeeForm();
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _processingForm = true;
    });

    try {
      final employeeData = {
        'dni': _dniController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'department': _departmentController.text.trim(),
        'position': _positionController.text.trim(),
        'status': 'Activo',
      };

      if (_selectedEmployeeId == null) {
        // Add new employee
        await _employeesCollection.add(employeeData);
      } else {
        // Update existing employee
        await _employeesCollection.doc(_selectedEmployeeId).update(employeeData);
      }

      // Reload employees
      await _loadEmployees();
      
      // Close form
      if (mounted) {
        Navigator.pop(context);
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedEmployeeId == null
                ? 'Trabajador agregado correctamente'
                : 'Trabajador actualizado correctamente',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Reset form
      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _processingForm = false;
      });
    }
  }

  Future<void> _deleteEmployee(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Está seguro que desea eliminar a $name? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _employeesCollection.doc(id).delete();
        
        // Reload employees
        await _loadEmployees();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trabajador eliminado correctamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showEmployeeForm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_selectedEmployeeId == null ? 'Agregar Trabajador' : 'Editar Trabajador'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _dniController,
                    decoration: const InputDecoration(
                      labelText: 'DNI / Identificación',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Este campo es requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombres',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Este campo es requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Apellidos',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Este campo es requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _departmentController,
                    decoration: const InputDecoration(
                      labelText: 'Departamento',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _positionController,
                    decoration: const InputDecoration(
                      labelText: 'Cargo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForm();
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: _processingForm ? null : _saveEmployee,
            child: _processingForm
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                : Text(_selectedEmployeeId == null ? 'Agregar' : 'Actualizar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trabajadores',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                FilledButton.icon(
                  onPressed: () {
                    _resetForm();
                    _showEmployeeForm();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Trabajador'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar trabajadores...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Employees table
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredEmployees.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No se encontraron trabajadores',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Card(
                          margin: EdgeInsets.zero,
                          child: DataTable2(
                            columnSpacing: 12,
                            horizontalMargin: 12,
                            columns: const [
                              DataColumn2(
                                label: Text('DNI'),
                                size: ColumnSize.S,
                              ),
                              DataColumn2(
                                label: Text('Nombre'),
                                size: ColumnSize.L,
                              ),
                              DataColumn2(
                                label: Text('Departamento'),
                                size: ColumnSize.M,
                              ),
                              DataColumn2(
                                label: Text('Cargo'),
                                size: ColumnSize.M,
                              ),
                              DataColumn2(
                                label: Text('Acciones'),
                                size: ColumnSize.S,
                              ),
                            ],
                            rows: _filteredEmployees.map((employee) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(employee['dni'] ?? '')),
                                  DataCell(
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                                          backgroundImage: employee['profilePicUrl'] != null
                                              ? NetworkImage(employee['profilePicUrl'])
                                              : null,
                                          child: employee['profilePicUrl'] == null
                                              ? Text(
                                                  '${employee['firstName'][0]}${employee['lastName'][0]}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context).primaryColor,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${employee['firstName']} ${employee['lastName']}',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(employee['department'] ?? '')),
                                  DataCell(Text(employee['position'] ?? '')),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 20),
                                          tooltip: 'Editar',
                                          onPressed: () => _editEmployee(employee),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 20),
                                          tooltip: 'Eliminar',
                                          color: Colors.red,
                                          onPressed: () => _deleteEmployee(
                                            employee['id'],
                                            '${employee['firstName']} ${employee['lastName']}',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// Locations Page
class LocationsPage extends StatefulWidget {
  const LocationsPage({super.key});

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  final _locationsCollection = FirebaseFirestore.instance.collection('locations');
  List<Map<String, dynamic>> _locations = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _radiusController = TextEditingController();
  
  String? _selectedLocationId;
  bool _processingForm = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await _locationsCollection.get();
      
      final locations = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'address': data['address'] ?? '',
          'latitude': data['latitude'] ?? 0.0,
          'longitude': data['longitude'] ?? 0.0,
          'radius': data['radius'] ?? 100,
          'active': data['active'] ?? true,
        };
      }).toList();

      setState(() {
        _locations = locations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading locations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredLocations {
    if (_searchQuery.isEmpty) {
      return _locations;
    }
    
    final query = _searchQuery.toLowerCase();
    return _locations.where((location) {
      return location['name'].toString().toLowerCase().contains(query) ||
          location['address'].toString().toLowerCase().contains(query);
    }).toList();
  }

  void _resetForm() {
    _selectedLocationId = null;
    _nameController.clear();
    _addressController.clear();
    _latitudeController.clear();
    _longitudeController.clear();
    _radiusController.text = '100';
  }

  void _editLocation(Map<String, dynamic> location) {
    setState(() {
      _selectedLocationId = location['id'];
      _nameController.text = location['name'] ?? '';
      _addressController.text = location['address'] ?? '';
      _latitudeController.text = location['latitude']?.toString() ?? '';
      _longitudeController.text = location['longitude']?.toString() ?? '';
      _radiusController.text = location['radius']?.toString() ?? '100';
    });

    _showLocationForm();
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _processingForm = true;
    });

    try {
      final locationData = {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'latitude': double.tryParse(_latitudeController.text) ?? 0.0,
        'longitude': double.tryParse(_longitudeController.text) ?? 0.0,
        'radius': int.tryParse(_radiusController.text) ?? 100,
        'active': true,
      };

      if (_selectedLocationId == null) {
        // Add new location
        await _locationsCollection.add(locationData);
      } else {
        // Update existing location
        await _locationsCollection.doc(_selectedLocationId).update(locationData);
      }

      // Reload locations
      await _loadLocations();
      
      // Close form
      if (mounted) {
        Navigator.pop(context);
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedLocationId == null
                ? 'Ubicación agregada correctamente'
                : 'Ubicación actualizada correctamente',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Reset form
      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _processingForm = false;
      });
    }
  }

  Future<void> _deleteLocation(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Está seguro que desea eliminar la ubicación "$name"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _locationsCollection.doc(id).delete();
        
        // Reload locations
        await _loadLocations();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubicación eliminada correctamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showLocationForm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_selectedLocationId == null ? 'Agregar Ubicación' : 'Editar Ubicación'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la Ubicación',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Este campo es requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Este campo es requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latitudeController,
                          decoration: const InputDecoration(
                            labelText: 'Latitud',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requerido';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _longitudeController,
                          decoration: const InputDecoration(
                            labelText: 'Longitud',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requerido';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _radiusController,
                    decoration: const InputDecoration(
                      labelText: 'Radio (metros)',
                      border: OutlineInputBorder(),
                      helperText: 'Distancia máxima permitida para registrar asistencia',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Este campo es requerido';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Ingrese un número válido';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForm();
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: _processingForm ? null : _saveLocation,
            child: _processingForm
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                : Text(_selectedLocationId == null ? 'Agregar' : 'Actualizar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ubicaciones',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                FilledButton.icon(
                  onPressed: () {
                    _resetForm();
                    _showLocationForm();
                  },
                  icon: const Icon(Icons.add_location_alt),
                  label: const Text('Agregar Ubicación'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar ubicaciones...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Locations table
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredLocations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No se encontraron ubicaciones',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Card(
                          margin: EdgeInsets.zero,
                          child: DataTable2(
                            columnSpacing: 12,
                            horizontalMargin: 12,
                            columns: const [
                              DataColumn2(
                                label: Text('Nombre'),
                                size: ColumnSize.L,
                              ),
                              DataColumn2(
                                label: Text('Dirección'),
                                size: ColumnSize.L,
                              ),
                              DataColumn2(
                                label: Text('Coordenadas'),
                                size: ColumnSize.M,
                              ),
                              DataColumn2(
                                label: Text('Radio'),
                                size: ColumnSize.S,
                              ),
                              DataColumn2(
                                label: Text('Acciones'),
                                size: ColumnSize.S,
                              ),
                            ],
                            rows: _filteredLocations.map((location) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: Theme.of(context).primaryColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            location['name'] ?? '',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(location['address'] ?? '')),
                                  DataCell(Text(
                                    '${location['latitude']}, ${location['longitude']}',
                                  )),
                                  DataCell(Text('${location['radius']} m')),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 20),
                                          tooltip: 'Editar',
                                          onPressed: () => _editLocation(location),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 20),
                                          tooltip: 'Eliminar',
                                          color: Colors.red,
                                          onPressed: () => _deleteLocation(
                                            location['id'],
                                            location['name'],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}