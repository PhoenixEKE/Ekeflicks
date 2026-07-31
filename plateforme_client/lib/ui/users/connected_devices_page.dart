import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/src/models/device.dart';

class ConnectedDevicesPage extends StatefulWidget {
  const ConnectedDevicesPage({super.key});

  @override
  State<ConnectedDevicesPage> createState() => _ConnectedDevicesPageState();
}

class _ConnectedDevicesPageState extends State<ConnectedDevicesPage> {
  bool _loading = true;
  String? _error;
  List<Device> _devices = [];

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // TODO: remplacer par l'appel API réel quand il sera prêt
      await Future.delayed(const Duration(seconds: 1)); // simuler chargement
      _devices = [
        Device(id: "1", name: "iPhone 14", type: "Mobile", lastActive: "2025-09-18 12:00"),
        Device(id: "2", name: "PC Windows", type: "Desktop", lastActive: "2025-09-17 18:30"),
      ];

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Impossible de récupérer les appareils : $e";
        _loading = false;
      });
    }
  }

  Future<void> _disconnectDevice(String deviceId) async {
    // Mock suppression
    setState(() {
      _devices.removeWhere((d) => d.id == deviceId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Appareil déconnecté avec succès")),
    );

    // TODO: appeler l'API réelle ici quand disponible
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.connectedDevices ?? "Appareils connectés"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDevices,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _devices.isEmpty
                  ? Center(child: Text(loc?.aucunAppareil ?? "Aucun appareil connecté"))
                  : ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.devices),
                            title: Text(device.name ?? "Appareil inconnu"),
                            subtitle: Text(
                              "Type: ${device.type ?? 'Inconnu'}\n"
                              "Dernière connexion: ${device.lastActive ?? 'N/A'}",
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.logout, color: Colors.red),
                              onPressed: () => _disconnectDevice(device.id!),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
