// lib/widgets/dialog/avatar_selector_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:app_ekeflicks/core/app_theme.dart';
import 'package:app_ekeflicks/providers/device_info_provider.dart';
import 'package:app_ekeflicks/providers/avatar_provider.dart';
import 'package:app_ekeflicks/providers/user_provider.dart';

class AvatarSelectorDialog extends StatefulWidget {
  final String? selectedAvatar;
  final ValueChanged<String> onAvatarSelected;

  const AvatarSelectorDialog({
    super.key,
    required this.onAvatarSelected,
    this.selectedAvatar,
  });

  @override
  State<AvatarSelectorDialog> createState() => _AvatarSelectorDialogState();
}

class _AvatarSelectorDialogState extends State<AvatarSelectorDialog> {
  int _focusedIndex = 0;
  final int _crossAxisCount = 3;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Charger les avatars au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final avatarProvider = Provider.of<AvatarProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (!avatarProvider.isLoading && avatarProvider.avatars.isEmpty) {
        avatarProvider.loadAvatars(userProvider.apiClient);
      }

      // Initialiser le focus sur l'avatar sélectionné
      if (widget.selectedAvatar != null && avatarProvider.avatars.isNotEmpty) {
        final idx = avatarProvider.avatars.indexWhere(
          (avatar) => avatar['url'] == widget.selectedAvatar
        );
        if (idx >= 0) {
          setState(() {
            _focusedIndex = idx;
          });
        }
      }
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_focusNode.canRequestFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// Gestion navigation TV
  void _onKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final avatarProvider = Provider.of<AvatarProvider>(context, listen: false);

      setState(() {
        switch (event.logicalKey) {
          case LogicalKeyboardKey.arrowUp:
            if (_focusedIndex - _crossAxisCount >= 0) {
              _focusedIndex -= _crossAxisCount;
            }
            break;
          case LogicalKeyboardKey.arrowDown:
            if (_focusedIndex + _crossAxisCount < avatarProvider.avatars.length) {
              _focusedIndex += _crossAxisCount;
            }
            break;
          case LogicalKeyboardKey.arrowLeft:
            if (_focusedIndex % _crossAxisCount > 0) {
              _focusedIndex--;
            }
            break;
          case LogicalKeyboardKey.arrowRight:
            if (_focusedIndex % _crossAxisCount < _crossAxisCount - 1 &&
                _focusedIndex < avatarProvider.avatars.length - 1) {
              _focusedIndex++;
            }
            break;
          case LogicalKeyboardKey.enter:
          case LogicalKeyboardKey.select:
            _selectAvatar(_focusedIndex);
            break;
          default:
            break;
        }
      });
    }
  }

  void _selectAvatar(int index) {
    final avatarProvider = Provider.of<AvatarProvider>(context, listen: false);

    if (index >= 0 && index < avatarProvider.avatars.length) {
      final avatarUrl = avatarProvider.avatars[index]['url']!;
      print('🟢 Avatar sélectionné: index=$index, url=$avatarUrl');

      // Fermer le dialogue et retourner l'URL sélectionnée
      Navigator.of(context).pop(avatarUrl);
    } else {
      // Si index invalide, fermer sans retourner de valeur
      print('🔴 Index invalide: $index');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceInfo = Provider.of<DeviceInfoProvider>(context);
    final avatarProvider = Provider.of<AvatarProvider>(context);
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.dialogBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Choisir un avatar",
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),

            if (avatarProvider.isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: AppTheme.primaryOrange,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chargement des avatars...',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )
            else if (avatarProvider.error != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur de chargement',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        avatarProvider.error!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          final userProvider = Provider.of<UserProvider>(
                            context,
                            listen: false,
                          );
                          avatarProvider.loadAvatars(userProvider.apiClient);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                        ),
                        child: const Text(
                          'Réessayer',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (avatarProvider.avatars.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 48,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun avatar disponible',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: deviceInfo.isTV
                    ? RawKeyboardListener(
                        focusNode: _focusNode,
                        onKey: _onKey,
                        child: _buildAvatarGrid(deviceInfo.isTV, avatarProvider.avatars),
                      )
                    : _buildAvatarGrid(false, avatarProvider.avatars),
              ),

            const SizedBox(height: 16),
            if (!deviceInfo.isTV && !avatarProvider.isLoading && avatarProvider.error == null)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Annuler',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarGrid(bool isTV, List<Map<String, String>> avatars) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: avatars.length,
      itemBuilder: (context, index) {
        final avatar = avatars[index];
        final avatarUrl = avatar['url']!;
        final isSelected = avatarUrl == widget.selectedAvatar;
        final isFocused = isTV && index == _focusedIndex;

        return GestureDetector(
          onTap: () {
            print('🖱️ Avatar sélectionné: ${avatar['name']}');
            _selectAvatar(index);
          },
          child: Focus(
            canRequestFocus: false,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isFocused
                      ? AppTheme.primaryOrange
                      : (isSelected
                          ? AppTheme.primaryOrange
                          : Colors.transparent),
                  width: isFocused || isSelected ? 3 : 1,
                ),
                borderRadius: BorderRadius.circular(60),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryOrange.withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: ClipOval(
                child: Stack(
                  children: [
                    Image.network(
                      avatarUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    ),
                    if (isSelected)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Center(
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
