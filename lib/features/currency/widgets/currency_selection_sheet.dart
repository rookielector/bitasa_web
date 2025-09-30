// lib/features/currency/widgets/currency_selection_sheet.dart

import 'package:bitasa_web/features/currency/currency.dart';
import 'package:bitasa_web/features/currency/currency_data.dart';
import 'package:flutter/material.dart';

class CurrencySelectionSheet extends StatefulWidget {
  const CurrencySelectionSheet({super.key});

  @override
  State<CurrencySelectionSheet> createState() => _CurrencySelectionSheetState();
}

class _CurrencySelectionSheetState extends State<CurrencySelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Currency> _filteredCurrencies = allCurrencies;

  @override
  void initState() {
    super.initState();
    // Escuchamos los cambios en el campo de búsqueda para filtrar la lista
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCurrencies = allCurrencies.where((currency) {
        final idLower = currency.id.toLowerCase();
        final nameLower = currency.nameSingular.toLowerCase();
        return idLower.contains(query) || nameLower.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      // Le damos una altura máxima del 70% de la pantalla
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // --- Barra pequeña en la parte superior para indicar que se puede deslizar ---
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Selecciona una moneda',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // --- Campo de Búsqueda ---
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 16),
          // --- Lista de Monedas ---
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCurrencies.length,
              itemBuilder: (context, index) {
                final currency = _filteredCurrencies[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.surface,
                    child: Icon(currency.icon, color: theme.iconTheme.color),
                  ),
                  title: Text(currency.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(currency.nameSingular),
                  onTap: () {
                    // Al tocar una moneda, cerramos el bottom sheet y devolvemos el ID seleccionado
                    Navigator.pop(context, currency.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}