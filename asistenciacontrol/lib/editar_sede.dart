import 'package:asistenciacontrol/selecionar_ubicacion.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models.dart';

class EditarSedePage extends StatefulWidget {
  final String sedeId;
  final Sede sede;
  
  const EditarSedePage({
    super.key, 
    required this.sedeId, 
    required this.sede,
  });

  @override
  // ignore: library_private_types_in_public_api
  _EditarSedePageState createState() => _EditarSedePageState();
}

class _EditarSedePageState extends State<EditarSedePage> with SingleTickerProviderStateMixin {
  final CollectionReference _sedesRef = FirebaseFirestore.instance.collection('sedes');
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  // Estado expandido/colapsado del mapa
  bool _isMapExpanded = false;
  late AnimationController _animationController;
  
  bool _isActive = true;
  bool _isLoading = false;
  bool _mapInitialized = false;
  bool _dataLoaded = false;
  
  // Variables para manejar el mapa
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(4.6097, -74.0817); // Coordenadas por defecto
  Set<Marker> _markers = {};
  BitmapDescriptor? _customMarkerIcon;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _createCustomMarker();
    _loadSedeData();
  }
    
  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
  
  Future<void> _loadSedeData() async {
    setState(() => _isLoading = true);
    
    try {
      // Inicializar controladores con datos existentes
      _nameController.text = widget.sede.name;
      _addressController.text = widget.sede.address;
      _isActive = widget.sede.isActive;
      
      // Configurar la ubicación inicial
      _selectedLocation = LatLng(widget.sede.latitude, widget.sede.longitude);
      
      // Inicializar el mapa con los datos cargados
      await _initMapWithLocation();
      
      setState(() {
        _dataLoaded = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error al cargar datos de la sede', isError: true);
    }
  }
  
  Future<void> _createCustomMarker() async {
    // ignore: deprecated_member_use
    _customMarkerIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/location_pin.png',
    );
  }

  Future<void> _initMapWithLocation() async {
    setState(() => _mapInitialized = false);

    try {
      setState(() {
        _mapInitialized = true;
        // Actualizar marcador con la ubicación cargada
        _updateMarker();
      });
    } catch (e) {
      setState(() {
        _mapInitialized = true;
      });
      _showSnackBar('No se pudo inicializar el mapa', isError: true);
    }
  }
  
  void _toggleMapExpansion() {
    setState(() {
      _isMapExpanded = !_isMapExpanded;
      if (_isMapExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _updateMarker() {
    if (_customMarkerIcon == null) return;
    
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('sede_location'),
          position: _selectedLocation,
          draggable: true,
          icon: _customMarkerIcon!,
          infoWindow: const InfoWindow(
            title: 'Ubicación de la sede',
            snippet: 'Arrastra para ajustar',
          ),
          onDragEnd: (LatLng newPosition) {
            setState(() {
              _selectedLocation = newPosition;
              _updateAddress();
            });
          },
        ),
      };
    });
  }

  Future<void> _updateAddress() async {
    String address = await MapUtils.getAddressFromLatLng(_selectedLocation);
    setState(() => _addressController.text = address);
  }

  void _openFullScreenMap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => MapLocationPicker(
          initialLocation: _selectedLocation,
          customMarkerIcon: _customMarkerIcon,
          onLocationSelected: (LatLng location, String address) {
            setState(() {
              _selectedLocation = location;
              _addressController.text = address;
              _updateMarker();
            });
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _updateSede() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Actualizar los datos de la sede
      await _sedesRef.doc(widget.sedeId).update({
        'name': _nameController.text,
        'address': _addressController.text,
        'latitude': _selectedLocation.latitude,
        'longitude': _selectedLocation.longitude,
        'isActive': _isActive,
        'updatedAt': DateTime.now(),
      });
      
      _showSnackBar('¡Sede actualizada correctamente!');
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Error', 'No se pudo actualizar la sede: $e');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Editar Sede',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.deepPurple.shade600,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          !_dataLoaded
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                margin: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información de la sede
                    _buildInfoCard(),
                    const SizedBox(height: 20),
                    
                    // Tarjeta de mapa
                    _buildMapCard(),
                    const SizedBox(height: 20),
                    
                    // Estatus de la sede
                    _buildStatusCard(),
                    const SizedBox(height: 20),
                    
                    // Botón guardar
                    _buildUpdateButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          
          // Overlay de carga
          if (_isLoading)
            Container(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      shadowColor: Colors.grey.shade300,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Información de la Sede',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.deepPurple.shade700,
                ),
              ),
              Divider(color: Colors.grey.shade200, thickness: 1.5),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _nameController,
                labelText: 'Nombre de Sede',
                icon: LucideIcons.building,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre de la sede';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _addressController,
                labelText: 'Dirección',
                icon: LucideIcons.mapPin,
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor seleccione una ubicación en el mapa';
                  }
                  return null;
                },
                onTap: _toggleMapExpansion,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      shadowColor: Colors.grey.shade300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado del mapa
          ListTile(
            title: Text(
              'Ubicación de la Sede',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.deepPurple.shade700,
              ),
            ),
            subtitle: const Text(
              'Ubicación actual de la sede',
              style: TextStyle(fontSize: 13),
            ),
            trailing: IconButton(
              icon: Icon(LucideIcons.maximize2, color: Colors.deepPurple.shade600),
              onPressed: _openFullScreenMap,
              tooltip: 'Pantalla completa',
            ),
          ),
          
          // Vista miniatura del mapa (siempre visible)
          Container(
            height: 180, // Altura fija para el mapa en miniatura
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: _isLoading || !_mapInitialized
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.deepPurple.shade600),
                        const SizedBox(height: 16),
                        const Text('Cargando mapa...'),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _selectedLocation,
                          zoom: 15,
                        ),
                        markers: _markers,
                        myLocationEnabled: false,
                        myLocationButtonEnabled: false,
                        mapToolbarEnabled: false,
                        zoomControlsEnabled: false,
                        compassEnabled: false,
                        scrollGesturesEnabled: false,
                        zoomGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        tiltGesturesEnabled: false, 
                        onMapCreated: (GoogleMapController controller) {
                          if (_mapController == null) {
                            _mapController = controller;
                            // ignore: deprecated_member_use
                            _mapController?.setMapStyle(MapUtils.mapStyle);
                          }
                        },
                        onTap: (_) => _openFullScreenMap(), // Abre el mapa completo al tocar
                      ),
                      
                      // Instrucción visual en miniatura
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            // ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.eye,
                                size: 12, 
                                color: Colors.deepPurple
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Vista previa',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
            ),
          ),
          
          // Información de la dirección
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.deepPurple.shade200, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.mapPin, size: 18, color: Colors.deepPurple.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _addressController.text,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Información de coordenadas
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.deepPurple.shade200, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.compass, size: 18, color: Colors.deepPurple.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(LucideIcons.globe, size: 18, color: Colors.deepPurple.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Lon: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      shadowColor: Colors.grey.shade300,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado de la Sede',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.deepPurple.shade700,
              ),
            ),
            Divider(color: Colors.grey.shade200, thickness: 1.5),
            const SizedBox(height: 8),
            SwitchListTile(
              title: Text(
                'Sede Activa',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.deepPurple.shade800,
                ),
              ),
              subtitle: Text(
                _isActive 
                    ? 'La sede está en funcionamiento' 
                    : 'La sede está desactivada',
                style: TextStyle(
                  fontSize: 14,
                  color: _isActive ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
              activeColor: Colors.deepPurple.shade600,
              activeTrackColor: Colors.deepPurple.shade200,
              inactiveThumbColor: Colors.grey.shade400,
              inactiveTrackColor: Colors.grey.shade300,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              secondary: Icon(
                _isActive ? LucideIcons.check : LucideIcons.x,
                color: _isActive ? Colors.green.shade600 : Colors.red.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        hintText: readOnly ? 'Toca para cambiar ubicación' : null,
        prefixIcon: Icon(icon, color: Colors.deepPurple.shade600),
        suffixIcon: readOnly 
            ? Icon(LucideIcons.mapPin, color: Colors.deepPurple.shade600)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.deepPurple.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.deepPurple.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.deepPurple.shade600, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
    );
  }

  Widget _buildUpdateButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _updateSede,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple.shade600,
        disabledBackgroundColor: Colors.deepPurple.shade300,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 5,
        shadowColor: Colors.deepPurple.shade200,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: _isLoading 
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Actualizando...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.save, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Actualizar Sede',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                LucideIcons.alertTriangle,
                color: Colors.deepPurple.shade700,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: Colors.deepPurple.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Aceptar',
                style: TextStyle(
                  color: Colors.deepPurple.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}