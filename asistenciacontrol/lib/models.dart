import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart';


class Employee {
  String? id;
  String dni;
  String name;
  String lastName;
  String phoneNumber;
  String sede;
  Timestamp? registeredAt;
  String? fingerprintTemplate;
  String? faceRecognitionTemplate;
  bool isActive;
  bool biometricVerified;

  Employee({
    this.id,
    required this.dni,
    required this.name,
    required this.lastName,
    required this.phoneNumber,
    required this.sede,
    this.registeredAt,
    this.fingerprintTemplate,
    this.faceRecognitionTemplate,
    this.isActive = true,
    this.biometricVerified = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'dni': dni,
      'name': name,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'sede': sede,  // Asegúrate de guardar el ID de la sede aquí
      'registeredAt': registeredAt ?? FieldValue.serverTimestamp(),
      'fingerprintTemplate': fingerprintTemplate,
      'faceRecognitionTemplate': faceRecognitionTemplate,
      'isActive': isActive,
      'biometricVerified': biometricVerified,
    };
  }

  factory Employee.fromMap(String id, Map<String, dynamic> data) {
    return Employee(
      id: id,
      dni: data['dni'] ?? '',
      name: data['name'] ?? '',
      lastName: data['lastName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      sede: data['sede'] ?? '',
      registeredAt: data['registeredAt'],
      fingerprintTemplate: data['fingerprintTemplate'],
      faceRecognitionTemplate: data['faceRecognitionTemplate'],
      isActive: data['isActive'] ?? true,
      biometricVerified: data['biometricVerified'] ?? false,
    );
  }

  String get fullName => '$name $lastName';
}

class BiometricTemplate {
  final Uint8List featureVector;
  final DateTime createdAt;

  BiometricTemplate({
    required this.featureVector,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Serialización a JSON
  Map<String, dynamic> toJson() => {
    'featureVector': featureVector.toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  // Deserialización desde JSON
  factory BiometricTemplate.fromJson(Map<String, dynamic> json) {
    return BiometricTemplate(
      featureVector: Uint8List.fromList(json['featureVector']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

// Enum para tipos de verificación biométrica
enum BiometricVerificationType {
  none,
  fingerprint,
  faceRecognition,
  bothFingerAndFace
}

class FingerprintBiometrics {
  // Método simplificado de extracción de características de huella digital
  static BiometricTemplate extractFingerprintFeatures(Uint8List fingerprintImage) {
    // Simulación de extracción de características
    // En una implementación real, usarías un método más complejo
    List<int> simulatedFeatures = _simulateFeatureExtraction(fingerprintImage);
    
    return BiometricTemplate(
      featureVector: Uint8List.fromList(simulatedFeatures)
    );
  }

  // Método simulado de extracción de características
  static List<int> _simulateFeatureExtraction(Uint8List image) {
    // Genera un vector de características aleatorio basado en la imagen
    final random = Random();
    return List.generate(64, (_) => random.nextInt(256));
  }

  // Comparación de huellas digitales
  static double compareFingerprintTemplates(
    BiometricTemplate template1, 
    BiometricTemplate template2
  ) {
    // Comparación de vectores de características
    if (template1.featureVector.length != template2.featureVector.length) {
      return 0.0;
    }
    
    double hammingDistance = 0.0;
    for (int i = 0; i < template1.featureVector.length; i++) {
      hammingDistance += (template1.featureVector[i] ^ template2.featureVector[i]).bitCount;
    }
    
    // Normalizar distancia de Hamming
    double similarity = 1.0 - (hammingDistance / template1.featureVector.length);
    
    return similarity;
  }
}

class FacialBiometrics {
  // Método simplificado de extracción de características faciales
  static BiometricTemplate extractFacialFeatures(Uint8List faceImage) {
    // Simulación de extracción de características
    // En una implementación real, usarías un método más complejo
    List<int> simulatedFeatures = _simulateFeatureExtraction(faceImage);
    
    return BiometricTemplate(
      featureVector: Uint8List.fromList(simulatedFeatures)
    );
  }

  // Método simulado de extracción de características
  static List<int> _simulateFeatureExtraction(Uint8List image) {
    // Genera un vector de características aleatorio basado en la imagen
    final random = Random();
    return List.generate(64, (_) => random.nextInt(256));
  }

  // Comparación de características faciales
  static double compareFacialTemplates(
    BiometricTemplate template1, 
    BiometricTemplate template2
  ) {
    // Comparación de vectores de características
    if (template1.featureVector.length != template2.featureVector.length) {
      return 0.0;
    }
    
    // Calcular distancia euclidiana
    double distance = 0.0;
    for (int i = 0; i < template1.featureVector.length; i++) {
      double diff = (template1.featureVector[i] / 255.0) - 
                    (template2.featureVector[i] / 255.0);
      distance += diff * diff;
    }
    
    // Convertir distancia a similaridad
    double similarity = 1.0 / (1.0 + sqrt(distance));
    
    return similarity;
  }
}

// Extensión para contar bits
extension BitCount on int {
  int get bitCount {
    int count = 0;
    int n = this;
    while (n != 0) {
      count += n & 1;
      n >>= 1;
    }
    return count;
  }
}

// Attendance Model
class Attendance {
  String? id;
  String employeeId;
  DateTime checkIn;
  DateTime? checkOut;
  String sede;
  Map<String, dynamic>? checkInDetails;
  Map<String, dynamic>? checkOutDetails;
  String? status;
  String? totalHoursWorked;
  
  // Nuevo getter para date
  String get date {
    // Primero intenta obtener la fecha de checkInDetails
    if (checkInDetails != null && checkInDetails!.containsKey('date')) {
      return checkInDetails!['date'] as String;
    }
    
    // Si no, usa la fecha del checkIn
    return '${checkIn.year}-${checkIn.month.toString().padLeft(2, '0')}-${checkIn.day.toString().padLeft(2, '0')}';
  }
  
  // Nuevos campos para verificación biométrica
  bool biometricVerified;
  BiometricVerificationType verificationType;

  Attendance({
    this.id,
    required this.employeeId,
    required this.checkIn,
    this.checkOut,
    required this.sede,
    this.checkInDetails,
    this.checkOutDetails,
    this.status,
    this.totalHoursWorked,
    this.biometricVerified = false,
    this.verificationType = BiometricVerificationType.none,
  });

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'checkIn': checkIn,
      'checkOut': checkOut,
      'sede': sede,
      'status': status,
      'totalHoursWorked': totalHoursWorked,
      'biometricVerified': biometricVerified,
      'verificationType': verificationType.toString().split('.').last,
    };
  }

  factory Attendance.fromMap(String id, Map<String, dynamic> data) {
    DateTime parseCheckIn() {
      try {
        if (data['checkIn'] is Timestamp) {
          return (data['checkIn'] as Timestamp).toDate();
        } else if (data['checkIn'] is Map) {
          final dateStr = data['date'] as String? ?? DateTime.now().toString().split(' ')[0];
          final timeStr = data['checkIn']['time'] as String? ?? '00:00:00';
          return DateTime.parse('$dateStr $timeStr');
        }
      } catch (e) {
        print('Error parsing check-in time: $e');
      }
      return DateTime.now();
    }

    DateTime? parseCheckOut() {
      try {
        if (data['checkOut'] == null) {
          return null;
        } else if (data['checkOut'] is Timestamp) {
          return (data['checkOut'] as Timestamp).toDate();
        } else if (data['checkOut'] is Map) {
          final dateStr = data['date'] as String? ?? DateTime.now().toString().split(' ')[0];
          final timeStr = data['checkOut']['time'] as String? ?? '00:00:00';
          return DateTime.parse('$dateStr $timeStr');
        }
      } catch (e) {
        print('Error parsing check-out time: $e');
      }
      return null;
    }

    final employeeId = data['employeeId'] ?? data['dni'] ?? '';

    // Parseo de verificación biométrica
    final biometricVerified = data['biometricVerified'] ?? false;
    final verificationType = data['verificationType'] != null 
      ? BiometricVerificationType.values.firstWhere(
          (type) => type.toString().split('.').last == data['verificationType'], 
          orElse: () => BiometricVerificationType.none
        )
      : BiometricVerificationType.none;

    return Attendance(
      id: id,
      employeeId: employeeId,
      checkIn: parseCheckIn(),
      checkOut: parseCheckOut(),
      sede: data['sede'] ?? 'Unknown',
      checkInDetails: data['checkIn'] is Map ? data['checkIn'] as Map<String, dynamic> : null,
      checkOutDetails: data['checkOut'] is Map ? data['checkOut'] as Map<String, dynamic> : null,
      status: data['status'],
      totalHoursWorked: data['totalHoursWorked'],
      biometricVerified: biometricVerified,
      verificationType: verificationType,
    );
  }
}

// Biometric Attendance Verification Utility
class BiometricAttendanceVerification {
  // Método para verificar biométricamente
  static Future<Attendance> verifyAndCreateAttendance({
    required String employeeId,
    required String sede,
    required BiometricVerificationType verificationType,
    Uint8List? fingerprintImage,
    Uint8List? faceImage,
  }) async {
    try {
      bool verificationResult = await _performBiometricVerification(
        verificationType, 
        fingerprintImage, 
        faceImage
      );

      return Attendance(
        employeeId: employeeId,
        checkIn: DateTime.now(),
        sede: sede,
        biometricVerified: verificationResult,
        verificationType: verificationType,
      );
    } catch (e) {
      print('Biometric verification error: $e');
      throw Exception('Biometric verification failed');
    }
  }

  // Método privado para realizar verificación biométrica
  static Future<bool> _performBiometricVerification(
    BiometricVerificationType verificationType,
    Uint8List? fingerprintImage,
    Uint8List? faceImage,
  ) async {
    switch (verificationType) {
      case BiometricVerificationType.fingerprint:
        if (fingerprintImage == null) return false;
        // Simulación de verificación de huella
        return _simulateFingerprintVerification(fingerprintImage);
      
      case BiometricVerificationType.faceRecognition:
        if (faceImage == null) return false;
        // Simulación de verificación facial
        return _simulateFaceVerification(faceImage);
      
      case BiometricVerificationType.bothFingerAndFace:
        if (fingerprintImage == null || faceImage == null) return false;
        // Simulación de verificación combinada
        return _simulateCombinedVerification(fingerprintImage, faceImage);
      
      default:
        return false;
    }
  }

  // Métodos de simulación de verificación
  static bool _simulateFingerprintVerification(Uint8List fingerprintImage) {
    // Lógica simulada de verificación de huella
    return fingerprintImage.isNotEmpty;
  }

  static bool _simulateFaceVerification(Uint8List faceImage) {
    // Lógica simulada de verificación facial
    return faceImage.isNotEmpty;
  }

  static bool _simulateCombinedVerification(Uint8List fingerprintImage, Uint8List faceImage) {
    // Lógica simulada de verificación combinada
    return fingerprintImage.isNotEmpty && faceImage.isNotEmpty;
  }
}

// Sede Model
class Sede {
  String? id;
  String name;
  String address;
  double latitude;
  double longitude;
  DateTime createdAt;
  bool isActive;
  int empleadosCount; // Nuevo campo para el conteo de empleados

  // Constructor mejorado con todos los parámetros necesarios
  Sede({
    this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    DateTime? createdAt,
    this.isActive = true,
    this.empleadosCount = 0, // Valor por defecto en 0
  }) : this.createdAt = createdAt ?? DateTime.now();

  // Método toJson para convertir a Map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'empleadosCount': empleadosCount, // Incluir empleadosCount
    };
  }

  // Factory para crear la sede desde un Map
  factory Sede.fromMap(String id, Map<String, dynamic> data) {
    return Sede(
      id: id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
      empleadosCount: data['empleadosCount'] ?? 0, // Agregar empleadosCount al Map
    );
  }

  // Método para mostrar la sede como un String legible
  @override
  String toString() {
    return 'Sede(id: $id, name: $name, address: $address, latitude: $latitude, longitude: $longitude, createdAt: $createdAt, isActive: $isActive, empleadosCount: $empleadosCount)';
  }
  
  // Método para activar o desactivar una sede
  void toggleActiveStatus() {
    isActive = !isActive;
  }
}


// Enum para modo de vista de asistencia
enum AttendanceViewMode {
  daily,
  weekly,
  monthly
}