import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';

import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/models/producer_analytics.dart';
import 'package:plateforme_producteurs/models/technical_conformity_report.dart';
import 'package:plateforme_producteurs/services/producer_service.dart';

class ContentDetailsModal extends StatefulWidget {
  final Map<String, dynamic> content;

  const ContentDetailsModal({super.key, required this.content});

  @override
  State<ContentDetailsModal> createState() => _ContentDetailsModalState();
}

class _ContentDetailsModalState extends State<ContentDetailsModal> {
  String _humanDateTime(dynamic raw) {
    if (raw == null) return 'Non renseigné';

    final value = raw.toString().trim();
    if (value.isEmpty) return 'Non renseigné';

    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;

    final local = parsed.toLocal();

    return DateFormat("d MMMM yyyy 'à' HH:mm", 'fr_FR').format(local);
  }

  ProducerAnalyticsDetail? _analytics;
  bool _analyticsLoading = true;
  String? _analyticsError;

  final Map<String, String> _contentMediaPreviewUrls = {};
  final Map<String, String> _seasonMediaPreviewUrls = {};
  bool _mediaPreviewsLoading = false;

  String _filmMasterPreviewUrl = '';
  bool _filmMasterPreviewLoading = false;

  int _selectedTab = 0;

  Map<String, dynamic> get content => widget.content;

  bool get _isSeries =>
      (content['type']?.toString().trim().toLowerCase() ?? '') == 'series';

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
    _loadMediaPreviews();
    _loadFilmMasterPreview();
  }

  String _rawValue(Map<String, dynamic> source, String field) {
    return source[field]?.toString().trim() ?? '';
  }

  String _resolvedContentMedia(String finalField, String tempField) {
    final finalUrl = _rawValue(content, finalField);

    if (finalUrl.isNotEmpty) {
      return finalUrl;
    }

    final temporaryPath = _rawValue(content, tempField);

    if (temporaryPath.isEmpty) {
      return '';
    }

    return _contentMediaPreviewUrls[temporaryPath] ?? '';
  }

  String _resolvedSeasonMedia(
    Map<String, dynamic> season,
    String finalField,
    String tempField,
  ) {
    final finalUrl = _rawValue(season, finalField);

    if (finalUrl.isNotEmpty) {
      return finalUrl;
    }

    final temporaryPath = _rawValue(season, tempField);

    if (temporaryPath.isEmpty) {
      return '';
    }

    return _seasonMediaPreviewUrls[temporaryPath] ?? '';
  }

  bool _videoAssetHasUploadedSource(Map<String, dynamic> asset) {
    final uploadedAt = asset['source_uploaded_at']?.toString().trim() ?? '';

    final rawSize = asset['source_file_size_bytes'];

    final size = rawSize is num
        ? rawSize.toInt()
        : int.tryParse(rawSize?.toString() ?? '') ?? 0;

    return uploadedAt.isNotEmpty || size > 0;
  }

  Map<String, dynamic>? _preferredFilmVideoAsset(
    List<Map<String, dynamic>> assets,
  ) {
    final uploaded = assets.where(_videoAssetHasUploadedSource).toList();

    if (uploaded.isEmpty) {
      return null;
    }

    for (final asset in uploaded) {
      if (asset['is_default'] == true) {
        return asset;
      }
    }

    return uploaded.first;
  }

  String _resolvedFilmMaster() {
    final finalUrl = _text('video_url', fallback: '');

    if (finalUrl.isNotEmpty) {
      return finalUrl;
    }

    return _filmMasterPreviewUrl.trim();
  }

  Future<void> _loadFilmMasterPreview() async {
    if (_isSeries) {
      return;
    }

    // The final/public backend URL always has priority.
    if (_text('video_url', fallback: '').isNotEmpty) {
      return;
    }

    final contentId = _text('id', fallback: '');

    if (contentId.isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        _filmMasterPreviewLoading = true;
      });
    }

    var previewUrl = '';

    try {
      final assets = await ProducerService.instance.getMyVideoAssets(
        contentId: contentId,
      );

      final asset = _preferredFilmVideoAsset(assets);

      if (asset != null) {
        final assetId = asset['id']?.toString().trim() ?? '';

        if (assetId.isNotEmpty) {
          previewUrl = await ProducerService.instance
              .getVideoAssetSourcePreview(assetId: assetId);
        }
      }
    } catch (_) {
      // Private preview failure must not break ContentDetails.
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _filmMasterPreviewUrl = previewUrl;
      _filmMasterPreviewLoading = false;
    });
  }

  Future<void> _loadMediaPreviews() async {
    final contentId = _text('id', fallback: '');

    if (contentId.isEmpty) {
      return;
    }

    final contentPaths = <String>{
      _rawValue(content, 'poster_temp_path'),
      _rawValue(content, 'backdrop_temp_path'),
      _rawValue(content, 'trailer_temp_path'),
    }..removeWhere((value) => value.isEmpty);

    final seasonRequests = <MapEntry<String, String>>[];

    for (final season in _seasons()) {
      final seasonId = _rawValue(season, 'id');

      if (seasonId.isEmpty) {
        continue;
      }

      for (final field in const [
        'poster_temp_path',
        'backdrop_temp_path',
        'trailer_temp_path',
      ]) {
        final path = _rawValue(season, field);

        if (path.isNotEmpty) {
          seasonRequests.add(MapEntry(seasonId, path));
        }
      }
    }

    if (contentPaths.isEmpty && seasonRequests.isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        _mediaPreviewsLoading = true;
      });
    }

    final contentResolved = <String, String>{};
    final seasonResolved = <String, String>{};

    for (final path in contentPaths) {
      try {
        contentResolved[path] = await ProducerService.instance
            .getContentMediaPreview(contentId: contentId, temporaryPath: path);
      } catch (_) {
        // A failed preview must not hide a valid final URL or break the modal.
      }
    }

    for (final request in seasonRequests) {
      try {
        seasonResolved[request.value] = await ProducerService.instance
            .getSeasonMediaPreview(
              seasonId: request.key,
              temporaryPath: request.value,
            );
      } catch (_) {
        // Keep the season usable even when one temporary preview is unavailable.
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _contentMediaPreviewUrls.addAll(contentResolved);
      _seasonMediaPreviewUrls.addAll(seasonResolved);
      _mediaPreviewsLoading = false;
    });
  }

  Future<void> _loadAnalytics() async {
    final id = _text('id', fallback: '');

    if (id.isEmpty) {
      if (!mounted) return;

      setState(() {
        _analyticsLoading = false;
        _analyticsError = 'Identifiant du contenu indisponible.';
      });

      return;
    }

    try {
      final analytics = await ProducerService.instance
          .getProducerContentAnalytics(id);

      if (!mounted) return;

      setState(() {
        _analytics = analytics;
        _analyticsLoading = false;
        _analyticsError = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _analyticsLoading = false;
        _analyticsError = 'Analytics momentanément indisponibles.';
      });
    }
  }

  String _text(String field, {String fallback = '—'}) {
    final value = content[field]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  String _status() {
    return _text('producer_submission_status', fallback: 'unknown');
  }

  String _statusLabel() {
    switch (_status()) {
      case 'draft':
        return 'Brouillon';
      case 'pending':
        return 'En validation';
      case 'approved':
        return 'Validé';
      case 'rejected':
        return 'Refusé';
      default:
        return _status();
    }
  }

  Color _statusColor() {
    switch (_status()) {
      case 'draft':
        return AppTheme.disabled;
      case 'pending':
        return AppTheme.warning;
      case 'approved':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.error;
      default:
        return AppTheme.disabled;
    }
  }

  List<Map<String, dynamic>> _maps(String field) {
    final raw = content[field];

    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  List<String> _genres() {
    return _maps('genres')
        .map((item) => item['name']?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  List<String> _people(String field) {
    return _maps(field)
        .map((item) => item['name']?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _seasons() {
    return _maps('seasons');
  }

  Map<String, dynamic>? _firstSeason() {
    final seasons = _seasons();

    if (seasons.isEmpty) return null;

    for (final season in seasons) {
      final number = season['season_number']?.toString().trim() ?? '';

      if (number == '1') {
        return season;
      }
    }

    return seasons.first;
  }

  String _seriesHeroMedia(
    String contentFinalField,
    String contentTempField,
    String seasonFinalField,
    String seasonTempField,
  ) {
    if (_isSeries) {
      final season = _firstSeason();

      if (season != null) {
        final seasonMedia = _resolvedSeasonMedia(
          season,
          seasonFinalField,
          seasonTempField,
        );

        if (seasonMedia.isNotEmpty) {
          return seasonMedia;
        }
      }
    }

    return _resolvedContentMedia(contentFinalField, contentTempField);
  }

  Future<void> _openMediaPreview({
    required String title,
    required String url,
    required bool video,
  }) async {
    final normalizedUrl = url.trim();

    if (normalizedUrl.isEmpty || !mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (dialogContext) {
        final mediaQuery = MediaQuery.of(dialogContext);
        final screenWidth = mediaQuery.size.width;
        final screenHeight = mediaQuery.size.height;

        final dialogWidth = screenWidth >= 1200
            ? 860.0
            : screenWidth >= 760
            ? screenWidth * 0.78
            : screenWidth * 0.94;

        final dialogHeight = screenHeight >= 850 ? 640.0 : screenHeight * 0.82;

        return Dialog(
          backgroundColor: const Color(0xFF111111),
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: Column(
              children: [
                Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/logo_dark.png',
                        height: 30,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) {
                          return const Text(
                            'EKEFLICKS',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fermer',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: Colors.black,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(18),
                    child: video
                        ? _InlineProducerVideo(url: normalizedUrl, title: title)
                        : InteractiveViewer(
                            minScale: 0.8,
                            maxScale: 4,
                            child: Image.network(
                              normalizedUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) {
                                return _mediaUnavailable(
                                  Icons.broken_image_outlined,
                                  'Impossible de charger le média',
                                );
                              },
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mediaThumbnail({
    required String title,
    required String url,
    required IconData icon,
    required bool video,
    String? badge,
    BoxFit fit = BoxFit.cover,
    double width = 190,
    double height = 118,
  }) {
    final available = url.trim().isNotEmpty;

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: available
                ? () => _openMediaPreview(title: title, url: url, video: video)
                : null,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: height,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.textSecondary.withValues(alpha: 0.14),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (available && !video)
                    _networkImage(url: url, fallbackIcon: icon, fit: fit)
                  else if (available && video)
                    Container(
                      color: Colors.black,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        size: 46,
                        color: AppTheme.primary,
                      ),
                    )
                  else
                    _mediaUnavailable(icon, 'Indisponible'),

                  if (badge != null && badge.trim().isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                  if (available)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.72),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          video
                              ? Icons.play_arrow_rounded
                              : Icons.open_in_full_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _networkImage({
    required String url,
    required IconData fallbackIcon,
    required BoxFit fit,
  }) {
    if (url.trim().isEmpty) {
      return Container(
        color: AppTheme.cardBackground,
        alignment: Alignment.center,
        child: Icon(fallbackIcon, size: 42, color: AppTheme.primary),
      );
    }

    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) {
        return Container(
          color: AppTheme.cardBackground,
          alignment: Alignment.center,
          child: Icon(fallbackIcon, size: 42, color: AppTheme.primary),
        );
      },
    );
  }

  String _number(dynamic value, {int decimals = 0}) {
    if (value == null) return '—';

    final number = value is num ? value : num.tryParse(value.toString());

    if (number == null) return '—';

    if (decimals > 0) {
      return number.toStringAsFixed(decimals);
    }

    final integer = number.round();

    if (integer >= 1000000) {
      final value = integer / 1000000;

      return '${value.toStringAsFixed(value >= 10 ? 0 : 1)}M';
    }

    if (integer >= 1000) {
      final value = integer / 1000;

      return '${value.toStringAsFixed(value >= 10 ? 0 : 1)}K';
    }

    return integer.toString();
  }

  String _watchTime(num seconds) {
    if (seconds <= 0) {
      return '0 min';
    }

    final hours = seconds / 3600;

    if (hours >= 1) {
      return '${hours.toStringAsFixed(hours >= 10 ? 0 : 1)} h';
    }

    return '${(seconds / 60).round()} min';
  }

  String _durationLabel(dynamic raw) {
    if (raw == null) return '';

    final value = raw.toString().trim();

    if (value.isEmpty || value == 'null') {
      return '';
    }

    final seconds = int.tryParse(value);

    if (seconds == null) {
      return value;
    }

    final minutes = (seconds / 60).round();

    if (minutes < 60) {
      return '$minutes min';
    }

    final hours = minutes ~/ 60;
    final remainder = minutes % 60;

    return remainder == 0
        ? '${hours}h'
        : '${hours}h${remainder.toString().padLeft(2, '0')}';
  }

  String _ratingLabel() {
    final raw = content['rating_avg'] ?? content['rating'];

    final rating = raw is num ? raw.toDouble() : double.tryParse('$raw');

    if (rating == null) {
      return '—';
    }

    return rating.toStringAsFixed(1);
  }

  String _ratingCountLabel() {
    final count = content['rating_count'];

    if (count == null) return '';

    final value = int.tryParse(count.toString()) ?? 0;

    return value > 0 ? '(${_number(value)})' : '';
  }

  String? _top10Label() {
    final candidates = [
      content['top10_position'],
      content['top_10_position'],
      content['top10_rank'],
      content['top_10_rank'],
    ];

    for (final raw in candidates) {
      final position = int.tryParse(raw?.toString() ?? '');

      if (position != null && position >= 1 && position <= 10) {
        return '#$position TOP 10';
      }
    }

    return null;
  }

  Widget _statusBadge() {
    final color = _statusColor();

    return _pill(
      label: _statusLabel(),
      foreground: color,
      background: color.withValues(alpha: 0.15),
    );
  }

  Widget _pill({
    required String label,
    Color? foreground,
    Color? background,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background ?? AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (foreground ?? AppTheme.textSecondary).withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground ?? AppTheme.textSecondary),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground ?? AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      height: 66,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo_dark.png',
            height: 34,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              return const Text(
                'EKEFLICKS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontSize: 18,
                ),
              );
            },
          ),
          const Spacer(),
          Flexible(
            child: Text(
              'Détails du contenu',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Fermer',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    final poster = _isSeries
        ? _seriesHeroMedia(
            'poster_url',
            'poster_temp_path',
            'poster_url',
            'poster_temp_path',
          )
        : _resolvedContentMedia('poster_url', 'poster_temp_path');

    final contentBackdropUrl = _text('backdrop_url', fallback: '');

    final contentBannerUrl = _text('banner_url', fallback: '');

    final contentBackdrop = contentBackdropUrl.isNotEmpty
        ? contentBackdropUrl
        : contentBannerUrl.isNotEmpty
        ? contentBannerUrl
        : _resolvedContentMedia('backdrop_url', 'backdrop_temp_path');

    final firstSeason = _firstSeason();

    final seasonBackdrop = _isSeries && firstSeason != null
        ? _resolvedSeasonMedia(
            firstSeason,
            'backdrop_url',
            'backdrop_temp_path',
          )
        : '';

    final backdrop = seasonBackdrop.isNotEmpty
        ? seasonBackdrop
        : contentBackdrop;

    final genres = _genres();

    final meta = <String>[
      _isSeries ? 'SÉRIE' : 'FILM',
      _text('release_year', fallback: ''),
      if (!_isSeries) _durationLabel(content['duration']),
      _text('age_rating', fallback: ''),
    ].where((value) => value.trim().isNotEmpty).toList();

    final top10 = _top10Label();

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.textSecondary.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            left: 340,
            child: _networkImage(
              url: backdrop,
              fallbackIcon: _isSeries ? Icons.live_tv : Icons.movie,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppTheme.cardBackground,
                    AppTheme.cardBackground.withValues(alpha: 0.94),
                    AppTheme.cardBackground.withValues(alpha: 0.62),
                    AppTheme.cardBackground.withValues(alpha: 0.18),
                  ],
                  stops: const [0, 0.34, 0.65, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 122,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _networkImage(
                      url: poster,
                      fallbackIcon: _isSeries
                          ? Icons.live_tv_outlined
                          : Icons.movie_outlined,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _text('title', fallback: 'Sans titre'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 27,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          meta.join(' • '),
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 7,
                          children: [
                            _statusBadge(),
                            _pill(
                              label:
                                  '★ ${_ratingLabel()} ${_ratingCountLabel()}'
                                      .trim(),
                              foreground: AppTheme.warning,
                              background: AppTheme.warning.withValues(
                                alpha: 0.10,
                              ),
                            ),
                            if (top10 != null)
                              _pill(
                                label: top10,
                                foreground: AppTheme.primary,
                                background: AppTheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                                icon: Icons.emoji_events_outlined,
                              ),
                            ...genres
                                .take(3)
                                .map((genre) => _pill(label: genre)),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          _text(
                            'synopsis',
                            fallback: _text(
                              'description',
                              fallback: 'Aucun synopsis renseigné.',
                            ),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            height: 1.45,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 220),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiStrip() {
    final analytics = _analytics;

    final items = <_KpiData>[
      _KpiData(
        icon: Icons.play_circle_outline,
        label: 'VUES',
        value: analytics == null
            ? '—'
            : _number(analytics.content.qualifiedViews),
      ),
      _KpiData(
        icon: Icons.people_outline,
        label: 'SPECTATEURS',
        value: analytics == null
            ? '—'
            : _number(analytics.content.uniqueViewers),
      ),
      _KpiData(
        icon: Icons.schedule_outlined,
        label: 'WATCH TIME',
        value: analytics == null
            ? '—'
            : _watchTime(analytics.content.watchSeconds),
      ),
      _KpiData(
        icon: Icons.thumb_up_alt_outlined,
        label: 'LIKES',
        value: analytics == null
            ? '—'
            : _number(analytics.engagement.currentLikes),
      ),
      _KpiData(
        icon: Icons.task_alt_outlined,
        label: 'COMPLÉTION',
        value: analytics == null
            ? '—'
            : '${analytics.content.completionRatePercent.toStringAsFixed(1)} %',
      ),
    ];

    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.textSecondary.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: _analyticsLoading
          ? const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : _analyticsError != null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  _analyticsError!,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _analyticsLoading = true;
                      _analyticsError = null;
                    });

                    _loadAnalytics();
                  },
                  child: const Text('Réessayer'),
                ),
              ],
            )
          : Row(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  Expanded(child: _kpi(items[index])),
                  if (index != items.length - 1)
                    Container(
                      width: 1,
                      height: 38,
                      color: AppTheme.textSecondary.withValues(alpha: 0.12),
                    ),
                ],
              ],
            ),
    );
  }

  Widget _kpi(_KpiData data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(data.icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> get _tabs {
    return [
      'Vue d’ensemble',
      'Audience',
      'Médias',
      'Technique',
      if (_isSeries) 'Saisons',
    ];
  }

  Widget _tabsBar() {
    final tabs = _tabs;

    if (_selectedTab >= tabs.length) {
      _selectedTab = 0;
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.textSecondary.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final selected = _selectedTab == index;

          return TextButton(
            onPressed: () {
              setState(() {
                _selectedTab = index;
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: selected
                  ? AppTheme.primary
                  : AppTheme.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: const RoundedRectangleBorder(),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tabs[index],
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: selected ? 34 : 0,
                  height: 2,
                  color: AppTheme.primary,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _body() {
    final tabs = _tabs;
    final tab = tabs[_selectedTab.clamp(0, tabs.length - 1)];

    switch (tab) {
      case 'Audience':
        return _audience();
      case 'Médias':
        return _media();
      case 'Technique':
        return _technical();
      case 'Saisons':
        return _series();
      default:
        return _overview();
    }
  }

  Widget _overview() {
    final producers = _people('producer_team');
    final cast = _people('cast_team');

    return _contentGrid(
      children: [
        _panel(
          title: 'Informations',
          icon: Icons.info_outline,
          child: Column(
            children: [
              _info('Type', _isSeries ? 'Série' : 'Film'),
              _info('Année', _text('release_year')),
              _info('Langue', _text('language')),
              _info('Pays', _text('country')),
              if (!_isSeries)
                _info('Durée', _durationLabel(content['duration'])),
              _info('Classification', _text('age_rating')),
              _info('Genres', _genres().isEmpty ? '—' : _genres().join(', ')),
            ],
          ),
        ),
        _panel(
          title: 'Équipe',
          icon: Icons.groups_outlined,
          child: Column(
            children: [
              _info('Réalisateur', _text('director_name')),
              _info('Scénariste', _text('screenwriter_name')),
              _info(
                'Producteurs',
                producers.isEmpty ? '—' : producers.join(', '),
              ),
              _info('Casting', cast.isEmpty ? '—' : cast.join(', ')),
            ],
          ),
        ),
        _panel(
          title: 'Publication & validation',
          icon: Icons.verified_outlined,
          child: Column(
            children: [
              _info('Statut', _statusLabel()),
              _info('Créé', _humanDateTime(content['created_at'])),
              _info('Mis à jour', _humanDateTime(content['updated_at'])),
              _info('Publication', _text('published_at')),
              if (_text('review_reason', fallback: '').isNotEmpty)
                _info(
                  'Motif',
                  _text('review_reason'),
                  valueColor: AppTheme.error,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _audience() {
    final analytics = _analytics;

    if (_analyticsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (analytics == null) {
      return _emptyState(
        Icons.analytics_outlined,
        _analyticsError ?? 'Analytics indisponibles.',
      );
    }

    final engagement = analytics.engagement;

    return _contentGrid(
      children: [
        _panel(
          title: 'Visionnage',
          icon: Icons.ondemand_video_outlined,
          child: Column(
            children: [
              _info('Démarrages', _number(analytics.content.playStarts)),
              _info(
                'Vues qualifiées',
                _number(analytics.content.qualifiedViews),
              ),
              _info(
                'Spectateurs uniques',
                _number(analytics.content.uniqueViewers),
              ),
              _info(
                'Temps de visionnage',
                _watchTime(analytics.content.watchSeconds),
              ),
              _info(
                'Vues complètes',
                _number(analytics.content.completedViews),
              ),
            ],
          ),
        ),
        _panel(
          title: 'Performance',
          icon: Icons.insights_outlined,
          child: Column(
            children: [
              _info(
                'Taux de qualification',
                '${analytics.content.qualificationRatePercent.toStringAsFixed(1)} %',
              ),
              _info(
                'Complétion moyenne',
                '${analytics.content.completionRatePercent.toStringAsFixed(1)} %',
              ),
              _info(
                'Taux d’engagement',
                '${engagement.engagementRatePercent.toStringAsFixed(1)} %',
              ),
            ],
          ),
        ),
        _panel(
          title: 'Engagement',
          icon: Icons.favorite_border,
          child: Column(
            children: [
              _info('Likes', _number(engagement.likes)),
              _info('Unlikes', _number(engagement.unlikes)),
              _info('Net likes', _number(engagement.netLikes)),
              _info(
                'Utilisateurs ayant liké',
                _number(engagement.uniqueLikers),
              ),
              _info('Likes actuels', _number(engagement.currentLikes)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _media() {
    if (_mediaPreviewsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    const thumbnailWidth = 220.0;
    const thumbnailHeight = 132.0;

    final items = <Widget>[];

    if (_isSeries) {
      final seasons = _seasons();

      for (var index = 0; index < seasons.length; index++) {
        final season = seasons[index];

        final number =
            season['season_number']?.toString().trim() ?? '${index + 1}';

        final poster = _resolvedSeasonMedia(
          season,
          'poster_url',
          'poster_temp_path',
        );

        final backdrop = _resolvedSeasonMedia(
          season,
          'backdrop_url',
          'backdrop_temp_path',
        );

        if (poster.isNotEmpty) {
          items.add(
            _mediaThumbnail(
              title: 'Affiche',
              url: poster,
              icon: Icons.movie_outlined,
              video: false,
              badge: 'SAISON $number',
              fit: BoxFit.contain,
              width: thumbnailWidth,
              height: thumbnailHeight,
            ),
          );
        }

        if (backdrop.isNotEmpty) {
          items.add(
            _mediaThumbnail(
              title: 'Bannière',
              url: backdrop,
              icon: Icons.image_outlined,
              video: false,
              badge: 'SAISON $number',
              width: thumbnailWidth,
              height: thumbnailHeight,
            ),
          );
        }
      }
    } else {
      final poster = _resolvedContentMedia('poster_url', 'poster_temp_path');

      final backdropUrl = _text('backdrop_url', fallback: '');

      final bannerUrl = _text('banner_url', fallback: '');

      final banner = backdropUrl.isNotEmpty
          ? backdropUrl
          : bannerUrl.isNotEmpty
          ? bannerUrl
          : _resolvedContentMedia('backdrop_url', 'backdrop_temp_path');

      final trailer = _resolvedContentMedia('trailer_url', 'trailer_temp_path');

      final master = _resolvedFilmMaster();

      if (poster.isNotEmpty) {
        items.add(
          _mediaThumbnail(
            title: 'Affiche',
            url: poster,
            icon: Icons.movie_outlined,
            video: false,
            fit: BoxFit.contain,
            width: thumbnailWidth,
            height: thumbnailHeight,
          ),
        );
      }

      if (banner.isNotEmpty) {
        items.add(
          _mediaThumbnail(
            title: 'Bannière',
            url: banner,
            icon: Icons.image_outlined,
            video: false,
            width: thumbnailWidth,
            height: thumbnailHeight,
          ),
        );
      }

      if (trailer.isNotEmpty) {
        items.add(
          _mediaThumbnail(
            title: 'Bande-annonce',
            url: trailer,
            icon: Icons.play_circle_outline_rounded,
            video: true,
            width: thumbnailWidth,
            height: thumbnailHeight,
          ),
        );
      }

      items.add(
        _mediaThumbnail(
          title: _filmMasterPreviewLoading ? 'Master — chargement…' : 'Master',
          url: master,
          icon: Icons.video_library_outlined,
          video: true,
          width: thumbnailWidth,
          height: thumbnailHeight,
        ),
      );
    }

    if (items.isEmpty) {
      return _emptyState(
        Icons.perm_media_outlined,
        'Aucun média disponible pour ce contenu.',
      );
    }

    return Container(
      color: AppTheme.background,
      child: ListView(
        padding: const EdgeInsets.only(top: 18),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Wrap(
              spacing: 14,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: items,
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _mediaUnavailable(IconData icon, String label) {
    return Container(
      width: double.infinity,
      color: AppTheme.background,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 38, color: AppTheme.textSecondary),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _technicalSubmissionSummary() {
    final raw = content['technical_submission_summary'];

    if (raw is! Map) {
      return const SizedBox.shrink();
    }

    final summary = Map<String, dynamic>.from(raw);
    final status = summary['status']?.toString().trim() ?? '';
    final allowed = summary['submission_allowed'] == true;
    final humanReview = summary['human_review_required'] == true;

    String label;
    String description;
    IconData icon;

    switch (status) {
      case 'conform':
        label = 'Conforme';
        description = 'Le contrôle technique autorise la soumission.';
        icon = Icons.check_circle_outline_rounded;
        break;

      case 'review_required':
        label = 'À vérifier';
        description =
            'Soumission autorisée — l’équipe de validation '
            'effectuera une vérification humaine.';
        icon = Icons.fact_check_outlined;
        break;

      case 'non_conform':
        label = 'Non conforme bloquant';
        description =
            'La soumission est bloquée jusqu’à correction '
            'ou remplacement du master.';
        icon = Icons.block_rounded;
        break;

      case 'not_started':
        label = 'Analyse requise';
        description = 'Le master doit être analysé avant la soumission.';
        icon = Icons.hourglass_empty_rounded;
        break;

      case 'specification_missing':
        label = 'Spécification indisponible';
        description =
            'Aucun cahier des charges technique publié '
            'n’est disponible.';
        icon = Icons.rule_folder_outlined;
        break;

      default:
        label = allowed ? 'Soumission autorisée' : 'Analyse en cours';
        description = allowed
            ? 'Le contrôle technique permet la soumission.'
            : 'La soumission sera disponible lorsque les contrôles '
                  'techniques requis seront terminés.';
        icon = allowed
            ? Icons.check_circle_outline_rounded
            : Icons.pending_outlined;
    }

    final blockingErrors = (summary['blocking_errors'] is List)
        ? (summary['blocking_errors'] as List)
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false)
        : const <String>[];

    final warnings = (summary['warnings'] is List)
        ? (summary['warnings'] as List)
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false)
        : const <String>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (humanReview) ...[
            const SizedBox(height: 12),
            const Text(
              'Décision finale : validation humaine EKEFLICKS.',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          for (final error in blockingErrors) ...[
            const SizedBox(height: 10),
            Text(
              'Blocage : $error',
              style: const TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          for (final warning in warnings) ...[
            const SizedBox(height: 10),
            Text(
              'Avertissement : $warning',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _technical() {
    final conformity = TechnicalConformityReport.fromTrailerOwner(content);

    final rows = <Widget>[
      _technicalRow(
        title: 'Statut de l’analyse',
        value: _text('trailer_analysis_status', fallback: 'Non analysé'),
        description: 'État actuel de l’analyse technique de la bande-annonce.',
      ),
      _technicalRow(
        title: 'Conformité technique',
        value: conformity.displayLabel,
        description: 'Résultat global du contrôle de conformité technique.',
      ),
      _technicalRow(
        title: 'Dernière analyse',
        value: _humanDateTime(content['trailer_analyzed_at']),
        description:
            'Date et heure réelles du dernier contrôle technique disponible.',
      ),
    ];

    final specificationVersion = conformity.specificationVersion?.trim() ?? '';

    if (specificationVersion.isNotEmpty) {
      rows.add(
        _technicalRow(
          title: 'Spécification',
          value: specificationVersion,
          description: 'Version des règles utilisée pour cette analyse.',
        ),
      );
    }

    for (final error in conformity.blockingErrors) {
      rows.add(
        _technicalRow(
          title: 'Erreur bloquante',
          value: error,
          description:
              'Ce contrôle doit être corrigé avant validation technique.',
        ),
      );
    }

    for (final warning in conformity.warnings) {
      rows.add(
        _technicalRow(
          title: 'Avertissement',
          value: warning,
          description: 'Point signalé par le moteur de conformité.',
        ),
      );
    }

    for (final check in conformity.checks) {
      final details = <String>[];

      final expected = _technicalValue(check.expected);
      if (expected.isNotEmpty) {
        details.add('Attendu : $expected');
      }

      final actual = _technicalValue(check.actual);
      if (actual.isNotEmpty) {
        details.add('Détecté : $actual');
      }

      final message = (check.message ?? '').trim();
      if (message.isNotEmpty) {
        details.add(message);
      }

      if (check.blocking == true) {
        details.add('Contrôle bloquant');
      }

      final label = check.label.trim();
      final status = check.status.trim();
      final fallbackLabel = 'Contrôle technique';

      rows.add(
        _technicalRow(
          title: label.isNotEmpty
              ? label
              : fallbackLabel.isNotEmpty
              ? fallbackLabel
              : 'Contrôle technique',
          value: status.isNotEmpty ? status : 'Non renseigné',
          description: details.join(' • '),
        ),
      );
    }

    final specification = content['technical_specification'];

    if (conformity.checks.isEmpty && specification is Map) {
      for (final entry in specification.entries) {
        final key = entry.key.toString().trim();
        final value = entry.value;

        if (key.isEmpty || value == null) {
          continue;
        }

        final rendered = _technicalValue(value);

        if (rendered.isEmpty) {
          continue;
        }

        rows.add(
          _technicalRow(
            title: _technicalLabel(key),
            value: rendered,
            description: _technicalDescription(key),
          ),
        );
      }
    }

    final report = _text('trailer_analysis_report', fallback: '');

    if (report.isNotEmpty) {
      rows.add(
        _technicalRow(
          title: 'Rapport d’analyse',
          value: report,
          description: 'Détail retourné par le moteur de contrôle technique.',
        ),
      );
    }

    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _technicalSubmissionSummary(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.textSecondary.withValues(alpha: 0.12),
                ),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: rows.length,
                separatorBuilder: (_, __) => Divider(
                  height: 28,
                  color: AppTheme.textSecondary.withValues(alpha: 0.12),
                ),
                itemBuilder: (_, index) => rows[index],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _technicalRow({
    required String title,
    required String value,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6, right: 12),
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              SelectableText(
                value.trim().isEmpty ? 'Non renseigné' : value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (description.trim().isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _technicalValue(dynamic value) {
    if (value == null) return '';

    if (value is List) {
      return value.map((item) => item.toString()).join(', ');
    }

    if (value is Map) {
      return value.entries
          .map(
            (entry) =>
                '${_technicalLabel(entry.key.toString())}: '
                '${entry.value}',
          )
          .join(' • ');
    }

    return value.toString().trim();
  }

  String _technicalLabel(String key) {
    const labels = <String, String>{
      'color_space': 'Espace colorimétrique',
      'color_primaries': 'Primaires colorimétriques',
      'color_transfer': 'Fonction de transfert',
      'transfer_characteristics': 'Caractéristiques de transfert',
      'width': 'Largeur',
      'height': 'Hauteur',
      'resolution': 'Résolution',
      'fps': 'Fréquence d’images',
      'frame_rate': 'Fréquence d’images',
      'video_codec': 'Codec vidéo',
      'codec': 'Codec',
      'audio_codec': 'Codec audio',
      'video_bitrate': 'Débit vidéo',
      'audio_bitrate': 'Débit audio',
      'bitrate': 'Débit',
      'duration': 'Durée',
      'format': 'Format',
      'container': 'Conteneur',
      'sample_rate': 'Fréquence audio',
      'channels': 'Canaux audio',
      'loudness': 'Niveau sonore',
      'hdr': 'HDR',
    };

    if (labels.containsKey(key)) {
      return labels[key]!;
    }

    final normalized = key.replaceAll('_', ' ').replaceAll('-', ' ').trim();

    if (normalized.isEmpty) return key;

    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  String _technicalDescription(String key) {
    const descriptions = <String, String>{
      'color_space': 'Espace colorimétrique détecté dans la vidéo.',
      'color_primaries':
          'Référence des couleurs primaires déclarées dans le flux.',
      'color_transfer': 'Fonction de transfert colorimétrique détectée.',
      'transfer_characteristics':
          'Caractéristiques de transfert déclarées dans le flux vidéo.',
      'width': 'Largeur de l’image vidéo détectée.',
      'height': 'Hauteur de l’image vidéo détectée.',
      'resolution': 'Dimensions d’image détectées pour la vidéo.',
      'fps': 'Nombre d’images affichées par seconde.',
      'frame_rate': 'Nombre d’images affichées par seconde.',
      'video_codec': 'Format de compression de la piste vidéo.',
      'codec': 'Codec détecté dans le média.',
      'audio_codec': 'Format de compression de la piste audio.',
      'video_bitrate': 'Débit de données de la piste vidéo.',
      'audio_bitrate': 'Débit de données de la piste audio.',
      'bitrate': 'Débit de données détecté dans le média.',
      'duration': 'Durée technique détectée pour le média.',
      'format': 'Format technique détecté.',
      'container': 'Conteneur multimédia détecté.',
      'sample_rate': 'Fréquence d’échantillonnage de la piste audio.',
      'channels': 'Configuration des canaux audio détectée.',
      'loudness': 'Mesure de niveau sonore retournée par l’analyse.',
      'hdr': 'Indique la présence ou non de métadonnées HDR.',
    };

    return descriptions[key] ??
        'Information technique retournée par l’analyse du média.';
  }

  Widget _series() {
    final seasons = _seasons();

    if (!_isSeries) {
      return _emptyState(
        Icons.live_tv_outlined,
        'Ce contenu n’est pas une série.',
      );
    }

    if (seasons.isEmpty) {
      return _emptyState(
        Icons.video_library_outlined,
        'Aucune saison disponible.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: seasons.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final season = seasons[index];

        final description = season['description']?.toString().trim() ?? '';

        final trailer = _resolvedSeasonMedia(
          season,
          'trailer_url',
          'trailer_temp_path',
        );

        final episodesRaw = season['episodes'];

        final episodes = episodesRaw is List
            ? episodesRaw
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList(growable: false)
            : const <Map<String, dynamic>>[];

        final number =
            season['season_number']?.toString().trim() ?? '${index + 1}';

        final title = season['title']?.toString().trim() ?? '';

        final status =
            season['trailer_analysis_status']?.toString().trim() ?? '';

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.textSecondary.withValues(alpha: 0.12),
            ),
          ),
          child: ExpansionTile(
            initiallyExpanded: index == 0,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Text(
              title.isEmpty ? 'Saison $number' : 'Saison $number — $title',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              '${episodes.length} épisode'
              '${episodes.length > 1 ? 's' : ''}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            children: [
              _seasonRow(
                number: number,
                title: title,
                description: description,
                trailer: trailer,
                analysisStatus: status,
                episodeCount: episodes.length,
              ),
              if (episodes.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Aucun épisode dans cette saison.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                for (
                  var episodeIndex = 0;
                  episodeIndex < episodes.length;
                  episodeIndex++
                )
                  _episode(episodes[episodeIndex], episodeIndex),
            ],
          ),
        );
      },
    );
  }

  Widget _seasonRow({
    required String number,
    required String title,
    required String description,
    required String trailer,
    required String analysisStatus,
    required int episodeCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final compact = constraints.maxWidth < 720;

          final media = trailer.isNotEmpty
              ? _mediaThumbnail(
                  title: 'Bande-annonce — Saison $number',
                  url: trailer,
                  icon: Icons.play_circle_outline_rounded,
                  video: true,
                  badge: 'SAISON $number',
                  width: 210,
                  height: 118,
                )
              : SizedBox(
                  width: 210,
                  height: 118,
                  child: _mediaUnavailable(
                    Icons.videocam_off_outlined,
                    'Bande-annonce indisponible',
                  ),
                );

          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.isEmpty ? 'Saison $number' : 'Saison $number — $title',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description.isEmpty
                    ? 'Aucune description renseignée.'
                    : description,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 5,
                children: [
                  Text(
                    '$episodeCount épisode'
                    '${episodeCount > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  if (analysisStatus.isNotEmpty)
                    Text(
                      'Analyse : $analysisStatus',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [media, const SizedBox(height: 12), info],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              media,
              const SizedBox(width: 16),
              Expanded(child: info),
            ],
          );
        },
      ),
    );
  }

  Widget _episode(Map<String, dynamic> episode, int index) {
    final number =
        episode['episode_number']?.toString().trim() ?? '${index + 1}';

    final title = episode['title']?.toString().trim() ?? '';

    final thumbnail = episode['thumbnail_url']?.toString().trim() ?? '';

    final master = episode['video_url']?.toString().trim() ?? '';

    final duration = _durationLabel(
      episode['duration'] ?? episode['duration_seconds'],
    );

    final description = episode['description']?.toString().trim() ?? '';

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final compact = constraints.maxWidth < 720;

          final media = master.isNotEmpty
              ? _mediaThumbnail(
                  title: 'Master — Épisode $number',
                  url: master,
                  icon: Icons.play_circle_outline,
                  video: true,
                  badge: 'EP $number',
                  width: 210,
                  height: 118,
                )
              : SizedBox(
                  width: 210,
                  height: 118,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _networkImage(
                      url: thumbnail,
                      fallbackIcon: Icons.play_circle_outline,
                      fit: BoxFit.cover,
                    ),
                  ),
                );

          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Épisode $number'
                '${title.isEmpty ? '' : ' — $title'}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description.isEmpty
                    ? 'Aucune description renseignée.'
                    : description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
              if (duration.isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  'Durée : $duration',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [media, const SizedBox(height: 12), info],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              media,
              const SizedBox(width: 16),
              Expanded(child: info),
            ],
          );
        },
      ),
    );
  }

  Widget _contentGrid({required List<Widget> children}) {
    return LayoutBuilder(
      builder: (_, constraints) {
        if (constraints.maxWidth < 720) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  children[index],
                  if (index != children.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                Expanded(child: children[index]),
                if (index != children.length - 1) const SizedBox(width: 12),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _panel({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final compact = MediaQuery.sizeOf(context).width < 720;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (compact)
            child
          else
            Expanded(child: SingleChildScrollView(child: child)),
        ],
      ),
    );
  }

  Widget _info(String label, String value, {Color? valueColor}) {
    final safeValue = value.trim().isEmpty ? '—' : value.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              safeValue,
              style: TextStyle(
                color: valueColor ?? AppTheme.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 34, color: AppTheme.textSecondary),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _desktop() {
    return Column(
      children: [
        _header(),
        _hero(),
        _kpiStrip(),
        _tabsBar(),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _compact() {
    return Column(
      children: [
        _header(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _hero(),
                SizedBox(height: 116, child: _compactKpis()),
                _tabsBar(),
                SizedBox(height: 760, child: _body()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _compactKpis() {
    final analytics = _analytics;

    if (_analyticsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (analytics == null) {
      return _emptyState(
        Icons.analytics_outlined,
        _analyticsError ?? 'Analytics indisponibles.',
      );
    }

    final items = [
      _KpiData(
        icon: Icons.play_circle_outline,
        label: 'VUES',
        value: _number(analytics.content.qualifiedViews),
      ),
      _KpiData(
        icon: Icons.people_outline,
        label: 'SPECTATEURS',
        value: _number(analytics.content.uniqueViewers),
      ),
      _KpiData(
        icon: Icons.thumb_up_alt_outlined,
        label: 'LIKES',
        value: _number(analytics.engagement.currentLikes),
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (_, index) {
        return SizedBox(
          width: 150,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: _kpi(items[index]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 900;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(child: desktop ? _desktop() : _compact()),
    );
  }
}

class _KpiData {
  final IconData icon;
  final String label;
  final String value;

  const _KpiData({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _InlineProducerVideo extends StatefulWidget {
  const _InlineProducerVideo({required this.url, required this.title});

  final String url;
  final String title;

  @override
  State<_InlineProducerVideo> createState() => _InlineProducerVideoState();
}

class _InlineProducerVideoState extends State<_InlineProducerVideo> {
  late final VideoPlayerController _controller;
  late final Future<void> _initialize;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));

    _initialize = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialize,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _videoError();
        }

        final aspectRatio = _controller.value.aspectRatio > 0
            ? _controller.value.aspectRatio
            : 16 / 9;

        return Container(
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Row(
                  children: [
                    IconButton.filled(
                      tooltip: _controller.value.isPlaying ? 'Pause' : 'Lire',
                      onPressed: () {
                        setState(() {
                          if (_controller.value.isPlaying) {
                            _controller.pause();
                          } else {
                            _controller.play();
                          }
                        });
                      },
                      icon: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _videoError() {
    return Container(
      color: AppTheme.background,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.textSecondary,
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            'Impossible de lire ${widget.title.toLowerCase()}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
