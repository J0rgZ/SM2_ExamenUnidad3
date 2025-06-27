import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';
import 'agregar_empleado.dart';
import 'captura_biometrica_page.dart';
import 'editar_empleado.dart';

class EmpleadosPage extends StatefulWidget {
  const EmpleadosPage({super.key});

  @override
  _EmpleadosPageState createState() => _EmpleadosPageState();
}

class _EmpleadosPageState extends State<EmpleadosPage> {
  final CollectionReference _employeesRef = 
      FirebaseFirestore.instance.collection('employees');
  final CollectionReference _sedesRef = 
      FirebaseFirestore.instance.collection('sedes');

  List<Employee> _employees = [];
  List<Sede> _sedes = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<Employee> _filteredEmployees = [];
  
  // New filter state
  String _currentFilter = 'Todos';

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
    } catch (e) {
      _showErrorDialog('Error de Carga', 'No se pudieron cargar los datos: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _filteredEmployees = _employees;
      });
    }
  }

  Future<void> _fetchEmployees() async {
    QuerySnapshot snapshot = await _employeesRef.get();
    setState(() {
      _employees = snapshot.docs.map((doc) {
        return Employee.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      _filteredEmployees = _employees;
    });
  }

  Future<void> _fetchSedes() async {
    QuerySnapshot snapshot = await _sedesRef.get();
    setState(() {
      _sedes = snapshot.docs.map((doc) {
        return Sede.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  void _filterEmployees(String query) {
    setState(() {
      _filteredEmployees = _employees.where((employee) {
        final searchLower = query.toLowerCase();
        final matchesSearch = employee.name.toLowerCase().contains(searchLower) ||
               employee.lastName.toLowerCase().contains(searchLower) ||
               employee.dni.toLowerCase().contains(searchLower);
        
        // Apply additional filtering based on current filter
        final matchesFilter = _currentFilter == 'Todos' || 
          (_currentFilter == 'Activos' && employee.isActive) ||
          (_currentFilter == 'Inactivos' && !employee.isActive) ||
          (_currentFilter == 'Sin Biométricos' && 
            (employee.fingerprintTemplate == null || 
             employee.faceRecognitionTemplate == null));
        
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              pinned: true,
              floating: true,
              snap: true,
              elevation: 4,
              backgroundColor: Colors.deepPurple.shade600,
              title: Text(
                'Gestión de Empleados',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 22,
                  letterSpacing: 0.5,
                ),
              ),
              actions: [
                _buildFilterChip(),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(80),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: _buildSearchField(),
                ),
              ),
            ),
          ];
        },
        body: _buildEmployeeContent(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEmployee(context),
        backgroundColor: Colors.deepPurple.shade600,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Agregar Empleado', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _filterEmployees,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Buscar empleados...',
        hintStyle: TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.search, color: Colors.white),
        suffixIcon: _searchController.text.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                _searchController.clear();
                _filterEmployees('');
              },
            )
          : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilterChip() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_list, color: Colors.white),
      tooltip: 'Filtrar',
      onSelected: (String value) {
        setState(() {
          _currentFilter = value;
          _filterEmployees(_searchController.text);
        });
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'Todos',
          child: Row(
            children: [
              Icon(Icons.people, color: Colors.deepPurple),
              const SizedBox(width: 10),
              const Text('Todos los Empleados'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'Activos',
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 10),
              const Text('Empleados Activos'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'Inactivos',
          child: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red),
              const SizedBox(width: 10),
              const Text('Empleados Inactivos'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'Sin Biométricos',
          child: Row(
            children: [
              Icon(Icons.fingerprint, color: Colors.orange),
              const SizedBox(width: 10),
              const Text('Sin Biométricos'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateToEditEmployee(context, employee),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildEmployeeAvatar(employee),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildEmployeeDetails(employee),
                ),
                _buildEmployeeActions(employee),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeAvatar(Employee employee) {
    return CircleAvatar(
      radius: 35,
      backgroundColor: employee.isActive 
        ? Colors.deepPurple.shade200 
        : Colors.grey.shade400,
      child: Text(
        '${employee.name[0]}${employee.lastName[0]}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmployeeDetails(Employee employee) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          employee.fullName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: employee.isActive ? Colors.deepPurple.shade700 : Colors.grey.shade700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        _buildDetailText('DNI: ${employee.dni}'),
        _buildDetailText('Sede: ${employee.sede}'),
        const SizedBox(height: 6),
        _buildStatusIndicator(employee),
        if (employee.fingerprintTemplate == null || employee.faceRecognitionTemplate == null)
          _buildBiometricWarning(),
      ],
    );
  }

  Widget _buildDetailText(String text) {
    return Text(
      text, 
      style: TextStyle(
        fontSize: 14, 
        color: Colors.grey.shade600,
        overflow: TextOverflow.ellipsis,
      ),
      maxLines: 1,
    );
  }

  Widget _buildStatusIndicator(Employee employee) {
    return Row(
      children: [
        Icon(
          employee.isActive ? Icons.check_circle : Icons.cancel,
          color: employee.isActive ? Colors.green : Colors.red,
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          employee.isActive ? 'Activo' : 'Inactivo',
          style: TextStyle(
            fontSize: 14, 
            fontWeight: FontWeight.w600,
            color: employee.isActive ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildBiometricWarning() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        'Biométricos: Incompletos',
        style: TextStyle(
          color: Colors.orange.shade700, 
          fontSize: 14, 
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmployeeActions(Employee employee) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (employee.fingerprintTemplate == null || employee.faceRecognitionTemplate == null)
          IconButton(
            icon: const Icon(Icons.fingerprint, color: Colors.green, size: 28),
            onPressed: () => _navigateToBiometricCapture(employee),
          ),
        IconButton(
          icon: Icon(
            employee.isActive ? Icons.toggle_on : Icons.toggle_off,
            color: employee.isActive ? Colors.green : Colors.grey,
            size: 36,
          ),
          onPressed: () => _toggleEmployeeStatus(employee),
        ),
      ],
    );
  }

  Widget _buildEmployeeContent() {
    return RefreshIndicator(
      onRefresh: _fetchInitialData,
      color: Colors.deepPurple,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.deepPurple,
              ),
            )
          : _filteredEmployees.isEmpty
              ? _buildNoResultsState()
              : _buildEmployeeList(),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off, 
            size: 100, 
            color: Colors.grey[400]
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron empleados',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w300
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _filteredEmployees.length,
      itemBuilder: (context, index) {
        final employee = _filteredEmployees[index];
        return _buildEmployeeCard(employee);
      },
    );
  }

  Future<void> _toggleEmployeeStatus(Employee employee) async {
    try {
      await _employeesRef.doc(employee.id).update({
        'isActive': !employee.isActive,
      });
      await _fetchEmployees();
    } catch (e) {
      _showErrorDialog('Error', 'No se pudo cambiar el estado del empleado: $e');
    }
  }

  void _navigateToBiometricCapture(Employee employee) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CapturaBiometricaPage(employee: employee),
      ),
    );

    if (result == true) {
      await _fetchEmployees();
    }
  }

  void _navigateToAddEmployee(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgregarEmpleadoPage(sedes: _sedes),
      ),
    );

    if (result == true) {
      await _fetchEmployees();
      _searchController.clear();
    }
  }

  void _navigateToEditEmployee(BuildContext context, Employee employee) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarEmpleadoPage(
          employee: employee, 
          sedes: _sedes
        ),
      ),
    );

    if (result == true) {
      await _fetchEmployees();
      _searchController.clear();
    }
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