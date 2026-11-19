import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/providers/profile_provider.dart';
import 'package:app_ekeflicks/src/models/profile.dart';
import 'package:app_ekeflicks/services/profile_access_service.dart';

// Configuration dynamique pour les profils
class ProfileConfig {
  final List<String> adultAvatars;
  final List<String> childAvatars;
  final String defaultAdultAvatar;
  final String defaultChildAvatar;
  final int gridColumns;
  final double gridSpacing;
  final double gridChildAspectRatio;
  final Map<String, String> profileTypes;

  ProfileConfig({
    required this.adultAvatars,
    required this.childAvatars,
    required this.defaultAdultAvatar,
    required this.defaultChildAvatar,
    this.gridColumns = 4,
    this.gridSpacing = 12,
    this.gridChildAspectRatio = 0.75,
    Map<String, String>? profileTypes,
  }) : profileTypes =
           profileTypes ??
           {'main': 'Adult', 'child': 'Child', 'guest': 'Guest'};
}

class ProfileSwitcher extends StatefulWidget {
  final List<Profile> profiles;
  final Function(Profile) onProfileSelected;
  final ProfileConfig config;

  const ProfileSwitcher({
    super.key,
    required this.profiles,
    required this.onProfileSelected,
    required this.config,
  });

  @override
  State<ProfileSwitcher> createState() => _ProfileSwitcherState();
}

class _ProfileSwitcherState extends State<ProfileSwitcher> {
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc?.chooseProfile ?? 'Choose Profile',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          _buildProfilesGrid(context),
        ],
      ),
    );
  }

  Widget _buildProfilesGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.config.gridColumns,
        crossAxisSpacing: widget.config.gridSpacing,
        mainAxisSpacing: widget.config.gridSpacing,
        childAspectRatio: widget.config.gridChildAspectRatio,
      ),
      itemCount: widget.profiles.length,
      itemBuilder: (context, index) {
        final profile = widget.profiles[index];
        final profileTypeKey = profile.type?.name ?? 'main';
        final profileType =
            widget.config.profileTypes[profileTypeKey] ?? profileTypeKey;
        final avatarUrl = profile.avatarUrl ?? '';
        final hasCustomAvatar =
            avatarUrl.isNotEmpty &&
            !avatarUrl.contains('/avatars/default-adult.png') &&
            !avatarUrl.contains('/avatars/default-child.png');
        final imagePath =
            hasCustomAvatar
                ? avatarUrl
                : (profileTypeKey == 'child'
                    ? widget.config.defaultChildAvatar
                    : widget.config.defaultAdultAvatar);

        return _ProfileCard(
          profile: profile,
          profileType: profileType,
          imagePath: imagePath,
          onTap: () async {
            if (profile.id != null) {
              // Vérifier l'accès au profil (PIN parental si nécessaire)
              if (!await ProfileAccessService.canOpen(context, profile) ||
                  !context.mounted) {
                return;
              }
              await _switchProfile(profile);
              widget.onProfileSelected(profile);
            }
          },
        );
      },
    );
  }

  Future<void> _switchProfile(Profile profile) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      await profileProvider.selectProfile(profile);
    } catch (e) {
      setState(() {
        _error = 'Failed to switch profile: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _ProfileCard extends StatefulWidget {
  final Profile profile;
  final String profileType;
  final String imagePath;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.profile,
    required this.profileType,
    required this.imagePath,
    required this.onTap,
  });

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.08 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 120),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      backgroundImage: _getImageProvider(widget.imagePath),
                      child:
                          widget.imagePath.isEmpty
                              ? const Icon(Icons.person, size: 24)
                              : null,
                    ),
                    if (widget.profile.type?.name == 'child')
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.child_care,
                          color: theme.colorScheme.onPrimary,
                          size: 10,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: Text(
                    widget.profile.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    widget.profileType,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ImageProvider _getImageProvider(String imagePath) {
    if (imagePath.isEmpty) {
      return const AssetImage('assets/avatars/adult.png');
    }

    if (imagePath.startsWith('http')) {
      return NetworkImage(imagePath);
    } else {
      return AssetImage(imagePath);
    }
  }
}
