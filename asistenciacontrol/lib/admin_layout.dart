// admin_layout.dart
import 'package:flutter/material.dart';

class AdminLayout extends StatelessWidget {
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final int currentIndex;
  final bool isLoading;

  const AdminLayout({
    Key? key,
    required this.body,
    required this.title,
    this.actions,
    required this.currentIndex,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 2,
      backgroundColor: Theme.of(context).primaryColor,
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: false,
      actions: [
        ...(actions ?? []),
      ],
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Cargando datos...',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      color: Colors.grey[50],
      child: body,
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey[600],
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 11),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_alt_rounded),
          label: 'Empleados',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.location_on_rounded),
          label: 'Sedes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assessment_rounded),
          label: 'Reportes',
        ),
      ],
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;
    
    // Navegar a la página seleccionada sin acumular páginas en el stack
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context, 
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const DashboardPage(),
            transitionsBuilder: _createTransition,
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context, 
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const EmpleadosPage(),
            transitionsBuilder: _createTransition,
          ),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context, 
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const SedesPage(),
            transitionsBuilder: _createTransition,
          ),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context, 
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const ReportesPage(),
            transitionsBuilder: _createTransition,
          ),
        );
        break;
    }
  }

  // Transición suave entre pantallas
  Widget _createTransition(context, animation, secondaryAnimation, child) {
    const begin = Offset(0.0, 0.05);
    const end = Offset.zero;
    const curve = Curves.easeOut;
    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    var offsetAnimation = animation.drive(tween);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: offsetAnimation,
        child: child,
      ),
    );
  }
}

// Ejemplo de implementación del Dashboard
class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  // Tus variables de estado aquí

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    // Simular carga de datos
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Panel de Control',
      currentIndex: 0,
      isLoading: _isLoading,
      body: _buildDashboardContent(),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummarySection(),
            const SizedBox(height: 24),
            _buildAttendanceSection(),
            const SizedBox(height: 24),
            _buildRecentActivitySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            'Resumen General',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E4053),
            ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              title: 'Total Empleados',
              value: '124',
              icon: Icons.people_alt_rounded,
              color: Colors.blue,
              subtitle: 'Activos',
            ),
            _buildStatCard(
              title: 'Asistencia Hoy',
              value: '87%',
              icon: Icons.how_to_reg_rounded,
              color: Colors.green,
              subtitle: '108 presentes',
            ),
            _buildStatCard(
              title: 'Sedes',
              value: '12',
              icon: Icons.location_on_rounded,
              color: Colors.orange,
              subtitle: 'En operación',
            ),
            _buildStatCard(
              title: 'Ausencias',
              value: '16',
              icon: Icons.person_off_rounded,
              color: Colors.red.shade700,
              subtitle: 'Hoy',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            'Asistencia Diaria',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E4053),
            ),
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: const Center(
              child: Text(
                'Gráfico de asistencia (implementar según necesidades)',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            'Actividad Reciente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E4053),
            ),
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.2),
                  child: const Icon(Icons.person, color: Colors.blue),
                ),
                title: const Text(
                  'Juan Pérez registró entrada',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Hace 30 minutos - Sede Central',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Simplemente definimos los encabezados de las otras páginas para completar
class EmpleadosPage extends StatefulWidget {
  const EmpleadosPage({Key? key}) : super(key: key);

  @override
  _EmpleadosPageState createState() => _EmpleadosPageState();
}

class _EmpleadosPageState extends State<EmpleadosPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Carga de datos
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Gestión de Empleados',
      currentIndex: 1,
      isLoading: _isLoading,
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            // Acción para añadir empleado
          },
        ),
      ],
      body: const Center(child: Text('Contenido de Empleados')),
    );
  }
}

class SedesPage extends StatefulWidget {
  const SedesPage({Key? key}) : super(key: key);

  @override
  _SedesPageState createState() => _SedesPageState();
}

class _SedesPageState extends State<SedesPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Carga de datos
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Gestión de Sedes',
      currentIndex: 2,
      isLoading: _isLoading,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_location),
          onPressed: () {
            // Acción para añadir sede
          },
        ),
      ],
      body: const Center(child: Text('Contenido de Sedes')),
    );
  }
}

class ReportesPage extends StatefulWidget {
  const ReportesPage({Key? key}) : super(key: key);

  @override
  _ReportesPageState createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Carga de datos
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Reportes y Análisis',
      currentIndex: 3,
      isLoading: _isLoading,
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () {
            // Acción para filtrar reportes
          },
        ),
      ],
      body: const Center(child: Text('Contenido de Reportes')),
    );
  }
}