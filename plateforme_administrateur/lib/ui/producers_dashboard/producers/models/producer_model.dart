// lib/producers_dashboard/producers/models/producer_model.dart

class Producer {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String country;
  final String password;
  final int totalVideos;
  final int validatedVideos;
  final int rejectedVideos;
  final int pendingVideos;
  final int totalViews;
  final Map<String, int> viewsPerVideo;
  final double earnings;
  final String status;

  Producer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.country,
    required this.password,
    this.totalVideos = 0,
    this.validatedVideos = 0,
    this.rejectedVideos = 0,
    this.pendingVideos = 0,
    this.totalViews = 0,
    this.viewsPerVideo = const {},
    this.earnings = 0,
    this.status = 'Actif',
  });
}