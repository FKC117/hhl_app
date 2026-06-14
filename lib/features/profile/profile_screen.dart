import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/session/app_session_scope.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.of(context);
    final user = session.currentUser;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFE4F4F1),
                  foregroundColor: AppColors.primaryDark,
                  child: Icon(Icons.person_rounded, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.fullName ?? 'Patient profile shell',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user == null
                      ? 'This screen will later use `/api/v1/auth/me/` and editable patient data.'
                      : '${user.email}\nRole: ${user.role.isEmpty ? 'Patient' : user.role}\nPhone: ${user.phone.isEmpty ? 'Not provided' : user.phone}',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
