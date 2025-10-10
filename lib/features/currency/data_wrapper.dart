// lib/features/currency/data_wrapper.dart

// Esta enumeración define las posibles fuentes de nuestros datos.
// Nos permite etiquetar la información para saber de dónde vino.
enum DataSource {
  cache,  // Los datos vinieron del almacenamiento local (shared_preferences).
  network // Los datos vinieron de la red (Firebase).
}

// Esta es una clase genérica que "envuelve" nuestros datos.
// Puede contener cualquier tipo de dato (indicado por <T>) y lo acompaña
// con una etiqueta que indica su origen (source).
class DataWrapper<T> {
  // Los datos reales, por ejemplo: Map<String, double>.
  final T data;
  
  // La etiqueta que nos dice si los datos son de la caché o de la red.
  final DataSource source;

  // Constructor para crear una nueva instancia del wrapper.
  DataWrapper({
    required this.data,
    required this.source,
  });
}