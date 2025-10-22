// lib/features/faq/screens/faq_screen.dart

import 'package:flutter/material.dart';

// Un modelo simple para organizar nuestras preguntas y respuestas.
class FaqItem {
  final String question;
  final String answer;

  const FaqItem({required this.question, required this.answer});
}

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  // Lista con todo el contenido de nuestras preguntas frecuentes.
  final List<FaqItem> faqItems = const [
    FaqItem(
      question: '¿Qué hace Bitasa Web?',
      answer: 'Bitasa Web es una calculadora de divisas progresiva (PWA) que te permite realizar conversiones rápidas y precisas entre Bolívares (VES), Dólares (USD), Euros (EUR) y, próximamente, criptomonedas. Además, te permite generar y compartir "Datos de Pago" profesionales.',
    ),
    FaqItem(
      question: '¿Son las tasas del Banco Central de Venezuela (BCV)?',
      answer: '¡Sí! Todas nuestras tasas de cambio para monedas fiat (VES, USD, EUR) se basan en la información publicada diariamente por el Banco Central de Venezuela, asegurando que tus cálculos sean siempre legales y precisos.',
    ),
    FaqItem(
      question: '¿Puedo ver tasas de otros días?',
      answer: '¡Claro! En la pantalla de la Calculadora, simplemente toca la fecha que se muestra en la parte inferior para abrir un calendario y seleccionar el día que deseas consultar. La aplicación buscará la tasa oficial para esa fecha.',
    ),
    FaqItem(
      question: '¿Para qué debo añadir mis datos en la pestaña "Cuentas"?',
      answer: 'La sección "Cuentas" es opcional y te permite guardar tus datos de Pago Móvil o Transferencia de forma segura y 100% local en tu dispositivo. Al tener una cuenta guardada, puedes generar y compartir "Datos de Pago" completos (con tu información bancaria, motivo, etc.), lo que facilita que te paguen.',
    ),
    FaqItem(
      question: '¿Mi información es pública?',
      answer: 'No, nunca. Todos los datos que guardas en Bitasa Web (Cuentas Financieras, Cálculos Guardados) se almacenan de forma privada y segura únicamente en tu dispositivo/navegador. Nosotros no tenemos acceso a tu información.',
    ),
    FaqItem(
      question: '¿Cómo funciona el "Modo Offline"?',
      answer: 'Bitasa Web está diseñada para funcionar sin conexión a internet. La aplicación guarda localmente las últimas tasas consultadas. Si abres la app sin conexión, podrás seguir realizando todos tus cálculos con los datos más recientes que tengas guardados.',
    ),
    FaqItem(
      question: '¿Cómo instalo Bitasa Web en mi dispositivo?',
      answer: 'Puedes instalar Bitasa Web para un acceso más rápido. En tu navegador (Chrome, Edge, Safari), busca el icono de "Instalar" en la barra de direcciones o la opción "Añadir a la pantalla de inicio" en el menú del navegador. Esto añadirá un icono de Bitasa a tu escritorio o pantalla de inicio, ¡como una app nativa!',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preguntas Frecuentes'),
        // El botón de 'volver' se añade automáticamente por la navegación.
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: faqItems.length,
        itemBuilder: (context, index) {
          final item = faqItems[index];
          // Usamos ExpansionTile para el efecto de "acordeón".
          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ExpansionTile(
              title: Text(
                item.question,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              // Los hijos de ExpansionTile son los que se muestran al expandir.
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                  child: Text(item.answer),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}