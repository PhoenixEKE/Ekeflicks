// lib/widgets/dialog/age_selector_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:app_ekeflicks/core/app_theme.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/providers/device_info_provider.dart';

class AgeSelectorDialog extends StatefulWidget {
  final int? currentAge;
  final dynamic profileType;

  const AgeSelectorDialog({
    super.key,
    this.currentAge,
    this.profileType,
  });

  @override
  State<AgeSelectorDialog> createState() => _AgeSelectorDialogState();
}

class _AgeSelectorDialogState extends State<AgeSelectorDialog> {
  late int _selectedAge;
  int _focusedAge = 0;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedAge = widget.currentAge ?? 8;
    _focusedAge = _selectedAge;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_focusNode.canRequestFocus) {
        _focusNode.requestFocus();
      }
      _scrollToAge(_selectedAge);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToAge(int age) {
    if (!_scrollController.hasClients) return;

    final index = age - 3;
    final itemWidth = 80.0;
    final position = (index * itemWidth).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      position,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          setState(() {
            if (_focusedAge > 3) {
              _focusedAge--;
              _scrollToAge(_focusedAge);
            }
          });
          break;
        case LogicalKeyboardKey.arrowRight:
          setState(() {
            if (_focusedAge < 17) {
              _focusedAge++;
              _scrollToAge(_focusedAge);
            }
          });
          break;
        case LogicalKeyboardKey.arrowUp:
        case LogicalKeyboardKey.arrowDown:
          // Navigation verticale optionnelle
          break;
        case LogicalKeyboardKey.enter:
        case LogicalKeyboardKey.select:
          _selectAge(_focusedAge);
          break;
        default:
          break;
      }
    }
  }

  void _selectAge(int age) {
    Navigator.pop(context, age);
  }

  @override
  Widget build(BuildContext context) {
    final deviceInfo = Provider.of<DeviceInfoProvider>(context);
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isTV = deviceInfo.isTV;
    final isDesktop = deviceInfo.isDesktop;

    return Dialog(
      backgroundColor: theme.dialogBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxWidth: isTV ? 600 : 500,
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titre
            Text(
              loc?.selectionAge ?? 'Sélectionnez un âge',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Âge sélectionné
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${loc?.ageActuel ?? 'Âge sélectionné'}: $_focusedAge',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Sélecteur d'âge
            Expanded(
              child: isTV || isDesktop
                  ? RawKeyboardListener(
                      focusNode: _focusNode,
                      onKey: _onKey,
                      child: _buildAgeSelector(theme, isTV),
                    )
                  : _buildAgeSelector(theme, false),
            ),
            const SizedBox(height: 16),

            // Instructions pour TV
            if (isTV)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '← → pour naviguer • ENTRÉE pour valider',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Boutons d'action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Bouton Annuler
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.errorContainer,
                    foregroundColor: theme.colorScheme.onErrorContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text(loc?.annuler ?? 'Annuler'),
                ),

                // Bouton Valider
                ElevatedButton(
                  onPressed: () => _selectAge(_focusedAge),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text(loc?.valider ?? 'Valider'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeSelector(ThemeData theme, bool isTV) {
    return Column(
      children: [
        // Slider pour mobile/desktop
        if (!isTV) ...[
          Slider(
            value: _focusedAge.toDouble(),
            min: 3,
            max: 17,
            divisions: 14,
            label: _focusedAge.toString(),
            activeColor: AppTheme.primaryOrange,
            inactiveColor: theme.colorScheme.surfaceVariant,
            thumbColor: AppTheme.primaryOrange,
            onChanged: (value) {
              setState(() {
                _focusedAge = value.round();
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('3', style: theme.textTheme.bodySmall),
              Text('17', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 24),
        ],

        // Grille d'âges pour TV
        if (isTV) Expanded(child: _buildAgeGrid(theme)),
      ],
    );
  }

  Widget _buildAgeGrid(ThemeData theme) {
    final ages = List.generate(15, (index) => index + 3); // Âges de 3 à 17

    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      itemCount: ages.length,
      itemBuilder: (context, index) {
        final age = ages[index];
        final isSelected = age == _focusedAge;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: GestureDetector(
            onTap: () {
              setState(() => _focusedAge = age);
              _selectAge(age);
            },
            child: Focus(
              canRequestFocus: false,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryOrange
                      : theme.colorScheme.surfaceVariant,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryOrange
                        : theme.colorScheme.outline.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryOrange.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    age.toString(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
