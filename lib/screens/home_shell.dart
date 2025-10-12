// lib/screens/home_shell.dart

import 'package:bitasa_web/features/calculator/screens/calculator_view.dart';
import 'package:bitasa_web/core/theme/theme_provider.dart';
import 'package:bitasa_web/features/historical/screens/historical_prices_screen.dart';
import 'package:bitasa_web/features/accounts/screens/financial_accounts_screen.dart';
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
    // --- CAMBIO 1: OBTENEMOS EL NOTIFIER Y EL VALOR BOOLEANO ---
    // Leemos el notifier para poder llamar a sus métodos.
    final themeNotifier = ref.read(themeProvider.notifier);
    // Usamos el nuevo getter 'isDarkMode' pasándole el contexto.
    final isDarkMode = themeNotifier.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80, 
        title: Image.asset('assets/images/logo.webp', height: 65),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            // El icono ahora depende del booleano simple 'isDarkMode'.
            icon: Icon(isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: 'Cambiar Tema',
            // --- CAMBIO 2: LLAMAMOS AL NUEVO MÉTODO TOGGLE ---
            onPressed: () => themeNotifier.toggleTheme(context),
          ),
        ],
      ),
      body: SafeArea(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
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
        onTap: _onItemTapped,
      ),
    );
  }
}