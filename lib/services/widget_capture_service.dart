// lib/services/widget_capture_service.dart

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class WidgetCaptureService {
  
  // Método principal que toma una GlobalKey y devuelve los bytes de la imagen.
  Future<Uint8List?> captureWidget(GlobalKey key) async {
    try {
      // 1. Buscamos el 'RepaintBoundary' asociado a la clave.
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) {
        print('Error de captura: No se pudo encontrar el RenderRepaintBoundary.');
        return null;
      }

      // 2. Convertimos el boundary en una imagen con una resolución de 3.0x (alta calidad).
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      
      // 3. Convertimos la imagen a datos de bytes en formato PNG.
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        print('Error de captura: No se pudieron generar los datos de bytes.');
        return null;
      }

      // 4. Devolvemos la lista de bytes.
      return byteData.buffer.asUint8List();
      
    } catch (e) {
      print('Excepción al capturar el widget: $e');
      return null;
    }
  }
}