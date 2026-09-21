import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:plateforme_producteurs/core/core.dart';

import '../contents/contents_page.dart';
import 'package:flutter/services.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:plateforme_producteurs/core/web_helpers.dart';
import 'package:plateforme_producteurs/services/producer_service.dart';
import 'package:plateforme_producteurs/models/technical_conformity_report.dart';

void main() {
  runApp(
    MaterialApp(
      home: const UploadPage(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

enum ContentType { serie, film }

enum LanguageOption { francais, anglais, autres }

class PersonWithImage {
  final String name;
  final String? imagePath;
  final Uint8List? imageBytes;
  final String? imageFilename;
  final String? imageTempPath;
  final String? imageUrl;
  final String? previewUrl;

  const PersonWithImage({
    required this.name,
    this.imagePath,
    this.imageBytes,
    this.imageFilename,
    this.imageTempPath,
    this.imageUrl,
    this.previewUrl,
  });

  bool get hasPersistedImage =>
      (imageTempPath?.trim().isNotEmpty ?? false) ||
      (imageUrl?.trim().isNotEmpty ?? false);
}

class TechnicalSpecificationContextEngine {
  const TechnicalSpecificationContextEngine._();

  static Map<String, dynamic>? section(
    Map<String, dynamic>? specification,
    String sectionKey,
  ) {
    if (specification == null) {
      return null;
    }

    final rawSections = specification['sections'];

    if (rawSections is! List) {
      return null;
    }

    final normalizedKey = sectionKey.trim().toLowerCase();

    for (final rawSection in rawSections) {
      if (rawSection is! Map) {
        continue;
      }

      final section = Map<String, dynamic>.from(rawSection);
      final key = section['key']?.toString().trim().toLowerCase() ?? '';

      if (key == normalizedKey) {
        return section;
      }
    }

    return null;
  }

  static List<Map<String, dynamic>> items(
    Map<String, dynamic>? specification, {
    required String sectionKey,
    String? deliveryLevel,
    String? conditional,
  }) {
    final resolvedSection = section(specification, sectionKey);

    if (resolvedSection == null) {
      return const <Map<String, dynamic>>[];
    }

    final rawItems = resolvedSection['items'];

    if (rawItems is! List) {
      return const <Map<String, dynamic>>[];
    }

    final normalizedDeliveryLevel = deliveryLevel?.trim().toLowerCase();

    final normalizedConditional = conditional?.trim().toLowerCase();

    return rawItems
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .where((item) {
          final rawLevels = item['delivery_levels'];

          if (rawLevels is List &&
              rawLevels.isNotEmpty &&
              normalizedDeliveryLevel != null &&
              normalizedDeliveryLevel.isNotEmpty) {
            final levels = rawLevels
                .map((value) => value.toString().trim().toLowerCase())
                .where((value) => value.isNotEmpty)
                .toSet();

            if (!levels.contains(normalizedDeliveryLevel)) {
              return false;
            }
          }

          final itemConditional = item['conditional']
              ?.toString()
              .trim()
              .toLowerCase();

          if (itemConditional != null && itemConditional.isNotEmpty) {
            if (normalizedConditional == null ||
                normalizedConditional.isEmpty ||
                itemConditional != normalizedConditional) {
              return false;
            }
          }

          return true;
        })
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> trailerTechnicalItems(
    Map<String, dynamic>? specification, {
    required String deliveryLevel,
  }) {
    return items(
      specification,
      sectionKey: 'trailer',
      deliveryLevel: deliveryLevel,
    );
  }

  static List<Map<String, dynamic>> metadataItems(
    Map<String, dynamic>? specification, {
    required bool isSeries,
    Set<String>? fields,
  }) {
    final resolvedItems = items(specification, sectionKey: 'metadata').where((
      item,
    ) {
      final conditional =
          item['conditional']?.toString().trim().toLowerCase() ?? '';

      if (conditional.isEmpty) {
        return true;
      }

      return isSeries && conditional == 'series';
    });

    if (fields == null || fields.isEmpty) {
      return resolvedItems.toList(growable: false);
    }

    return resolvedItems
        .where((item) {
          final field = item['field']?.toString().trim() ?? '';

          return fields.contains(field);
        })
        .toList(growable: false);
  }

  static String version(Map<String, dynamic>? specification) {
    return specification?['version']?.toString().trim() ?? '';
  }

  static String sectionTitle(
    Map<String, dynamic>? specification,
    String sectionKey,
  ) {
    return section(specification, sectionKey)?['title']?.toString().trim() ??
        '';
  }

  static Map<String, dynamic>? masterLevelItem(
    Map<String, dynamic>? specification,
    String deliveryLevel,
  ) {
    final normalizedLevel = deliveryLevel.trim().toLowerCase();

    final wantedLabel = switch (normalizedLevel) {
      'premium' => 'master premium',
      'standard' => 'master standard',
      _ => 'master distribution',
    };

    for (final item in items(specification, sectionKey: 'master_levels')) {
      final label = item['label']?.toString().trim().toLowerCase() ?? '';

      if (label == wantedLabel) {
        return item;
      }
    }

    return null;
  }

  static List<Map<String, dynamic>> principlesItems(
    Map<String, dynamic>? specification,
  ) {
    return items(specification, sectionKey: 'principles');
  }

  static List<Map<String, dynamic>> conformityItems(
    Map<String, dynamic>? specification,
  ) {
    return items(specification, sectionKey: 'conformity');
  }

  static List<Map<String, dynamic>> deadlineItems(
    Map<String, dynamic>? specification,
  ) {
    return items(specification, sectionKey: 'deadlines');
  }

  static List<Map<String, dynamic>> xmlItems(
    Map<String, dynamic>? specification,
  ) {
    return items(specification, sectionKey: 'xml');
  }

  static List<Map<String, dynamic>> namingItems(
    Map<String, dynamic>? specification, {
    required String context,
  }) {
    final allItems = items(specification, sectionKey: 'naming');

    final normalizedContext = context.trim().toLowerCase();

    bool isGeneral(Map<String, dynamic> item) {
      final label = item['label']?.toString().trim().toLowerCase() ?? '';

      return label.startsWith('règle —') || label.startsWith('regle —');
    }

    bool matchesContext(Map<String, dynamic> item) {
      final label = item['label']?.toString().trim().toLowerCase() ?? '';

      switch (normalizedContext) {
        case 'film':
          return label.startsWith('film —');

        case 'episode':
          return label.startsWith('épisode —') || label.startsWith('episode —');

        case 'series_trailer':
          return label.startsWith('trailer série —') ||
              label.startsWith('trailer serie —');

        default:
          return false;
      }
    }

    return allItems
        .where((item) => isGeneral(item) || matchesContext(item))
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> masterTechnicalItems(
    Map<String, dynamic>? specification,
    String deliveryLevel,
  ) {
    final normalizedLevel = deliveryLevel.trim().toLowerCase();

    return items(
      specification,
      sectionKey: 'program_video',
      deliveryLevel: normalizedLevel,
    );
  }
}

class _TechnicalTrailerRequirements extends StatelessWidget {
  final ValueListenable<Map<String, dynamic>?> specificationListenable;
  final String deliveryLevel;

  const _TechnicalTrailerRequirements({
    required this.specificationListenable,
    required this.deliveryLevel,
  });

  static const Map<String, String> _deliveryLevelLabels = {
    'premium': 'Master Premium',
    'standard': 'Master Standard',
    'distribution': 'Master Distribution',
  };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: specificationListenable,
      builder: (context, specification, _) {
        if (specification == null) {
          return const SizedBox.shrink();
        }

        final normalizedLevel = deliveryLevel.trim().toLowerCase();

        final items = TechnicalSpecificationContextEngine.trailerTechnicalItems(
          specification,
          deliveryLevel: normalizedLevel,
        );

        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        final version = TechnicalSpecificationContextEngine.version(
          specification,
        );

        final sectionTitle = TechnicalSpecificationContextEngine.sectionTitle(
          specification,
          'trailer',
        );

        final levelLabel =
            _deliveryLevelLabels[normalizedLevel] ?? normalizedLevel;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                version.isEmpty
                    ? 'Exigences bande-annonce — $levelLabel'
                    : 'Exigences bande-annonce — V$version — $levelLabel',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (sectionTitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  sectionTitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 8),
              ...items.map(
                (item) => _TechnicalRequirementLine(
                  label: item['label']?.toString().trim() ?? '',
                  value: item['value']?.toString().trim() ?? '',
                  blocking:
                      item['severity']?.toString().trim().toLowerCase() ==
                      'blocking',
                  warning:
                      item['severity']?.toString().trim().toLowerCase() ==
                      'warning',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TechnicalMetadataRequirements extends StatelessWidget {
  final ValueListenable<Map<String, dynamic>?> specificationListenable;
  final bool isSeries;
  final Set<String> fields;

  const _TechnicalMetadataRequirements({
    required this.specificationListenable,
    required this.isSeries,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: specificationListenable,
      builder: (context, specification, _) {
        if (specification == null) {
          return const SizedBox.shrink();
        }

        final requirements = TechnicalSpecificationContextEngine.metadataItems(
          specification,
          isSeries: isSeries,
          fields: fields,
        );

        if (requirements.isEmpty) {
          return const SizedBox.shrink();
        }

        final version = TechnicalSpecificationContextEngine.version(
          specification,
        );

        final sectionTitle = TechnicalSpecificationContextEngine.sectionTitle(
          specification,
          'metadata',
        );

        final title = version.isEmpty
            ? (sectionTitle.isEmpty ? 'Exigences métadonnées' : sectionTitle)
            : 'Exigences métadonnées — V$version';

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8, bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...requirements.map(
                (item) => _TechnicalRequirementLine(
                  label: item['label']?.toString().trim() ?? '',
                  value: item['value']?.toString().trim() ?? '',
                  blocking: item['required'] == true,
                  warning: item['required'] != true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TechnicalPrinciplesRequirements extends StatelessWidget {
  const _TechnicalPrinciplesRequirements({
    required this.specificationListenable,
  });

  final ValueListenable<Map<String, dynamic>?> specificationListenable;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: specificationListenable,
      builder: (context, specification, _) {
        if (specification == null) {
          return const SizedBox.shrink();
        }

        final requirements =
            TechnicalSpecificationContextEngine.principlesItems(specification)
                .where((item) {
                  final label = item['label']?.toString().trim() ?? '';
                  final value = item['value']?.toString().trim() ?? '';

                  return label.isNotEmpty && value.isNotEmpty;
                })
                .toList(growable: false);

        if (requirements.isEmpty) {
          return const SizedBox.shrink();
        }

        final version = TechnicalSpecificationContextEngine.version(
          specification,
        );

        final section = TechnicalSpecificationContextEngine.section(
          specification,
          'principles',
        );

        final rawTitle = section?['title']?.toString().trim() ?? '';
        final description = section?['description']?.toString().trim() ?? '';

        final title = rawTitle.isEmpty
            ? 'Principes généraux de livraison'
            : rawTitle;

        final versionSuffix = version.toString().trim().isEmpty
            ? ''
            : ' — V${version.toString().trim()}';

        return Card(
          margin: const EdgeInsets.only(top: 12, bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title$versionSuffix',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(description),
                ],
                const SizedBox(height: 12),
                ...requirements.map(
                  (item) => _TechnicalRequirementLine(
                    label: item['label']!.toString().trim(),
                    value: item['value']!.toString().trim(),
                    blocking: false,
                    warning: false,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TechnicalConformityRequirements extends StatelessWidget {
  const _TechnicalConformityRequirements({
    required this.specificationListenable,
  });

  final ValueListenable<Map<String, dynamic>?> specificationListenable;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: specificationListenable,
      builder: (context, specification, _) {
        if (specification == null) {
          return const SizedBox.shrink();
        }

        final items =
            TechnicalSpecificationContextEngine.conformityItems(specification)
                .where((item) {
                  final label = item['label']?.toString().trim() ?? '';
                  final value = item['value']?.toString().trim() ?? '';

                  return label.isNotEmpty && value.isNotEmpty;
                })
                .toList(growable: false);

        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        final version = TechnicalSpecificationContextEngine.version(
          specification,
        );

        final section = TechnicalSpecificationContextEngine.section(
          specification,
          'conformity',
        );

        final rawTitle = section?['title']?.toString().trim() ?? '';
        final description = section?['description']?.toString().trim() ?? '';

        final title = rawTitle.isEmpty
            ? 'Contrôle de conformité EKEFLICKS'
            : rawTitle;

        final versionSuffix = version.toString().trim().isEmpty
            ? ''
            : ' — V${version.toString().trim()}';

        return Card(
          margin: const EdgeInsets.only(top: 12, bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title$versionSuffix',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(description),
                ],
                const SizedBox(height: 12),
                ...items.map(
                  (item) => _TechnicalRequirementLine(
                    label: item['label']!.toString().trim(),
                    value: item['value']!.toString().trim(),
                    blocking: false,
                    warning: false,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TechnicalRequirementsAccordion extends StatefulWidget {
  const _TechnicalRequirementsAccordion({
    super.key,
    required this.title,
    required this.children,
    this.leading,
  });

  final String title;
  final List<Widget> children;
  final Widget? leading;

  @override
  State<_TechnicalRequirementsAccordion> createState() =>
      _TechnicalRequirementsAccordionState();
}

class _TechnicalRequirementsAccordionState
    extends State<_TechnicalRequirementsAccordion> {
  bool _isExpanded = false;

  void expand() {
    if (_isExpanded) {
      return;
    }

    setState(() {
      _isExpanded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      _isExpanded ? '−' : '+',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (widget.leading != null) ...[
                    widget.leading!,
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.children,
            ),
          ),
        ],
      ],
    );
  }
}

class _TechnicalDeadlineRequirements extends StatelessWidget {
  final ValueListenable<Map<String, dynamic>?> specificationListenable;

  const _TechnicalDeadlineRequirements({required this.specificationListenable});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: specificationListenable,
      builder: (context, specification, _) {
        if (specification == null) {
          return const SizedBox.shrink();
        }

        final requirements =
            TechnicalSpecificationContextEngine.deadlineItems(specification)
                .where((item) {
                  final label = item['label']?.toString().trim() ?? '';
                  final value = item['value']?.toString().trim() ?? '';
                  return label.isNotEmpty && value.isNotEmpty;
                })
                .toList(growable: false);

        if (requirements.isEmpty) {
          return const SizedBox.shrink();
        }

        final version = TechnicalSpecificationContextEngine.version(
          specification,
        );

        final section = TechnicalSpecificationContextEngine.section(
          specification,
          'deadlines',
        );

        final sectionTitle = TechnicalSpecificationContextEngine.sectionTitle(
          specification,
          'deadlines',
        );

        final description = section?['description']?.toString().trim() ?? '';

        final title = sectionTitle.isEmpty
            ? 'Délais de livraison'
            : sectionTitle;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 16, bottom: 20),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _TechnicalRequirementsAccordion(
            title: version.isEmpty ? title : '$title — V$version',
            children: [
              if (description.isNotEmpty) ...[
                Text(description),
                const SizedBox(height: 8),
              ],
              ...requirements.map(
                (item) => _TechnicalRequirementLine(
                  label: item['label']?.toString().trim() ?? '',
                  value: item['value']?.toString().trim() ?? '',
                  blocking: false,
                  warning: false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TechnicalXmlRequirements extends StatelessWidget {
  final ValueListenable<Map<String, dynamic>?> specificationListenable;

  const _TechnicalXmlRequirements({required this.specificationListenable});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: specificationListenable,
      builder: (context, specification, _) {
        if (specification == null) {
          return const SizedBox.shrink();
        }

        final requirements =
            TechnicalSpecificationContextEngine.xmlItems(specification)
                .where((item) {
                  final label = item['label']?.toString().trim() ?? '';
                  final value = item['value']?.toString().trim() ?? '';
                  return label.isNotEmpty && value.isNotEmpty;
                })
                .toList(growable: false);

        if (requirements.isEmpty) {
          return const SizedBox.shrink();
        }

        final version = TechnicalSpecificationContextEngine.version(
          specification,
        );

        final section = TechnicalSpecificationContextEngine.section(
          specification,
          'xml',
        );

        final sectionTitle = TechnicalSpecificationContextEngine.sectionTitle(
          specification,
          'xml',
        );

        final description = section?['description']?.toString().trim() ?? '';

        final title = sectionTitle.isEmpty
            ? 'Import XML des métadonnées'
            : sectionTitle;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 12, bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _TechnicalRequirementsAccordion(
            title: version.isEmpty ? title : '$title — V$version',
            children: [
              if (description.isNotEmpty) ...[
                Text(description),
                const SizedBox(height: 8),
              ],
              ...requirements.map(
                (item) => _TechnicalRequirementLine(
                  label: item['label']?.toString().trim() ?? '',
                  value: item['value']?.toString().trim() ?? '',
                  blocking: false,
                  warning: false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TechnicalNamingRequirements extends StatelessWidget {
  final ValueListenable<Map<String, dynamic>?> specificationListenable;
  final String namingContext;

  const _TechnicalNamingRequirements({
    required this.specificationListenable,
    required this.namingContext,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: specificationListenable,
      builder: (context, specification, _) {
        if (specification == null) {
          return const SizedBox.shrink();
        }

        final requirements =
            TechnicalSpecificationContextEngine.namingItems(
                  specification,
                  context: namingContext,
                )
                .where((item) {
                  final label = item['label']?.toString().trim() ?? '';
                  final value = item['value']?.toString().trim() ?? '';
                  return label.isNotEmpty && value.isNotEmpty;
                })
                .toList(growable: false);

        if (requirements.isEmpty) {
          return const SizedBox.shrink();
        }

        final version = TechnicalSpecificationContextEngine.version(
          specification,
        );

        final sectionTitle = TechnicalSpecificationContextEngine.sectionTitle(
          specification,
          'naming',
        );

        final title = sectionTitle.isEmpty
            ? 'Convention de nommage'
            : sectionTitle;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _TechnicalRequirementsAccordion(
            title: version.isEmpty ? title : '$title — V$version',
            children: [
              ...requirements.map(
                (item) => _TechnicalRequirementLine(
                  label: item['label']?.toString().trim() ?? '',
                  value: item['value']?.toString().trim() ?? '',
                  blocking: false,
                  warning: false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TechnicalMasterRequirements extends StatelessWidget {
  const _TechnicalMasterRequirements({
    required this.specificationListenable,
    required this.deliveryLevel,
    this.accordionKey,
  });

  final ValueListenable<Map<String, dynamic>?> specificationListenable;
  final String deliveryLevel;

  final GlobalKey<_TechnicalRequirementsAccordionState>? accordionKey;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: specificationListenable,
      builder: (context, specification, _) {
        if (specification == null) {
          return const SizedBox.shrink();
        }

        final version = TechnicalSpecificationContextEngine.version(
          specification,
        );

        final levelItem = TechnicalSpecificationContextEngine.masterLevelItem(
          specification,
          deliveryLevel,
        );

        final technicalItems =
            TechnicalSpecificationContextEngine.masterTechnicalItems(
              specification,
              deliveryLevel,
            );

        final levelLabel = levelItem?['label']?.toString().trim() ?? '';

        final levelValue = levelItem?['value']?.toString().trim() ?? '';

        final visibleItems = technicalItems
            .where((item) {
              final label = item['label']?.toString().trim() ?? '';
              final value = item['value']?.toString().trim() ?? '';
              return label.isNotEmpty && value.isNotEmpty;
            })
            .toList(growable: false);

        if (levelLabel.isEmpty && levelValue.isEmpty && visibleItems.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
            ),
          ),
          child: _TechnicalRequirementsAccordion(
            key: accordionKey,
            leading: const Icon(Icons.rule_outlined, size: 18),
            title: version.isEmpty
                ? 'Exigences techniques'
                : 'Exigences techniques — V$version',
            children: [
              if (levelLabel.isNotEmpty)
                Text(
                  levelLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              if (levelValue.isNotEmpty) ...[
                if (levelLabel.isNotEmpty) const SizedBox(height: 4),
                Text(levelValue),
              ],
              if (visibleItems.isNotEmpty) ...[
                if (levelLabel.isNotEmpty || levelValue.isNotEmpty)
                  const SizedBox(height: 12),
                ...visibleItems.map(
                  (item) => _TechnicalRequirementLine(
                    label: item['label']?.toString().trim() ?? '',
                    value: item['value']?.toString().trim() ?? '',
                    blocking:
                        item['severity']?.toString().trim().toLowerCase() ==
                        'blocking',
                    warning:
                        item['severity']?.toString().trim().toLowerCase() ==
                        'warning',
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TechnicalImageRequirements extends StatelessWidget {
  final ValueListenable<Map<String, dynamic>?> specificationListenable;
  final String sectionKey;

  const _TechnicalImageRequirements({
    required this.specificationListenable,
    required this.sectionKey,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: specificationListenable,
      builder: (context, specification, _) {
        if (specification == null) {
          return const SizedBox.shrink();
        }

        final items =
            TechnicalSpecificationContextEngine.items(
                  specification,
                  sectionKey: sectionKey,
                )
                .where((item) {
                  final label = item['label']?.toString().trim() ?? '';
                  final value = item['value']?.toString().trim() ?? '';
                  return label.isNotEmpty && value.isNotEmpty;
                })
                .toList(growable: false);

        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        final version = TechnicalSpecificationContextEngine.version(
          specification,
        );

        final sectionTitle = TechnicalSpecificationContextEngine.sectionTitle(
          specification,
          sectionKey,
        );

        final fallbackTitle = switch (sectionKey) {
          'poster' => 'Exigences Poster',
          'banner' => 'Exigences Bannière',
          _ => 'Exigences techniques',
        };

        final title = sectionTitle.isEmpty ? fallbackTitle : sectionTitle;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _TechnicalRequirementsAccordion(
            title: version.isEmpty ? title : '$title — V$version',
            children: [
              ...items.map(
                (item) => _TechnicalRequirementLine(
                  label: item['label']?.toString().trim() ?? '',
                  value: item['value']?.toString().trim() ?? '',
                  blocking: item['required'] == true,
                  warning: false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TechnicalRequirementLine extends StatelessWidget {
  const _TechnicalRequirementLine({
    required this.label,
    required this.value,
    required this.blocking,
    required this.warning,
  });

  final String label;
  final String value;
  final bool blocking;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final prefix = blocking
        ? 'Obligatoire'
        : warning
        ? 'Recommandé'
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: value),
                if (prefix != null)
                  TextSpan(
                    text: ' — $prefix',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TechnicalSubmissionValidationResult {
  const _TechnicalSubmissionValidationResult({
    required this.message,
    this.route,
  });

  final String message;
  final Future<void> Function()? route;
}

class UploadPage extends StatefulWidget {
  const UploadPage({super.key, this.contentId, this.onExit});

  final String? contentId;
  final VoidCallback? onExit;

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final _formKey = GlobalKey<FormState>();

  final ValueNotifier<Map<String, dynamic>?> _technicalSpecificationNotifier =
      ValueNotifier<Map<String, dynamic>?>(null);
  ContentType? _contentType;
  final titleController = TextEditingController();
  final originalTitleController = TextEditingController();
  final synopsisController = TextEditingController();
  final descriptionController = TextEditingController();
  final durationController = TextEditingController();

  String? selectedAgeRating;

  static const List<String> allLanguages = [
    'Français',
    'Anglais',
    'Arabe',
    'Portugais',
    'Espagnol',
    'Allemand',
    'Italien',
    'Dioula',
    'Bambara',
    'Baoulé',
    'Bété',
    'Sénoufo',
    'Wolof',
    'Lingala',
    'Swahili',
    'Haoussa',
    'Yoruba',
    'Igbo',
    'Peul',
    'Mooré',
    'Fon',
    'Ewé',
    'Akan',
    'Twi',
    'Amharique',
    'Somali',
    'Tamazight',
    'Malgache',
  ];

  final Set<String> selectedAudioLanguages = {};
  final Set<String> selectedSubtitleLanguages = {};

  static const List<String> allGenres = [
    'Action',
    'Aventure',
    'Comédie',
    'Drame',
    'Documentaire',
    'Télé-réalité',
    'Horreur',
    'Romance',
    'Science-Fiction',
    'Fantastique',
    'Thriller',
    'Animation',
    'Musical',
    'Biopic',
    'Famille',
    'Historique',
    'Policier',
    'Sport',
  ];
  final Set<String> selectedGenres = {};

  LanguageOption? selectedLanguage;
  final languageOtherController = TextEditingController();
  int? releaseYear;
  String? selectedCountry;
  final countryOtherController = TextEditingController();

  final statut = "En attente";
  final directorNameController = TextEditingController();
  String? directorImagePath;
  Uint8List? directorImageBytes;
  String? directorImageFilename;
  String? directorImageTempPath;
  String? directorImageUrl;
  String? directorImagePreviewUrl;

  final screenwriterNameController = TextEditingController();
  String? screenwriterImagePath;
  Uint8List? screenwriterImageBytes;
  String? screenwriterImageFilename;
  String? screenwriterImageTempPath;
  String? screenwriterImageUrl;
  String? screenwriterImagePreviewUrl;

  final List<PersonWithImage> producers = [];
  final List<PersonWithImage> actors = [];

  XFile? trailerFile;
  VideoPlayerController? trailerPlayerController;

  XFile? posterFile;
  XFile? bannerFile;
  XFile? videoFile;
  VideoPlayerController? videoPlayerController;

  String selectedDeliveryLevel = 'distribution';

  static const Map<String, String> deliveryLevelLabels = {
    'premium': 'Master Premium',
    'standard': 'Master Standard',
    'distribution': 'Master Distribution',
  };

  bool _isSubmitting = false;

  final GlobalKey<_TechnicalRequirementsAccordionState>
  _filmMasterRequirementsKey =
      GlobalKey<_TechnicalRequirementsAccordionState>();

  bool _isSavingDraft = false;
  bool _isPersistingMedia = false;
  bool _isLoadingDraft = false;
  String? _draftContentId;

  String? _savingStatus;

  Timer? _autoSaveTimer;
  bool _autoSaveRunning = false;
  bool _autoSavePending = false;
  // Modifié temporairement pendant l'application locale
  // des métadonnées XML.
  // ignore: prefer_final_fields
  bool _suppressAutoSave = false;
  bool _autoSaveDirty = false;
  bool _autoSaveBackoffActive = false;
  int _autoSaveFailureCount = 0;
  String? _autoSaveStatus;

  bool _serverHasPoster = false;
  bool _serverHasBackdrop = false;
  bool _serverHasTrailer = false;
  bool _serverHasMaster = false;

  TechnicalConformityReport? _movieTechnicalConformity;
  TechnicalConformityReport? _contentTrailerTechnicalConformity;

  // A5.11E-3B
  // Un seul timer central pour le rafraîchissement des rapports
  // techniques. Aucun polling périodique permanent.
  Timer? _technicalConformityRefreshTimer;
  int _technicalConformityRefreshStep = 0;
  bool _technicalConformityRefreshRunning = false;

  static const List<Duration> _technicalConformityRefreshDelays = [
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(seconds: 60),
  ];

  @override
  void initState() {
    super.initState();

    _loadTechnicalSpecification();

    titleController.addListener(_scheduleAutoSave);
    originalTitleController.addListener(_scheduleAutoSave);
    synopsisController.addListener(_scheduleAutoSave);
    descriptionController.addListener(_scheduleAutoSave);
    durationController.addListener(_scheduleAutoSave);
    languageOtherController.addListener(_scheduleAutoSave);
    countryOtherController.addListener(_scheduleAutoSave);
    directorNameController.addListener(_scheduleAutoSave);
    screenwriterNameController.addListener(_scheduleAutoSave);

    final contentId = widget.contentId?.trim();
    if (contentId != null && contentId.isNotEmpty) {
      _draftContentId = contentId;
      _loadDraft(contentId);
    }
  }

  Future<void> _loadTechnicalSpecification() async {
    try {
      final specification = await ProducerService.instance
          .getTechnicalSpecification();

      if (!mounted) {
        return;
      }

      _technicalSpecificationNotifier.value = specification;
    } catch (_) {
      if (!mounted) {
        return;
      }

      // Le formulaire reste utilisable si le cahier des charges
      // est momentanément indisponible. Aucune règle n'est
      // recopiée localement en fallback.
      _technicalSpecificationNotifier.value = null;
    }
  }

  final List<SeasonWrapper> seasons = [];
  final List<String> _deletedSeasonIds = [];

  final ImagePicker _picker = ImagePicker();

  bool _isLoadingXmlPreview = false;
  Map<String, dynamic>? _xmlMetadataPreview;
  String? _xmlMetadataFilename;

  static const List<String> africanCountries = [
    "Algérie",
    "Angola",
    "Bénin",
    "Botswana",
    "Burkina Faso",
    "Burundi",
    "Cameroun",
    "Cap-Vert",
    "République centrafricaine",
    "Tchad",
    "Comores",
    "République du Congo",
    "République démocratique du Congo",
    "Côte d'Ivoire",
    "Djibouti",
    "Égypte",
    "Guinée équatoriale",
    "Érythrée",
    "Eswatini",
    "Éthiopie",
    "Gabon",
    "Gambie",
    "Ghana",
    "Guinée",
    "Guinée-Bissau",
    "Kenya",
    "Lesotho",
    "Liberia",
    "Libye",
    "Madagascar",
    "Malawi",
    "Mali",
    "Mauritanie",
    "Maurice",
    "Maroc",
    "Mozambique",
    "Namibie",
    "Niger",
    "Nigéria",
    "Rwanda",
    "São Tomé-et-Príncipe",
    "Sénégal",
    "Seychelles",
    "Sierra Leone",
    "Somalie",
    "Afrique du Sud",
    "Soudan du Sud",
    "Soudan",
    "Tanzanie",
    "Togo",
    "Tunisie",
    "Ouganda",
    "Zambie",
    "Zimbabwe",
  ];

  Future<void> _downloadXmlTemplate() async {
    if (_contentType == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Type de contenu requis : sélectionnez Film ou Série '
            'avant de télécharger le modèle XML.',
          ),
        ),
      );
      return;
    }

    final isSeries = _contentType == ContentType.serie;

    final assetPath = isSeries
        ? 'assets/xml/modele-ekeflicks-serie.xml'
        : 'assets/xml/modele-ekeflicks-film.xml';

    final filename = isSeries
        ? 'modele-ekeflicks-serie.xml'
        : 'modele-ekeflicks-film.xml';

    try {
      final data = await rootBundle.load(assetPath);

      downloadXmlBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        filename,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de télécharger le modèle XML : $error'),
        ),
      );
    }
  }

  Future<void> _pickAndPreviewXmlMetadata() async {
    if (_isLoadingXmlPreview) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xml'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de lire le fichier XML sélectionné.'),
        ),
      );

      return;
    }

    setState(() {
      _isLoadingXmlPreview = true;
    });

    try {
      final preview = await ProducerService.instance.previewXmlMetadata(
        bytes: bytes,
        filename: file.name,
        contentId: _draftContentId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _xmlMetadataPreview = preview;
        _xmlMetadataFilename = file.name;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d’analyser le XML : $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingXmlPreview = false;
        });
      } else {
        _isLoadingXmlPreview = false;
      }
    }
  }

  List<PersonWithImage> _xmlPeopleWithPreservedImages(
    List<String> names,
    List<PersonWithImage> current,
  ) {
    final byName = <String, PersonWithImage>{};

    for (final person in current) {
      final key = person.name.trim().toLowerCase();

      if (key.isNotEmpty) {
        byName.putIfAbsent(key, () => person);
      }
    }

    return names.map((name) {
      final cleaned = name.trim();
      final existing = byName[cleaned.toLowerCase()];

      if (existing != null) {
        return PersonWithImage(
          name: cleaned,
          imagePath: existing.imagePath,
          imageBytes: existing.imageBytes,
          imageFilename: existing.imageFilename,
          imageTempPath: existing.imageTempPath,
          imageUrl: existing.imageUrl,
          previewUrl: existing.previewUrl,
        );
      }

      return PersonWithImage(name: cleaned);
    }).toList();
  }

  bool _xmlSeriesHasServerBackedStructure() {
    return seasons.any(
      (wrapper) => (wrapper.serverId?.trim() ?? '').isNotEmpty,
    );
  }

  List<SeasonWrapper> _buildXmlSeriesStructure(List<dynamic> rawSeasons) {
    final built = <SeasonWrapper>[];

    for (final rawSeason in rawSeasons) {
      if (rawSeason is! Map) {
        continue;
      }

      final rawSeasonNumber = rawSeason['season_number'];

      final seasonNumber = rawSeasonNumber is int
          ? rawSeasonNumber
          : int.tryParse(rawSeasonNumber?.toString() ?? '');

      if (seasonNumber == null || seasonNumber <= 0) {
        continue;
      }

      final initialEpisodes = <EpisodeInitialData>[];

      final rawEpisodes = rawSeason['episodes'];

      if (rawEpisodes is List) {
        for (final rawEpisode in rawEpisodes) {
          if (rawEpisode is! Map) {
            continue;
          }

          final rawEpisodeNumber = rawEpisode['episode_number'];

          final episodeNumber = rawEpisodeNumber is int
              ? rawEpisodeNumber
              : int.tryParse(rawEpisodeNumber?.toString() ?? '');

          if (episodeNumber == null || episodeNumber <= 0) {
            continue;
          }

          final rawDuration = rawEpisode['duration'];

          final duration = rawDuration is int
              ? rawDuration
              : int.tryParse(rawDuration?.toString() ?? '');

          initialEpisodes.add(
            EpisodeInitialData(
              serverId: '',
              episodeNumber: episodeNumber,
              title: rawEpisode['title']?.toString().trim() ?? '',
              description: rawEpisode['description']?.toString().trim() ?? '',
              duration: duration,
              serverHasVideo: false,
            ),
          );
        }
      }

      final key = GlobalKey<SeasonState>();

      late final SeasonWrapper wrapper;

      wrapper = SeasonWrapper(
        key: key,
        serverId: null,
        season: SeasonForm(
          key: key,
          technicalSpecificationListenable: _technicalSpecificationNotifier,
          deliveryLevel: selectedDeliveryLevel,
          seasonNumber: seasonNumber,
          initialTitle: rawSeason['title']?.toString().trim() ?? '',
          initialDescription: rawSeason['description']?.toString().trim() ?? '',
          initialServerHasPoster: false,
          initialServerHasBackdrop: false,
          initialServerHasTrailer: false,
          initialEpisodes: initialEpisodes,
          onChanged: () => _scheduleAutoSave(),
          onRetryTrailerAnalysis: () => _retrySeasonTrailerAnalysis(wrapper),
          onRemove: () {
            setState(() {
              seasons.removeWhere((item) => identical(item, wrapper));
            });

            _scheduleAutoSave(immediate: true);
          },
        ),
      );

      built.add(wrapper);
    }

    return built;
  }

  void _applyXmlMetadataToForm() {
    final preview = _xmlMetadataPreview;

    if (preview == null) {
      return;
    }

    if (_autoSaveRunning ||
        _isSavingDraft ||
        _isPersistingMedia ||
        _isSubmitting ||
        _isLoadingDraft) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Une sauvegarde est en cours. '
            'Réessayez une fois celle-ci terminée.',
          ),
        ),
      );
      return;
    }

    final recognized = preview['recognized'];

    final recognizedMap = recognized is Map
        ? Map<String, dynamic>.from(recognized)
        : <String, dynamic>{};

    final rawContent = recognizedMap['content'];

    final rawSeasons = recognizedMap['seasons'];

    final content = rawContent is Map
        ? Map<String, dynamic>.from(rawContent)
        : <String, dynamic>{};

    final hasTitle = content.containsKey('title');
    final hasOriginalTitle = content.containsKey('original_title');
    final hasSynopsis = content.containsKey('synopsis');
    final hasDescription = content.containsKey('description');
    final hasDuration = content.containsKey('duration');
    final hasAgeRating = content.containsKey('age_rating');
    final hasReleaseYear = content.containsKey('release_year');
    final hasGenres = content.containsKey('genres');
    final hasAudioLanguages = content.containsKey('audio_languages');
    final hasSubtitleLanguages = content.containsKey('subtitle_languages');
    final hasLanguage = content.containsKey('language');
    final hasCountry = content.containsKey('country');
    final hasDirectors = content.containsKey('directors');
    final hasScreenwriters = content.containsKey('screenwriters');
    final hasProducers = content.containsKey('producers');
    final hasCast = content.containsKey('cast');

    String textValue(String key) {
      final raw = content[key];

      if (raw == null) {
        return '';
      }

      return raw.toString().trim();
    }

    List<String> listValue(String key) {
      final raw = content[key];

      if (raw is! List) {
        return <String>[];
      }

      final values = <String>[];
      final seen = <String>{};

      for (final item in raw) {
        final cleaned = item.toString().trim();

        if (cleaned.isEmpty) {
          continue;
        }

        final normalized = cleaned.toLowerCase();

        if (seen.add(normalized)) {
          values.add(cleaned);
        }
      }

      return values;
    }

    final type = textValue('type').toLowerCase();

    final mappedType = switch (type) {
      'movie' => ContentType.film,
      'series' => ContentType.serie,
      _ => null,
    };

    final hasXmlSeriesStructure =
        mappedType == ContentType.serie &&
        rawSeasons is List &&
        rawSeasons.isNotEmpty;

    final seriesStructureBlocked =
        hasXmlSeriesStructure && _xmlSeriesHasServerBackedStructure();

    final xmlSeriesStructure = hasXmlSeriesStructure && !seriesStructureBlocked
        ? _buildXmlSeriesStructure(List<dynamic>.from(rawSeasons))
        : <SeasonWrapper>[];

    final language = textValue('language');

    LanguageOption? mappedLanguage;
    var mappedOtherLanguage = '';

    switch (language.toLowerCase()) {
      case 'français':
      case 'francais':
        mappedLanguage = LanguageOption.francais;
        break;

      case 'anglais':
      case 'english':
        mappedLanguage = LanguageOption.anglais;
        break;

      case '':
        mappedLanguage = null;
        break;

      default:
        mappedLanguage = LanguageOption.autres;
        mappedOtherLanguage = language;
    }

    final country = textValue('country');

    String? mappedCountry;
    var mappedOtherCountry = '';

    if (country.isEmpty) {
      mappedCountry = null;
    } else if (africanCountries.contains(country)) {
      mappedCountry = country;
    } else {
      mappedCountry = 'Autres';
      mappedOtherCountry = country;
    }

    final releaseYearValue = int.tryParse(textValue('release_year'));

    final durationValue = int.tryParse(textValue('duration'));

    final requestedGenres = listValue('genres');

    final genres = requestedGenres.where(allGenres.contains).toSet();

    final audioLanguages = listValue('audio_languages').toSet();

    final subtitleLanguages = listValue('subtitle_languages').toSet();

    final directors = listValue('directors');
    final screenwriters = listValue('screenwriters');
    final producersValues = listValue('producers');
    final castValues = listValue('cast');

    final newDirectorName = directors.isEmpty ? '' : directors.first;

    final oldDirectorName = directorNameController.text.trim();

    final preserveDirectorImage =
        oldDirectorName.isNotEmpty &&
        newDirectorName.isNotEmpty &&
        oldDirectorName.toLowerCase() == newDirectorName.toLowerCase();

    final newScreenwriterName = screenwriters.isEmpty
        ? ''
        : screenwriters.first;

    final oldScreenwriterName = screenwriterNameController.text.trim();

    final preserveScreenwriterImage =
        oldScreenwriterName.isNotEmpty &&
        newScreenwriterName.isNotEmpty &&
        oldScreenwriterName.toLowerCase() == newScreenwriterName.toLowerCase();

    final xmlProducers = _xmlPeopleWithPreservedImages(
      producersValues,
      producers,
    );

    final xmlActors = _xmlPeopleWithPreservedImages(castValues, actors);

    // Aucun autosave déjà planifié ne doit pouvoir
    // persister les valeurs XML après leur application.
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    _autoSavePending = false;
    _autoSaveDirty = false;

    _suppressAutoSave = true;

    try {
      setState(() {
        if (mappedType != null) {
          _contentType = mappedType;
        }

        if (hasTitle) {
          titleController.text = textValue('title');
        }

        if (hasOriginalTitle) {
          originalTitleController.text = textValue('original_title');
        }

        if (hasSynopsis) {
          synopsisController.text = textValue('synopsis');
        }

        if (hasDescription) {
          descriptionController.text = textValue('description');
        }

        if (hasDuration) {
          durationController.text = durationValue?.toString() ?? '';
        }

        if (hasAgeRating) {
          final ageRating = textValue('age_rating');
          selectedAgeRating = ageRating.isEmpty ? null : ageRating;
        }

        if (hasReleaseYear) {
          releaseYear = releaseYearValue;
        }

        if (hasGenres) {
          selectedGenres
            ..clear()
            ..addAll(genres);
        }

        if (hasAudioLanguages) {
          selectedAudioLanguages
            ..clear()
            ..addAll(audioLanguages);
        }

        if (hasSubtitleLanguages) {
          selectedSubtitleLanguages
            ..clear()
            ..addAll(subtitleLanguages);
        }

        if (hasLanguage) {
          selectedLanguage = mappedLanguage;
          languageOtherController.text = mappedOtherLanguage;
        }

        if (hasCountry) {
          selectedCountry = mappedCountry;
          countryOtherController.text = mappedOtherCountry;
        }

        if (hasDirectors) {
          directorNameController.text = newDirectorName;

          if (!preserveDirectorImage) {
            directorImagePath = null;
            directorImageBytes = null;
            directorImageFilename = null;
            directorImageTempPath = null;
            directorImageUrl = null;
            directorImagePreviewUrl = null;
          }
        }

        if (hasScreenwriters) {
          screenwriterNameController.text = newScreenwriterName;

          if (!preserveScreenwriterImage) {
            screenwriterImagePath = null;
            screenwriterImageBytes = null;
            screenwriterImageFilename = null;
            screenwriterImageTempPath = null;
            screenwriterImageUrl = null;
            screenwriterImagePreviewUrl = null;
          }
        }

        if (hasProducers) {
          producers
            ..clear()
            ..addAll(xmlProducers);
        }

        if (hasCast) {
          actors
            ..clear()
            ..addAll(xmlActors);
        }

        if (hasXmlSeriesStructure && !seriesStructureBlocked) {
          seasons
            ..clear()
            ..addAll(xmlSeriesStructure);
        }
      });
    } finally {
      _suppressAutoSave = false;
    }

    setState(() {
      _xmlMetadataPreview = null;
      _xmlMetadataFilename = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          seriesStructureBlocked
              ? 'Métadonnées XML appliquées au formulaire. '
                    'La structure saisons/épisodes déjà enregistrée '
                    'n’a pas été remplacée. Vérifiez-la avant de sauvegarder.'
              : 'Métadonnées XML appliquées au formulaire. '
                    'Vérifiez les informations avant de sauvegarder.',
        ),
      ),
    );
  }

  Widget _buildXmlMetadataPreviewCard() {
    final preview = _xmlMetadataPreview;

    if (preview == null) {
      return const SizedBox.shrink();
    }

    final recognized = preview['recognized'];

    final recognizedMap = recognized is Map
        ? Map<String, dynamic>.from(recognized)
        : <String, dynamic>{};

    final rawContent = recognizedMap['content'];

    final content = rawContent is Map
        ? Map<String, dynamic>.from(rawContent)
        : <String, dynamic>{};

    final rawWarnings = preview['warnings'];

    final warnings = rawWarnings is List ? rawWarnings : const <dynamic>[];

    final rawUnresolvedGenres = preview['unresolved_genres'];

    final unresolvedGenres = rawUnresolvedGenres is List
        ? rawUnresolvedGenres
        : const <dynamic>[];

    String value(String key) {
      final raw = content[key];

      if (raw == null) {
        return '';
      }

      if (raw is List) {
        return raw.map((item) => item.toString()).join(', ');
      }

      return raw.toString();
    }

    final rows = <MapEntry<String, String>>[
      MapEntry('Type', value('type')),
      MapEntry('Titre', value('title')),
      MapEntry('Titre original', value('original_title')),
      MapEntry('Synopsis', value('synopsis')),
      MapEntry('Synopsis long', value('description')),
      MapEntry('Année', value('release_year')),
      MapEntry('Classification', value('age_rating')),
      MapEntry('Durée', value('duration')),
      MapEntry('Langue originale', value('language')),
      MapEntry('Langues audio', value('audio_languages')),
      MapEntry('Sous-titres', value('subtitle_languages')),
      MapEntry('Pays', value('country')),
      MapEntry('Genres', value('genres')),
      MapEntry('Réalisateur', value('directors')),
      MapEntry('Scénariste', value('screenwriters')),
      MapEntry('Producteurs', value('producers')),
      MapEntry('Casting', value('cast')),
    ].where((entry) => entry.value.trim().isNotEmpty).toList();

    return Card(
      margin: const EdgeInsets.only(top: 16, bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _xmlMetadataFilename == null
                        ? 'Prévisualisation XML'
                        : 'Prévisualisation XML — '
                              '$_xmlMetadataFilename',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fermer',
                  onPressed: () {
                    setState(() {
                      _xmlMetadataPreview = null;
                      _xmlMetadataFilename = null;
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Aucune donnée n’a encore été appliquée '
              'au formulaire.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _isBusy || _autoSaveRunning
                    ? null
                    : _applyXmlMetadataToForm,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('APPLIQUER AU FORMULAIRE'),
              ),
            ),
            const SizedBox(height: 16),
            ...rows.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      TextSpan(
                        text: '${entry.key} : ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: entry.value),
                    ],
                  ),
                ),
              ),
            ),
            if (unresolvedGenres.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Genres non reconnus',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(unresolvedGenres.map((item) => item.toString()).join(', ')),
            ],
            if (warnings.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Avertissements',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ...warnings.map((warning) {
                if (warning is Map) {
                  final map = Map<String, dynamic>.from(warning);

                  final message = map['message']?.toString().trim() ?? '';

                  final code = map['code']?.toString().trim() ?? '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(message.isNotEmpty ? '• $message' : '• $code'),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• ${warning.toString()}'),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Future<XFile?> _pickImageFile() {
    return _picker.pickImage(source: ImageSource.gallery);
  }

  Future<XFile?> _pickVideoFile() {
    return _picker.pickVideo(source: ImageSource.gallery);
  }

  Future<void> _pickTrailer() async {
    final picked = await _pickVideoFile();
    if (picked == null) return;

    trailerPlayerController?.dispose();

    trailerPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(picked.path),
    );
    await trailerPlayerController!.initialize();
    await trailerPlayerController!.setLooping(true);
    await trailerPlayerController!.play();

    if (!mounted) return;

    setState(() => trailerFile = picked);
    _scheduleAutoSave(immediate: true);
  }

  Future<void> _addProducer() async {
    final nameC = TextEditingController();
    String? pickedImagePath;
    Uint8List? pickedImageBytes;
    String? pickedImageFilename;

    final person = await showDialog<PersonWithImage>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addProducerTitle),
        content: StatefulBuilder(
          builder: (context, setLocal) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameC,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.nameLabel,
                ),
              ),
              const SizedBox(height: 12),
              if (pickedImageBytes != null) ...[
                CircleAvatar(
                  radius: 38,
                  backgroundImage: MemoryImage(pickedImageBytes!),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picked = await _pickImageFile();

                      if (picked == null) return;

                      final bytes = await picked.readAsBytes();

                      if (bytes.isEmpty) return;

                      setLocal(() {
                        pickedImagePath = picked.path;
                        pickedImageBytes = bytes;
                        pickedImageFilename = picked.name;
                      });
                    },
                    icon: const Icon(Icons.add_a_photo),
                    label: Text(AppLocalizations.of(context)!.addImageButton),
                  ),
                  const SizedBox(width: 8),
                  if (pickedImagePath != null)
                    Flexible(
                      child: Text(
                        pickedImagePath!.split('/').last,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancelButton),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameC.text.trim();

              if (name.isEmpty) return;

              Navigator.pop(
                dialogContext,
                PersonWithImage(
                  name: name,
                  imagePath: pickedImagePath,
                  imageBytes: pickedImageBytes,
                  imageFilename: pickedImageFilename,
                ),
              );
            },
            child: Text(AppLocalizations.of(context)!.addButton),
          ),
        ],
      ),
    );

    if (!mounted || person == null) {
      return;
    }

    setState(() {
      producers.add(person);
    });
  }

  Future<void> _addActor() async {
    final nameC = TextEditingController();
    String? pickedImagePath;
    Uint8List? pickedImageBytes;
    String? pickedImageFilename;

    final person = await showDialog<PersonWithImage>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addActorTitle),
        content: StatefulBuilder(
          builder: (context, setLocal) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameC,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.nameLabel,
                ),
              ),
              const SizedBox(height: 12),
              if (pickedImageBytes != null) ...[
                CircleAvatar(
                  radius: 38,
                  backgroundImage: MemoryImage(pickedImageBytes!),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picked = await _pickImageFile();

                      if (picked == null) return;

                      final bytes = await picked.readAsBytes();

                      if (bytes.isEmpty) return;

                      setLocal(() {
                        pickedImagePath = picked.path;
                        pickedImageBytes = bytes;
                        pickedImageFilename = picked.name;
                      });
                    },
                    icon: const Icon(Icons.add_a_photo),
                    label: Text(AppLocalizations.of(context)!.addImageButton),
                  ),
                  const SizedBox(width: 8),
                  if (pickedImagePath != null)
                    Flexible(
                      child: Text(
                        pickedImagePath!.split('/').last,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancelButton),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameC.text.trim();

              if (name.isEmpty) return;

              Navigator.pop(
                dialogContext,
                PersonWithImage(
                  name: name,
                  imagePath: pickedImagePath,
                  imageBytes: pickedImageBytes,
                  imageFilename: pickedImageFilename,
                ),
              );
            },
            child: Text(AppLocalizations.of(context)!.addButton),
          ),
        ],
      ),
    );

    if (!mounted || person == null) {
      return;
    }

    setState(() {
      actors.add(person);
    });
  }

  Future<void> _pickPersonImageFor(String which) async {
    final picked = await _pickImageFile();

    if (picked == null) {
      return;
    }

    final bytes = await picked.readAsBytes();

    if (bytes.isEmpty || !mounted) {
      return;
    }

    setState(() {
      if (which == 'director') {
        directorImagePath = picked.path;
        directorImageBytes = bytes;
        directorImageFilename = picked.name;
        directorImageTempPath = null;
        directorImageUrl = null;
        directorImagePreviewUrl = null;
      }

      if (which == 'screenwriter') {
        screenwriterImagePath = picked.path;
        screenwriterImageBytes = bytes;
        screenwriterImageFilename = picked.name;
        screenwriterImageTempPath = null;
        screenwriterImageUrl = null;
        screenwriterImagePreviewUrl = null;
      }
    });
  }

  ImageProvider<Object>? _primaryPersonImageProvider(String which) {
    if (which == 'director') {
      final bytes = directorImageBytes;

      if (bytes != null && bytes.isNotEmpty) {
        return MemoryImage(bytes);
      }

      final finalUrl = directorImageUrl?.trim() ?? '';

      if (finalUrl.isNotEmpty) {
        return NetworkImage(finalUrl);
      }

      final previewUrl = directorImagePreviewUrl?.trim() ?? '';

      if (previewUrl.isNotEmpty) {
        return NetworkImage(previewUrl);
      }

      final localPath = directorImagePath?.trim() ?? '';

      if (localPath.isNotEmpty) {
        return FileImage(File(localPath));
      }

      return null;
    }

    final bytes = screenwriterImageBytes;

    if (bytes != null && bytes.isNotEmpty) {
      return MemoryImage(bytes);
    }

    final finalUrl = screenwriterImageUrl?.trim() ?? '';

    if (finalUrl.isNotEmpty) {
      return NetworkImage(finalUrl);
    }

    final previewUrl = screenwriterImagePreviewUrl?.trim() ?? '';

    if (previewUrl.isNotEmpty) {
      return NetworkImage(previewUrl);
    }

    final localPath = screenwriterImagePath?.trim() ?? '';

    if (localPath.isNotEmpty) {
      return FileImage(File(localPath));
    }

    return null;
  }

  void _addSeason() {
    final nextNumber = seasons.isEmpty
        ? 1
        : seasons
                  .map((wrapper) => wrapper.season.seasonNumber)
                  .reduce((a, b) => a > b ? a : b) +
              1;

    final key = GlobalKey<SeasonState>();

    late final SeasonWrapper wrapper;

    wrapper = SeasonWrapper(
      key: key,
      season: SeasonForm(
        key: key,
        technicalSpecificationListenable: _technicalSpecificationNotifier,
        deliveryLevel: selectedDeliveryLevel,
        seasonNumber: nextNumber,
        onChanged: () => _scheduleAutoSave(),
        onRetryTrailerAnalysis: () => _retrySeasonTrailerAnalysis(wrapper),
        onRemove: () {
          final serverId = wrapper.serverId?.trim() ?? '';

          setState(() {
            if (serverId.isNotEmpty) {
              _deletedSeasonIds.add(serverId);
            }

            seasons.removeWhere((item) => identical(item, wrapper));
          });

          _scheduleAutoSave(immediate: true);
        },
      ),
    );

    setState(() => seasons.add(wrapper));
    _scheduleAutoSave(immediate: true);
  }

  Future<void> _pickGlobalPoster(bool isPoster) async {
    final picked = await _pickImageFile();
    if (picked == null || !mounted) return;

    setState(() {
      if (isPoster) {
        posterFile = picked;
      } else {
        bannerFile = picked;
      }
    });

    _scheduleAutoSave(immediate: true);
  }

  Future<void> _pickGlobalVideo() async {
    final picked = await _pickVideoFile();
    if (picked == null) return;

    videoPlayerController?.dispose();
    videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(picked.path),
    );
    await videoPlayerController!.initialize();
    await videoPlayerController!.setLooping(true);
    await videoPlayerController!.play();

    if (!mounted) return;

    setState(() => videoFile = picked);
    _scheduleAutoSave(immediate: true);
  }

  bool get _isBusy =>
      _isSavingDraft || _isPersistingMedia || _isSubmitting || _isLoadingDraft;

  void _setSavingStatus(String? value) {
    if (!mounted) {
      _savingStatus = value;
      return;
    }

    setState(() => _savingStatus = value);
  }

  Future<void> _persistVideoAssetDeliveryLevel(String contentId) async {
    // Le niveau global appartient uniquement au master d'un film.
    // Pour une série, chaque épisode possède son propre VideoAsset
    // et donc son propre delivery_level.
    if (_contentType != ContentType.film) {
      return;
    }

    final service = ProducerService.instance;

    var assets = await service.getMyVideoAssets(contentId: contentId);

    assets = assets.where((asset) {
      final episode = asset['episode'];
      return episode == null || episode.toString().trim().isEmpty;
    }).toList();

    if (assets.isEmpty) {
      return;
    }

    final expectedLevel = selectedDeliveryLevel.trim().toLowerCase();

    if (!deliveryLevelLabels.containsKey(expectedLevel)) {
      throw StateError('Niveau de livraison master invalide.');
    }

    for (final asset in assets) {
      final assetId = asset['id']?.toString().trim() ?? '';

      if (assetId.isEmpty) {
        continue;
      }

      final currentLevel =
          asset['delivery_level']?.toString().trim().toLowerCase() ??
          'distribution';

      if (currentLevel == expectedLevel) {
        continue;
      }

      _setSavingStatus('Mise à jour du niveau technique du master…');

      await service.updateVideoAssetDeliveryLevel(
        assetId: assetId,
        deliveryLevel: expectedLevel,
      );
    }
  }

  Future<void> _persistPrimaryPersonImages(String contentId) async {
    final service = ProducerService.instance;

    final directorBytes = directorImageBytes;
    final directorFilename = directorImageFilename?.trim() ?? '';

    if (directorBytes != null &&
        directorBytes.isNotEmpty &&
        (directorImageTempPath?.trim().isEmpty ?? true)) {
      _setSavingStatus('Envoi de la photo du réalisateur…');

      final response = await service.uploadPrimaryPersonImage(
        contentId: contentId,
        role: 'director',
        bytes: directorBytes,
        filename: directorFilename.isNotEmpty
            ? directorFilename
            : 'director.jpg',
      );

      final temporaryPath = response['temporary_path']?.toString().trim();

      if (temporaryPath == null || temporaryPath.isEmpty) {
        throw StateError(
          'Le serveur n’a pas retourné le chemin TEMP '
          'de la photo du réalisateur.',
        );
      }

      directorImageTempPath = temporaryPath;
      directorImageUrl = null;
      directorImagePreviewUrl = null;
    }

    final screenwriterBytes = screenwriterImageBytes;
    final screenwriterFilename = screenwriterImageFilename?.trim() ?? '';

    if (screenwriterBytes != null &&
        screenwriterBytes.isNotEmpty &&
        (screenwriterImageTempPath?.trim().isEmpty ?? true)) {
      _setSavingStatus('Envoi de la photo du scénariste…');

      final response = await service.uploadPrimaryPersonImage(
        contentId: contentId,
        role: 'screenwriter',
        bytes: screenwriterBytes,
        filename: screenwriterFilename.isNotEmpty
            ? screenwriterFilename
            : 'screenwriter.jpg',
      );

      final temporaryPath = response['temporary_path']?.toString().trim();

      if (temporaryPath == null || temporaryPath.isEmpty) {
        throw StateError(
          'Le serveur n’a pas retourné le chemin TEMP '
          'de la photo du scénariste.',
        );
      }

      screenwriterImageTempPath = temporaryPath;
      screenwriterImageUrl = null;
      screenwriterImagePreviewUrl = null;
    }
  }

  Future<void> _persistTeamImages(String contentId) async {
    final service = ProducerService.instance;

    Future<void> persistMembers(
      List<PersonWithImage> members,
      String roleLabel,
      String filenamePrefix,
    ) async {
      for (var index = 0; index < members.length; index++) {
        final person = members[index];

        if (person.hasPersistedImage) {
          continue;
        }

        var bytes = person.imageBytes;

        if (bytes == null || bytes.isEmpty) {
          final localPath = person.imagePath?.trim();

          if (localPath == null || localPath.isEmpty) {
            continue;
          }

          bytes = await XFile(localPath).readAsBytes();
        }

        if (bytes.isEmpty) {
          throw StateError('La photo de ${person.name} est vide.');
        }

        _setSavingStatus(
          'Envoi de la photo $roleLabel '
          '${index + 1}/${members.length}…',
        );

        final explicitFilename = person.imageFilename?.trim() ?? '';

        final filename = explicitFilename.isNotEmpty
            ? explicitFilename
            : '${filenamePrefix}_${index + 1}.jpg';

        final response = await service.uploadTeamImage(
          contentId: contentId,
          bytes: bytes,
          filename: filename,
        );

        final temporaryPath = response['temporary_path']?.toString().trim();

        if (temporaryPath == null || temporaryPath.isEmpty) {
          throw StateError(
            'Le serveur n’a pas retourné le chemin TEMP '
            'de la photo de ${person.name}.',
          );
        }

        members[index] = PersonWithImage(
          name: person.name,
          imagePath: person.imagePath,
          imageBytes: person.imageBytes,
          imageFilename: person.imageFilename,
          imageTempPath: temporaryPath,
          imageUrl: person.imageUrl,
          previewUrl: person.previewUrl,
        );
      }
    }

    await persistMembers(producers, 'du producteur', 'producer');

    await persistMembers(actors, 'de l’acteur', 'actor');
  }

  bool _technicalConformityNeedsRefresh(TechnicalConformityReport? report) {
    if (report == null) {
      return true;
    }

    final status = report.analysisStatus.trim().toLowerCase();

    return status == 'not_started' ||
        status == 'pending' ||
        status == 'analyzing';
  }

  bool _hasTechnicalConformityPending() {
    if (_serverHasTrailer &&
        _technicalConformityNeedsRefresh(_contentTrailerTechnicalConformity)) {
      return true;
    }

    if (_contentType == ContentType.film) {
      return _serverHasMaster &&
          _technicalConformityNeedsRefresh(_movieTechnicalConformity);
    }

    if (_contentType != ContentType.serie) {
      return false;
    }

    for (final seasonWrapper in seasons) {
      final seasonState = seasonWrapper.key.currentState;

      if (seasonState == null) {
        continue;
      }

      if (seasonState.serverHasTrailer &&
          _technicalConformityNeedsRefresh(
            seasonState.trailerTechnicalConformity,
          )) {
        return true;
      }

      for (final episodeWrapper in seasonState.episodes) {
        final episodeState = episodeWrapper.key.currentState;

        if (episodeState == null || !episodeState.serverHasVideo) {
          continue;
        }

        if (_technicalConformityNeedsRefresh(
          episodeState.technicalConformity,
        )) {
          return true;
        }
      }
    }

    return false;
  }

  void _cancelTechnicalConformityRefresh() {
    _technicalConformityRefreshTimer?.cancel();
    _technicalConformityRefreshTimer = null;
    _technicalConformityRefreshStep = 0;
  }

  void _startTechnicalConformityRefresh() {
    if (!mounted || !_hasTechnicalConformityPending()) {
      return;
    }

    // Une nouvelle analyse repart du début de la séquence.
    _technicalConformityRefreshTimer?.cancel();
    _technicalConformityRefreshTimer = null;
    _technicalConformityRefreshStep = 0;

    _scheduleNextTechnicalConformityRefresh();
  }

  void _scheduleNextTechnicalConformityRefresh() {
    if (!mounted ||
        _technicalConformityRefreshRunning ||
        !_hasTechnicalConformityPending()) {
      return;
    }

    if (_technicalConformityRefreshStep >=
        _technicalConformityRefreshDelays.length) {
      _technicalConformityRefreshTimer = null;
      return;
    }

    final delay =
        _technicalConformityRefreshDelays[_technicalConformityRefreshStep];

    _technicalConformityRefreshStep++;

    _technicalConformityRefreshTimer?.cancel();

    _technicalConformityRefreshTimer = Timer(delay, () {
      _technicalConformityRefreshTimer = null;
      _refreshTechnicalConformity();
    });
  }

  Future<void> _refreshTechnicalConformity() async {
    if (!mounted || _technicalConformityRefreshRunning) {
      return;
    }

    final contentId = _draftContentId?.trim();

    if (contentId == null ||
        contentId.isEmpty ||
        !_hasTechnicalConformityPending()) {
      _cancelTechnicalConformityRefresh();
      return;
    }

    // Ne pas ajouter de trafic technique pendant une opération
    // d'enregistrement/upload/soumission déjà active.
    if (_isBusy || _autoSaveRunning) {
      _scheduleNextTechnicalConformityRefresh();
      return;
    }

    _technicalConformityRefreshRunning = true;

    try {
      final service = ProducerService.instance;

      // ------------------------------------------------------
      // TRAILER GLOBAL CONTENT
      // ------------------------------------------------------
      if (_serverHasTrailer &&
          _technicalConformityNeedsRefresh(
            _contentTrailerTechnicalConformity,
          )) {
        final content = await service.getContent(contentId);

        if (!mounted) {
          return;
        }

        setState(() {
          _contentTrailerTechnicalConformity =
              TechnicalConformityReport.fromTrailerOwner(content);
        });
      }

      // ------------------------------------------------------
      // MASTER FILM
      // ------------------------------------------------------
      if (_contentType == ContentType.film) {
        if (_serverHasMaster &&
            _technicalConformityNeedsRefresh(_movieTechnicalConformity)) {
          var assets = await service.getMyVideoAssets(contentId: contentId);

          assets = assets.where((asset) {
            final episode = asset['episode'];

            return episode == null || episode.toString().trim().isEmpty;
          }).toList();

          final uploadedAsset = _firstUploadedVideoAsset(assets);

          if (!mounted) {
            return;
          }

          setState(() {
            _movieTechnicalConformity = uploadedAsset == null
                ? null
                : TechnicalConformityReport.fromVideoAsset(uploadedAsset);
          });
        }
      } else if (_contentType == ContentType.serie) {
        // ----------------------------------------------------
        // TRAILERS SAISONS
        // ----------------------------------------------------
        var seasonTrailerRefreshNeeded = false;

        for (final wrapper in seasons) {
          final state = wrapper.key.currentState;

          if (state != null &&
              state.serverHasTrailer &&
              _technicalConformityNeedsRefresh(
                state.trailerTechnicalConformity,
              )) {
            seasonTrailerRefreshNeeded = true;
            break;
          }
        }

        if (seasonTrailerRefreshNeeded) {
          final rawSeasons = await service.getSeasons(contentId: contentId);

          final seasonsById = <String, Map<String, dynamic>>{};

          for (final rawSeason in rawSeasons) {
            final id = rawSeason['id']?.toString().trim() ?? '';

            if (id.isNotEmpty) {
              seasonsById[id] = rawSeason;
            }
          }

          for (final wrapper in seasons) {
            if (!mounted) {
              return;
            }

            final state = wrapper.key.currentState;
            final seasonId = wrapper.serverId?.trim() ?? '';

            if (state == null ||
                seasonId.isEmpty ||
                !state.serverHasTrailer ||
                !_technicalConformityNeedsRefresh(
                  state.trailerTechnicalConformity,
                )) {
              continue;
            }

            final rawSeason = seasonsById[seasonId];

            if (rawSeason == null) {
              continue;
            }

            state.setTrailerTechnicalConformity(
              TechnicalConformityReport.fromTrailerOwner(rawSeason),
            );
          }
        }

        // ----------------------------------------------------
        // MASTERS EPISODES — LOGIQUE EXISTANTE
        // ----------------------------------------------------
        for (final seasonWrapper in seasons) {
          if (!mounted) {
            return;
          }

          final seasonState = seasonWrapper.key.currentState;

          if (seasonState == null) {
            continue;
          }

          for (final episodeWrapper in seasonState.episodes) {
            if (!mounted) {
              return;
            }

            final episodeState = episodeWrapper.key.currentState;

            if (episodeState == null ||
                !episodeState.serverHasVideo ||
                !_technicalConformityNeedsRefresh(
                  episodeState.technicalConformity,
                )) {
              continue;
            }

            final episodeId = episodeWrapper.serverId?.trim() ?? '';

            if (episodeId.isEmpty) {
              continue;
            }

            final assets = await service.getMyVideoAssets(
              contentId: contentId,
              episodeId: episodeId,
            );

            final uploadedAsset = _firstUploadedVideoAsset(assets);

            if (!mounted) {
              return;
            }

            episodeState.setServerVideoAsset(uploadedAsset);
          }
        }
      }
    } catch (_) {
      // Le rafraîchissement technique reste informatif.
      // Une erreur réseau ne doit ni casser le brouillon ni
      // provoquer une rafale de requêtes.
    } finally {
      _technicalConformityRefreshRunning = false;

      if (mounted && _hasTechnicalConformityPending()) {
        _scheduleNextTechnicalConformityRefresh();
      } else {
        _cancelTechnicalConformityRefresh();
      }
    }
  }

  Future<void> _retryContentTrailerAnalysis() async {
    final contentId = _draftContentId?.trim() ?? '';

    if (contentId.isEmpty || _isBusy) {
      return;
    }

    try {
      await ProducerService.instance.retryTrailerAnalysis(contentId: contentId);

      if (!mounted) {
        return;
      }

      setState(() {
        _contentTrailerTechnicalConformity =
            TechnicalConformityReport.fromTrailerOwner(<String, dynamic>{
              'trailer_analysis_status': 'pending',
              'trailer_technical_conformity': null,
            });
      });

      _startTechnicalConformityRefresh();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de relancer l’analyse de la bande-annonce : $error',
          ),
        ),
      );
    }
  }

  Future<void> _retrySeasonTrailerAnalysis(SeasonWrapper wrapper) async {
    final seasonId = wrapper.serverId?.trim() ?? '';
    final state = wrapper.key.currentState;

    if (seasonId.isEmpty || state == null || _isBusy) {
      return;
    }

    try {
      await ProducerService.instance.retrySeasonTrailerAnalysis(
        seasonId: seasonId,
      );

      if (!mounted) {
        return;
      }

      state.setTrailerTechnicalConformity(
        TechnicalConformityReport.fromTrailerOwner(<String, dynamic>{
          'trailer_analysis_status': 'pending',
          'trailer_technical_conformity': null,
        }),
      );

      _startTechnicalConformityRefresh();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de relancer l’analyse du trailer de la saison : $error',
          ),
        ),
      );
    }
  }

  void _scheduleAutoSave({bool immediate = false}) {
    if (_suppressAutoSave || _isLoadingDraft || _isSubmitting) {
      return;
    }

    _autoSaveDirty = true;

    // Une modification effectuée pendant un backoff reste bien
    // marquée comme non enregistrée, mais elle ne doit jamais
    // raccourcir le délai de reprise après une erreur serveur.
    if (_autoSaveBackoffActive) {
      return;
    }

    _autoSaveTimer?.cancel();

    _autoSaveTimer = Timer(
      immediate
          ? const Duration(milliseconds: 350)
          : const Duration(seconds: 3),
      _runAutoSave,
    );
  }

  Future<void> _runAutoSave() async {
    if (!mounted || _suppressAutoSave || _isLoadingDraft || _isSubmitting) {
      return;
    }

    if (_contentType == null || titleController.text.trim().isEmpty) {
      return;
    }

    if (_autoSaveRunning || _isSavingDraft || _isPersistingMedia) {
      _autoSavePending = true;
      return;
    }

    _autoSaveRunning = true;
    _autoSavePending = false;
    _autoSaveDirty = false;

    var autoSaveFailed = false;

    setState(() {
      _autoSaveStatus = 'Enregistrement automatique…';
    });

    try {
      final draftId = await _saveDraft(showConfirmation: false);

      if (draftId != null && draftId.isNotEmpty) {
        await _persistDraftMedia(draftId);
      }

      if (mounted) {
        setState(() {
          _autoSaveStatus = 'Toutes les modifications sont enregistrées';
        });
      }
    } catch (_) {
      autoSaveFailed = true;
      _autoSaveDirty = true;

      if (mounted) {
        setState(() {
          _autoSaveStatus =
              'Sauvegarde automatique interrompue — nouvelle tentative';
        });
      }
    } finally {
      _autoSaveRunning = false;

      _autoSaveTimer?.cancel();

      if (autoSaveFailed) {
        _autoSavePending = false;
        _autoSaveBackoffActive = true;
        _autoSaveFailureCount++;

        final backoffSeconds = switch (_autoSaveFailureCount) {
          1 => 10,
          2 => 20,
          3 => 40,
          _ => 60,
        };

        _autoSaveTimer = Timer(Duration(seconds: backoffSeconds), () {
          _autoSaveBackoffActive = false;
          _runAutoSave();
        });
      } else {
        _autoSaveBackoffActive = false;
        _autoSaveFailureCount = 0;

        if (_autoSavePending || _autoSaveDirty) {
          _autoSavePending = false;
          _autoSaveTimer = Timer(const Duration(seconds: 1), _runAutoSave);
        }
      }
    }
  }

  Future<String?> _saveDraft({bool showConfirmation = false}) async {
    if (_isSavingDraft) {
      return _draftContentId;
    }

    final title = titleController.text.trim();
    final contentType = _contentType;

    // Le backend exige un titre et un type pour créer Content.
    // Tant que ces deux informations n'existent pas, on conserve
    // simplement le formulaire local à l'écran.
    if (title.isEmpty || contentType == null) {
      if (showConfirmation && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Choisissez le type et renseignez le titre '
              'pour créer le brouillon.',
            ),
          ),
        );
      }
      return null;
    }

    setState(() {
      _isSavingDraft = true;
      _savingStatus = 'Enregistrement des informations…';
    });

    try {
      final service = ProducerService.instance;

      List<int>? genreIds;
      if (selectedGenres.isNotEmpty) {
        genreIds = await service.getGenreIdsByNames(selectedGenres);
      }

      final language = switch (selectedLanguage) {
        LanguageOption.francais => 'Français',
        LanguageOption.anglais => 'Anglais',
        LanguageOption.autres => languageOtherController.text.trim(),
        null => '',
      };

      final country = selectedCountry == 'Autres'
          ? countryOtherController.text.trim()
          : (selectedCountry ?? '');

      final type = contentType == ContentType.serie ? 'series' : 'movie';

      if (_draftContentId == null) {
        final content = await service.createContent(
          title: title,
          description: descriptionController.text,
          synopsis: synopsisController.text,
          type: type,
          releaseYear: releaseYear,
          genreIds: genreIds ?? const [],
        );

        final id = content['id']?.toString();

        if (id == null || id.isEmpty) {
          throw StateError(
            'Le serveur n’a pas retourné l’identifiant du brouillon.',
          );
        }

        _draftContentId = id;
      }

      final draftId = _draftContentId!;

      _setSavingStatus('Enregistrement des informations…');

      var producerTeam = producers
          .map(
            (person) => <String, dynamic>{
              'name': person.name.trim(),
              if (person.imageTempPath?.trim().isNotEmpty ?? false)
                'image_temp_path': person.imageTempPath!.trim(),
              if (person.imageUrl?.trim().isNotEmpty ?? false)
                'image_url': person.imageUrl!.trim(),
            },
          )
          .toList();

      var castTeam = actors
          .map(
            (person) => <String, dynamic>{
              'name': person.name.trim(),
              if (person.imageTempPath?.trim().isNotEmpty ?? false)
                'image_temp_path': person.imageTempPath!.trim(),
              if (person.imageUrl?.trim().isNotEmpty ?? false)
                'image_url': person.imageUrl!.trim(),
            },
          )
          .toList();

      final duration = int.tryParse(durationController.text.trim());

      final audioLanguages = selectedAudioLanguages.toList();

      final subtitleLanguages = selectedSubtitleLanguages.toList();

      // Les métadonnées sont persistées avant tout upload média.
      // Une erreur temporaire d'upload ne doit jamais faire perdre
      // les informations saisies par le producteur.
      await service.updateContent(
        contentId: draftId,
        title: title,
        originalTitle: originalTitleController.text,
        description: descriptionController.text,
        synopsis: synopsisController.text,
        type: type,
        releaseYear: releaseYear,
        duration: duration,
        ageRating: selectedAgeRating ?? '',
        genreIds: genreIds,
        language: language,
        country: country,
        audioLanguages: audioLanguages,
        subtitleLanguages: subtitleLanguages,
        directorName: directorNameController.text,
        screenwriterName: screenwriterNameController.text,
        producerTeam: producerTeam,
        castTeam: castTeam,
      );

      // Synchroniser le niveau de livraison des masters déjà créés.
      // Cette étape ne crée aucun VideoAsset : les nouveaux assets
      // reçoivent directement le niveau lors de leur création.
      await _persistVideoAssetDeliveryLevel(draftId);

      // Les photos sont ensuite persistées. Si un upload échoue,
      // les métadonnées ci-dessus sont déjà enregistrées.
      await _persistPrimaryPersonImages(draftId);
      await _persistTeamImages(draftId);

      producerTeam = producers
          .map(
            (person) => <String, dynamic>{
              'name': person.name.trim(),
              if (person.imageTempPath?.trim().isNotEmpty ?? false)
                'image_temp_path': person.imageTempPath!.trim(),
              if (person.imageUrl?.trim().isNotEmpty ?? false)
                'image_url': person.imageUrl!.trim(),
            },
          )
          .toList();

      castTeam = actors
          .map(
            (person) => <String, dynamic>{
              'name': person.name.trim(),
              if (person.imageTempPath?.trim().isNotEmpty ?? false)
                'image_temp_path': person.imageTempPath!.trim(),
              if (person.imageUrl?.trim().isNotEmpty ?? false)
                'image_url': person.imageUrl!.trim(),
            },
          )
          .toList();

      // Synchroniser uniquement les informations susceptibles d'avoir
      // changé après l'upload des photos.
      await service.updateContent(
        contentId: draftId,
        producerTeam: producerTeam,
        castTeam: castTeam,
      );

      if (contentType == ContentType.serie) {
        await _persistSeriesStructure(draftId);
      }

      if (showConfirmation && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Brouillon enregistré.')));
      }

      return draftId;
    } finally {
      if (mounted) {
        setState(() => _isSavingDraft = false);
      } else {
        _isSavingDraft = false;
      }
    }
  }

  void _leaveUploadPage() {
    final callback = widget.onExit;

    if (callback != null) {
      callback();
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _saveDraftAndQuit() async {
    if (_isBusy) {
      return;
    }

    try {
      final draftId = await _saveDraft(showConfirmation: false);

      if (draftId == null || draftId.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Choisissez le type et renseignez le titre '
              'avant de quitter.',
            ),
          ),
        );
        return;
      }

      await _persistDraftMedia(draftId);

      if (!mounted) return;

      _setSavingStatus(null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brouillon et médias enregistrés.')),
      );

      _leaveUploadPage();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d’enregistrer le brouillon : $error'),
        ),
      );
    }
  }

  bool _videoAssetHasUploadedSource(Map<String, dynamic> asset) {
    final uploadedAt = asset['source_uploaded_at'];

    if (uploadedAt is String && uploadedAt.trim().isNotEmpty) {
      return true;
    }

    return false;
  }

  Map<String, dynamic>? _firstUploadedVideoAsset(
    List<Map<String, dynamic>> assets,
  ) {
    for (final asset in assets) {
      if (_videoAssetHasUploadedSource(asset)) {
        return asset;
      }
    }

    return null;
  }

  Future<List<SeasonWrapper>> _buildLoadedSeriesStructure({
    required String contentId,
    required Map<String, dynamic> content,
  }) async {
    final service = ProducerService.instance;
    final loaded = <SeasonWrapper>[];

    final rawSeasons = content['seasons'];

    if (rawSeasons is! List) {
      return loaded;
    }

    for (final rawSeason in rawSeasons) {
      if (rawSeason is! Map) {
        continue;
      }

      final seasonId = rawSeason['id']?.toString().trim() ?? '';

      final rawSeasonNumber = rawSeason['season_number'];

      final seasonNumber = rawSeasonNumber is int
          ? rawSeasonNumber
          : int.tryParse(rawSeasonNumber?.toString() ?? '');

      if (seasonId.isEmpty || seasonNumber == null) {
        continue;
      }

      final episodeInitialData = <EpisodeInitialData>[];

      final rawEpisodes = rawSeason['episodes'];

      if (rawEpisodes is List) {
        for (final rawEpisode in rawEpisodes) {
          if (rawEpisode is! Map) {
            continue;
          }

          final episodeId = rawEpisode['id']?.toString().trim() ?? '';

          final rawEpisodeNumber = rawEpisode['episode_number'];

          final episodeNumber = rawEpisodeNumber is int
              ? rawEpisodeNumber
              : int.tryParse(rawEpisodeNumber?.toString() ?? '');

          if (episodeId.isEmpty || episodeNumber == null) {
            continue;
          }

          final assets = await service.getMyVideoAssets(
            contentId: contentId,
            episodeId: episodeId,
          );

          final uploadedAsset = _firstUploadedVideoAsset(assets);

          final hasVideo = uploadedAsset != null;

          final deliveryAsset =
              uploadedAsset ?? (assets.isNotEmpty ? assets.first : null);

          final rawEpisodeDeliveryLevel = deliveryAsset?['delivery_level']
              ?.toString()
              .trim()
              .toLowerCase();

          final episodeDeliveryLevel =
              rawEpisodeDeliveryLevel != null &&
                  deliveryLevelLabels.containsKey(rawEpisodeDeliveryLevel)
              ? rawEpisodeDeliveryLevel
              : 'distribution';

          final technicalConformity = uploadedAsset == null
              ? null
              : TechnicalConformityReport.fromVideoAsset(uploadedAsset);

          episodeInitialData.add(
            EpisodeInitialData(
              serverId: episodeId,
              episodeNumber: episodeNumber,
              title: rawEpisode['title']?.toString() ?? '',
              description: rawEpisode['description']?.toString() ?? '',
              duration: rawEpisode['duration'] is int
                  ? rawEpisode['duration'] as int
                  : int.tryParse(rawEpisode['duration']?.toString() ?? ''),
              serverHasVideo: hasVideo,
              deliveryLevel: episodeDeliveryLevel,
              technicalConformity: technicalConformity,
            ),
          );
        }
      }

      final key = GlobalKey<SeasonState>();

      late final SeasonWrapper wrapper;

      wrapper = SeasonWrapper(
        key: key,
        serverId: seasonId,
        season: SeasonForm(
          key: key,
          technicalSpecificationListenable: _technicalSpecificationNotifier,
          deliveryLevel: selectedDeliveryLevel,
          seasonNumber: seasonNumber,
          onChanged: () => _scheduleAutoSave(),
          onRetryTrailerAnalysis: () => _retrySeasonTrailerAnalysis(wrapper),
          initialTitle: rawSeason['title']?.toString() ?? '',
          initialDescription: rawSeason['description']?.toString() ?? '',
          initialServerHasPoster:
              (rawSeason['poster_temp_path']?.toString().trim().isNotEmpty ??
                  false) ||
              (rawSeason['poster_url']?.toString().trim().isNotEmpty ?? false),
          initialServerHasBackdrop:
              (rawSeason['backdrop_temp_path']?.toString().trim().isNotEmpty ??
                  false) ||
              (rawSeason['backdrop_url']?.toString().trim().isNotEmpty ??
                  false),
          initialServerHasTrailer:
              (rawSeason['trailer_temp_path']?.toString().trim().isNotEmpty ??
                  false) ||
              (rawSeason['trailer_url']?.toString().trim().isNotEmpty ?? false),
          initialTrailerTechnicalConformity:
              TechnicalConformityReport.fromTrailerOwner(
                Map<String, dynamic>.from(rawSeason),
              ),
          initialEpisodes: episodeInitialData,
          onRemove: () {
            final serverId = wrapper.serverId?.trim() ?? '';

            setState(() {
              if (serverId.isNotEmpty) {
                _deletedSeasonIds.add(serverId);
              }

              seasons.removeWhere((item) => identical(item, wrapper));
            });

            _scheduleAutoSave(immediate: true);
          },
        ),
      );

      loaded.add(wrapper);
    }

    return loaded;
  }

  Future<void> _loadDraft(String contentId) async {
    if (_isLoadingDraft) return;

    setState(() => _isLoadingDraft = true);

    try {
      final service = ProducerService.instance;
      final content = await service.getContent(contentId);

      final type = content['type']?.toString().trim().toLowerCase();

      final loadedType = switch (type) {
        'series' => ContentType.serie,
        'movie' => ContentType.film,
        _ => null,
      };

      final loadedSeriesStructure = loadedType == ContentType.serie
          ? await _buildLoadedSeriesStructure(
              contentId: contentId,
              content: content,
            )
          : <SeasonWrapper>[];

      var loadedDeliveryLevel = 'distribution';

      final loadedAssets = await service.getMyVideoAssets(contentId: contentId);

      if (loadedType == ContentType.film) {
        for (final asset in loadedAssets) {
          final episode = asset['episode'];

          if (episode != null && episode.toString().trim().isNotEmpty) {
            continue;
          }

          if (!_videoAssetHasUploadedSource(asset)) {
            continue;
          }

          final rawDeliveryLevel = asset['delivery_level']
              ?.toString()
              .trim()
              .toLowerCase();

          if (rawDeliveryLevel != null &&
              deliveryLevelLabels.containsKey(rawDeliveryLevel)) {
            loadedDeliveryLevel = rawDeliveryLevel;
            break;
          }
        }
      }

      final loadedGenres = <String>{};
      final rawGenres = content['genres'];

      if (rawGenres is List) {
        for (final item in rawGenres) {
          if (item is Map) {
            final name = item['name']?.toString().trim();

            if (name != null && name.isNotEmpty) {
              loadedGenres.add(name);
            }
          }
        }
      }

      final language = content['language']?.toString().trim() ?? '';

      LanguageOption? loadedLanguage;
      var loadedOtherLanguage = '';

      switch (language.toLowerCase()) {
        case 'français':
        case 'francais':
          loadedLanguage = LanguageOption.francais;
          break;

        case 'anglais':
        case 'english':
          loadedLanguage = LanguageOption.anglais;
          break;

        case '':
          loadedLanguage = null;
          break;

        default:
          loadedLanguage = LanguageOption.autres;
          loadedOtherLanguage = language;
      }

      final country = content['country']?.toString().trim() ?? '';

      String? loadedCountry;
      var loadedOtherCountry = '';

      if (country.isEmpty) {
        loadedCountry = null;
      } else if (africanCountries.contains(country)) {
        loadedCountry = country;
      } else {
        loadedCountry = 'Autres';
        loadedOtherCountry = country;
      }

      final loadedProducers = <PersonWithImage>[];
      final rawProducerTeam = content['producer_team'];

      if (rawProducerTeam is List) {
        for (final item in rawProducerTeam) {
          if (item is Map) {
            final name = item['name']?.toString().trim();

            if (name != null && name.isNotEmpty) {
              final imagePath = item['image_path']?.toString().trim();

              final imageTempPath = item['image_temp_path']?.toString().trim();

              final imageUrl = item['image_url']?.toString().trim();

              loadedProducers.add(
                PersonWithImage(
                  name: name,
                  imagePath: imagePath != null && imagePath.isNotEmpty
                      ? imagePath
                      : null,
                  imageTempPath:
                      imageTempPath != null && imageTempPath.isNotEmpty
                      ? imageTempPath
                      : null,
                  imageUrl: imageUrl != null && imageUrl.isNotEmpty
                      ? imageUrl
                      : null,
                ),
              );
            }
          }
        }
      }

      for (var index = 0; index < loadedProducers.length; index++) {
        final person = loadedProducers[index];

        final finalUrl = person.imageUrl?.trim() ?? '';
        final temporaryPath = person.imageTempPath?.trim() ?? '';

        // Une URL finale CDN est prioritaire.
        // Sinon, une photo TEMP reçoit une URL MinIO signée.
        if (finalUrl.isNotEmpty || temporaryPath.isEmpty) {
          continue;
        }

        try {
          final previewUrl = await service.getTeamImagePreview(
            contentId: contentId,
            temporaryPath: temporaryPath,
          );

          loadedProducers[index] = PersonWithImage(
            name: person.name,
            imagePath: person.imagePath,
            imageTempPath: person.imageTempPath,
            imageUrl: person.imageUrl,
            previewUrl: previewUrl,
          );
        } catch (_) {
          // La preview ne doit pas empêcher
          // l'ouverture du brouillon.
        }
      }

      final loadedActors = <PersonWithImage>[];
      final rawCastTeam = content['cast_team'];

      if (rawCastTeam is List) {
        for (final item in rawCastTeam) {
          if (item is Map) {
            final name = item['name']?.toString().trim();

            if (name != null && name.isNotEmpty) {
              final imagePath = item['image_path']?.toString().trim();

              final imageTempPath = item['image_temp_path']?.toString().trim();

              final imageUrl = item['image_url']?.toString().trim();

              loadedActors.add(
                PersonWithImage(
                  name: name,
                  imagePath: imagePath != null && imagePath.isNotEmpty
                      ? imagePath
                      : null,
                  imageTempPath:
                      imageTempPath != null && imageTempPath.isNotEmpty
                      ? imageTempPath
                      : null,
                  imageUrl: imageUrl != null && imageUrl.isNotEmpty
                      ? imageUrl
                      : null,
                ),
              );
            }
          }
        }
      }

      for (var index = 0; index < loadedActors.length; index++) {
        final person = loadedActors[index];

        final finalUrl = person.imageUrl?.trim() ?? '';
        final temporaryPath = person.imageTempPath?.trim() ?? '';

        if (finalUrl.isNotEmpty || temporaryPath.isEmpty) {
          continue;
        }

        try {
          final previewUrl = await service.getTeamImagePreview(
            contentId: contentId,
            temporaryPath: temporaryPath,
          );

          loadedActors[index] = PersonWithImage(
            name: person.name,
            imagePath: person.imagePath,
            imageBytes: person.imageBytes,
            imageTempPath: person.imageTempPath,
            imageUrl: person.imageUrl,
            previewUrl: previewUrl,
          );
        } catch (_) {
          // Une erreur de preview ne doit pas empêcher
          // l'ouverture du brouillon.
        }
      }

      final directorTempPath =
          content['director_image_temp_path']?.toString().trim() ?? '';

      final directorFinalUrl =
          content['director_image_url']?.toString().trim() ?? '';

      String? loadedDirectorPreviewUrl;

      if (directorFinalUrl.isEmpty && directorTempPath.isNotEmpty) {
        try {
          loadedDirectorPreviewUrl = await service.getTeamImagePreview(
            contentId: contentId,
            temporaryPath: directorTempPath,
          );
        } catch (_) {
          // Une erreur de preview ne doit pas empêcher
          // l'ouverture du brouillon.
        }
      }

      final screenwriterTempPath =
          content['screenwriter_image_temp_path']?.toString().trim() ?? '';

      final screenwriterFinalUrl =
          content['screenwriter_image_url']?.toString().trim() ?? '';

      String? loadedScreenwriterPreviewUrl;

      if (screenwriterFinalUrl.isEmpty && screenwriterTempPath.isNotEmpty) {
        try {
          loadedScreenwriterPreviewUrl = await service.getTeamImagePreview(
            contentId: contentId,
            temporaryPath: screenwriterTempPath,
          );
        } catch (_) {
          // Une erreur de preview ne doit pas empêcher
          // l'ouverture du brouillon.
        }
      }

      final assets = await service.getMyVideoAssets(contentId: contentId);

      final filmAssets = loadedType == ContentType.film
          ? assets.where((asset) {
              final episode = asset['episode'];
              return episode == null || episode.toString().trim().isEmpty;
            }).toList()
          : <Map<String, dynamic>>[];

      final loadedFilmAsset = _firstUploadedVideoAsset(filmAssets);

      final hasMaster = loadedFilmAsset != null;

      final loadedMovieTechnicalConformity = loadedFilmAsset == null
          ? null
          : TechnicalConformityReport.fromVideoAsset(loadedFilmAsset);

      final loadedContentTrailerTechnicalConformity =
          TechnicalConformityReport.fromTrailerOwner(content);

      if (!mounted) return;

      final description = content['description']?.toString().trim() ?? '';

      final synopsis = content['synopsis']?.toString().trim() ?? '';

      final rawYear = content['release_year'];

      final rawDuration = content['duration'];

      final loadedDuration = rawDuration == null ? '' : rawDuration.toString();

      final loadedAgeRating = content['age_rating']?.toString().trim() ?? '';

      final rawAudioLanguages = content['audio_languages'];

      final loadedAudioLanguages = rawAudioLanguages is List
          ? rawAudioLanguages
                .map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty)
                .toSet()
          : <String>{};

      final rawSubtitleLanguages = content['subtitle_languages'];

      final loadedSubtitleLanguages = rawSubtitleLanguages is List
          ? rawSubtitleLanguages
                .map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty)
                .toSet()
          : <String>{};

      setState(() {
        _draftContentId = contentId;
        _contentType = loadedType;
        selectedDeliveryLevel = loadedDeliveryLevel;

        _deletedSeasonIds.clear();

        seasons
          ..clear()
          ..addAll(loadedSeriesStructure);

        titleController.text = content['title']?.toString() ?? '';

        originalTitleController.text =
            content['original_title']?.toString() ?? '';

        synopsisController.text = synopsis;
        descriptionController.text = description;

        durationController.text = loadedDuration;

        selectedAgeRating = loadedAgeRating.isEmpty ? null : loadedAgeRating;

        selectedAudioLanguages
          ..clear()
          ..addAll(loadedAudioLanguages);

        selectedSubtitleLanguages
          ..clear()
          ..addAll(loadedSubtitleLanguages);

        selectedGenres
          ..clear()
          ..addAll(loadedGenres);

        releaseYear = rawYear is int
            ? rawYear
            : int.tryParse(rawYear?.toString() ?? '');

        selectedLanguage = loadedLanguage;
        languageOtherController.text = loadedOtherLanguage;

        selectedCountry = loadedCountry;
        countryOtherController.text = loadedOtherCountry;

        directorNameController.text =
            content['director_name']?.toString() ?? '';

        directorImagePath = null;
        directorImageBytes = null;
        directorImageFilename = null;
        directorImageTempPath = directorTempPath.isNotEmpty
            ? directorTempPath
            : null;
        directorImageUrl = directorFinalUrl.isNotEmpty
            ? directorFinalUrl
            : null;
        directorImagePreviewUrl = loadedDirectorPreviewUrl;

        screenwriterNameController.text =
            content['screenwriter_name']?.toString() ?? '';

        screenwriterImagePath = null;
        screenwriterImageBytes = null;
        screenwriterImageFilename = null;
        screenwriterImageTempPath = screenwriterTempPath.isNotEmpty
            ? screenwriterTempPath
            : null;
        screenwriterImageUrl = screenwriterFinalUrl.isNotEmpty
            ? screenwriterFinalUrl
            : null;
        screenwriterImagePreviewUrl = loadedScreenwriterPreviewUrl;

        producers
          ..clear()
          ..addAll(loadedProducers);

        actors
          ..clear()
          ..addAll(loadedActors);

        _serverHasPoster = _hasTemporaryMedia(content, 'poster_temp_path');

        _serverHasBackdrop = _hasTemporaryMedia(content, 'backdrop_temp_path');

        _serverHasTrailer = _hasTemporaryMedia(content, 'trailer_temp_path');

        _serverHasMaster = hasMaster;
        _movieTechnicalConformity = loadedMovieTechnicalConformity;
        _contentTrailerTechnicalConformity =
            loadedContentTrailerTechnicalConformity;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de charger le brouillon : $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingDraft = false);

        if (_hasTechnicalConformityPending()) {
          _startTechnicalConformityRefresh();
        }
      } else {
        _isLoadingDraft = false;
      }
    }
  }

  Future<void> _persistSeriesStructure(String contentId) async {
    if (_contentType != ContentType.serie) {
      return;
    }

    final service = ProducerService.instance;

    // ----------------------------------------------------------
    // Saisons supprimées
    // ----------------------------------------------------------
    for (final seasonId in List<String>.from(_deletedSeasonIds)) {
      _setSavingStatus('Suppression d’une saison retirée…');

      await service.deleteSeason(seasonId);

      _deletedSeasonIds.remove(seasonId);
    }

    // ----------------------------------------------------------
    // Création / mise à jour saisons + épisodes
    // ----------------------------------------------------------
    for (var seasonIndex = 0; seasonIndex < seasons.length; seasonIndex++) {
      final wrapper = seasons[seasonIndex];
      final state = wrapper.key.currentState;

      if (state == null) {
        throw StateError(
          'La saison ${wrapper.season.seasonNumber} '
          'n’est pas disponible.',
        );
      }

      final seasonNumber = wrapper.season.seasonNumber;

      final seasonTitle = state.seasonTitleController.text.trim();
      final seasonDescription = state.seasonDescriptionController.text.trim();

      _setSavingStatus('Enregistrement de la saison $seasonNumber…');

      var seasonId = wrapper.serverId?.trim() ?? '';

      if (seasonId.isEmpty) {
        final response = await service.createSeason(
          contentId: contentId,
          seasonNumber: seasonNumber,
          title: seasonTitle,
          description: seasonDescription,
          episodeCount: state.episodes.length,
        );

        seasonId = response['id']?.toString().trim() ?? '';

        if (seasonId.isEmpty) {
          throw StateError(
            'Le serveur n’a pas retourné '
            'l’identifiant de la saison $seasonNumber.',
          );
        }

        wrapper.serverId = seasonId;
      } else {
        await service.updateSeason(
          seasonId: seasonId,
          title: seasonTitle,
          description: seasonDescription,
          episodeCount: state.episodes.length,
        );
      }

      // --------------------------------------------------------
      // Episodes supprimés de cette saison
      // --------------------------------------------------------
      for (final episodeId in List<String>.from(state.deletedEpisodeIds)) {
        _setSavingStatus(
          'Suppression d’un épisode retiré '
          'de la saison $seasonNumber…',
        );

        await service.deleteEpisode(episodeId);

        state.deletedEpisodeIds.remove(episodeId);
      }

      // --------------------------------------------------------
      // Episodes présents
      // --------------------------------------------------------
      for (
        var episodeIndex = 0;
        episodeIndex < state.episodes.length;
        episodeIndex++
      ) {
        final episodeWrapper = state.episodes[episodeIndex];

        final episodeState = episodeWrapper.key.currentState;

        if (episodeState == null) {
          throw StateError(
            'Un épisode de la saison '
            '$seasonNumber n’est pas disponible.',
          );
        }

        final episodeNumber = episodeWrapper.episode.episodeNumber;

        final enteredTitle = episodeState.titleController.text.trim();

        final episodeTitle = enteredTitle.isNotEmpty
            ? enteredTitle
            : 'Épisode $episodeNumber';

        final description = episodeState.descController.text.trim();

        final duration = int.tryParse(
          episodeState.durationController.text.trim(),
        );

        _setSavingStatus(
          'Enregistrement S$seasonNumber '
          'E$episodeNumber…',
        );

        var episodeId = episodeWrapper.serverId?.trim() ?? '';

        if (episodeId.isEmpty) {
          final response = await service.createEpisode(
            seasonId: seasonId,
            episodeNumber: episodeNumber,
            title: episodeTitle,
            description: description,
            duration: duration,
          );

          episodeId = response['id']?.toString().trim() ?? '';

          if (episodeId.isEmpty) {
            throw StateError(
              'Le serveur n’a pas retourné '
              'l’identifiant de S$seasonNumber '
              'E$episodeNumber.',
            );
          }

          episodeWrapper.serverId = episodeId;
        } else {
          await service.updateEpisode(
            episodeId: episodeId,
            title: episodeTitle,
            description: description,
            duration: duration,
          );
        }
      }

      // Le compteur doit refléter la structure réellement
      // persistée après les créations/suppressions.
      await service.updateSeason(
        seasonId: seasonId,
        title: seasonTitle,
        description: seasonDescription,
        episodeCount: state.episodes.length,
      );
    }
  }

  Future<void> _persistSeriesSeasonMedia(String contentId) async {
    if (_contentType != ContentType.serie) {
      return;
    }

    final service = ProducerService.instance;

    for (final wrapper in seasons) {
      final state = wrapper.key.currentState;

      if (state == null) {
        continue;
      }

      final seasonId = wrapper.serverId?.trim() ?? '';
      final seasonNumber = wrapper.season.seasonNumber;

      if (seasonId.isEmpty) {
        throw StateError(
          'La saison $seasonNumber '
          'n’a pas d’identifiant serveur.',
        );
      }

      // --------------------------------------------------------
      // POSTER
      // --------------------------------------------------------
      final poster = state.posterFile;

      if (poster != null) {
        _setSavingStatus('Envoi du poster de la saison $seasonNumber…');

        final bytes = await poster.readAsBytes();

        if (bytes.isEmpty) {
          throw StateError('Le poster de la saison $seasonNumber est vide.');
        }

        await service.uploadSeasonMedia(
          seasonId: seasonId,
          mediaType: 'poster',
          bytes: bytes,
          filename: poster.name,
        );

        state.markPosterPersisted();
      }

      // --------------------------------------------------------
      // BANNIERE
      // --------------------------------------------------------
      final banner = state.bannerFile;

      if (banner != null) {
        _setSavingStatus('Envoi de la bannière de la saison $seasonNumber…');

        final bytes = await banner.readAsBytes();

        if (bytes.isEmpty) {
          throw StateError('La bannière de la saison $seasonNumber est vide.');
        }

        await service.uploadSeasonMedia(
          seasonId: seasonId,
          mediaType: 'backdrop',
          bytes: bytes,
          filename: banner.name,
        );

        state.markBackdropPersisted();
      }

      // --------------------------------------------------------
      // TRAILER
      // --------------------------------------------------------
      final trailer = state.trailerFile;

      if (trailer != null) {
        _setSavingStatus('Envoi du trailer de la saison $seasonNumber…');

        final length = await trailer.length();

        if (length <= 0) {
          throw StateError('Le trailer de la saison $seasonNumber est vide.');
        }

        final session = await service.createSeasonTrailerUploadSession(
          seasonId: seasonId,
          filename: trailer.name,
          sizeBytes: length,
        );

        final uploadUrl = session['upload_url']?.toString().trim() ?? '';

        final completionToken =
            session['completion_token']?.toString().trim() ?? '';

        if (uploadUrl.isEmpty || completionToken.isEmpty) {
          throw StateError(
            'La session d’upload du trailer '
            'de la saison $seasonNumber est incomplète.',
          );
        }

        await uploadBlobUrlToPresignedUrl(
          blobUrl: trailer.path,
          uploadUrl: uploadUrl,
          expectedSize: length,
        );

        await service.completeSeasonTrailerUpload(
          seasonId: seasonId,
          completionToken: completionToken,
        );

        state.markTrailerPersisted(
          TechnicalConformityReport.fromTrailerOwner(<String, dynamic>{
            'trailer_analysis_status': 'pending',
            'trailer_technical_conformity': null,
          }),
        );

        _startTechnicalConformityRefresh();
      }
    }
  }

  Future<void> _persistSeriesEpisodeVideos(String contentId) async {
    if (_contentType != ContentType.serie) {
      return;
    }

    final service = ProducerService.instance;

    for (final seasonWrapper in seasons) {
      final seasonState = seasonWrapper.key.currentState;

      if (seasonState == null) {
        continue;
      }

      final seasonNumber = seasonWrapper.season.seasonNumber;

      for (final episodeWrapper in seasonState.episodes) {
        final episodeState = episodeWrapper.key.currentState;

        if (episodeState == null) {
          continue;
        }

        final episodeId = episodeWrapper.serverId?.trim() ?? '';

        if (episodeId.isEmpty) {
          throw StateError('Episode sans identifiant serveur.');
        }

        final episodeNumber = episodeWrapper.episode.episodeNumber;

        var assets = await service.getMyVideoAssets(
          contentId: contentId,
          episodeId: episodeId,
        );

        final expectedDeliveryLevel = episodeState.selectedDeliveryLevel
            .trim()
            .toLowerCase();

        if (!deliveryLevelLabels.containsKey(expectedDeliveryLevel)) {
          throw StateError(
            'Niveau de livraison invalide pour '
            'S$seasonNumber E$episodeNumber.',
          );
        }

        var deliveryLevelChanged = false;

        final existingAsset =
            _firstUploadedVideoAsset(assets) ??
            (assets.isNotEmpty ? assets.first : null);

        if (existingAsset != null) {
          final existingAssetId = existingAsset['id']?.toString().trim() ?? '';

          final currentDeliveryLevel =
              existingAsset['delivery_level']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              'distribution';

          if (existingAssetId.isNotEmpty &&
              currentDeliveryLevel != expectedDeliveryLevel) {
            _setSavingStatus(
              'Mise à jour du niveau technique '
              'S$seasonNumber E$episodeNumber…',
            );

            final updatedAsset = await service.updateVideoAssetDeliveryLevel(
              assetId: existingAssetId,
              deliveryLevel: expectedDeliveryLevel,
            );

            final mergedAsset = <String, dynamic>{
              ...existingAsset,
              ...updatedAsset,
              'delivery_level': expectedDeliveryLevel,
            };

            assets = assets.map((item) {
              final itemId = item['id']?.toString().trim() ?? '';

              return itemId == existingAssetId ? mergedAsset : item;
            }).toList();

            deliveryLevelChanged = true;
          }
        }

        final source = episodeState.videoFile;

        // Rien de nouveau à envoyer.
        if (source == null) {
          final uploadedAsset = _firstUploadedVideoAsset(assets);

          episodeState.setServerVideoAsset(
            uploadedAsset,
            invalidateConformity: deliveryLevelChanged,
          );

          continue;
        }

        _setSavingStatus(
          'Envoi vidéo S$seasonNumber '
          'E$episodeNumber…',
        );

        final length = await source.length();

        if (length <= 0) {
          throw StateError(
            'La vidéo S$seasonNumber '
            'E$episodeNumber est vide.',
          );
        }

        final asset = assets.isNotEmpty
            ? assets.first
            : await service.createVideoAsset(
                contentId: contentId,
                episodeId: episodeId,
                title: episodeState.titleController.text.trim().isNotEmpty
                    ? episodeState.titleController.text.trim()
                    : 'S$seasonNumber '
                          'E$episodeNumber',
                deliveryLevel: expectedDeliveryLevel,
              );

        final assetId = asset['id']?.toString().trim() ?? '';

        if (assetId.isEmpty) {
          throw StateError(
            'Le serveur n’a pas retourné '
            'l’identifiant vidéo de '
            'S$seasonNumber E$episodeNumber.',
          );
        }

        final session = await service.createSourceUploadSession(
          assetId: assetId,
          filename: source.name,
          sizeBytes: length,
        );

        final uploadUrl = session['upload_url']?.toString() ?? '';

        final completionToken = session['completion_token']?.toString() ?? '';

        if (uploadUrl.isEmpty || completionToken.isEmpty) {
          throw StateError(
            'Session d’upload incomplète pour '
            'S$seasonNumber E$episodeNumber.',
          );
        }

        await uploadBlobUrlToPresignedUrl(
          blobUrl: source.path,
          uploadUrl: uploadUrl,
          expectedSize: length,
        );

        await service.completeSourceUpload(
          assetId: assetId,
          completionToken: completionToken,
        );

        assets = await service.getMyVideoAssets(
          contentId: contentId,
          episodeId: episodeId,
        );

        final uploadedAsset = _firstUploadedVideoAsset(assets);

        if (uploadedAsset == null) {
          throw StateError(
            'La vidéo S$seasonNumber '
            'E$episodeNumber n’a pas été '
            'confirmée par le serveur.',
          );
        }

        episodeState.markVideoPersisted(uploadedAsset);

        if (_technicalConformityNeedsRefresh(
          episodeState.technicalConformity,
        )) {
          _startTechnicalConformityRefresh();
        }
      }
    }
  }

  Future<Map<String, dynamic>> _getCurrentDraft(String contentId) async {
    return ProducerService.instance.getContent(contentId);
  }

  bool _hasTemporaryMedia(Map<String, dynamic> content, String field) {
    final value = content[field];
    return value is String && value.trim().isNotEmpty;
  }

  Future<void> _persistDraftMedia(String contentId) async {
    if (mounted) {
      setState(() => _isPersistingMedia = true);
    } else {
      _isPersistingMedia = true;
    }

    try {
      final service = ProducerService.instance;

      var currentDraft = await _getCurrentDraft(contentId);

      // --------------------------------------------------------
      // AFFICHE
      // --------------------------------------------------------
      if (!_hasTemporaryMedia(currentDraft, 'poster_temp_path')) {
        final poster = posterFile;

        if (poster != null) {
          _setSavingStatus('Envoi de l’affiche…');

          await service.uploadContentMedia(
            contentId: contentId,
            mediaType: 'poster',
            bytes: await poster.readAsBytes(),
            filename: poster.name,
          );
        }
      }

      // --------------------------------------------------------
      // BANNIERE
      // --------------------------------------------------------
      currentDraft = await _getCurrentDraft(contentId);

      if (!_hasTemporaryMedia(currentDraft, 'backdrop_temp_path')) {
        final banner = bannerFile;

        if (banner != null) {
          _setSavingStatus('Envoi de la bannière…');

          await service.uploadContentMedia(
            contentId: contentId,
            mediaType: 'backdrop',
            bytes: await banner.readAsBytes(),
            filename: banner.name,
          );
        }
      }

      // --------------------------------------------------------
      // TRAILER
      // Upload direct navigateur -> stockage temporaire.
      // XFile.length() évite de charger une première fois
      // toute la vidéo en mémoire uniquement pour mesurer sa taille.
      // --------------------------------------------------------
      currentDraft = await _getCurrentDraft(contentId);

      if (!_hasTemporaryMedia(currentDraft, 'trailer_temp_path')) {
        final trailer = trailerFile;

        if (trailer != null) {
          _setSavingStatus('Envoi de la bande-annonce…');

          try {
            await trailerPlayerController?.pause();
          } catch (_) {}

          trailerPlayerController?.dispose();
          trailerPlayerController = null;

          final trailerLength = await trailer.length();

          if (trailerLength <= 0) {
            throw StateError('Le trailer sélectionné est vide.');
          }

          final session = await service.createTrailerUploadSession(
            contentId: contentId,
            filename: trailer.name,
            sizeBytes: trailerLength,
          );

          final uploadUrl = session['upload_url']?.toString() ?? '';

          final completionToken = session['completion_token']?.toString() ?? '';

          if (uploadUrl.isEmpty || completionToken.isEmpty) {
            throw StateError(
              'La session d’upload du trailer '
              'est incomplète.',
            );
          }

          await uploadBlobUrlToPresignedUrl(
            blobUrl: trailer.path,
            uploadUrl: uploadUrl,
            expectedSize: trailerLength,
          );

          await service.completeTrailerUpload(
            contentId: contentId,
            completionToken: completionToken,
          );

          if (mounted) {
            setState(() {
              _contentTrailerTechnicalConformity =
                  TechnicalConformityReport.fromTrailerOwner(<String, dynamic>{
                    'trailer_analysis_status': 'pending',
                    'trailer_technical_conformity': null,
                  });
            });

            _startTechnicalConformityRefresh();
          }
        }
      }

      // --------------------------------------------------------
      // VIDEO MASTER
      // Uniquement pour un Film.
      // Pour une Série, chaque VideoAsset appartient à un Episode.
      // --------------------------------------------------------
      var assets = <Map<String, dynamic>>[];
      var hasMaster = false;

      if (_contentType == ContentType.film) {
        assets = await service.getMyVideoAssets(contentId: contentId);

        assets = assets.where((asset) {
          final episode = asset['episode'];
          return episode == null || episode.toString().trim().isEmpty;
        }).toList();

        hasMaster = assets.any(_videoAssetHasUploadedSource);
      }

      final master = _contentType == ContentType.film ? videoFile : null;

      if (!hasMaster && master != null) {
        _setSavingStatus('Envoi de la vidéo master…');

        try {
          await videoPlayerController?.pause();
        } catch (_) {}

        videoPlayerController?.dispose();
        videoPlayerController = null;

        final asset = assets.isNotEmpty
            ? assets.first
            : await service.createVideoAsset(
                contentId: contentId,
                title: titleController.text.trim(),
                deliveryLevel: selectedDeliveryLevel,
              );

        final assetId = asset['id']?.toString() ?? '';

        if (assetId.isEmpty) {
          throw StateError(
            'Le serveur n’a pas retourné '
            'l’identifiant de la vidéo.',
          );
        }

        final masterLength = await master.length();

        if (masterLength <= 0) {
          throw StateError('La vidéo sélectionnée est vide.');
        }

        final uploadSession = await service.createSourceUploadSession(
          assetId: assetId,
          filename: master.name,
          sizeBytes: masterLength,
        );

        final uploadUrl = uploadSession['upload_url']?.toString() ?? '';

        final completionToken =
            uploadSession['completion_token']?.toString() ?? '';

        if (uploadUrl.isEmpty || completionToken.isEmpty) {
          throw StateError(
            'La session d’upload de la vidéo '
            'est incomplète.',
          );
        }

        await uploadBlobUrlToPresignedUrl(
          blobUrl: master.path,
          uploadUrl: uploadUrl,
          expectedSize: masterLength,
        );

        await service.completeSourceUpload(
          assetId: assetId,
          completionToken: completionToken,
        );

        assets = await service.getMyVideoAssets(contentId: contentId);

        assets = assets.where((asset) {
          final episode = asset['episode'];
          return episode == null || episode.toString().trim().isEmpty;
        }).toList();

        hasMaster = assets.any(_videoAssetHasUploadedSource);
      }

      if (_contentType == ContentType.serie) {
        await _persistSeriesSeasonMedia(contentId);
        await _persistSeriesEpisodeVideos(contentId);
      }

      // --------------------------------------------------------
      // ETAT FINAL SERVEUR
      // --------------------------------------------------------
      currentDraft = await _getCurrentDraft(contentId);

      if (!mounted) return;

      setState(() {
        _serverHasPoster = _hasTemporaryMedia(currentDraft, 'poster_temp_path');

        _serverHasBackdrop = _hasTemporaryMedia(
          currentDraft,
          'backdrop_temp_path',
        );

        _serverHasTrailer = _hasTemporaryMedia(
          currentDraft,
          'trailer_temp_path',
        );

        _serverHasMaster = hasMaster;

        _contentTrailerTechnicalConformity =
            TechnicalConformityReport.fromTrailerOwner(currentDraft);

        if (_contentType == ContentType.film) {
          final uploadedFilmAsset = _firstUploadedVideoAsset(assets);

          _movieTechnicalConformity = uploadedFilmAsset == null
              ? null
              : TechnicalConformityReport.fromVideoAsset(uploadedFilmAsset);
        }

        // Les fichiers locaux ont été persistés côté serveur.
        if (_serverHasPoster) {
          posterFile = null;
        }

        if (_serverHasBackdrop) {
          bannerFile = null;
        }

        if (_serverHasTrailer) {
          trailerFile = null;
        }

        if (_serverHasMaster) {
          videoFile = null;
        }
      });

      if (_hasTechnicalConformityPending()) {
        _startTechnicalConformityRefresh();
      }

      _setSavingStatus('Finalisation de l’enregistrement…');
    } finally {
      if (mounted) {
        setState(() => _isPersistingMedia = false);
      } else {
        _isPersistingMedia = false;
      }
    }
  }

  _TechnicalSubmissionValidationResult?
  _validateTechnicalConformityForSubmission() {
    if (_contentType == ContentType.film) {
      if (!_serverHasMaster) {
        return _TechnicalSubmissionValidationResult(
          message:
              'Le master vidéo du film est obligatoire avant la soumission.',
          route: _scrollToFilmMasterRequirements,
        );
      }

      final report = _movieTechnicalConformity;

      if (report == null) {
        return _TechnicalSubmissionValidationResult(
          message:
              'L’analyse technique du master du film doit être terminée '
              'avant la soumission.',
          route: _scrollToFilmMasterRequirements,
        );
      }

      if (report.displayStatus != TechnicalConformityDisplayStatus.conform) {
        return _TechnicalSubmissionValidationResult(
          message:
              'Le master du film ne peut pas être soumis : '
              '${report.displayLabel}. '
              'La soumission est autorisée uniquement lorsque '
              'le rapport indique « Conforme ».',
          route: _scrollToFilmMasterRequirements,
        );
      }

      return null;
    }

    if (_contentType == ContentType.serie) {
      for (final seasonWrapper in seasons) {
        final seasonState = seasonWrapper.key.currentState;

        if (seasonState == null) {
          return const _TechnicalSubmissionValidationResult(
            message:
                'Impossible de vérifier la conformité technique '
                'd’une saison.',
          );
        }

        final seasonNumber = seasonWrapper.season.seasonNumber;

        for (final episodeWrapper in seasonState.episodes) {
          final episodeState = episodeWrapper.key.currentState;

          final episodeNumber = episodeWrapper.episode.episodeNumber;

          if (episodeState == null) {
            return _TechnicalSubmissionValidationResult(
              message:
                  'Impossible de vérifier le master '
                  'S$seasonNumber E$episodeNumber.',
            );
          }

          if (!episodeState.serverHasVideo) {
            return _TechnicalSubmissionValidationResult(
              message:
                  'Le master vidéo S$seasonNumber '
                  'E$episodeNumber est obligatoire avant '
                  'la soumission.',
              route: episodeState.scrollToMasterRequirements,
            );
          }

          final report = episodeState.technicalConformity;

          if (report == null) {
            return _TechnicalSubmissionValidationResult(
              message:
                  'L’analyse technique du master '
                  'S$seasonNumber E$episodeNumber doit être '
                  'terminée avant la soumission.',
              route: episodeState.scrollToMasterRequirements,
            );
          }

          if (report.displayStatus !=
              TechnicalConformityDisplayStatus.conform) {
            return _TechnicalSubmissionValidationResult(
              message:
                  'Le master S$seasonNumber '
                  'E$episodeNumber ne peut pas être soumis : '
                  '${report.displayLabel}. '
                  'La soumission est autorisée uniquement '
                  'lorsque le rapport indique « Conforme ».',
              route: episodeState.scrollToMasterRequirements,
            );
          }
        }
      }
    }

    return null;
  }

  String? _validateFinalMetadata() {
    if (originalTitleController.text.trim().isEmpty) {
      return 'Le titre original est obligatoire.';
    }

    final shortSynopsis = synopsisController.text.trim();

    if (shortSynopsis.length < 150 || shortSynopsis.length > 300) {
      return 'Le synopsis court doit contenir entre '
          '150 et 300 caractères.';
    }

    final longSynopsis = descriptionController.text.trim();

    if (longSynopsis.isNotEmpty &&
        (longSynopsis.length < 500 || longSynopsis.length > 1000)) {
      return 'Le synopsis long, lorsqu’il est renseigné, '
          'doit contenir entre 500 et 1000 caractères.';
    }

    if (selectedGenres.isEmpty) {
      return 'Ajoutez au moins un genre.';
    }

    if (releaseYear == null) {
      return 'L’année de production est obligatoire.';
    }

    if (directorNameController.text.trim().isEmpty) {
      return 'Le réalisateur est obligatoire.';
    }

    if (screenwriterNameController.text.trim().isEmpty) {
      return 'Le scénariste est obligatoire.';
    }

    if (selectedAgeRating == null || selectedAgeRating!.trim().isEmpty) {
      return 'La classification est obligatoire.';
    }

    if (_contentType == ContentType.film) {
      final duration = int.tryParse(durationController.text.trim());

      if (duration == null || duration <= 0) {
        return 'La durée exacte du film est obligatoire '
            'et doit être supérieure à 0 minute.';
      }
    }

    if (selectedLanguage == null) {
      return 'La langue originale est obligatoire.';
    }

    if (selectedLanguage == LanguageOption.autres &&
        languageOtherController.text.trim().isEmpty) {
      return 'Précisez la langue originale.';
    }

    if (selectedAudioLanguages.isEmpty) {
      return 'Ajoutez au moins une langue audio.';
    }

    // selectedSubtitleLanguages peut rester vide :
    // [] signifie explicitement aucun sous-titre disponible.

    if (selectedCountry == null || selectedCountry!.trim().isEmpty) {
      return 'Le pays d’origine est obligatoire.';
    }

    if (selectedCountry == 'Autres' &&
        countryOtherController.text.trim().isEmpty) {
      return 'Précisez le pays d’origine.';
    }

    return null;
  }

  Future<void> _scrollToFilmMasterRequirements() async {
    _filmMasterRequirementsKey.currentState?.expand();

    await WidgetsBinding.instance.endOfFrame;

    final targetContext = _filmMasterRequirementsKey.currentContext;

    if (targetContext == null) {
      return;
    }

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: 0.12,
    );
  }

  Future<void> _saveForm() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.formValidationError),
        ),
      );
      return;
    }

    final metadataError = _validateFinalMetadata();

    if (metadataError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(metadataError)));
      return;
    }

    if (selectedGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.genreSelectionError),
        ),
      );
      return;
    }

    if (selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.languageSelectionError),
        ),
      );
      return;
    }
    if (selectedLanguage == LanguageOption.autres &&
        languageOtherController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.languageSpecifyError),
        ),
      );
      return;
    }

    if (selectedCountry == null || selectedCountry!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.countrySelectionError),
        ),
      );
      return;
    }
    if (selectedCountry == "Autres" &&
        countryOtherController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.countrySpecifyError),
        ),
      );
      return;
    }

    if (releaseYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.yearSelectionError),
        ),
      );
      return;
    }

    if (directorNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.directorNameError),
        ),
      );
      return;
    }
    if (screenwriterNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.screenwriterNameError),
        ),
      );
      return;
    }

    if (_contentType != ContentType.serie) {
      if (posterFile == null && !_serverHasPoster) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.posterSelectionError),
          ),
        );
        return;
      }
      if (bannerFile == null && !_serverHasBackdrop) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.bannerSelectionError),
          ),
        );
        return;
      }
      if (trailerFile == null && !_serverHasTrailer) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La bande-annonce est obligatoire '
              'avant la soumission.',
            ),
          ),
        );
        return;
      }

      if (videoFile == null && !_serverHasMaster) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.videoSelectionError),
          ),
        );
        return;
      }
    } else {
      if (seasons.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.seasonSelectionError),
          ),
        );
        return;
      }
      for (final w in seasons) {
        final valid = w.key.currentState?.validateSeason() ?? false;
        if (!valid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.seasonValidationError,
              ),
            ),
          );
          return;
        }
      }
    }

    setState(() => _isSubmitting = true);

    String? createdContentId;

    try {
      final service = ProducerService.instance;

      final contentId = await _saveDraft();

      if (contentId == null || contentId.isEmpty) {
        throw StateError('Impossible de créer ou sauvegarder le brouillon.');
      }

      createdContentId = contentId;

      final hasCompleteProducer = producers.any(
        (person) => person.name.trim().isNotEmpty && person.hasPersistedImage,
      );

      if (!hasCompleteProducer) {
        throw StateError(
          'Ajoutez au moins un producteur avec son nom '
          'et sa photo avant la soumission.',
        );
      }

      final hasCompleteActor = actors.any(
        (person) => person.name.trim().isNotEmpty && person.hasPersistedImage,
      );

      if (!hasCompleteActor) {
        throw StateError(
          'Ajoutez au moins un acteur avec son nom '
          'et sa photo avant la soumission.',
        );
      }

      await _persistDraftMedia(contentId);

      final technicalConformityError =
          _validateTechnicalConformityForSubmission();

      if (technicalConformityError != null) {
        final route = technicalConformityError.route;

        if (route == null) {
          throw StateError(technicalConformityError.message);
        }

        await route();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${technicalConformityError.message} '
              'Consultez les critères techniques affichés à cet emplacement. '
              'Le brouillon créé a été conservé.',
            ),
            duration: const Duration(seconds: 8),
          ),
        );

        return;
      }

      final selectedLanguageValue = switch (selectedLanguage!) {
        LanguageOption.francais => 'Français',
        LanguageOption.anglais => 'Anglais',
        LanguageOption.autres => languageOtherController.text.trim(),
      };

      final selectedCountryValue = selectedCountry == 'Autres'
          ? countryOtherController.text.trim()
          : selectedCountry!;

      final notes = <String>[
        'Langue : $selectedLanguageValue',
        'Pays : $selectedCountryValue',
        'Réalisateur : ${directorNameController.text.trim()}',
        'Scénariste : ${screenwriterNameController.text.trim()}',
        if (producers.isNotEmpty)
          'Producteurs : ${producers.map((person) => person.name).join(', ')}',
        if (actors.isNotEmpty)
          'Acteurs : ${actors.map((person) => person.name).join(', ')}',
      ].join('\n');

      await service.submitContent(contentId: contentId, producerNotes: notes);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Contenu envoyé avec succès. '
            'L’analyse technique et IA est en cours.',
          ),
        ),
      );

      _leaveUploadPage();
    } catch (error) {
      if (!mounted) return;

      final suffix = createdContentId == null
          ? ''
          : ' Le brouillon créé a été conservé.';

      final errorMessage = 'Échec de l’envoi : $error$suffix';

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Erreur d’envoi'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: SingleChildScrollView(child: SelectableText(errorMessage)),
            ),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: errorMessage));

                  if (!dialogContext.mounted) return;

                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Erreur copiée dans le presse-papiers.'),
                    ),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copier l’erreur'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Fermer'),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  ImageProvider<Object>? _teamImageProvider(PersonWithImage person) {
    final bytes = person.imageBytes;

    if (bytes != null && bytes.isNotEmpty) {
      return MemoryImage(bytes);
    }

    final finalUrl = person.imageUrl?.trim() ?? '';

    if (finalUrl.isNotEmpty) {
      return NetworkImage(finalUrl);
    }

    final previewUrl = person.previewUrl?.trim() ?? '';

    if (previewUrl.isNotEmpty) {
      return NetworkImage(previewUrl);
    }

    final localPath = person.imagePath?.trim() ?? '';

    if (localPath.isNotEmpty) {
      return FileImage(File(localPath));
    }

    return null;
  }

  Future<void> _confirmRemovePerson<T>(List<T> list, T item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmationTitle),
        content: Text(AppLocalizations.of(context)!.confirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.deleteButton),
          ),
        ],
      ),
    );
    if (ok == true) setState(() => list.remove(item));
  }

  List<int> get years {
    final currentYear = DateTime.now().year;
    return [for (var y = 1980; y <= currentYear; y++) y];
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _technicalConformityRefreshTimer?.cancel();
    _technicalSpecificationNotifier.dispose();

    titleController.removeListener(_scheduleAutoSave);
    originalTitleController.removeListener(_scheduleAutoSave);
    synopsisController.removeListener(_scheduleAutoSave);
    descriptionController.removeListener(_scheduleAutoSave);
    durationController.removeListener(_scheduleAutoSave);
    languageOtherController.removeListener(_scheduleAutoSave);
    countryOtherController.removeListener(_scheduleAutoSave);
    directorNameController.removeListener(_scheduleAutoSave);
    screenwriterNameController.removeListener(_scheduleAutoSave);

    titleController.dispose();
    originalTitleController.dispose();
    synopsisController.dispose();
    descriptionController.dispose();
    durationController.dispose();
    languageOtherController.dispose();
    countryOtherController.dispose();
    directorNameController.dispose();
    screenwriterNameController.dispose();
    videoPlayerController?.dispose();
    trailerPlayerController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ajouter un contenu',
                    style: AppTheme.textTitle.copyWith(fontSize: 24),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isBusy
                      ? null
                      : () async {
                          final contentId = await showDialog<String>(
                            context: context,
                            barrierDismissible: true,
                            builder: (dialogContext) {
                              return Dialog(
                                insetPadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 24,
                                ),
                                backgroundColor: AppTheme.background,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadiusMedium,
                                  ),
                                ),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 1000,
                                    maxHeight: 760,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusMedium,
                                    ),
                                    child: const ContentsPage(
                                      selectionMode: true,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );

                          if (!context.mounted) return;

                          final selectedId = contentId?.trim();

                          if (selectedId != null && selectedId.isNotEmpty) {
                            await _loadDraft(selectedId);
                          }
                        },
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('MES BROUILLONS'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 620),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Importer les métadonnées XML',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Le fichier est analysé '
                            'sans enregistrer ni '
                            'modifier le contenu.',
                          ),
                          if (_contentType == null) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Avant de télécharger le modèle XML, '
                                      'sélectionnez d’abord le type de contenu '
                                      '(Film ou Série) ci-dessous. Le modèle '
                                      'sera adapté au type choisi.',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _downloadXmlTemplate,
                          icon: const Icon(Icons.download_outlined),
                          label: const Text('TÉLÉCHARGER LE MODÈLE XML'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isLoadingXmlPreview || _isBusy
                              ? null
                              : _pickAndPreviewXmlMetadata,
                          icon: _isLoadingXmlPreview
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_file),
                          label: Text(
                            _isLoadingXmlPreview
                                ? 'ANALYSE…'
                                : 'IMPORTER UN XML',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            _TechnicalXmlRequirements(
              specificationListenable: _technicalSpecificationNotifier,
            ),

            _buildXmlMetadataPreviewCard(),

            Text(
              l10n.contentTypeLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<ContentType>(
              value: _contentType,
              items: ContentType.values
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.name.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() => _contentType = v);
                _scheduleAutoSave(immediate: true);
              },
              validator: (v) => v == null ? l10n.requiredFieldError : null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // TITLE
            TextFormField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: l10n.titleLabel,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? l10n.requiredFieldError : null,
            ),
            const SizedBox(height: 16),

            // TITRE ORIGINAL
            TextFormField(
              controller: originalTitleController,
              decoration: const InputDecoration(
                labelText: 'Titre original',
                helperText: 'Titre dans la langue originale du programme.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // SYNOPSIS COURT
            TextFormField(
              controller: synopsisController,
              decoration: const InputDecoration(
                labelText: 'Synopsis court',
                helperText: '150 à 300 caractères à la soumission finale.',
                border: OutlineInputBorder(),
              ),
              minLines: 3,
              maxLines: 5,
              maxLength: 300,
            ),
            const SizedBox(height: 16),

            // SYNOPSIS LONG
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Synopsis long',
                helperText:
                    'Facultatif — recommandé entre 500 et '
                    '1000 caractères.',
                border: OutlineInputBorder(),
              ),
              minLines: 5,
              maxLines: 10,
              maxLength: 1000,
            ),
            const SizedBox(height: 16),

            _TechnicalMetadataRequirements(
              specificationListenable: _technicalSpecificationNotifier,
              isSeries: _contentType == ContentType.serie,
              fields: const {
                'title',
                'original_title',
                'synopsis',
                'long_synopsis',
              },
            ),
            const SizedBox(height: 12),

            // GENRES
            Text(
              l10n.genresLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: allGenres.map((g) {
                final selected = selectedGenres.contains(g);
                return FilterChip(
                  label: Text(g),
                  selected: selected,
                  onSelected: (sel) {
                    setState(() {
                      if (sel) {
                        selectedGenres.add(g);
                      } else {
                        selectedGenres.remove(g);
                      }
                    });
                    _scheduleAutoSave();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            _TechnicalMetadataRequirements(
              specificationListenable: _technicalSpecificationNotifier,
              isSeries: _contentType == ContentType.serie,
              fields: const {'genres'},
            ),
            const SizedBox(height: 12),

            // LANGUE
            Text(
              l10n.languageLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<LanguageOption>(
              value: selectedLanguage,
              items: LanguageOption.values
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.name.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() => selectedLanguage = v);
                _scheduleAutoSave();
              },
              validator: (v) => v == null ? l10n.requiredFieldError : null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            if (selectedLanguage == LanguageOption.autres) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: languageOtherController,
                decoration: InputDecoration(
                  labelText: l10n.languageSpecifyLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (selectedLanguage == LanguageOption.autres &&
                      (v == null || v.isEmpty)) {
                    return l10n.requiredFieldError;
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 20),

            // PAYS
            Text(
              l10n.countryLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedCountry,
              items: [
                ...africanCountries.map(
                  (c) => DropdownMenuItem(value: c, child: Text(c)),
                ),
                DropdownMenuItem(
                  value: "Autres",
                  child: Text(l10n.otherOption),
                ),
              ],

              onChanged: (v) {
                setState(() => selectedCountry = v);
                _scheduleAutoSave();
              },
              validator: (v) =>
                  v == null || v.isEmpty ? l10n.requiredFieldError : null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            if (selectedCountry == "Autres") ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: countryOtherController,
                decoration: InputDecoration(
                  labelText: l10n.countrySpecifyLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (selectedCountry == "Autres" && (v == null || v.isEmpty)) {
                    return l10n.requiredFieldError;
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 20),

            _TechnicalMetadataRequirements(
              specificationListenable: _technicalSpecificationNotifier,
              isSeries: _contentType == ContentType.serie,
              fields: const {'original_language', 'country_of_origin'},
            ),
            const SizedBox(height: 12),

            // Année
            Text(
              l10n.releaseYearLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: releaseYear,
              items: years
                  .map(
                    (y) =>
                        DropdownMenuItem(value: y, child: Text(y.toString())),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() => releaseYear = v);
                _scheduleAutoSave();
              },
              validator: (v) => v == null ? l10n.requiredFieldError : null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // CLASSIFICATION
            DropdownButtonFormField<String>(
              value: selectedAgeRating,
              decoration: const InputDecoration(
                labelText: 'Classification',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Tout public',
                  child: Text('Tout public'),
                ),
                DropdownMenuItem(value: '12+', child: Text('12+')),
                DropdownMenuItem(value: '16+', child: Text('16+')),
                DropdownMenuItem(value: '18+', child: Text('18+')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedAgeRating = value;
                });
                _scheduleAutoSave();
              },
            ),
            const SizedBox(height: 20),

            if (_contentType == ContentType.film) ...[
              TextFormField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Durée exacte (minutes)',
                  helperText: 'Durée du film en minutes.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            _TechnicalMetadataRequirements(
              specificationListenable: _technicalSpecificationNotifier,
              isSeries: _contentType == ContentType.serie,
              fields: {
                'production_year',
                'age_rating',
                if (_contentType == ContentType.film) 'duration',
              },
            ),
            const SizedBox(height: 12),

            // LANGUES AUDIO
            Text(
              'Langues audio',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: null,
              decoration: const InputDecoration(
                labelText: 'Ajouter une langue audio',
                helperText: 'Au moins une langue audio est obligatoire.',
                border: OutlineInputBorder(),
              ),
              items: allLanguages
                  .where(
                    (language) => !selectedAudioLanguages.contains(language),
                  )
                  .map(
                    (language) => DropdownMenuItem<String>(
                      value: language,
                      child: Text(language),
                    ),
                  )
                  .toList(),
              onChanged: (language) {
                if (language == null) {
                  return;
                }

                setState(() {
                  selectedAudioLanguages.add(language);
                });

                _scheduleAutoSave();
              },
            ),
            if (selectedAudioLanguages.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedAudioLanguages
                    .map(
                      (language) => InputChip(
                        label: Text(language),
                        onDeleted: () {
                          setState(() {
                            selectedAudioLanguages.remove(language);
                          });

                          _scheduleAutoSave();
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 20),

            // SOUS-TITRES
            Text(
              'Langues des sous-titres',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: null,
              decoration: const InputDecoration(
                labelText: 'Ajouter une langue de sous-titres',
                helperText:
                    'Facultatif. Ne sélectionnez aucune langue '
                    'si le contenu ne possède pas de sous-titres.',
                border: OutlineInputBorder(),
              ),
              items: allLanguages
                  .where(
                    (language) => !selectedSubtitleLanguages.contains(language),
                  )
                  .map(
                    (language) => DropdownMenuItem<String>(
                      value: language,
                      child: Text(language),
                    ),
                  )
                  .toList(),
              onChanged: (language) {
                if (language == null) {
                  return;
                }

                setState(() {
                  selectedSubtitleLanguages.add(language);
                });

                _scheduleAutoSave();
              },
            ),
            if (selectedSubtitleLanguages.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedSubtitleLanguages
                    .map(
                      (language) => InputChip(
                        label: Text(language),
                        onDeleted: () {
                          setState(() {
                            selectedSubtitleLanguages.remove(language);
                          });

                          _scheduleAutoSave();
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 24),

            _TechnicalMetadataRequirements(
              specificationListenable: _technicalSpecificationNotifier,
              isSeries: _contentType == ContentType.serie,
              fields: const {'audio_languages', 'subtitle_languages'},
            ),
            const SizedBox(height: 12),

            // Équipe de production
            Text(
              l10n.productionTeamTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Réalisateur
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: directorNameController,
                    decoration: InputDecoration(
                      labelText: l10n.directorLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? l10n.requiredFieldError : null,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickPersonImageFor('director'),
                      icon: const Icon(Icons.add_a_photo),
                      label: Text(l10n.addImageButton),
                    ),
                    if (_primaryPersonImageProvider('director') != null)
                      const SizedBox(height: 6),
                    if (_primaryPersonImageProvider('director') != null)
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: _primaryPersonImageProvider(
                          'director',
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Scénariste
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: screenwriterNameController,
                    decoration: InputDecoration(
                      labelText: l10n.screenwriterLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? l10n.requiredFieldError : null,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickPersonImageFor('screenwriter'),
                      icon: const Icon(Icons.add_a_photo),
                      label: Text(l10n.addImageButton),
                    ),
                    if (_primaryPersonImageProvider('screenwriter') != null)
                      const SizedBox(height: 6),
                    if (_primaryPersonImageProvider('screenwriter') != null)
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: _primaryPersonImageProvider(
                          'screenwriter',
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Producteurs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.producersLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: _addProducer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: Text(l10n.addButton),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...producers.map((p) {
              final imageProvider = _teamImageProvider(p);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: imageProvider,
                    radius: 20,
                    child: imageProvider == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(p.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmRemovePerson(producers, p),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),

            // Acteurs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.actorsLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: _addActor,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: Text(l10n.addButton),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...actors.map((p) {
              final imageProvider = _teamImageProvider(p);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: imageProvider,
                    radius: 20,
                    child: imageProvider == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(p.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmRemovePerson(actors, p),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            _TechnicalMetadataRequirements(
              specificationListenable: _technicalSpecificationNotifier,
              isSeries: _contentType == ContentType.serie,
              fields: const {'directors', 'cast', 'screenwriters', 'producers'},
            ),
            const SizedBox(height: 12),

            // --- Saisons (si série) ---
            if (_contentType == ContentType.serie) ...[
              _TechnicalMetadataRequirements(
                specificationListenable: _technicalSpecificationNotifier,
                isSeries: true,
                fields: const {'season_episode'},
              ),
              const SizedBox(height: 12),

              Text(
                l10n.seasonManagementTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.seasonsLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: _addSeason,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: Text(l10n.addSeasonButton),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...seasons.map((w) => w.season),
              const SizedBox(height: 16),
            ],

            // Bande annonce
            if (_contentType != ContentType.serie) ...[
              Text(
                l10n.trailerLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _pickTrailer,
                    child: Text(l10n.addTrailerButton),
                  ),
                  const SizedBox(width: 16),
                  if (trailerFile != null &&
                      trailerPlayerController != null &&
                      trailerPlayerController!.value.isInitialized)
                    Container(
                      width: 200,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio:
                              trailerPlayerController!.value.aspectRatio,
                          child: VideoPlayer(trailerPlayerController!),
                        ),
                      ),
                    ),
                  if (trailerFile != null &&
                      (trailerPlayerController == null ||
                          !trailerPlayerController!.value.isInitialized))
                    Text(trailerFile!.path.split('/').last)
                  else if (_serverHasTrailer)
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Bande-annonce déjà enregistrée'),
                      ],
                    ),
                ],
              ),
              _TechnicalTrailerRequirements(
                specificationListenable: _technicalSpecificationNotifier,
                deliveryLevel: selectedDeliveryLevel,
              ),

              const SizedBox(height: 10),

              if (_serverHasTrailer &&
                  _contentTrailerTechnicalConformity != null) ...[
                const SizedBox(height: 12),
                _TechnicalConformityBadge(
                  report: _contentTrailerTechnicalConformity!,
                  assetLabel: 'Bande-annonce',
                  onRetry: _retryContentTrailerAnalysis,
                ),
              ],
              if (trailerFile != null &&
                  trailerPlayerController != null &&
                  trailerPlayerController!.value.isInitialized) ...[
                const SizedBox(height: 8),
                VideoProgressIndicator(
                  trailerPlayerController!,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Colors.red,
                    bufferedColor: Colors.grey,
                    backgroundColor: Colors.grey,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    trailerPlayerController!.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    size: 36,
                  ),
                  onPressed: () {
                    setState(() {
                      if (trailerPlayerController!.value.isPlaying) {
                        trailerPlayerController!.pause();
                      } else {
                        trailerPlayerController!.play();
                      }
                    });
                  },
                ),
              ],
              const SizedBox(height: 24),
            ],

            if (_contentType != ContentType.serie) ...[
              // Fichiers multimédias (pour film)
              Text(
                l10n.mediaFilesTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                l10n.posterLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _pickGlobalPoster(true),
                    child: Text(l10n.addPosterButton),
                  ),
                  const SizedBox(width: 16),
                  if (posterFile != null)
                    Container(
                      width: 100,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.network(posterFile!.path, fit: BoxFit.cover),
                    )
                  else if (_serverHasPoster)
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Affiche déjà enregistrée'),
                      ],
                    ),
                ],
              ),

              _TechnicalImageRequirements(
                specificationListenable: _technicalSpecificationNotifier,
                sectionKey: 'poster',
              ),

              const SizedBox(height: 20),

              Text(
                l10n.bannerLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _pickGlobalPoster(false),
                    child: Text(l10n.addBannerButton),
                  ),
                  const SizedBox(width: 16),
                  if (bannerFile != null)
                    Container(
                      width: 200,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.network(bannerFile!.path, fit: BoxFit.cover),
                    )
                  else if (_serverHasBackdrop)
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Bannière déjà enregistrée'),
                      ],
                    ),
                ],
              ),

              _TechnicalImageRequirements(
                specificationListenable: _technicalSpecificationNotifier,
                sectionKey: 'banner',
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.35),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Niveau de livraison du master',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sélectionnez le niveau technique '
                      'correspondant au fichier master.',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedDeliveryLevel,
                      decoration: const InputDecoration(
                        labelText: 'Niveau du master',
                        border: OutlineInputBorder(),
                      ),
                      items: deliveryLevelLabels.entries
                          .map(
                            (entry) => DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: _isBusy
                          ? null
                          : (value) {
                              if (value == null ||
                                  !deliveryLevelLabels.containsKey(value)) {
                                return;
                              }

                              setState(() => selectedDeliveryLevel = value);

                              _scheduleAutoSave(immediate: true);
                            },
                    ),
                    const SizedBox(height: 10),
                    _TechnicalNamingRequirements(
                      specificationListenable: _technicalSpecificationNotifier,
                      namingContext: 'film',
                    ),
                    const SizedBox(height: 10),
                    _TechnicalMasterRequirements(
                      specificationListenable: _technicalSpecificationNotifier,
                      deliveryLevel: selectedDeliveryLevel,
                      accordionKey: _filmMasterRequirementsKey,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Text(
                l10n.mainVideoLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _pickGlobalVideo,
                    child: Text(l10n.addVideoButton),
                  ),
                  const SizedBox(width: 16),
                  if (videoFile != null &&
                      videoPlayerController != null &&
                      videoPlayerController!.value.isInitialized)
                    Container(
                      width: 200,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: videoPlayerController!.value.aspectRatio,
                          child: VideoPlayer(videoPlayerController!),
                        ),
                      ),
                    ),
                  if (videoFile != null &&
                      (videoPlayerController == null ||
                          !videoPlayerController!.value.isInitialized))
                    Text(videoFile!.path.split('/').last),
                  if (videoFile == null && _serverHasMaster)
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Vidéo master déjà enregistrée'),
                      ],
                    ),
                ],
              ),
              if (_serverHasMaster && _movieTechnicalConformity != null) ...[
                const SizedBox(height: 12),
                _TechnicalConformityBadge(
                  report: _movieTechnicalConformity!,
                  assetLabel: 'Master du film',
                ),
              ],

              if (videoFile != null &&
                  videoPlayerController != null &&
                  videoPlayerController!.value.isInitialized) ...[
                const SizedBox(height: 8),
                VideoProgressIndicator(
                  videoPlayerController!,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Colors.red,
                    bufferedColor: Colors.grey,
                    backgroundColor: Colors.grey,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    videoPlayerController!.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    size: 36,
                  ),
                  onPressed: () {
                    setState(() {
                      if (videoPlayerController!.value.isPlaying) {
                        videoPlayerController!.pause();
                      } else {
                        videoPlayerController!.play();
                      }
                    });
                  },
                ),
              ],
              const SizedBox(height: 24),
            ],

            // ETAT DE SAUVEGARDE / UPLOAD
            if (_autoSaveStatus != null) ...[
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 760),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      _autoSaveStatus!.startsWith('Toutes les modifications')
                          ? Icons.check_circle_outline
                          : _autoSaveStatus!.startsWith(
                              'Sauvegarde automatique interrompue',
                            )
                          ? Icons.warning_amber_rounded
                          : Icons.sync,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _autoSaveStatus!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_isBusy && _savingStatus != null) ...[
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 760),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _savingStatus!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            _TechnicalPrinciplesRequirements(
              specificationListenable: _technicalSpecificationNotifier,
            ),

            _TechnicalConformityRequirements(
              specificationListenable: _technicalSpecificationNotifier,
            ),

            _TechnicalDeadlineRequirements(
              specificationListenable: _technicalSpecificationNotifier,
            ),

            // ACTIONS BROUILLON + SOUMISSION
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: _isBusy
                      ? null
                      : () async {
                          try {
                            final draftId = await _saveDraft(
                              showConfirmation: false,
                            );

                            if (draftId == null || draftId.isEmpty) {
                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Choisissez le type et '
                                    'renseignez le titre.',
                                  ),
                                ),
                              );
                              return;
                            }

                            await _persistDraftMedia(draftId);

                            if (!context.mounted) return;

                            _setSavingStatus(null);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Brouillon et médias '
                                  'enregistrés.',
                                ),
                              ),
                            );
                          } catch (error) {
                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Impossible d’enregistrer le brouillon : '
                                  '$error',
                                ),
                              ),
                            );
                          }
                        },
                  icon: _isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 14,
                    ),
                    child: Text(
                      _isBusy ? 'ENREGISTREMENT…' : 'ENREGISTRER LE BROUILLON',
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isBusy ? null : _saveDraftAndQuit,
                  icon: _isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.exit_to_app),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 14,
                    ),
                    child: Text(
                      _isBusy ? 'ENREGISTREMENT…' : 'ENREGISTRER ET QUITTER',
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isSubmitting || _isSavingDraft || _isLoadingDraft
                      ? null
                      : _saveForm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            l10n.submitButton.toUpperCase(),
                            style: const TextStyle(fontSize: 18),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class SeasonWrapper {
  final GlobalKey<SeasonState> key;
  final SeasonForm season;
  String? serverId;

  SeasonWrapper({required this.key, required this.season, this.serverId});
}

class EpisodeInitialData {
  final String serverId;
  final int episodeNumber;
  final String title;
  final String description;
  final int? duration;
  final bool serverHasVideo;
  final String deliveryLevel;
  final TechnicalConformityReport? technicalConformity;

  const EpisodeInitialData({
    required this.serverId,
    required this.episodeNumber,
    required this.title,
    required this.description,
    required this.duration,
    required this.serverHasVideo,
    this.deliveryLevel = 'distribution',
    this.technicalConformity,
  });
}

class SeasonForm extends StatefulWidget {
  final ValueListenable<Map<String, dynamic>?> technicalSpecificationListenable;
  final String deliveryLevel;
  final int seasonNumber;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final Future<void> Function()? onRetryTrailerAnalysis;
  final String initialTitle;
  final String initialDescription;
  final bool initialServerHasPoster;
  final bool initialServerHasBackdrop;
  final bool initialServerHasTrailer;
  final TechnicalConformityReport? initialTrailerTechnicalConformity;
  final List<EpisodeInitialData> initialEpisodes;

  const SeasonForm({
    super.key,
    required this.technicalSpecificationListenable,
    required this.deliveryLevel,
    required this.seasonNumber,
    required this.onRemove,
    required this.onChanged,
    this.onRetryTrailerAnalysis,
    this.initialTitle = '',
    this.initialDescription = '',
    this.initialServerHasPoster = false,
    this.initialServerHasBackdrop = false,
    this.initialServerHasTrailer = false,
    this.initialTrailerTechnicalConformity,
    this.initialEpisodes = const [],
  });

  @override
  SeasonState createState() => SeasonState();
}

class SeasonState extends State<SeasonForm> {
  final TextEditingController seasonTitleController = TextEditingController();
  final TextEditingController seasonDescriptionController =
      TextEditingController();

  XFile? posterFile;
  XFile? bannerFile;
  XFile? trailerFile;

  bool serverHasPoster = false;
  bool serverHasBackdrop = false;
  bool serverHasTrailer = false;
  TechnicalConformityReport? trailerTechnicalConformity;

  final ImagePicker _picker = ImagePicker();

  final List<EpisodeWrapper> episodes = [];
  final List<String> deletedEpisodeIds = [];

  @override
  void initState() {
    super.initState();

    seasonTitleController.text = widget.initialTitle;
    seasonDescriptionController.text = widget.initialDescription;

    seasonTitleController.addListener(widget.onChanged);
    seasonDescriptionController.addListener(widget.onChanged);

    serverHasPoster = widget.initialServerHasPoster;
    serverHasBackdrop = widget.initialServerHasBackdrop;
    serverHasTrailer = widget.initialServerHasTrailer;
    trailerTechnicalConformity = widget.initialTrailerTechnicalConformity;

    for (final initial in widget.initialEpisodes) {
      _appendEpisode(
        episodeNumber: initial.episodeNumber,
        serverId: initial.serverId,
        initialTitle: initial.title,
        initialDescription: initial.description,
        initialDuration: initial.duration,
        initialServerHasVideo: initial.serverHasVideo,
        initialDeliveryLevel: initial.deliveryLevel,
        initialTechnicalConformity: initial.technicalConformity,
        notify: false,
      );
    }
  }

  void _appendEpisode({
    required int episodeNumber,
    String? serverId,
    String initialTitle = '',
    String initialDescription = '',
    int? initialDuration,
    bool initialServerHasVideo = false,
    String initialDeliveryLevel = 'distribution',
    TechnicalConformityReport? initialTechnicalConformity,
    bool notify = true,
  }) {
    final key = GlobalKey<EpisodeState>();

    late final EpisodeWrapper wrapper;

    wrapper = EpisodeWrapper(
      key: key,
      serverId: serverId,
      episode: EpisodeForm(
        key: key,
        technicalSpecificationListenable:
            widget.technicalSpecificationListenable,
        episodeNumber: episodeNumber,
        onChanged: widget.onChanged,
        initialTitle: initialTitle,
        initialDescription: initialDescription,
        initialDuration: initialDuration,
        initialServerHasVideo: initialServerHasVideo,
        initialDeliveryLevel: initialDeliveryLevel,
        initialTechnicalConformity: initialTechnicalConformity,
        onRemove: () {
          final id = wrapper.serverId?.trim() ?? '';

          setState(() {
            if (id.isNotEmpty) {
              deletedEpisodeIds.add(id);
            }

            episodes.removeWhere((item) => identical(item, wrapper));
          });

          widget.onChanged();
        },
      ),
    );

    if (notify) {
      setState(() => episodes.add(wrapper));
      widget.onChanged();
    } else {
      episodes.add(wrapper);
    }
  }

  Future<void> _pickSeasonPoster() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      posterFile = picked;
    });

    widget.onChanged();
  }

  Future<void> _pickSeasonBanner() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      bannerFile = picked;
    });

    widget.onChanged();
  }

  Future<void> _pickSeasonTrailer() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      trailerFile = picked;
    });

    widget.onChanged();
  }

  void markPosterPersisted() {
    if (!mounted) {
      serverHasPoster = true;
      posterFile = null;
      return;
    }

    setState(() {
      serverHasPoster = true;
      posterFile = null;
    });
  }

  void markBackdropPersisted() {
    if (!mounted) {
      serverHasBackdrop = true;
      bannerFile = null;
      return;
    }

    setState(() {
      serverHasBackdrop = true;
      bannerFile = null;
    });
  }

  void markTrailerPersisted([TechnicalConformityReport? conformity]) {
    if (!mounted) {
      serverHasTrailer = true;
      trailerFile = null;
      trailerTechnicalConformity = conformity;
      return;
    }

    setState(() {
      serverHasTrailer = true;
      trailerFile = null;
      trailerTechnicalConformity = conformity;
    });
  }

  void setTrailerTechnicalConformity(TechnicalConformityReport? conformity) {
    if (!mounted) {
      trailerTechnicalConformity = conformity;
      return;
    }

    setState(() {
      trailerTechnicalConformity = conformity;
    });
  }

  void _addEpisode() {
    final nextNumber = episodes.isEmpty
        ? 1
        : episodes
                  .map((wrapper) => wrapper.episode.episodeNumber)
                  .reduce((a, b) => a > b ? a : b) +
              1;

    _appendEpisode(episodeNumber: nextNumber);
  }

  bool validateSeason() {
    if (seasonDescriptionController.text.trim().isEmpty) {
      return false;
    }

    if (posterFile == null && !serverHasPoster) {
      return false;
    }

    if (bannerFile == null && !serverHasBackdrop) {
      return false;
    }

    if (trailerFile == null && !serverHasTrailer) {
      return false;
    }

    if (episodes.isEmpty) {
      return false;
    }

    for (final wrapper in episodes) {
      if (!(wrapper.key.currentState?.validateEpisode() ?? false)) {
        return false;
      }
    }

    return true;
  }

  @override
  void dispose() {
    seasonTitleController.removeListener(widget.onChanged);
    seasonDescriptionController.removeListener(widget.onChanged);

    seasonTitleController.dispose();
    seasonDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${l10n.seasonLabel} '
                  '${widget.seasonNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addEpisode,
                      tooltip: l10n.addEpisodeTooltip,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: widget.onRemove,
                      tooltip: l10n.removeSeasonTooltip,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: seasonTitleController,
              decoration: const InputDecoration(
                labelText: 'Titre de la saison (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: seasonDescriptionController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Résumé / descriptif de la saison *',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 14),

            _SeasonMediaSelector(
              label: 'Poster de la saison *',
              buttonLabel: 'Ajouter le poster',
              file: posterFile,
              serverHasMedia: serverHasPoster,
              onPressed: _pickSeasonPoster,
            ),

            _TechnicalImageRequirements(
              specificationListenable: widget.technicalSpecificationListenable,
              sectionKey: 'poster',
            ),

            const SizedBox(height: 12),

            _SeasonMediaSelector(
              label: 'Bannière de la saison *',
              buttonLabel: 'Ajouter la bannière',
              file: bannerFile,
              serverHasMedia: serverHasBackdrop,
              onPressed: _pickSeasonBanner,
            ),

            _TechnicalImageRequirements(
              specificationListenable: widget.technicalSpecificationListenable,
              sectionKey: 'banner',
            ),

            const SizedBox(height: 12),

            _SeasonMediaSelector(
              label: 'Trailer de la saison *',
              buttonLabel: 'Ajouter le trailer',
              file: trailerFile,
              serverHasMedia: serverHasTrailer,
              onPressed: _pickSeasonTrailer,
            ),

            _TechnicalNamingRequirements(
              specificationListenable: widget.technicalSpecificationListenable,
              namingContext: 'series_trailer',
            ),

            _TechnicalTrailerRequirements(
              specificationListenable: widget.technicalSpecificationListenable,
              deliveryLevel: widget.deliveryLevel,
            ),

            const SizedBox(height: 10),

            if (serverHasTrailer && trailerTechnicalConformity != null) ...[
              const SizedBox(height: 10),
              _TechnicalConformityBadge(
                report: trailerTechnicalConformity!,
                assetLabel: 'Trailer saison ${widget.seasonNumber}',
                onRetry: widget.onRetryTrailerAnalysis,
              ),
            ],

            const SizedBox(height: 18),

            Text(
              l10n.episodesLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            ...episodes.map((wrapper) => wrapper.episode),

            if (episodes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Ajoutez au moins un épisode.'),
              ),
          ],
        ),
      ),
    );
  }
}

class _SeasonMediaSelector extends StatelessWidget {
  final String label;
  final String buttonLabel;
  final XFile? file;
  final bool serverHasMedia;
  final VoidCallback onPressed;

  const _SeasonMediaSelector({
    required this.label,
    required this.buttonLabel,
    required this.file,
    required this.serverHasMedia,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final selectedName = file?.name.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.upload_file),
              label: Text(buttonLabel),
            ),
            if (selectedName.isNotEmpty)
              Text(selectedName, overflow: TextOverflow.ellipsis)
            else if (serverHasMedia)
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 6),
                  Text('Déjà enregistré'),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class EpisodeWrapper {
  final GlobalKey<EpisodeState> key;
  final EpisodeForm episode;
  String? serverId;

  EpisodeWrapper({required this.key, required this.episode, this.serverId});
}

class EpisodeForm extends StatefulWidget {
  final ValueListenable<Map<String, dynamic>?> technicalSpecificationListenable;
  final int episodeNumber;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final String initialTitle;
  final String initialDescription;
  final int? initialDuration;
  final bool initialServerHasVideo;
  final String initialDeliveryLevel;
  final TechnicalConformityReport? initialTechnicalConformity;

  const EpisodeForm({
    super.key,
    required this.technicalSpecificationListenable,
    required this.episodeNumber,
    required this.onRemove,
    required this.onChanged,
    this.initialTitle = '',
    this.initialDescription = '',
    this.initialDuration,
    this.initialServerHasVideo = false,
    this.initialDeliveryLevel = 'distribution',
    this.initialTechnicalConformity,
  });

  @override
  EpisodeState createState() => EpisodeState();
}

class EpisodeState extends State<EpisodeForm> {
  final GlobalKey<_TechnicalRequirementsAccordionState> _masterRequirementsKey =
      GlobalKey<_TechnicalRequirementsAccordionState>();

  final TextEditingController titleController = TextEditingController();

  final TextEditingController descController = TextEditingController();

  final TextEditingController durationController = TextEditingController();

  XFile? videoFile;
  bool serverHasVideo = false;

  String selectedDeliveryLevel = 'distribution';

  static const Map<String, String> deliveryLevelLabels = {
    'premium': 'Master Premium',
    'standard': 'Master Standard',
    'distribution': 'Master Distribution',
  };

  TechnicalConformityReport? technicalConformity;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    titleController.text = widget.initialTitle;
    descController.text = widget.initialDescription;
    durationController.text = widget.initialDuration?.toString() ?? '';

    titleController.addListener(widget.onChanged);
    descController.addListener(widget.onChanged);
    durationController.addListener(widget.onChanged);

    serverHasVideo = widget.initialServerHasVideo;

    final initialLevel = widget.initialDeliveryLevel.trim().toLowerCase();

    selectedDeliveryLevel = deliveryLevelLabels.containsKey(initialLevel)
        ? initialLevel
        : 'distribution';

    technicalConformity = widget.initialTechnicalConformity;
  }

  Future<XFile?> _pickVideo() async {
    return _picker.pickVideo(source: ImageSource.gallery);
  }

  Future<void> scrollToMasterRequirements() async {
    _masterRequirementsKey.currentState?.expand();

    await WidgetsBinding.instance.endOfFrame;

    final targetContext = _masterRequirementsKey.currentContext;

    if (targetContext == null) {
      return;
    }

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: 0.12,
    );
  }

  bool validateEpisode() {
    if (titleController.text.trim().isEmpty) {
      return false;
    }

    if (descController.text.trim().isEmpty) {
      return false;
    }

    final duration = int.tryParse(durationController.text.trim());

    if (duration == null || duration <= 0) {
      return false;
    }

    if (videoFile == null && !serverHasVideo) {
      return false;
    }

    return true;
  }

  void setServerVideoAsset(
    Map<String, dynamic>? asset, {
    bool invalidateConformity = false,
  }) {
    final hasVideo = asset != null;

    final report = asset == null || invalidateConformity
        ? null
        : TechnicalConformityReport.fromVideoAsset(asset);

    if (!mounted) {
      serverHasVideo = hasVideo;
      technicalConformity = report;
      return;
    }

    setState(() {
      serverHasVideo = hasVideo;
      technicalConformity = report;
    });
  }

  void markVideoPersisted(Map<String, dynamic> asset) {
    final report = TechnicalConformityReport.fromVideoAsset(asset);

    if (!mounted) {
      serverHasVideo = true;
      videoFile = null;
      technicalConformity = report;
      return;
    }

    setState(() {
      serverHasVideo = true;
      videoFile = null;
      technicalConformity = report;
    });
  }

  @override
  void dispose() {
    titleController.removeListener(widget.onChanged);
    descController.removeListener(widget.onChanged);
    durationController.removeListener(widget.onChanged);

    titleController.dispose();
    descController.dispose();
    durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${l10n.episodeLabel} '
                  '${widget.episodeNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onRemove,
                ),
              ],
            ),

            const SizedBox(height: 8),

            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Titre de l’épisode',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.requiredFieldError
                  : null,
            ),

            const SizedBox(height: 8),

            TextFormField(
              controller: descController,
              decoration: InputDecoration(
                labelText: l10n.episodeDescriptionLabel,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.requiredFieldError
                  : null,
            ),

            const SizedBox(height: 8),

            TextFormField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Durée exacte (minutes)',
                helperText: 'Durée exacte de cet épisode en minutes.',
                border: OutlineInputBorder(),
              ),
            ),

            _TechnicalMetadataRequirements(
              specificationListenable: widget.technicalSpecificationListenable,
              isSeries: true,
              fields: const {'duration'},
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: selectedDeliveryLevel,
              decoration: const InputDecoration(
                labelText: 'Niveau de livraison du master',
                helperText: 'Ce niveau s’applique uniquement à cet épisode.',
                border: OutlineInputBorder(),
              ),
              items: deliveryLevelLabels.entries
                  .map(
                    (entry) => DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null ||
                    !deliveryLevelLabels.containsKey(value) ||
                    value == selectedDeliveryLevel) {
                  return;
                }

                setState(() {
                  selectedDeliveryLevel = value;

                  // Le rapport actuel a été calculé avec l'ancien
                  // profil technique. Il devient donc obsolète
                  // immédiatement.
                  technicalConformity = null;
                });

                widget.onChanged();
              },
            ),

            const SizedBox(height: 8),

            _TechnicalNamingRequirements(
              specificationListenable: widget.technicalSpecificationListenable,
              namingContext: 'episode',
            ),

            _TechnicalMasterRequirements(
              specificationListenable: widget.technicalSpecificationListenable,
              deliveryLevel: selectedDeliveryLevel,
              accordionKey: _masterRequirementsKey,
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final picked = await _pickVideo();

                    if (picked == null) {
                      return;
                    }

                    setState(() {
                      videoFile = picked;

                      // Le rapport existant appartient à l'ancien
                      // fichier master et ne doit plus être affiché.
                      technicalConformity = null;
                    });

                    widget.onChanged();
                  },
                  child: Text(
                    serverHasVideo ? 'Remplacer la vidéo' : l10n.addVideoButton,
                  ),
                ),

                if (videoFile != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Text(
                      videoFile!.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else if (serverHasVideo)
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, size: 18),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Vidéo master déjà enregistrée',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            if (serverHasVideo && technicalConformity != null) ...[
              const SizedBox(height: 12),
              _TechnicalConformityBadge(
                report: technicalConformity!,
                assetLabel: 'Master épisode ${widget.episodeNumber}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TechnicalConformityBadge extends StatelessWidget {
  const _TechnicalConformityBadge({
    required this.report,
    required this.assetLabel,
    this.onRetry,
  });

  final TechnicalConformityReport report;
  final String assetLabel;
  final Future<void> Function()? onRetry;

  IconData get _icon {
    switch (report.displayStatus) {
      case TechnicalConformityDisplayStatus.conform:
        return Icons.check_circle_outline;

      case TechnicalConformityDisplayStatus.nonConform:
        return Icons.cancel_outlined;

      case TechnicalConformityDisplayStatus.reviewRequired:
        return Icons.warning_amber_rounded;

      case TechnicalConformityDisplayStatus.analyzing:
        return Icons.sync;

      case TechnicalConformityDisplayStatus.notStarted:
        return Icons.schedule;

      case TechnicalConformityDisplayStatus.failed:
        return Icons.error_outline;

      case TechnicalConformityDisplayStatus.unknown:
        return Icons.help_outline;
    }
  }

  Color _color(BuildContext context) {
    switch (report.displayStatus) {
      case TechnicalConformityDisplayStatus.conform:
        return Colors.green.shade700;

      case TechnicalConformityDisplayStatus.nonConform:
      case TechnicalConformityDisplayStatus.failed:
        return Theme.of(context).colorScheme.error;

      case TechnicalConformityDisplayStatus.reviewRequired:
        return Colors.orange.shade800;

      case TechnicalConformityDisplayStatus.analyzing:
        return Colors.blue.shade700;

      case TechnicalConformityDisplayStatus.notStarted:
      case TechnicalConformityDisplayStatus.unknown:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  String _valueText(dynamic value) {
    if (value == null) {
      return '—';
    }

    if (value is List) {
      if (value.isEmpty) {
        return '—';
      }

      return value.join(', ');
    }

    if (value is Map) {
      return value.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(', ');
    }

    final text = value.toString().trim();

    return text.isEmpty ? '—' : text;
  }

  Future<void> _showReport(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final color = _color(dialogContext);

        return AlertDialog(
          title: const Text('Rapport de conformité technique'),
          content: SizedBox(
            width: 720,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assetLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Icon(_icon, color: color),
                      const SizedBox(width: 8),
                      Text(
                        report.displayLabel,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  if (report.displayStatus ==
                          TechnicalConformityDisplayStatus.failed &&
                      onRetry != null) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          await onRetry!();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('RÉESSAYER L’ANALYSE'),
                      ),
                    ),
                  ],

                  if (report.specificationVersion != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Cahier des charges : '
                      'version '
                      '${report.specificationVersion}',
                    ),
                  ],

                  if (report.blockingErrors.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Corrections obligatoires',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...report.blockingErrors.map(
                      (message) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 18,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(message)),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (report.warnings.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Points à vérifier',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...report.warnings.map(
                      (message) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 18,
                              color: Colors.orange.shade800,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(message)),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (report.checks.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Contrôles techniques',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...report.checks.map((check) {
                      final passed = check.isPassed;
                      final failed = check.isFailed;
                      final review = check.isReview;

                      final checkColor = failed
                          ? theme.colorScheme.error
                          : review
                          ? Colors.orange.shade800
                          : passed
                          ? Colors.green.shade700
                          : theme.colorScheme.onSurfaceVariant;

                      final checkIcon = failed
                          ? Icons.cancel_outlined
                          : review
                          ? Icons.warning_amber_rounded
                          : passed
                          ? Icons.check_circle_outline
                          : Icons.help_outline;

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.4),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(checkIcon, size: 18, color: checkColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    check.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (check.ruleKey.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                check.ruleKey,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],

                            if (check.expected != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Attendu : '
                                '${_valueText(check.expected)}',
                              ),
                            ],

                            if (check.actual != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Détecté : '
                                '${_valueText(check.actual)}',
                              ),
                            ],

                            if (check.message != null) ...[
                              const SizedBox(height: 6),
                              Text(check.message!),
                            ],

                            if (check.blocking) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Contrôle bloquant',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],

                  if (!report.hasDetails) ...[
                    const SizedBox(height: 16),
                    Text(switch (report.displayStatus) {
                      TechnicalConformityDisplayStatus.analyzing =>
                        'L’analyse technique est '
                            'toujours en cours.',
                      TechnicalConformityDisplayStatus.notStarted =>
                        'L’analyse technique '
                            'n’a pas encore commencé.',
                      TechnicalConformityDisplayStatus.failed =>
                        'L’analyse technique '
                            'n’a pas pu être terminée.',
                      TechnicalConformityDisplayStatus.reviewRequired =>
                        'Le master nécessite '
                            'une vérification complémentaire.',
                      _ =>
                        'Aucun détail supplémentaire '
                            'n’est disponible.',
                    }),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('FERMER'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);

    return OutlinedButton.icon(
      onPressed: () => _showReport(context),
      icon: Icon(_icon, size: 18, color: color),
      label: Text(
        report.displayLabel,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.55)),
      ),
    );
  }
}
