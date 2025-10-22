// lib/screens/home_shell.dart

import 'package:bitasa_web/features/calculator/screens/calculator_view.dart';
import 'package:bitasa_web/core/theme/theme_provider.dart';
import 'package:bitasa_web/features/historical/screens/historical_prices_screen.dart';
import 'package:bitasa_web/features/accounts/screens/financial_accounts_screen.dart';
import 'package:bitasa_web/shared/widgets/ad_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeShell extends ConsumerStatefulWidget {
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ref.read(themeProvider.notifier);
    final isDarkMode = themeNotifier.isDarkMode(context);

    const double maxWidth = 800; // Definimos nuestro ancho máximo de contenido.

    return Scaffold(
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
        ],
      ),
      // --- CAMBIO CLAVE: Usamos un LayoutBuilder para el body ---
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Si la pantalla es más ancha que nuestro máximo, centramos el contenido.
          if (constraints.maxWidth > maxWidth) {
            return Center(
              child: SizedBox(
                width: maxWidth,
                child: SafeArea(child: _widgetOptions.elementAt(_selectedIndex)),
              ),
            );
          } else {
            // En pantallas estrechas, el contenido ocupa todo el ancho.
            return SafeArea(child: _widgetOptions.elementAt(_selectedIndex));
          }
        },
      ),
      
      // La barra inferior también usa el mismo patrón.
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth > maxWidth
              ? (constraints.maxWidth - maxWidth) / 2
              : 0.0;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: AdWidget(),
                ),
                BottomNavigationBar(
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'Calculadora'),
                    BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Cuentas'),
                    BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Históricos'),
                  ],
                  currentIndex: _selectedIndex,
                  selectedItemColor: Theme.of(context).colorScheme.secondary,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  onTap: _onItemTapped,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}