// Importa el paquete de pruebas de Flutter.
import 'package:flutter_test/flutter_test.dart';

// --- Modelo Simulado (Mock) ---
// Como no podemos acceder al modelo original fácilmente en un test unitario,
// creamos una versión simple aquí para poder realizar las pruebas.
class Employee {
  final String id;
  final String name;
  final String lastName;
  final String dni;
  final String sede;
  final bool isActive;
  final String? fingerprintTemplate;
  final String? faceRecognitionTemplate;

  Employee({
    required this.id,
    required this.name,
    required this.lastName,
    required this.dni,
    required this.sede,
    this.isActive = true,
    this.fingerprintTemplate,
    this.faceRecognitionTemplate,
  });

  String get fullName => '$name $lastName';
}
// --- Fin del Modelo Simulado ---

void main() {
  // Grupo de pruebas para la lógica de filtrado de empleados.
  group('Employee Filtering Logic', () {
    // Creamos una lista de empleados de prueba para usar en todos los tests.
    final List<Employee> mockEmployees = [
      Employee(id: '1', name: 'Ana', lastName: 'Gomez', dni: '12345678', sede: 'Sede A', isActive: true, fingerprintTemplate: 'data', faceRecognitionTemplate: 'data'),
      Employee(id: '2', name: 'Luis', lastName: 'Perez', dni: '87654321', sede: 'Sede B', isActive: false, fingerprintTemplate: 'data', faceRecognitionTemplate: 'data'),
      Employee(id: '3', name: 'Maria', lastName: 'Lopez', dni: '11223344', sede: 'Sede A', isActive: true, fingerprintTemplate: null, faceRecognitionTemplate: null),
      Employee(id: '4', name: 'Carlos', lastName: 'Sanchez', dni: '55667788', sede: 'Sede C', isActive: true, fingerprintTemplate: 'data', faceRecognitionTemplate: null),
    ];

    // --- PRUEBA UNITARIA 1 ---
    test('El getter fullName debe combinar nombre y apellido correctamente', () {
      // Objetivo: Verificar que el modelo de datos funciona como se espera.
      final employee = Employee(id: 'test', name: 'Juan', lastName: 'Perales', dni: '000', sede: 'test');
      
      // Verificamos que 'Juan Perales' sea el resultado esperado.
      expect(employee.fullName, 'Juan Perales');
    });

    // --- PRUEBA UNITARIA 2 ---
    test('Debe filtrar empleados por término de búsqueda (nombre)', () {
      // Objetivo: Simular la búsqueda por texto.
      const query = 'ana';
      
      // Lógica de filtrado (extraída de tu Widget)
      final filteredList = mockEmployees.where((employee) {
        return employee.name.toLowerCase().contains(query.toLowerCase());
      }).toList();

      // Verificamos que solo encontró 1 empleado (Ana Gomez).
      expect(filteredList.length, 1);
      expect(filteredList.first.name, 'Ana');
    });

    // --- PRUEBA UNITARIA 3 ---
    test('Debe filtrar empleados por estado "Inactivos"', () {
      // Objetivo: Simular el filtro de estado.
      const statusFilter = 'Inactivos';

      // Lógica de filtrado (extraída de tu Widget)
      final filteredList = mockEmployees.where((employee) {
        return statusFilter == 'Inactivos' && !employee.isActive;
      }).toList();
      
      // Verificamos que solo encontró 1 empleado inactivo (Luis Perez).
      expect(filteredList.length, 1);
      expect(filteredList.first.name, 'Luis');
    });
    
    // --- PRUEBA EXTRA (Opcional, pero recomendada) ---
    test('Debe filtrar empleados "Sin Biométricos" completos', () {
      // Objetivo: Simular el filtro de biométricos incompletos.
      const biometricFilter = 'Sin Biométricos';

      // Lógica de filtrado (extraída de tu Widget)
      final filteredList = mockEmployees.where((employee) {
        return biometricFilter == 'Sin Biométricos' &&
               (employee.fingerprintTemplate == null || employee.faceRecognitionTemplate == null);
      }).toList();

      // Verificamos que encontró 2 empleados con biométricos incompletos (Maria y Carlos).
      expect(filteredList.length, 2);
      expect(filteredList.any((e) => e.name == 'Maria'), isTrue);
      expect(filteredList.any((e) => e.name == 'Carlos'), isTrue);
    });
  });
}