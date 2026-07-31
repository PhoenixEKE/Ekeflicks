// lib/widgets/dialogs/country_selection_dialog.dart
import 'package:flutter/material.dart';
import 'package:app_ekeflicks/services/geolocation_service.dart';

class CountrySelectionDialog extends StatefulWidget {
  final String? currentCountry;
  final Function(String) onCountrySelected;

  const CountrySelectionDialog({
    super.key,
    this.currentCountry,
    required this.onCountrySelected,
  });

  @override
  State<CountrySelectionDialog> createState() => _CountrySelectionDialogState();
}

class _CountrySelectionDialogState extends State<CountrySelectionDialog> {
  late List<Map<String, String>> _filteredCountries;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredCountries = GeolocationService.popularCountries;
    _searchController.addListener(_filterCountries);
  }

  void _filterCountries() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = GeolocationService.popularCountries;
      } else {
        _filteredCountries = GeolocationService.popularCountries.where((country) {
          return country['name']!.toLowerCase().contains(query) ||
                 country['code']!.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sélectionner un pays',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Barre de recherche
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un pays...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
            const SizedBox(height: 16),
            
            // Liste des pays
            Expanded(
              child: _filteredCountries.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun pays trouvé',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredCountries.length,
                      itemBuilder: (context, index) {
                        final country = _filteredCountries[index];
                        return ListTile(
                          leading: Text(
                            country['flag']!,
                            style: const TextStyle(fontSize: 20),
                          ),
                          title: Text(country['name']!),
                          trailing: widget.currentCountry == country['code']
                              ? Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () {
                            widget.onCountrySelected(country['code']!);
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      },
                    ),
            ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}