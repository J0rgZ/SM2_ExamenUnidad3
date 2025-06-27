import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../models.dart';

class CapturaBiometricaPage extends StatefulWidget {
  final Employee employee;

  const CapturaBiometricaPage({Key? key, required this.employee}) : super(key: key);

  @override
  _CapturaBiometricaPageState createState() => _CapturaBiometricaPageState();
}

class _CapturaBiometricaPageState extends State<CapturaBiometricaPage> {
  final LocalAuthentication _localAuthentication = LocalAuthentication();

  // Verificación de la disponibilidad de biometría
  Future<bool> _checkBiometricAvailability() async {
    try {
      bool canCheckBiometrics = await _localAuthentication.canCheckBiometrics;
      if (!canCheckBiometrics) return false;

      List<BiometricType> availableBiometrics =
          await _localAuthentication.getAvailableBiometrics();
      return availableBiometrics.contains(BiometricType.fingerprint) ||
          availableBiometrics.contains(BiometricType.face);
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }

  // Función para autenticar con biometría
  Future<bool> _authenticateWithBiometric(String reason) async {
    try {
      final bool didAuthenticate = await _localAuthentication.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return didAuthenticate;
    } catch (e) {
      print("Error during authentication: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Captura Biométrica - ${widget.employee.name}'),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<bool>(
        future: _checkBiometricAvailability(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.hasData && snapshot.data == true) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBiometricCaptureRow(
                  icon: Icons.fingerprint,
                  title: 'Huella Digital',
                  onCapturar: () async {
                    bool isAuthenticated = await _authenticateWithBiometric('Capturar Huella Digital');
                    if (isAuthenticated) {
                      // Aquí podrías guardar o procesar la biometría del empleado
                      // Por ejemplo, actualizar el modelo de empleado
                      widget.employee.biometricVerified = true;
                      
                      // Devolver true para indicar captura exitosa
                      Navigator.of(context).pop(true);
                    } else {
                      // Mostrar mensaje de error
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Autenticación fallida'))
                      );
                    }
                  },
                ),
                SizedBox(height: 20),
                _buildBiometricCaptureRow(
                  icon: Icons.face,
                  title: 'Reconocimiento Facial',
                  onCapturar: () async {
                    bool isAuthenticated = await _authenticateWithBiometric('Capturar Reconocimiento Facial');
                    if (isAuthenticated) {
                      // Aquí podrías guardar o procesar la biometría del empleado
                      widget.employee.biometricVerified = true;
                      
                      // Devolver true para indicar captura exitosa
                      Navigator.of(context).pop(true);
                    } else {
                      // Mostrar mensaje de error
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Autenticación fallida'))
                      );
                    }
                  },
                ),
              ],
            );
          } else {
            return Center(
              child: Text(
                'Biometría no disponible', 
                style: TextStyle(fontSize: 18),
              ),
            );
          }
        },
      ),
    );
  }

  // Método para capturar la biometría
  Widget _buildBiometricCaptureRow({
    required IconData icon,
    required String title,
    required VoidCallback onCapturar,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey,
            size: 30,
          ),
          SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          Spacer(),
          ElevatedButton(
            onPressed: onCapturar,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Capturar'),
          ),
        ],
      ),
    );
  }
}
