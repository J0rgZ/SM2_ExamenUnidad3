import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models.dart';

class EditarEmpleadoPage extends StatefulWidget {
  final Employee employee;
  final List<Sede> sedes;

  const EditarEmpleadoPage({
    super.key, 
    required this.employee, 
    required this.sedes
  });

  @override
  _EditarEmpleadoPageState createState() => _EditarEmpleadoPageState();
}

class _EditarEmpleadoPageState extends State<EditarEmpleadoPage> {
  final CollectionReference _employeesRef =
      FirebaseFirestore.instance.collection('employees');

  late TextEditingController _dniController;
  late TextEditingController _nameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late String? selectedSede;
  late bool _isActive;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing employee data
    _dniController = TextEditingController(text: widget.employee.dni);
    _nameController = TextEditingController(text: widget.employee.name);
    _lastNameController = TextEditingController(text: widget.employee.lastName);
    _phoneController = TextEditingController(text: widget.employee.phoneNumber);
    selectedSede = widget.employee.sede;
    _isActive = widget.employee.isActive;
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _dniController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Create an updated employee object
      Employee updatedEmployee = Employee(
        id: widget.employee.id,
        dni: _dniController.text,
        name: _nameController.text,
        lastName: _lastNameController.text,
        phoneNumber: _phoneController.text,
        sede: selectedSede!,
        registeredAt: widget.employee.registeredAt,
        isActive: _isActive,
        fingerprintTemplate: widget.employee.fingerprintTemplate,
        faceRecognitionTemplate: widget.employee.faceRecognitionTemplate,
      );

      // Update the employee in Firestore
      await _employeesRef.doc(widget.employee.id).update(updatedEmployee.toJson());
      
      // Navigate back with success
      Navigator.pop(context, true);
    } catch (e) {
      _showErrorDialog('Error', 'No se pudo actualizar el empleado: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Editar Empleado',
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
          icon: Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.trash2, color: Colors.white),
            onPressed: _confirmDeleteEmployee,
            tooltip: 'Eliminar Empleado',
          ),
        ],
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
                      if (widget.employee.registeredAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _buildRegistrationInfo(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildUpdateButton(),
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

  Widget _buildRegistrationInfo() {
    return Row(
      children: [
        Icon(LucideIcons.calendarDays, color: Colors.deepPurple.shade600, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Registrado el: ${_formatRegistrationDate()}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.deepPurple.shade700,
            ),
          ),
        ),
      ],
    );
  }

  String _formatRegistrationDate() {
    if (widget.employee.registeredAt == null) return 'Fecha no disponible';
    
    final date = widget.employee.registeredAt!.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildUpdateButton() {
    return ElevatedButton.icon(
      onPressed: _updateEmployee,
      icon: Icon(LucideIcons.save, color: Colors.white),
      label: Text(
        'Actualizar Empleado',
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

  void _confirmDeleteEmployee() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Eliminar Empleado',
            style: TextStyle(
              color: Colors.deepPurple.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '¿Está seguro que desea eliminar a ${widget.employee.fullName}?',
            style: TextStyle(color: Colors.deepPurple.shade600),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: _deleteEmployee,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
              child: Text(
                'Eliminar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEmployee() async {
    try {
      await _employeesRef.doc(widget.employee.id).delete();
      Navigator.of(context).pop(); // Dismiss the confirm dialog
      Navigator.of(context).pop(true); // Return to previous screen
    } catch (e) {
      _showErrorDialog('Error', 'No se pudo eliminar el empleado: $e');
    }
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