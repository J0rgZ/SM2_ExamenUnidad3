import 'package:asistenciacontrol/empleado.dart';
import 'package:asistenciacontrol/sede.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'models.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Firestore References
  final CollectionReference _employeesRef = 
      FirebaseFirestore.instance.collection('employees');
  final CollectionReference _sedesRef = 
      FirebaseFirestore.instance.collection('sedes');
  final CollectionReference _attendanceRef = 
      FirebaseFirestore.instance.collection('attendance');

  // State Variables
  List<Employee> _employees = [];
  List<Sede> _sedes = [];
  List<Attendance> _attendances = [];
  bool _isLoading = true;

   // Dashboard Statistics
  int _totalEmployees = 0;
  int _presentEmployees = 0;
  Map<String, int> _attendanceByLocation = {};
  
  // Filter Variables
  DateTime? _selectedDate;
  String? _selectedSede;

  // Añade estas variables de estado adicionales
  List<Employee> _presentEmployeesToday = [];
  List<Employee> _absentEmployeesToday = [];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchEmployees(),
        _fetchSedes(),
      ]);
      await _fetchAttendances(); // Cargar asistencias después de empleados y sedes
    } catch (e) {
      _showErrorDialog('Error de Carga', 'No se pudieron cargar los datos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Modifica el método _calculateDashboardStatistics para incluir listas de presentes/ausentes
  Future<void> _calculateDashboardStatistics() async {
    // Total Employees
    _totalEmployees = _employees.length;

    // Obtener la fecha de hoy (o la fecha seleccionada si existe)
    final targetDate = _selectedDate ?? DateTime.now();
    final dateToCheck = DateTime(targetDate.year, targetDate.month, targetDate.day);
    
    // Identificar empleados presentes hoy
    final presentEmployeeIds = _attendances
        .where((attendance) {
          final attendanceDate = DateTime(
            attendance.checkIn.year,
            attendance.checkIn.month,
            attendance.checkIn.day);
          return attendanceDate.isAtSameMomentAs(dateToCheck);
        })
        .map((a) => a.employeeId)
        .toSet();
    
    _presentEmployeesToday = _employees
        .where((emp) => presentEmployeeIds.contains(emp.id) || presentEmployeeIds.contains(emp.dni))
        .toList();
    
    _absentEmployeesToday = _employees
        .where((emp) => !presentEmployeeIds.contains(emp.id) && !presentEmployeeIds.contains(emp.dni))
        .toList();
    
    _presentEmployees = _presentEmployeesToday.length;

    // Attendance by Location
    _attendanceByLocation = {};
    for (var attendance in _attendances) {
      if (_attendanceByLocation[attendance.sede] == null) {
        _attendanceByLocation[attendance.sede] = 0;
      }
      _attendanceByLocation[attendance.sede] = _attendanceByLocation[attendance.sede]! + 1;
    }
  }

  Future<void> _fetchEmployees() async {
    QuerySnapshot snapshot = await _employeesRef.get();
    _employees = snapshot.docs.map((doc) {
      return Employee.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }

  Future<void> _fetchSedes() async {
    QuerySnapshot snapshot = await _sedesRef.get();
    _sedes = snapshot.docs.map((doc) {
      return Sede.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }

  Future<void> _fetchAttendances() async {
    Query query = _attendanceRef;
    
    // Determine date range for fetching
    DateTime startOfDay;
    DateTime endOfDay;
    
    if (_selectedDate != null) {
      startOfDay = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
    } else {
      final now = DateTime.now();
      startOfDay = DateTime(now.year, now.month, now.day);
    }
    
    endOfDay = startOfDay.add(const Duration(days: 1));
    
    // Apply date filters
    if (_doesAttendanceUseNestedStructure()) {
      // Si la estructura usa un campo "date" separado
      query = query.where('date', isEqualTo: DateFormat('yyyy-MM-dd').format(startOfDay));
    } else {
      // Si la estructura usa timestamp directamente
      query = query.where('checkIn', isGreaterThanOrEqualTo: startOfDay)
                .where('checkIn', isLessThan: endOfDay);
    }
    
    // Apply sede filter if selected
    if (_selectedSede != null) {
      query = query.where('sede', isEqualTo: _selectedSede);
    }

    try {
      QuerySnapshot snapshot = await query.get();
      
      setState(() {
        _attendances = snapshot.docs.map((doc) {
          return Attendance.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        }).toList();
      });
      
      // Actualizar estadísticas del dashboard
      await _calculateDashboardStatistics();
    } catch (e) {
      _showErrorDialog('Error', 'No se pudieron cargar las asistencias: $e');
    }
  }

  bool _doesAttendanceUseNestedStructure() {
    // You might need to retrieve a sample document first to check its structure
    // For now, let's assume your structure is the nested one from Firestore
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          'Panel de Administración',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchInitialData(),
            tooltip: 'Actualizar datos',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboardView(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildDashboardView() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateFilter(),
              const SizedBox(height: 20),
              _buildQuickStatistics(),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
                child: Text(
                  'Asistencia Diaria',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E4053),
                  ),
                ),
              ),
              _buildAttendanceChart(),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
                child: Text(
                  'Distribución por Ubicación',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E4053),
                  ),
                ),
              ),
              _buildLocationBreakdown(),
              const SizedBox(height: 16), // Espacio adicional al final
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Icon(Icons.filter_list, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            const Text(
              'Fecha:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Theme.of(context).primaryColor,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = pickedDate;
                    });
                    await _fetchAttendances();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate != null
                            ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                            : 'Hoy (${DateFormat('dd/MM/yyyy').format(DateTime.now())})',
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                      Icon(Icons.calendar_today, size: 16, color: Theme.of(context).primaryColor),
                    ],
                  ),
                ),
              ),
            ),
            if (_selectedDate != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    setState(() {
                      _selectedDate = null;
                    });
                    await _fetchAttendances();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.clear,
                      color: Colors.red.shade600,
                      size: 18,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatistics() {
    // Calcular el porcentaje de asistencia
    final attendancePercentage = _totalEmployees > 0 
        ? (_presentEmployees / _totalEmployees * 100).toStringAsFixed(1) 
        : '0.0';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(
            'Resumen de Asistencia',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E4053),
            ),
          ),
        ),
        // Usamos LayoutBuilder para detectar el ancho disponible
        LayoutBuilder(
          builder: (context, constraints) {
            // Si el ancho es menor a 600px, mostramos las tarjetas en columna
            // Si es mayor, las mostramos en fila como antes
            bool isSmallScreen = constraints.maxWidth < 600;
            
            return isSmallScreen 
              ? Column(
                  children: [
                    _buildEmployeeCard(
                      title: 'Total Empleados',
                      value: _totalEmployees.toString(),
                      icon: Icons.people_alt_rounded,
                      progressValue: 1.0,
                      baseColor: Colors.blue,
                      suffix: 'empleados',
                      tag: 'Plantilla',
                      tagIcon: Icons.info_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildEmployeeCard(
                      title: 'Empleados Presentes',
                      value: _presentEmployees.toString(),
                      icon: Icons.how_to_reg_rounded,
                      progressValue: _totalEmployees > 0 ? _presentEmployees / _totalEmployees : 0,
                      baseColor: Colors.green,
                      suffix: 'de $_totalEmployees',
                      tag: '$attendancePercentage%',
                      tagIcon: Icons.percent,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildEmployeeCard(
                        title: 'Total Empleados',
                        value: _totalEmployees.toString(),
                        icon: Icons.people_alt_rounded,
                        progressValue: 1.0,
                        baseColor: Colors.blue,
                        suffix: 'empleados',
                        tag: 'Plantilla',
                        tagIcon: Icons.info_outline,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildEmployeeCard(
                        title: 'Empleados Presentes',
                        value: _presentEmployees.toString(),
                        icon: Icons.how_to_reg_rounded,
                        progressValue: _totalEmployees > 0 ? _presentEmployees / _totalEmployees : 0,
                        baseColor: Colors.green,
                        suffix: 'de $_totalEmployees',
                        tag: '$attendancePercentage%',
                        tagIcon: Icons.percent,
                      ),
                    ),
                  ],
                );
          }
        ),
      ],
    );
  }

  // Método reutilizable para construir las tarjetas de estadísticas
  Widget _buildEmployeeCard({
    required String title,
    required String value,
    required IconData icon,
    required double progressValue,
    required MaterialColor baseColor,
    required String suffix,
    required String tag,
    required IconData tagIcon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              baseColor.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: icono y etiqueta
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: baseColor.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: baseColor.shade700,
                    ),
                  ),
                  // Etiqueta
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: baseColor.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tagIcon,
                          size: 14,
                          color: baseColor.shade800,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          tag,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: baseColor.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Título
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 6),
              // Valor principal con sufijo
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: baseColor.shade800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    suffix,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Barra de progreso
              LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(baseColor.shade500),
                minHeight: 5,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceChart() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Asistencias del ${_selectedDate != null ? DateFormat('dd/MM/yyyy').format(_selectedDate!) : "día de hoy"}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3142),
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 2,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 1)),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFF4361EE),
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: Color(0xFF2D3142),
                                  ),
                                  dialogBackgroundColor: Colors.white,
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _selectedDate = pickedDate;
                            });
                            await _fetchAttendances();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.blue.shade700,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  return constraints.maxWidth < 600
                      ? Column(
                          children: [
                            _buildAttendanceStatusCard(
                              title: 'Presentes',
                              count: _presentEmployeesToday.length,
                              icon: Icons.check_circle_rounded,
                              color: const Color(0xFF4CAF50),
                              employees: _presentEmployeesToday,
                            ),
                            const SizedBox(height: 16),
                            _buildAttendanceStatusCard(
                              title: 'Ausentes',
                              count: _absentEmployeesToday.length,
                              icon: Icons.cancel_rounded,
                              color: const Color(0xFFE53935),
                              employees: _absentEmployeesToday,
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _buildAttendanceStatusCard(
                                title: 'Presentes',
                                count: _presentEmployeesToday.length,
                                icon: Icons.check_circle_rounded,
                                color: const Color(0xFF4CAF50),
                                employees: _presentEmployeesToday,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildAttendanceStatusCard(
                                title: 'Ausentes',
                                count: _absentEmployeesToday.length,
                                icon: Icons.cancel_rounded,
                                color: const Color(0xFFE53935),
                                employees: _absentEmployeesToday,
                              ),
                            ),
                          ],
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceStatusCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required List<Employee> employees,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showEmployeeListDialog(title, employees),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: color,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                count.toString(),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2D3142),
                                  height: 0.9,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  'empleados',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: color,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Toca para ver detalles',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEmployeeListDialog(String title, List<Employee> employees) {
    final Color themeColor = title == 'Presentes' 
        ? const Color(0xFF4CAF50)
        : const Color(0xFFE53935);
        
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: 520,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          title == 'Presentes' 
                              ? Icons.check_circle_rounded 
                              : Icons.cancel_rounded,
                          color: themeColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3142),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${employees.length} empleados',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF2D3142)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                Flexible(
                  child: employees.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  child: Icon(
                                    title == 'Presentes' ? Icons.people : Icons.person_off,
                                    size: 36,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'No hay empleados en esta categoría',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Los empleados aparecerán aquí cuando cambien su estado',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: employees.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            thickness: 1,
                            indent: 72,
                            color: Color(0xFFEEEEEE),
                          ),
                          itemBuilder: (context, index) {
                            final employee = employees[index];
                            // Buscar la asistencia del empleado para el día seleccionado
                            final attendance = _attendances.firstWhere(
                              (a) => a.employeeId == employee.id || a.employeeId == employee.dni, 
                              orElse: () => Attendance(
                                employeeId: employee.id ?? employee.dni,
                                checkIn: DateTime.now(),
                                sede: employee.sede,
                              ),
                            );
                            
                            // Extraer las horas directamente de los campos checkInDetails y checkOutDetails
                            String checkInTime = '';
                            String checkOutTime = '-- : --';
                            
                            if (attendance.checkInDetails != null && attendance.checkInDetails!['time'] != null) {
                              checkInTime = attendance.checkInDetails!['time'] as String;
                            } else {
                              // Fallback al formato tradicional si no está el detalle
                              checkInTime = DateFormat('HH:mm').format(attendance.checkIn);
                            }
                            
                            if (attendance.checkOutDetails != null && attendance.checkOutDetails!['time'] != null) {
                              checkOutTime = attendance.checkOutDetails!['time'] as String;
                            } else if (attendance.checkOut != null) {
                              // Fallback al formato tradicional si no está el detalle
                              checkOutTime = DateFormat('HH:mm').format(attendance.checkOut!);
                            }
                            
                            return InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                _showEmployeeAttendanceDialog(employee: employee, attendance: attendance);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Avatar
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: themeColor.withOpacity(0.1),
                                      child: Text(
                                        '${employee.name[0]}${employee.lastName[0]}'.toUpperCase(),
                                        style: TextStyle(
                                          color: themeColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Información del empleado
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Nombre del empleado
                                          Text(
                                            '${employee.name} ${employee.lastName}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: Color(0xFF2D3142),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          // DNI
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              'DNI: ${employee.dni}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          // Horarios en filas separadas para prevenir sobrebordamiento
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.login,
                                                size: 14,
                                                color: Colors.green[700],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Entrada: $checkInTime',
                                                style: TextStyle(
                                                  color: Colors.green[700],
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.logout,
                                                size: 14,
                                                color: attendance.checkOut != null 
                                                    ? Colors.red[700] 
                                                    : Colors.grey[400],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Salida: $checkOutTime',
                                                style: TextStyle(
                                                  color: attendance.checkOut != null 
                                                      ? Colors.red[700] 
                                                      : Colors.grey[400],
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Badge de sede
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8F9FA),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(color: const Color(0xFFE9ECEF)),
                                      ),
                                      child: Text(
                                        employee.sede,
                                        style: const TextStyle(
                                          color: Color(0xFF495057),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (employees.isNotEmpty) ...[
                  const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2D3142),
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: const Text(
                        'Cerrar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // Nuevo método para mostrar los detalles completos de la asistencia
  void _showEmployeeAttendanceDialog({
    required Employee employee,
    required Attendance attendance,
  }) {
    // Extraer las horas directamente de los detalles
    String checkInTime = '';
    String checkOutTime = '-- : --';
    
    if (attendance.checkInDetails != null && attendance.checkInDetails!['time'] != null) {
      checkInTime = attendance.checkInDetails!['time'] as String;
    } else {
      checkInTime = DateFormat('HH:mm:ss').format(attendance.checkIn);
    }
    
    if (attendance.checkOutDetails != null && attendance.checkOutDetails!['time'] != null) {
      checkOutTime = attendance.checkOutDetails!['time'] as String;
    } else if (attendance.checkOut != null) {
      checkOutTime = DateFormat('HH:mm:ss').format(attendance.checkOut!);
    }
    
    final checkInDate = attendance.date;
    
    // Calcular horas trabajadas
    String hoursWorked = attendance.totalHoursWorked ?? 'Pendiente';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 360;
        
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxWidth: 520,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Encabezado con información del empleado
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Información del empleado
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: attendance.checkOut != null
                                  ? const Color(0xFF4CAF50).withOpacity(0.1)
                                  : const Color(0xFFFFA000).withOpacity(0.1),
                              child: Text(
                                '${employee.name[0]}${employee.lastName[0]}'.toUpperCase(),
                                style: TextStyle(
                                  color: attendance.checkOut != null
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFFFA000),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${employee.name} ${employee.lastName}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3142),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'DNI: ${employee.dni}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Color(0xFF2D3142)),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        
                        // Estado - Movido a una nueva fila para evitar sobrebordamiento
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: attendance.checkOut != null
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: attendance.checkOut != null
                                      ? const Color(0xFFC8E6C9)
                                      : const Color(0xFFFFE0B2),
                                ),
                              ),
                              child: Text(
                                attendance.status ?? (attendance.checkOut != null ? 'Completado' : 'En curso'),
                                style: TextStyle(
                                  color: attendance.checkOut != null
                                      ? const Color(0xFF388E3C)
                                      : const Color(0xFFEF6C00),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Sede y fecha
                        _buildResponsiveDetailRow(
                          'Sede:',
                          attendance.sede,
                          Icons.location_on_outlined,
                          Colors.purple,
                          isSmallScreen,
                        ),
                        const SizedBox(height: 16),
                        _buildResponsiveDetailRow(
                          'Fecha:',
                          checkInDate,
                          Icons.calendar_today_outlined,
                          Colors.blue,
                          isSmallScreen,
                        ),
                        const SizedBox(height: 16),
                        
                        // Tarjetas de entrada/salida - Ahora responsivas
                        isSmallScreen 
                            ? Column(
                                children: [
                                  _buildAttendanceDetailCard(
                                    'Hora de entrada',
                                    checkInTime,
                                    Icons.login_rounded,
                                    const Color(0xFF4CAF50),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildAttendanceDetailCard(
                                    'Hora de salida',
                                    checkOutTime,
                                    Icons.logout_rounded,
                                    attendance.checkOut != null
                                        ? const Color(0xFFE53935)
                                        : Colors.grey,
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: _buildAttendanceDetailCard(
                                      'Hora de entrada',
                                      checkInTime,
                                      Icons.login_rounded,
                                      const Color(0xFF4CAF50),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildAttendanceDetailCard(
                                      'Hora de salida',
                                      checkOutTime,
                                      Icons.logout_rounded,
                                      attendance.checkOut != null
                                          ? const Color(0xFFE53935)
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 16),
                        // Horas trabajadas
                        _buildResponsiveDetailRow(
                          'Horas trabajadas:',
                          hoursWorked,
                          Icons.timer_outlined,
                          Colors.amber[800]!,
                          isSmallScreen,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2D3142),
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: const Text(
                        'Cerrar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget responsivo para mostrar detalles de asistencia
  Widget _buildResponsiveDetailRow(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isSmallScreen,
  ) {
    return isSmallScreen 
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 36, top: 4),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          )
        : Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D3142),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
  }

  // Widget para las tarjetas de entrada/salida - optimizado para evitar desbordamientos
  Widget _buildAttendanceDetailCard(
    String label,
    String time,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            time,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color == Colors.grey ? Colors.grey[500] : Colors.grey[900],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }


  Widget _buildLocationBreakdown() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Asistencia por Sedes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Column(
              children: _sedes.map((sede) {
                // Cálculo de empleados presentes/total por sede
                int totalEnSede = _employees.where((emp) => emp.sede == sede.name).length;
                int presentesEnSede = _presentEmployeesToday.where((emp) => emp.sede == sede.name).length;
                double porcentaje = totalEnSede > 0 ? (presentesEnSede / totalEnSede) * 100 : 0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              sede.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            '$presentesEnSede/$totalEnSede',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: totalEnSede > 0 ? presentesEnSede / totalEnSede : 0,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(_getColorForPercentage(porcentaje)),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${porcentaje.toStringAsFixed(1)}% de asistencia',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Método para generar colores dinámicos según el porcentaje
  Color _getColorForPercentage(double percentage) {
    if (percentage >= 90) {
      return Colors.green;
    } else if (percentage >= 70) {
      return Colors.lightGreen;
    } else if (percentage >= 50) {
      return Colors.amber;
    } else if (percentage >= 30) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Empleados',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.location_city),
          label: 'Sedes',
        ),
      ],
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
    );
  }

  // Add these methods to your main page's state class
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const EmpleadosPage())
          );
          break;
        case 1:
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const SedesPage())
          );
          break;
      }
    });
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }
}

// Enum for Attendance View Modes
enum AttendanceViewMode {
  daily('Diario'),
  weekly('Semanal'),
  monthly('Mensual');

  final String label;
  const AttendanceViewMode(this.label);
}