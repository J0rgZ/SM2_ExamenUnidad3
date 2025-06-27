import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models.dart';

class AgregarEmpleadoPage extends StatefulWidget {
  final List<Sede> sedes;

  const AgregarEmpleadoPage({super.key, required this.sedes});

  @override
  // ignore: library_private_types_in_public_api
  _AgregarEmpleadoPageState createState() => _AgregarEmpleadoPageState();
}

class _AgregarEmpleadoPageState extends State<AgregarEmpleadoPage> {
  final CollectionReference _employeesRef =
      FirebaseFirestore.instance.collection('employees');

  final _dniController = TextEditingController();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? selectedSede;
  bool _isActive = true;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    selectedSede = widget.sedes.isNotEmpty ? widget.sedes.first.name : null;
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      Employee newEmployee = Employee(
        dni: _dniController.text,
        name: _nameController.text,
        lastName: _lastNameController.text,
        phoneNumber: _phoneController.text,
        sede: selectedSede!,
        registeredAt: Timestamp.now(),
        isActive: _isActive,
        fingerprintTemplate: null,
        faceRecognitionTemplate: null,
      );

      await _employeesRef.add(newEmployee.toJson());
      Navigator.pop(context, true);
    } catch (e) {
      _showErrorDialog('Error', 'No se pudo guardar el empleado: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Agregar Empleado',
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
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextFormField(
                        controller: _dniController,
                        labelText: 'DNI',
                        icon: LucideIcons.creditCard,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el DNI';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        controller: _nameController,
                        labelText: 'Nombre',
                        icon: LucideIcons.user,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        controller: _lastNameController,
                        labelText: 'Apellidos',
                        icon: LucideIcons.userCheck,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese los apellidos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        controller: _phoneController,
                        labelText: 'Número de Teléfono',
                        icon: LucideIcons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _buildSedeDropdown(),
                      const SizedBox(height: 16),
                      _buildActiveSwitch(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSaveButton(),
            ],
          ),
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
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.deepPurple.shade600),
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
      ),
      validator: validator,
      keyboardType: keyboardType,
    );
  }

  Widget _buildSedeDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedSede,
      decoration: InputDecoration(
        labelText: 'Sede',
        prefixIcon: Icon(LucideIcons.mapPin, color: Colors.deepPurple.shade600),
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
      ),
      items: widget.sedes.map((sede) {
        return DropdownMenuItem(
          value: sede.name,
          child: Text(sede.name),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedSede = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Por favor seleccione una sede';
        }
        return null;
      },
    );
  }

  Widget _buildActiveSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(LucideIcons.userCheck, color: Colors.deepPurple.shade600),
            const SizedBox(width: 10),
            Text(
              'Empleado Activo',
              style: TextStyle(
                fontSize: 16,
                color: Colors.deepPurple.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Switch.adaptive(
          value: _isActive,
          onChanged: (bool value) {
            setState(() {
              _isActive = value;
            });
          },
          activeColor: Colors.deepPurple.shade600,
          activeTrackColor: Colors.deepPurple.shade200,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _saveEmployee,
      icon: const Icon(LucideIcons.save, color: Colors.white),
      label: const Text(
        'Guardar Empleado',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple.shade600,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 5,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(
              color: Colors.deepPurple.shade700,
              fontWeight: FontWeight.bold,
            ),
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