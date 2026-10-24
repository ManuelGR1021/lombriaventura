import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lombriaventura/providers/usuario_provider.dart';
import 'package:lombriaventura/screens/menu_principal.dart';
import 'package:lombriaventura/services/actividad_service.dart';
import 'package:provider/provider.dart';

String _dia(DateTime fecha) => fecha.toIso8601String().split('T')[0];

Future<void> _abrirCajas() async {
  final dir = Directory('.dart_tool/hive_menu_test');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  Hive.init(dir.path);

  for (final nombre in [
    'actividad',
    'configuracion',
    'monedas',
    'historial_ventas',
    'retos',
    'recordatorios',
  ]) {
    if (Hive.isBoxOpen(nombre)) {
      await Hive.box(nombre).clear();
    } else {
      await Hive.openBox(nombre);
    }
  }

  final config = Hive.box('configuracion');
  await config.put('login_exitoso', true);
  await config.put('usuario_nombre', 'Ana López');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_abrirCajas);

  test('record de racha usa el tramo consecutivo más largo', () async {
    final box = Hive.box('actividad');
    await box.clear();
    final hoy = DateTime.now();
    for (var i = 10; i <= 13; i++) {
      await box.put(_dia(hoy.subtract(Duration(days: i))), true);
    }
    await box.put(_dia(hoy), true);
    await box.put(_dia(hoy.subtract(const Duration(days: 1))), true);

    final servicio = ActividadService();
    expect(servicio.obtenerRacha(), 2);
    expect(servicio.obtenerRecordRacha(), 4);

    await box.clear();
    expect(servicio.obtenerRecordRacha(), 0);
  });

  testWidgets('el menú saluda con el nombre y no desborda en 320 px', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UsuarioProvider(),
        child: const MaterialApp(home: MenuPrincipal()),
      ),
    );
    await tester.pump();

    expect(find.text('¡Hola, Ana López!'), findsOneWidget);
    expect(find.text('LombriAula'), findsOneWidget);
    expect(find.text('Mis juegos'), findsOneWidget);
    expect(find.text('Mi negocio real'), findsOneWidget);

    final aula = tester.getTopLeft(find.text('LombriAula')).dy;
    final juegos = tester.getTopLeft(find.text('Mis juegos')).dy;
    final negocio = tester.getTopLeft(find.text('Mi negocio real')).dy;
    expect(aula, lessThan(juegos));
    expect(juegos, lessThan(negocio));

    final dinamico = tester.takeException();
    expect(
      dinamico?.toString().contains('overflowed') ?? false,
      isFalse,
      reason: dinamico?.toString(),
    );

    await tester.tap(find.text('Mis juegos'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Memorama ecológico'), findsOneWidget);

    // El menú programa un aviso a los 3 s. Avanzar el reloj evita un timer
    // pendiente; el reto 1 no está completo, así que no abre un diálogo.
    await tester.pump(const Duration(seconds: 4));
  });
}
