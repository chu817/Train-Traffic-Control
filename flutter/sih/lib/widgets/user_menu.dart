import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/page_transitions_fixed.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';

class UserMenu extends StatelessWidget {
  const UserMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final email = user?.email ?? 'User';
    final initial = email.isNotEmpty ? email.characters.first.toUpperCase() : 'U';
    return PopupMenuButton<int>(
      tooltip: 'Account',
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(email, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(user?.uid ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 0,
          child: Row(children: [Icon(Icons.person, size: 18), SizedBox(width: 8), Text('Profile')]),
        ),
        const PopupMenuItem(
          value: 1,
          child: Row(children: [Icon(Icons.logout, size: 18), SizedBox(width: 8), Text('Sign out')]),
        ),
      ],
      onSelected: (value) async {
        if (value == 0) {
          if (!context.mounted) return;
          Navigator.of(context).push(PageRoutes.fadeThrough(const ProfileScreen()));
        } else if (value == 1) {
          await AuthService().signOut();
          if (!context.mounted) return;
          Navigator.of(context).pushReplacement(PageRoutes.fadeThrough(const LoginScreen()));
        }
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF0D47A1),
            child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Text(email, style: const TextStyle(color: Colors.black87)),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
        ],
      ),
    );
  }
}


