import 'package:flutter/material.dart';
import 'package:plateforme_producteurs/ui/producers_dashboard/users/models/user_model.dart';

class UserWidget extends StatelessWidget {
  final User user;

  const UserWidget({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildAvatar(),
        const SizedBox(width: 12),
        _buildUserInfo(),
      ],
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.grey[200],
      backgroundImage: user.profileImage != null 
          ? NetworkImage(user.profileImage!)
          : null,
      child: user.profileImage == null
          ? const Icon(Icons.person, size: 20)
          : null,
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          user.email,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}