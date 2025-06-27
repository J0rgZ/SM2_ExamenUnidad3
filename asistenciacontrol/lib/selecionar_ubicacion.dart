import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:async';

class MapUtils {
  // Estilo personalizado para el mapa
  static const String mapStyle = '''
  [
    {
      "featureType": "poi",
      "elementType": "labels",
      "stylers": [
        { "visibility": "off" }
      ]
    },
    {
      "featureType": "transit",
      "elementType": "labels",
      "stylers": [
        { "visibility": "off" }
      ]
    }
  ]
  ''';

  // Obtener dirección desde coordenadas
  static Future<String> getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );
      
      if (placemarks.isEmpty) return 'Dirección desconocida';
        
      Placemark place = placemarks.first;
      return [
        if (place.thoroughfare?.isNotEmpty == true) place.thoroughfare,
        if (place.subThoroughfare?.isNotEmpty == true) place.subThoroughfare,
        if (place.locality?.isNotEmpty == true) place.locality,
        if (place.administrativeArea?.isNotEmpty == true) place.administrativeArea,
      ].where((element) => element != null).join(', ');
    } catch (e) {
      return 'Error al obtener dirección';
    }
  }

  // Verificar y solicitar permisos de ubicación
  static Future<bool> checkLocationPermission(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si los servicios de ubicación están habilitados
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar(
        context, 
        'Los servicios de ubicación están desactivados',
        color: Colors.orange.shade700,
        action: SnackBarAction(
          label: 'Ajustes',
          onPressed: () => Geolocator.openLocationSettings(),
        ),
      );
      return false;
    }

    // Verificar permisos de ubicación
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar(
          context, 
          'Los permisos de ubicación están denegados',
          color: Colors.red.shade700,
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar(
        context, 
        'Los permisos de ubicación están permanentemente denegados',
        color: Colors.red.shade700,
        action: SnackBarAction(
          label: 'Ajustes',
          onPressed: () => Geolocator.openAppSettings(),
        ),
      );
      return false;
    }

    return true;
  }

  // Obtener la ubicación actual del usuario
  static Future<LatLng?> getCurrentLocation(BuildContext context) async {
    try {
      if (!await checkLocationPermission(context)) {
        return null;
      }
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      _showSnackBar(
        context, 
        'Error al obtener la ubicación actual: ${e.toString()}',
        color: Colors.red.shade700,
      );
      return null;
    }
  }
  
  // Método auxiliar para mostrar SnackBars
  static void _showSnackBar(
    BuildContext context, 
    String message, {
    Color? color, 
    SnackBarAction? action
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        action: action,
      ),
    );
  }
}

class MapLocationPicker extends StatefulWidget {
  final Function(LatLng, String) onLocationSelected;
  final BitmapDescriptor? customMarkerIcon;
  final String? title;
  final String? confirmButtonText;
  final LatLng? initialLocation; // Ahora es opcional

  const MapLocationPicker({
    Key? key,
    required this.onLocationSelected,
    this.customMarkerIcon,
    this.title = 'Seleccionar Ubicación',
    this.confirmButtonText = 'Confirmar Ubicación',
    this.initialLocation, // Ya no es required
  }) : super(key: key);

  @override
  _MapLocationPickerState createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  // Ubicación predeterminada (se actualizará con la ubicación del dispositivo)
  LatLng _selectedLocation = const LatLng(0, 0);
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  String _address = 'Obteniendo dirección...';
  bool _isLoading = true; // Comienza cargando para obtener ubicación
  bool _isMapReady = false;
  double _currentZoom = 15.0;
  
  // Variables para la búsqueda
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _isSearching = false;
  List<String> _searchHistory = [];
  List<String> _searchSuggestions = [];
  bool _showSearchHistory = false;
  Timer? _debounceTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController?.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Inicializar la ubicación (prioriza ubicación del dispositivo)
  Future<void> _initializeLocation() async {
    // Si se proporcionó una ubicación inicial, úsala primero
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation!;
      _updateMarker();
    }
    
    // Intenta obtener la ubicación actual del dispositivo
    await _getCurrentLocation();
  }

  // Obtener la ubicación actual del dispositivo
  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    
    try {
      LatLng? currentLocation = await MapUtils.getCurrentLocation(context);
      
      if (currentLocation != null && mounted) {
        setState(() {
          _selectedLocation = currentLocation;
          _updateMarker();
        });
        
        // Obtener la dirección de la ubicación
        _getAddressFromLatLng();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Actualizar el marcador en el mapa
  void _updateMarker() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation,
          draggable: true,
          icon: widget.customMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          onDragStart: (_) {
            setState(() => _address = 'Arrastrando marcador...');
          },
          onDragEnd: (LatLng newPosition) {
            setState(() {
              _selectedLocation = newPosition;
              _getAddressFromLatLng();
            });
          },
          infoWindow: const InfoWindow(
            title: 'Ubicación seleccionada',
            snippet: 'Arrastra para ajustar',
          ),
        ),
      };
    });
  }

  // Obtener la dirección a partir de coordenadas
  Future<void> _getAddressFromLatLng() async {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 800), () async {
      if (!mounted) return;
      
      setState(() => _isLoading = true);
      
      try {
        String address = await MapUtils.getAddressFromLatLng(_selectedLocation);
        if (mounted) {
          setState(() {
            _address = address;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _address = 'No se pudo obtener la dirección';
          });
        }
      }
    });
  }
  
  // Búsqueda de ubicación por dirección
  void _searchLocation() async {
    if (_searchController.text.isEmpty) return;
    
    FocusScope.of(context).unfocus();
    
    setState(() {
      _isLoading = true;
      _isSearching = true;
      _showSearchHistory = false;
    });
    
    try {
      List<Location> locations = await locationFromAddress(_searchController.text);
      
      if (!mounted) return;
      
      if (locations.isNotEmpty) {
        Location location = locations.first;
        LatLng newLocation = LatLng(location.latitude, location.longitude);
        
        // Actualizar historial
        if (!_searchHistory.contains(_searchController.text) && 
            _searchController.text.trim().isNotEmpty) {
          setState(() {
            _searchHistory.insert(0, _searchController.text);
            if (_searchHistory.length > 5) {
              _searchHistory.removeLast();
            }
          });
        }
        
        setState(() {
          _selectedLocation = newLocation;
          _updateMarker();
          _currentZoom = 16.0;
        });
        
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: newLocation,
              zoom: _currentZoom,
              tilt: 0,
              bearing: 0,
            ),
          ),
        );
        
        _getAddressFromLatLng();
      } else {
        MapUtils._showSnackBar(
          context, 
          'No se encontró la dirección. Intenta ser más específico.',
          color: Colors.amber.shade700,
          action: SnackBarAction(
            label: 'Entendido',
            textColor: Colors.white,
            onPressed: () {},
          ),
        );
        setState(() => _address = 'Dirección no encontrada');
      }
    } catch (e) {
      if (!mounted) return;
      
      MapUtils._showSnackBar(
        context, 
        'Error al buscar dirección. Verifica tu conexión a internet.',
        color: Colors.red.shade700,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSearching = false;
        });
      }
    }
  }
  
  // Actualizar sugerencias de búsqueda
  void _updateSearchSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchSuggestions = [];
        _showSearchHistory = true;
      });
      return;
    }
    
    List<String> filtered = _searchHistory
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();
    
    setState(() {
      _searchSuggestions = filtered;
      _showSearchHistory = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.deepPurple.shade600;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title!,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Volver',
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.check, color: Colors.white),
            onPressed: () => widget.onLocationSelected(_selectedLocation, _address),
            tooltip: 'Confirmar ubicación',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa a pantalla completa
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: _currentZoom,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _mapController?.setMapStyle(MapUtils.mapStyle);
              setState(() {
                _isMapReady = true;
              });
            },
            onTap: (LatLng position) {
              FocusScope.of(context).unfocus();
              setState(() {
                _showSearchHistory = false;
                _selectedLocation = position;
                _updateMarker();
                _getAddressFromLatLng();
              });
            },
            onCameraMove: (CameraPosition position) {
              _currentZoom = position.zoom;
            },
          ),
          
          // Panel de búsqueda deslizable
          DraggableScrollableSheet(
            initialChildSize: 0.2,
            minChildSize: 0.1,
            maxChildSize: 0.5,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Indicador de arrastre
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    
                    // Campo de búsqueda
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Buscar dirección...',
                              prefixIcon: Icon(LucideIcons.search, color: Colors.grey.shade600),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(LucideIcons.x, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchSuggestions = [];
                                          _showSearchHistory = true;
                                        });
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onChanged: (value) => _updateSearchSuggestions(value),
                            onTap: () {
                              setState(() {
                                _showSearchHistory = true;
                              });
                            },
                            onFieldSubmitted: (_) => _searchLocation(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _searchLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(56, 56),
                          ),
                          child: _isSearching
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(LucideIcons.search, color: Colors.white),
                        ),
                      ],
                    ),
                    
                    // Sugerencias de búsqueda
                    if ((_searchSuggestions.isNotEmpty || (_showSearchHistory && _searchHistory.isNotEmpty)) && 
                        _searchFocusNode.hasFocus)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_showSearchHistory && _searchHistory.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Búsquedas recientes',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              
                            ..._showSearchHistory
                                ? _searchHistory.map(_buildSuggestionItem)
                                : _searchSuggestions.map(_buildSuggestionItem),
                          ],
                        ),
                      ),
                    
                    // Dirección seleccionada
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 20, color: primaryColor),
                          const SizedBox(width: 12),
                          _isLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryColor,
                                ),
                              )
                            : Expanded(
                                child: Text(
                                  _address,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(LucideIcons.copy, color: Colors.grey.shade600),
                            onPressed: () {
                              // Implementar el copiado al portapapeles
                              MapUtils._showSnackBar(
                                context, 
                                'Coordenadas copiadas al portapapeles',
                                color: Colors.green.shade700,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Coordenadas
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(LucideIcons.compass, size: 16, color: primaryColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(LucideIcons.globe, size: 16, color: primaryColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Lon: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Controles del mapa
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.25,
            child: Column(
              children: [
                // Botón Mi Ubicación
                _buildMapControlButton(
                  icon: LucideIcons.crosshair,
                  onPressed: _getCurrentLocation,
                  tooltip: 'Mi ubicación',
                ),
                const SizedBox(height: 16),
                
                // Botón Zoom In
                _buildMapControlButton(
                  icon: LucideIcons.plus,
                  onPressed: () {
                    _mapController?.animateCamera(CameraUpdate.zoomIn());
                  },
                  tooltip: 'Acercar',
                ),
                const SizedBox(height: 16),
                
                // Botón Zoom Out
                _buildMapControlButton(
                  icon: LucideIcons.minus,
                  onPressed: () {
                    _mapController?.animateCamera(CameraUpdate.zoomOut());
                  },
                  tooltip: 'Alejar',
                ),
              ],
            ),
          ),
          
          // Indicador de carga
          if (_isLoading && !_isMapReady)
            Container(
              color: Colors.white.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'Cargando mapa...',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Método para construir botones de control del mapa
  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: Colors.deepPurple.shade600,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
  
  // Método para construir items de sugerencia
  Widget _buildSuggestionItem(String suggestion) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _searchController.text = suggestion;
            _showSearchHistory = false;
            _searchSuggestions = [];
          });
          _searchLocation();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                LucideIcons.history,
                size: 18,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  suggestion,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  LucideIcons.arrowUpRight,
                  size: 18,
                  color: Colors.grey.shade700,
                ),
                onPressed: () {
                  setState(() {
                    _searchController.text = suggestion;
                    _showSearchHistory = false;
                    _searchSuggestions = [];
                  });
                  _searchLocation();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}