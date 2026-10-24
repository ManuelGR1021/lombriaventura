import 'package:hive_flutter/hive_flutter.dart';

class ActividadService {
  static const String _boxName = 'actividad';

  // Registrar actividad hoy
  Future<void> registrarActividad() async {
    final box = Hive.box(_boxName);
    final hoy = DateTime.now().toIso8601String().split('T')[0];
    
    // Guardar el día como activo
    await box.put(hoy, true);
  }

  // Obtener total de días activos
  int obtenerDiasActivos() {
    final box = Hive.box(_boxName);
    return box.keys.length;
  }

  // Obtener días consecutivos (racha actual)
  int obtenerRacha() {
    final box = Hive.box(_boxName);
    int racha = 0;
    DateTime fecha = DateTime.now();

    while (true) {
      final key = fecha.toIso8601String().split('T')[0];
      if (box.get(key, defaultValue: false)) {
        racha++;
        fecha = fecha.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return racha;
  }

  /// Récord histórico de días consecutivos.
  ///
  /// Recorre las fechas guardadas en Hive (`actividad`) y devuelve la racha
  /// más larga. Si todavía no hay días registrados, devuelve 0.
  int obtenerRecordRacha() {
    final box = Hive.box(_boxName);
    final dias = <DateTime>{};

    for (final key in box.keys) {
      if (box.get(key) != true) continue;
      final parsed = DateTime.tryParse(key.toString());
      if (parsed == null) continue;
      dias.add(DateTime(parsed.year, parsed.month, parsed.day));
    }

    if (dias.isEmpty) return 0;

    final orden = dias.toList()..sort();
    var mejor = 1;
    var actual = 1;
    for (var i = 1; i < orden.length; i++) {
      final diferencia = orden[i].difference(orden[i - 1]).inDays;
      if (diferencia == 1) {
        actual++;
        if (actual > mejor) mejor = actual;
      } else if (diferencia > 1) {
        actual = 1;
      }
    }

    final rachaActual = obtenerRacha();
    return mejor > rachaActual ? mejor : rachaActual;
  }

  // Obtener fase de Max según días activos
  Map<String, dynamic> obtenerFaseMax() {
    final dias = obtenerDiasActivos();
    
    if (dias >= 31) {
      return {
        'fase': 5,
        'nombre': 'Max Manzanero',
        'emoji': '🌲',
        'altura': 200,
        'descripcion': '¡Soy un árbol adulto! Doy manzanas y sombra.',
      };
    } else if (dias >= 15) {
      return {
        'fase': 4,
        'nombre': 'Max Joven',
        'emoji': '🌳',
        'altura': 80,
        'descripcion': '¡Estoy creciendo fuerte! Mis ramas se extienden.',
      };
    } else if (dias >= 8) {
      return {
        'fase': 3,
        'nombre': 'Pequeño Max',
        'emoji': '🪴',
        'altura': 30,
        'descripcion': '¡Ya tengo hojitas! Necesito sol y agua.',
      };
    } else if (dias >= 4) {
      return {
        'fase': 2,
        'nombre': 'Brotesito',
        'emoji': '🌱',
        'altura': 10,
        'descripcion': '¡Estoy brotando! Apenas salgo de la tierra.',
      };
    } else {
      return {
        'fase': 1,
        'nombre': 'Semillita',
        'emoji': '🌰',
        'altura': 0,
        'descripcion': 'Soy una semilla. ¡Cuídame para que crezca!',
      };
    }
  }
}