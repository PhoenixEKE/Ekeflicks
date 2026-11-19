// lib/src/models/device.dart
class Device {
  final String? id;
  final String? name;
  final String? type;
  final String? lastActive;

  Device({
    this.id,
    this.name,
    this.type,
    this.lastActive,
  });

  /// Créer un objet [Device] depuis un JSON
  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String?,
      name: json['name'] as String?,
      type: json['type'] as String?,
      lastActive: json['lastActive'] as String?,
    );
  }

  /// Convertir un objet [Device] en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'lastActive': lastActive,
    };
  }

  /// Pour debug
  @override
  String toString() {
    return 'Device(id: $id, name: $name, type: $type, lastActive: $lastActive)';
  }
}
