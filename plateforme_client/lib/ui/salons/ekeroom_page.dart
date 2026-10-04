import 'dart:async';
import 'dart:convert';

import 'package:app_ekeflicks/core/app_responsive.dart';
import 'package:app_ekeflicks/providers/device_info_provider.dart';
import 'package:app_ekeflicks/providers/user_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Ekeroom supports realtime chat and synchronized playback on every client.
/// Video calling is available on web/mobile; TV remains chat-first.
class EkeroomPage extends StatefulWidget {
  final String? initialSalonId;
  final String? contentId;
  final String? contentTitle;
  final Map<String, dynamic>? Function()? readPlaybackState;
  final void Function(Map<String, dynamic>)? onRemotePlaybackState;

  const EkeroomPage({
    super.key,
    this.initialSalonId,
    this.contentId,
    this.contentTitle,
    this.readPlaybackState,
    this.onRemotePlaybackState,
  });

  static Widget fromRoute(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            const <String, dynamic>{};
    return EkeroomPage(
      initialSalonId: args['salonId']?.toString(),
      contentId: args['contentId']?.toString(),
      contentTitle: args['contentTitle']?.toString(),
    );
  }

  @override
  State<EkeroomPage> createState() => _EkeroomPageState();
}

class _EkeroomPageState extends State<EkeroomPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _joinCodeController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  late final Future<void> _rendererReady;

  List<Map<String, dynamic>> _salons = const [];
  List<Map<String, dynamic>> _messages = const [];
  Map<String, dynamic>? _salon;
  List<Map<String, dynamic>>? _cachedIceServers;
  DateTime? _iceServersExpireAt;
  String? _iceServersSalonId;
  Future<List<Map<String, dynamic>>>? _iceServersRequest;
  bool _loading = false;
  bool _connected = false;
  bool _isTv = false;
  bool _videoCallActive = false;
  bool _disposing = false;
  String? _error;
  int _sequence = 0;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSubscription;
  Timer? _heartbeat;
  Timer? _playbackTimer;
  MediaStream? _localStream;
  final Map<String, RTCPeerConnection> _peers = {};
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};

  bool get _english => Localizations.localeOf(context).languageCode == 'en';

  String get _userId {
    final dynamic user = context.read<UserProvider>().currentUser;
    return user?.id?.toString() ?? '';
  }

  dynamic get _dio => context.read<UserProvider>().apiClient.dio;

  @override
  void initState() {
    super.initState();
    _rendererReady = _localRenderer.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSalons();
      final id = widget.initialSalonId;
      if (id != null && id.isNotEmpty) _joinSalonById(id);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final deviceInfo = context.watch<DeviceInfoProvider>();
    _isTv = deviceInfo.isTV ||
        (defaultTargetPlatform == TargetPlatform.android &&
            AppResponsive.isTVSize(context));
  }

  @override
  void dispose() {
    _disposing = true;
    _searchController.dispose();
    _joinCodeController.dispose();
    _messageController.dispose();
    _heartbeat?.cancel();
    _playbackTimer?.cancel();
    _socketSubscription?.cancel();
    _channel?.sink.close();
    unawaited(_disposeMediaResources());
    super.dispose();
  }

  Future<void> _disposeMediaResources() async {
    try {
      await _rendererReady;
    } catch (_) {
      // Continue disposal even if renderer initialization failed.
    }
    await _closeVideoCall();
    await _localRenderer.dispose();
  }

  List<Map<String, dynamic>> _records(Object? payload) {
    final raw = payload is Map ? (payload['results'] ?? const []) : payload;
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Future<void> _loadSalons({String query = ''}) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _dio.get<Object>(
        '/salons/',
        queryParameters: {
          'status': 'open',
          if (query.trim().isNotEmpty) 'search': query.trim(),
          if (widget.contentId?.isNotEmpty == true)
            'content_id': widget.contentId,
        },
      );
      if (!mounted) return;
      setState(() => _salons = _records(response.data));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _salons = const [];
        _error = _english
            ? 'Ekeroom rooms could not be loaded.'
            : 'Impossible de charger les salons Ekeroom.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createSalon() async {
    final nameController = TextEditingController(
      text: widget.contentTitle == null
          ? ''
          : (_english ? 'Movie night' : 'Soirée cinéma'),
    );
    bool isPublic = false;
    DateTime? scheduledAt;
    final details = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(_english ? 'Create an Ekeroom' : 'Créer un Ekeroom'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  maxLength: 120,
                  decoration: InputDecoration(
                    labelText: _english ? 'Room name' : 'Nom du salon',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isPublic,
                  onChanged: (value) => setDialogState(() => isPublic = value),
                  title: Text(_english ? 'Public room' : 'Salon public'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: Text(
                    scheduledAt == null
                        ? (_english ? 'Start now' : 'Démarrer maintenant')
                        : (_english ? 'Scheduled · ' : 'Programmé · ') +
                            scheduledAt!.toLocal().toString(),
                  ),
                  subtitle: Text(_english
                      ? 'You can schedule a viewing session.'
                      : 'Vous pouvez programmer une séance.'),
                  trailing: IconButton(
                    tooltip: _english ? 'Choose a date' : 'Choisir une date',
                    onPressed: () async {
                      final now = DateTime.now();
                      final date = await showDatePicker(
                        context: dialogContext,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 365)),
                        initialDate: scheduledAt ?? now,
                      );
                      if (date == null || !dialogContext.mounted) return;
                      final time = await showTimePicker(
                        context: dialogContext,
                        initialTime: TimeOfDay.fromDateTime(
                          scheduledAt ?? now.add(const Duration(hours: 1)),
                        ),
                      );
                      if (time == null) return;
                      setDialogState(() {
                        scheduledAt = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    },
                    icon: const Icon(Icons.edit_calendar),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(_english ? 'Cancel' : 'Annuler'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(dialogContext, {
                  'name': name,
                  'visibility': isPublic ? 'public' : 'private',
                  if (scheduledAt != null)
                    'scheduled_at': scheduledAt!.toUtc().toIso8601String(),
                });
              },
              child: Text(_english ? 'Create' : 'Créer'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    if (details == null || !mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/salons/',
        data: {
          ...details,
          if (widget.contentId?.isNotEmpty == true)
            'content_id': widget.contentId,
          'mode': 'social',
          'capacity': 10,
          'audio_enabled': true,
          'video_enabled': !_isTv,
        },
      );
      await _openSalon(Map<String, dynamic>.from(response.data ?? const {}));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _joinSalonById(String id) async {
    if (!mounted || id.isEmpty) return;
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/salons/' + id + '/join/',
      );
      await _openSalon(Map<String, dynamic>.from(response.data ?? const {}));
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  Future<void> _joinByCode() async {
    final code = _joinCodeController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/salons/join-by-code/',
        data: {'join_code': code},
      );
      _joinCodeController.clear();
      await _openSalon(Map<String, dynamic>.from(response.data ?? const {}));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadHistory(String salonId) async {
    final response = await _dio.get<Object>(
      '/salons/' + salonId + '/messages/',
    );
    if (!mounted) return;
    setState(() => _messages = _records(response.data));
  }

  Future<void> _openSalon(Map<String, dynamic> salon) async {
    final id = salon['id']?.toString();
    if (id == null || id.isEmpty) return;
    await _disconnectRealtime();
    _iceServersCache = null;
    _iceServersExpireAt = null;
    _iceServersSalonId = null;
    _iceServersRequest = null;
    setState(() {
      _salon = salon;
      _messages = const [];
      _sequence = 0;
      _loading = true;
      _error = null;
    });
    try {
      await _loadHistory(id);
      final ticketResponse = await _dio.post<Map<String, dynamic>>(
        '/salons/' + id + '/realtime-ticket/',
      );
      final payload = ticketResponse.data ?? const <String, dynamic>{};
      final base = Uri.parse(_dio.options.baseUrl.toString());
      final uri = Uri(
        scheme: base.scheme == 'https' ? 'wss' : 'ws',
        host: base.host,
        port: base.hasPort ? base.port : null,
        path: payload['websocket_path']?.toString() ?? '/ws/salons/' + id + '/',
        queryParameters: {'ticket': payload['ticket']?.toString() ?? ''},
      );
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _socketSubscription = channel.stream.listen(
        _onRealtimeData,
        onError: (_) {
          if (mounted) setState(() => _connected = false);
        },
        onDone: () {
          if (mounted) setState(() => _connected = false);
        },
      );
      _heartbeat?.cancel();
      _heartbeat = Timer.periodic(
        const Duration(seconds: 25),
        (_) => _send({'type': 'ping'}),
      );
      _playbackTimer?.cancel();
      if (widget.readPlaybackState != null) {
        _playbackTimer = Timer.periodic(
          const Duration(seconds: 10),
          (_) => _publishPlayback(),
        );
      }
      if (mounted) {
        setState(() {
          _loading = false;
          _connected = true;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _connected = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _disconnectRealtime() async {
    _heartbeat?.cancel();
    _playbackTimer?.cancel();
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    await _channel?.sink.close();
    _channel = null;
    _connected = false;
  }

  void _send(Map<String, dynamic> payload) {
    final channel = _channel;
    if (channel == null) return;
    channel.sink.add(jsonEncode(payload));
  }

  void _onRealtimeData(dynamic raw) {
    Map<String, dynamic> event;
    try {
      final decoded = jsonDecode(raw.toString());
      if (decoded is! Map) return;
      event = Map<String, dynamic>.from(decoded);
    } catch (_) {
      return;
    }

    final type = event['type']?.toString();
    if (!mounted) return;
    if (type == 'connection.ready') {
      setState(() => _connected = true);
      final playback = event['playback'];
      if (playback is Map) {
        _handlePlaybackState(Map<String, dynamic>.from(playback));
      }
    } else if (type == 'chat.message') {
      final message = event['message'];
      if (message is Map) {
        final row = Map<String, dynamic>.from(message);
        setState(() {
          if (!_messages.any((item) => item['id'] == row['id'])) {
            _messages = [..._messages, row];
          }
        });
      }
    } else if (type == 'playback.state') {
      final playback = event['playback'];
      if (playback is Map) {
        _handlePlaybackState(Map<String, dynamic>.from(playback));
      }
    } else if (type == 'webrtc.signal') {
      _handleWebRtcSignal(event);
    } else if (type == 'presence.joined' || type == 'presence.left') {
      unawaited(_handlePresenceUpdate(type == 'presence.joined'));
    } else if (type == 'error') {
      setState(() => _error = event['detail']?.toString());
    }
  }

  Future<void> _handlePresenceUpdate(bool joined) async {
    await _refreshCurrentSalon();
    if (joined && _videoCallActive) {
      await _startVideoCall();
    }
  }

  Future<void> _refreshCurrentSalon() async {
    final id = _salon?['id']?.toString();
    if (id == null) return;
    try {
      final response = await _dio.get<Map<String, dynamic>>('/salons/' + id + '/');
      if (mounted) {
        setState(() => _salon = Map<String, dynamic>.from(response.data ?? const {}));
      }
    } catch (_) {
      // Presence updates are best effort; chat remains connected.
    }
  }

  void _handlePlaybackState(Map<String, dynamic> state) {
    final sequence = (state['sequence'] as num?)?.toInt();
    if (sequence != null) _sequence = sequence;
    final updater = state['updated_by_id']?.toString();
    if (updater != null && updater.isNotEmpty && updater != _userId) {
      widget.onRemotePlaybackState?.call(state);
    }
  }

  void _publishPlayback() {
    final state = widget.readPlaybackState?.call();
    if (state == null || _channel == null) return;
    _send({
      'type': 'playback.update',
      'playback': {
        'expected_sequence': _sequence,
        'position_ms': (state['position_ms'] as num?)?.toInt() ?? 0,
        'is_playing': state['is_playing'] == true,
        'playback_rate': (state['playback_rate'] as num?)?.toDouble() ?? 1.0,
        'event_type': 'sync',
      },
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || !_connected) return;
    _send({'type': 'chat.send', 'text': text});
    _messageController.clear();
  }

  List<Map<String, dynamic>> get _members {
    final raw = _salon?['members'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<MediaStream> _ensureLocalMedia() async {
    if (_localStream != null) return _localStream!;
    await _rendererReady;
    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 640},
        'height': {'ideal': 480},
      },
    });
    _localStream = stream;
    _localRenderer.srcObject = stream;
    return stream;
  }

  static const List<Map<String, dynamic>> _fallbackIceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
  ];

  Future<List<Map<String, dynamic>>> _iceServersForCurrentSalon() async {
    final salonId = _salon?['id']?.toString();
    if (salonId == null || salonId.isEmpty) return _fallbackIceServers;

    final expiresAt = _iceServersExpireAt;
    if (_iceServersSalonId == salonId &&
        _cachedIceServers != null &&
        expiresAt != null &&
        DateTime.now().isBefore(expiresAt)) {
      return _cachedIceServers!;
    }

    if (_iceServersSalonId == salonId && _iceServersRequest != null) {
      return _iceServersRequest!;
    }

    _iceServersSalonId = salonId;
    final request = _fetchIceServers(salonId);
    _iceServersRequest = request;
    try {
      return await request;
    } finally {
      if (identical(_iceServersRequest, request)) {
        _iceServersRequest = null;
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchIceServers(String salonId) async {
    try {
      final response = await _dio.get<Object>(
        '/salons/' + salonId + '/ice-servers/',
      );
      final rawData = response.data;
      if (rawData is Map) {
        final payload = Map<String, dynamic>.from(rawData);
        final rawServers = payload['ice_servers'];
        if (rawServers is List) {
          final servers = rawServers
              .whereType<Map>()
              .map((server) => Map<String, dynamic>.from(server))
              .where((server) => server['urls'] != null)
              .toList();
          if (servers.isNotEmpty) {
            if (_iceServersSalonId == salonId) {
              final ttl = (payload['expires_in'] as num?)?.toInt() ?? 0;
              final cacheSeconds =
                  ttl > 0 ? (ttl - 15).clamp(15, ttl).toInt() : 180;
              _cachedIceServers = servers;
              _iceServersExpireAt = DateTime.now().add(
                Duration(seconds: cacheSeconds),
              );
            }
            return servers;
          }
        }
      }
    } catch (_) {
      debugPrint(
        'Ekeroom ICE credential request failed; using public STUN fallback.',
      );
    }

    if (_iceServersSalonId == salonId) {
      _cachedIceServers = _fallbackIceServers;
      _iceServersExpireAt = DateTime.now().add(const Duration(minutes: 3));
    }
    return _fallbackIceServers;
  }

  Future<RTCPeerConnection> _createPeer(
    String peerId, {
    bool sendOffer = false,
  }) async {
    final existing = _peers[peerId];
    if (existing != null) return existing;
    final peer = await createPeerConnection({
      'iceServers': await _iceServersForCurrentSalon(),
    });
    _peers[peerId] = peer;
    final local = await _ensureLocalMedia();
    for (final track in local.getTracks()) {
      await peer.addTrack(track, local);
    }
    peer.onIceCandidate = (candidate) {
      if (candidate.candidate == null) return;
      _send({
        'type': 'webrtc.signal',
        'signal_type': 'ice_candidate',
        'target_user_id': peerId,
        'payload': candidate.toMap(),
      });
    };
    peer.onTrack = (event) async {
      if (event.streams.isEmpty) return;
      var renderer = _remoteRenderers[peerId];
      if (renderer == null) {
        renderer = RTCVideoRenderer();
        await renderer.initialize();
        _remoteRenderers[peerId] = renderer;
      }
      renderer.srcObject = event.streams.first;
      if (mounted) setState(() {});
    };

    if (sendOffer) {
      final offer = await peer.createOffer();
      await peer.setLocalDescription(offer);
      _send({
        'type': 'webrtc.signal',
        'signal_type': 'offer',
        'target_user_id': peerId,
        'payload': offer.toMap(),
      });
    }
    return peer;
  }

  Future<void> _startVideoCall() async {
    if (_isTv || _salon?['video_enabled'] == false || !_connected) return;
    try {
      await _ensureLocalMedia();
      if (mounted) setState(() => _videoCallActive = true);
      final otherMembers = _members
          .map((item) => item['user_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty && id != _userId)
          .toSet();
      for (final peerId in otherMembers) {
        final offerer = _userId.isNotEmpty && _userId.compareTo(peerId) < 0;
        await _createPeer(peerId, sendOffer: offerer);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_english
              ? 'Camera or microphone unavailable: ' + error.toString()
              : 'Caméra ou microphone indisponible : ' + error.toString()),
        ),
      );
    }
  }

  Future<void> _handleWebRtcSignal(Map<String, dynamic> event) async {
    final peerId = event['sender_user_id']?.toString() ?? '';
    if (peerId.isEmpty || peerId == _userId) return;
    final signalType = event['signal_type']?.toString();
    final payload = event['payload'] is Map
        ? Map<String, dynamic>.from(event['payload'] as Map)
        : <String, dynamic>{};
    try {
      if (signalType == 'offer') {
        await _ensureLocalMedia();
        if (mounted) setState(() => _videoCallActive = true);
        final peer = await _createPeer(peerId);
        await peer.setRemoteDescription(RTCSessionDescription(
          payload['sdp']?.toString(),
          payload['type']?.toString(),
        ));
        final answer = await peer.createAnswer();
        await peer.setLocalDescription(answer);
        _send({
          'type': 'webrtc.signal',
          'signal_type': 'answer',
          'target_user_id': peerId,
          'payload': answer.toMap(),
        });
      } else if (signalType == 'answer') {
        final peer = _peers[peerId];
        if (peer == null) return;
        await peer.setRemoteDescription(RTCSessionDescription(
          payload['sdp']?.toString(),
          payload['type']?.toString(),
        ));
      } else if (signalType == 'ice_candidate') {
        final peer = _peers[peerId];
        if (peer == null) return;
        await peer.addCandidate(RTCIceCandidate(
          payload['candidate']?.toString(),
          payload['sdpMid']?.toString(),
          (payload['sdpMLineIndex'] as num?)?.toInt(),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_english
                ? 'Could not establish the video connection.'
                : 'Impossible d’établir la connexion vidéo.'),
          ),
        );
      }
    }
  }

  Future<void> _closeVideoCall() async {
    for (final peer in _peers.values) {
      await peer.close();
    }
    _peers.clear();
    for (final renderer in _remoteRenderers.values) {
      renderer.srcObject = null;
      await renderer.dispose();
    }
    _remoteRenderers.clear();
    final stream = _localStream;
    _localStream = null;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        track.stop();
      }
      await stream.dispose();
    }
    _localRenderer.srcObject = null;
    if (mounted && !_disposing) setState(() => _videoCallActive = false);
  }

  Future<void> _leaveSalon() async {
    final id = _salon?['id']?.toString();
    if (id != null) {
      try {
        await _dio.post<Object>('/salons/' + id + '/leave/');
      } catch (_) {
        // Closing the realtime channel is enough to leave the UI cleanly.
      }
    }
    await _disconnectRealtime();
    await _closeVideoCall();
    if (mounted) {
      setState(() {
        _salon = null;
        _messages = const [];
        _error = null;
      });
      _loadSalons();
    }
  }

  Widget _roomCard(Map<String, dynamic> salon) {
    final name = salon['name']?.toString() ?? 'Ekeroom';
    final contentTitle = salon['content_title']?.toString();
    final count = (salon['member_count'] as num?)?.toInt() ?? 0;
    final scheduled = salon['scheduled_at']?.toString();
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.groups_outlined)),
        title: Text(name),
        subtitle: Text([
          if (contentTitle != null && contentTitle.isNotEmpty) contentTitle,
          _english ? count.toString() + ' watching' : count.toString() + ' participant(s)',
          if (scheduled != null && scheduled.isNotEmpty)
            (_english ? 'Starts · ' : 'Débute · ') +
                (DateTime.tryParse(scheduled)?.toLocal().toString() ?? scheduled),
        ].join(' · ')),
        trailing: FilledButton(
          onPressed: _loading
              ? null
              : () => _joinSalonById(salon['id']?.toString() ?? ''),
          child: Text(_english ? 'Join' : 'Rejoindre'),
        ),
      ),
    );
  }

  Widget _messageBubble(Map<String, dynamic> message) {
    final own = message['author_id']?.toString() == _userId;
    final text = message['text']?.toString() ?? '';
    final name = own
        ? (_english ? 'You' : 'Vous')
        : (_english ? 'Guest' : 'Participant');
    return Align(
      alignment: own ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: own
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 3),
            Text(text),
          ],
        ),
      ),
    );
  }

  Widget _videoTiles() {
    if (!_videoCallActive) return const SizedBox.shrink();
    final tiles = <Widget>[
      SizedBox(
        width: 180,
        height: 120,
        child: RTCVideoView(
          _localRenderer,
          mirror: true,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        ),
      ),
      for (final renderer in _remoteRenderers.values)
        SizedBox(
          width: 180,
          height: 120,
          child: RTCVideoView(
            renderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
        ),
    ];
    return SizedBox(
      height: 130,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: tiles
            .map((tile) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: tile,
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _roomView() {
    final salon = _salon!;
    final name = salon['name']?.toString() ?? 'Ekeroom';
    final members = _members;
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: ListTile(
            leading: IconButton(
              tooltip: _english ? 'Back to rooms' : 'Retour aux salons',
              onPressed: _leaveSalon,
              icon: const Icon(Icons.arrow_back),
            ),
            title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(_connected
                ? (_english
                    ? 'Live · ' + members.length.toString() + ' participants'
                    : 'En direct · ' + members.length.toString() + ' participant(s)')
                : (_english ? 'Connecting…' : 'Connexion…')),
            trailing: Wrap(
              spacing: 2,
              children: [
                if (widget.readPlaybackState != null)
                  IconButton(
                    tooltip: _english ? 'Sync playback' : 'Synchroniser la lecture',
                    onPressed: _publishPlayback,
                    icon: const Icon(Icons.sync),
                  ),
                if (!_isTv && salon['video_enabled'] != false)
                  IconButton(
                    tooltip: _videoCallActive
                        ? (_english ? 'End video call' : 'Terminer la vidéo')
                        : (_english ? 'Start video call' : 'Démarrer la vidéo'),
                    onPressed: _videoCallActive ? _closeVideoCall : _startVideoCall,
                    icon: Icon(_videoCallActive ? Icons.videocam_off : Icons.videocam),
                  ),
                IconButton(
                  tooltip: _english ? 'Leave room' : 'Quitter le salon',
                  onPressed: _leaveSalon,
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
          ),
        ),
        if (members.isNotEmpty)
          SizedBox(
            height: 38,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: members
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Chip(
                          avatar: const Icon(Icons.person, size: 16),
                          label: Text(item['display_name']?.toString() ??
                              (_english ? 'Guest' : 'Participant')),
                        ),
                      ))
                  .toList(),
            ),
          ),
        _videoTiles(),
        Expanded(
          child: ListView(
            reverse: true,
            padding: const EdgeInsets.all(12),
            children: _messages.reversed.map(_messageBubble).toList(),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: _connected,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: _english ? 'Write a message…' : 'Écrire un message…',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: _english ? 'Send' : 'Envoyer',
                  onPressed: _connected ? _sendMessage : null,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_english
            ? 'Ekeroom · watch together'
            : 'Ekeroom · regarder ensemble'),
        actions: [
          if (_salon == null)
            IconButton(
              tooltip: _english ? 'Create a room' : 'Créer un salon',
              onPressed: _loading ? null : _createSalon,
              icon: const Icon(Icons.add_circle_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppResponsive.isTVSize(context) ? 1400 : 1000,
            ),
            child: _salon != null
                ? _roomView()
                : Column(
                    children: [
                      if (widget.contentTitle?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Text(
                            (_english ? 'Watch ' : 'Regarder ') +
                                widget.contentTitle! +
                                (_english ? ' together' : ' ensemble'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (value) => _loadSalons(query: value),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: _english
                                ? 'Search rooms or a film title'
                                : 'Rechercher un salon ou un film',
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  _loadSalons(query: _searchController.text),
                              icon: const Icon(Icons.search),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _joinCodeController,
                                textInputAction: TextInputAction.go,
                                onSubmitted: (_) => _joinByCode(),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.key),
                                  hintText: _english
                                      ? 'Room invitation code'
                                      : 'Code d’invitation du salon',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _loading ? null : _joinByCode,
                              child: Text(_english ? 'Join' : 'Rejoindre'),
                            ),
                          ],
                        ),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      if (_loading) const LinearProgressIndicator(),
                      Expanded(
                        child: _salons.isEmpty && !_loading
                            ? Center(
                                child: Text(_english
                                    ? 'No open rooms found. Create one and invite friends.'
                                    : 'Aucun salon ouvert. Créez-en un et invitez vos proches.'),
                              )
                            : ListView(
                                padding: const EdgeInsets.all(12),
                                children: [
                                  for (final salon in _salons) _roomCard(salon),
                                ],
                              ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
