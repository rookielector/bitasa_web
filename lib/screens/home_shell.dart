// lib/screens/home_shell.dart

import 'package:bitasa_web/features/calculator/screens/calculator_view.dart';
import 'package:bitasa_web/core/theme/theme_provider.dart';
import 'package:bitasa_web/features/historical/screens/historical_prices_screen.dart';
import 'package:bitasa_web/features/accounts/screens/financial_accounts_screen.dart';
import 'package:bitasa_web/shared/widgets/ad_widget.dart';
import 'package:bitasa_web/features/tutorial/providers/tutorial_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:url_launcher/url_launcher.dart';

// --- PASO 1: Creamos una GlobalKey para el estado de HomeShell ---
// La exportamos para que sea accesible desde otros archivos.
final homeShellKey = GlobalKey<_HomeShellState>();

class HomeShell extends ConsumerStatefulWidget {
  // Le asignamos la clave a través del constructor.
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    CalculatorView(),
    FinancialAccountsScreen(), 
    HistoricalPricesScreen(),
  ];

  // --- PASO 2: Hacemos el método público (quitando el '_') ---
  void onItemTapped(int index) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el enlace: $url')),
        );
      }
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acerca de Bitasa Web'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Simplifica tus transacciones con Bitasa Web, la aplicación esencial para conversiones de divisas. Obtén tasas de cambio legales, precisas y en tiempo real, utilizando la fuente del Banco Central de Venezuela (BCV).',
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                'Versión: 1.0.0',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ref.read(themeProvider.notifier);
    final isDarkMode = themeNotifier.isDarkMode(context);

    return ShowCaseWidget(
      builder: (context) => Scaffold(
        appBar: AppBar(
          toolbarHeight: 80, 
          title: Image.asset('assets/images/logo.webp', height: 65),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
              tooltip: 'Cambiar Tema',
              onPressed: () => themeNotifier.toggleTheme(context),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'restart_tour') {
                  final keys = ref.read(tutorialKeysProvider).keys;
                  ShowCaseWidget.of(context).startShowCase(keys);
                } else if (value == 'privacy') {
                  _launchURL('https://sites.google.com/view/bitasa/privacy');
                } else if (value == 'terms') {
                  _launchURL('https://sites.google.com/view/bitasa/terminos');
                } else if (value == 'about') {
                  _showAboutDialog();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'restart_tour',
                  child: ListTile(
                    leading: Icon(Icons.help_outline),
                    title: Text('Mostrar Tour Guiado'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'privacy',
                  child: ListTile(
                    leading: Icon(Icons.privacy_tip_outlined),
                    title: Text('Política de Privacidad'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'terms',
                  child: ListTile(
                    leading: Icon(Icons.gavel_outlined),
                    title: Text('Términos y Condiciones'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'about',
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Acerca de Bitasa'),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: AdWidget(),
            ),
            BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.calculate),
                  label: 'Calculadora',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  label: 'Cuentas',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: 'Históricos',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Theme.of(context).colorScheme.secondary,
              backgroundColor: Colors.transparent,
              elevation: 0,
              onTap: onItemTapped, // Usamos el método público
            ),
          ],
        ),
      ),
    );
  }
}