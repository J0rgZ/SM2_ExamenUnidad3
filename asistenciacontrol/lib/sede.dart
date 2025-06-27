import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import 'agregar_sede.dart';
import 'editar_sede.dart';
import 'models.dart';

class SedesPage extends StatefulWidget {
  const SedesPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SedesPageState createState() => _SedesPageState();
}

class _SedesPageState extends State<SedesPage> {
  final CollectionReference _sedesRef = 
      FirebaseFirestore.instance.collection('sedes');
  final CollectionReference _empleadosRef =
      FirebaseFirestore.instance.collection('empleados');

  List<Sede> _sedes = [];
  List<Sede> _filteredSedes = [];
  Map<String, int> _empleadosPorSede = {};
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSedesYEmpleados();
  }

  Future<void> _fetchSedesYEmpleados() async {
    setState(() => _isLoading = true);
    try {
      // Obtener todas las sedes
      QuerySnapshot sedeSnapshot = await _sedesRef.get();

      // Obtener todos los empleados
      QuerySnapshot empleadosSnapshot = await _empleadosRef.get();

      // Mapeo de IDs de sede a nombres de sede para buscar coincidencias en ambos campos
      Map<String, String> sedeIdToName = {};

      // Lista de todas las sedes
      List<Sede> sedes = sedeSnapshot.docs.map((doc) {
        Sede sede = Sede.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        sedeIdToName[doc.id] = sede.name;
        return sede;
      }).toList();

      // Contar empleados por sede (intentar con ambos: ID y nombre)
      Map<String, int> empleadosPorSede = {};

      for (var doc in empleadosSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String? sedeId;

        // Intentar encontrar la sede por ID o por nombre
        if (data.containsKey('sede')) {
          String sedeValue = data['sede'];

          // Verificar si es un ID de sede directamente
          if (sedes.any((s) => s.id == sedeValue)) {
            sedeId = sedeValue;
          }
          // O si es un nombre de sede
          else if (sedes.any((s) => s.name == sedeValue)) {
            sedeId = sedes.firstWhere((s) => s.name == sedeValue).id;
          }

          if (sedeId != null) {
            empleadosPorSede[sedeId] = (empleadosPorSede[sedeId] ?? 0) + 1;
          }
        }
      }

      // Depuración: Verificar cómo se están contando los empleados por sede
      developer.log('Empleados por sede: $empleadosPorSede');
      developer.log('Total sedes: ${sedes.length}');

      setState(() {
        _sedes = sedes;
        _filteredSedes = _sedes;
        _empleadosPorSede = empleadosPorSede;
      });
    } catch (e) {
      _showSnackBar('Error al cargar datos: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }



  void _filterSedes(String query) {
    setState(() {
      _filteredSedes = _sedes.where((sede) {
        final searchLower = query.toLowerCase();
        return sede.name.toLowerCase().contains(searchLower) ||
               sede.address.toLowerCase().contains(searchLower);
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
              backgroundColor: Colors.deepPurple.shade700,
              title: const Text(
                'Gestión de Sedes',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 22,
                  letterSpacing: 0.5,
                ),
              ),
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
        body: _buildSedesContent(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const AgregarSedePage())
          );
          
          if (result == true) {
            _fetchSedesYEmpleados(); // Actualiza la lista cuando regresa de agregar sede
          }
        },
        backgroundColor: Colors.deepPurple.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Agregar Sede', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _filterSedes,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Buscar sedes...',
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.search, color: Colors.white),
        suffixIcon: _searchController.text.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                _searchController.clear();
                _filterSedes('');
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

  Widget _buildSedeCard(Sede sede) {
    // Verificar tanto por ID como por nombre completo
    final int empleadosCount = _empleadosPorSede[sede.name] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            final result = await Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (context) => EditarSedePage(sede: sede, sedeId: sede.id ?? '')
              )
            );
            
            if (result == true) {
              _fetchSedesYEmpleados();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Primera fila: Avatar y detalles principales
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSedeAvatar(sede),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sede.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, 
                                  color: Colors.grey.shade600, size: 16),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  sede.address,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildSedeActions(sede),
                  ],
                ),
                const SizedBox(height: 12),
                // Segunda fila: Etiquetas de información
                _buildInfoLabels(sede, empleadosCount),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoLabels(Sede sede, int empleadosCount) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildEmployeeCounter(empleadosCount),
        _buildChipInfo(
          icon: sede.isActive ? Icons.check_circle : Icons.cancel,
          label: sede.isActive ? 'Activa' : 'Inactiva',
          backgroundColor: sede.isActive
              ? Colors.green.shade50
              : Colors.red.shade50,
          borderColor: sede.isActive
              ? Colors.green.shade200
              : Colors.red.shade200,
          textColor: sede.isActive
              ? Colors.green.shade800
              : Colors.red.shade800,
        ),
        // Mostrar ID para debugging
        if (sede.id != null) 
          Text(
            'ID: ${sede.id}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
      ],
    );
  }



  Widget _buildEmployeeCounter(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_alt, size: 14, color: Colors.blue.shade700),
          const SizedBox(width: 4),
          Text(
            '$count empleados',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSedeAvatar(Sede sede) {
    final int hashCode = sede.name.hashCode;
    final Color avatarColor = Colors.primaries[hashCode % Colors.primaries.length];
    
    return Stack(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: avatarColor.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: avatarColor, 
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.location_on, 
              color: avatarColor,
              size: 30,
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: sede.isActive ? Colors.green : Colors.red,
                width: 2,
              ),
            ),
            child: Icon(
              sede.isActive ? Icons.check_circle : Icons.cancel,
              color: sede.isActive ? Colors.green : Colors.red,
              size: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChipInfo({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSedeActions(Sede sede) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            iconSize: 20,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            icon: const Icon(Icons.edit, color: Colors.blue),
            tooltip: 'Editar sede',
            onPressed: () async {
              final result = await Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => EditarSedePage(sede: sede, sedeId: sede.id ?? ''))
              );
              if (result == true) {
                _fetchSedesYEmpleados();
              }
            },
          ),
        ),
        const SizedBox(width: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            iconSize: 20,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Eliminar sede',
            onPressed: () => _confirmDeleteSede(sede),
          ),
        ),
      ],
    );
  }

  Widget _buildSedesContent() {
    return RefreshIndicator(
      onRefresh: _fetchSedesYEmpleados,
      color: Colors.deepPurple,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.deepPurple,
              ),
            )
          : _filteredSedes.isEmpty
              ? _buildNoResultsState()
              : _buildSedesList(),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off, 
            size: 80, 
            color: Colors.grey[400]
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'No se encontraron sedes que coincidan con tu búsqueda'
                : 'No hay sedes registradas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w300
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchController.text.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.clear),
              label: const Text('Limpiar búsqueda'),
              onPressed: () {
                _searchController.clear();
                _filterSedes('');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSedesList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _filteredSedes.length,
      itemBuilder: (context, index) {
        final sede = _filteredSedes[index];
        return _buildSedeCard(sede);
      },
    );
  }

  Future<void> _confirmDeleteSede(Sede sede) async {
    // Verificar si la sede tiene empleados asignados
    final tieneEmpleados = await _checkSedeHasEmpleados(sede.id ?? '');
    
    if (tieneEmpleados) {
      _showSnackBar(
        'No se puede eliminar la sede porque tiene empleados asignados', 
        isError: true,
        duration: const Duration(seconds: 3)
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.amber),
              const SizedBox(width: 8),
              Text('Confirmar eliminación', style: TextStyle(color: Colors.red[700])),
            ],
          ),
          content: SingleChildScrollView(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                children: [
                  const TextSpan(text: '¿Estás seguro que deseas eliminar la sede '),
                  TextSpan(
                    text: sede.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteSede(sede);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _checkSedeHasEmpleados(String sedeId) async {
    try {
      // Verificando empleados para sede ID
      print("Verificando empleados para sede ID: $sedeId");

      final QuerySnapshot empleadosSnapshot = await _empleadosRef.get();
      print("Total empleados en la base de datos: ${empleadosSnapshot.docs.length}");
      
      empleadosSnapshot.docs.forEach((doc) {
        print("Empleado: ${doc.data()}");  // Muestra todos los datos del empleado
      });

      // Consulta por ID de sede
      final QuerySnapshot empleadosPorIdSnapshot = await _empleadosRef
          .where('sede', isEqualTo: sedeId)
          .limit(1)
          .get();

      print("Empleados encontrados por ID: ${empleadosPorIdSnapshot.docs.length}");

      if (empleadosPorIdSnapshot.docs.isNotEmpty) {
        return true;
      }

      // Si no se encontró, buscar por nombre de sede
      final sede = _sedes.firstWhere((s) => s.id == sedeId, orElse: () => Sede(
        name: '', 
        address: '', 
        latitude: 0, 
        longitude: 0
      ));

      if (sede.name.isNotEmpty) {
        print("Verificando empleados para sede nombre: ${sede.name}");
        final QuerySnapshot empleadosPorNombreSnapshot = await _empleadosRef
            .where('sede', isEqualTo: sede.name)
            .limit(1)
            .get();

        print("Empleados encontrados por nombre: ${empleadosPorNombreSnapshot.docs.length}");

        return empleadosPorNombreSnapshot.docs.isNotEmpty;
      }

      return false;
    } catch (e) {
      _showSnackBar('Error al verificar empleados: $e', isError: true);
      return false;
    }
  }

  Future<void> _deleteSede(Sede sede) async {
    try {
      await _sedesRef.doc(sede.id).delete();
      _showSnackBar('Sede eliminada correctamente');
      await _fetchSedesYEmpleados();
    } catch (e) {
      _showSnackBar('Error al eliminar la sede: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false, Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        duration: duration ?? const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(8),
      ),
    );
  }
}