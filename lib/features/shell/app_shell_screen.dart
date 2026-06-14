import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/session/app_session_scope.dart';
import '../ambulance/ambulance_screen.dart';
import '../appointments/appointments_screen.dart';
import '../diagnostics/diagnostics_screen.dart';
import '../doctors/doctors_screen.dart';
import '../home/chat_home_screen.dart';
import '../invoices/invoices_screen.dart';
import '../prescriptions/prescriptions_screen.dart';
import '../profile/profile_screen.dart';
import '../reports/reports_screen.dart';

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  int _currentIndex = 0;

  static const _destinations = <_ShellDestination>[
    _ShellDestination(
      title: 'Care Chat',
      subtitle: 'Chat-first healthcare help',
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
      sectionKey: 'chat',
    ),
    _ShellDestination(
      title: 'Doctors',
      subtitle: 'Find specialists and book visits',
      icon: Icons.medical_services_outlined,
      selectedIcon: Icons.medical_services_rounded,
      sectionKey: 'doctors',
    ),
    _ShellDestination(
      title: 'Appointments',
      subtitle: 'Upcoming, completed, and missed',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month_rounded,
      sectionKey: 'appointments',
    ),
    _ShellDestination(
      title: 'Diagnostics',
      subtitle: 'Tests, labs, and payment flow',
      icon: Icons.biotech_outlined,
      selectedIcon: Icons.biotech_rounded,
      sectionKey: 'diagnostics',
    ),
    _ShellDestination(
      title: 'Reports',
      subtitle: 'Lab reports and secure files',
      icon: Icons.folder_open_outlined,
      selectedIcon: Icons.folder_rounded,
      sectionKey: 'reports',
    ),
    _ShellDestination(
      title: 'Prescriptions',
      subtitle: 'Medication and doctor notes',
      icon: Icons.medication_outlined,
      selectedIcon: Icons.medication_rounded,
      sectionKey: 'prescriptions',
    ),
    _ShellDestination(
      title: 'Invoices',
      subtitle: 'Payments and invoice downloads',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      sectionKey: 'invoices',
    ),
    _ShellDestination(
      title: 'Profile',
      subtitle: 'Account and patient information',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      sectionKey: 'profile',
    ),
  ];

  static const _quickLinks = <_QuickLink>[
    _QuickLink(
      title: 'Emergency',
      icon: Icons.emergency_outlined,
      sectionKey: 'ambulance',
      color: Color(0xFFFFE8E8),
    ),
    _QuickLink(
      title: 'Reports',
      icon: Icons.description_outlined,
      sectionKey: 'reports',
      color: Color(0xFFFFF3DE),
    ),
    _QuickLink(
      title: 'Invoices',
      icon: Icons.receipt_long_outlined,
      sectionKey: 'invoices',
      color: Color(0xFFE7F4F1),
    ),
  ];

  int _indexForSection(String sectionKey) {
    final index = _destinations.indexWhere(
      (destination) => destination.sectionKey == sectionKey,
    );
    return index < 0 ? 0 : index;
  }

  void _openSection(String sectionKey) {
    if (sectionKey == 'ambulance') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AmbulanceScreen()));
      return;
    }

    setState(() {
      _currentIndex = _indexForSection(sectionKey);
    });
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return ChatHomeScreen(onOpenSection: _openSection);
      case 1:
        return const DoctorsScreen();
      case 2:
        return const AppointmentsScreen();
      case 3:
        return const DiagnosticsScreen();
      case 4:
        return const ReportsScreen();
      case 5:
        return const PrescriptionsScreen();
      case 6:
        return const InvoicesScreen();
      case 7:
        return const ProfileScreen();
      default:
        return ChatHomeScreen(onOpenSection: _openSection);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.of(context);
    final wide = MediaQuery.of(context).size.width >= 1100;
    final current = _destinations[_currentIndex];

    if (!session.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      });
    }

    final content = _buildCurrentScreen();

    if (wide) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              _DesktopSidebar(
                destinations: _destinations,
                currentIndex: _currentIndex,
                currentUserName: session.currentUser?.fullName ?? 'HHL Patient',
                currentUserEmail:
                    session.currentUser?.email ?? 'patient account',
                quickLinks: _quickLinks,
                onSelect: (index) {
                  setState(() => _currentIndex = index);
                },
                onQuickLink: _openSection,
                onLogout: () async {
                  await session.logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                },
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: content,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              current.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              session.currentUser == null
                  ? 'Healthcare platform'
                  : session.currentUser!.fullName,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await session.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacementNamed(AppRoutes.login);
            },
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: content,
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (value) {
          setState(() => _currentIndex = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services_rounded),
            label: 'Doctors',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Visits',
          ),
          NavigationDestination(
            icon: Icon(Icons.biotech_outlined),
            selectedIcon: Icon(Icons.biotech_rounded),
            label: 'Labs',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_open_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication_rounded),
            label: 'Rx',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Invoices',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.destinations,
    required this.currentIndex,
    required this.currentUserName,
    required this.currentUserEmail,
    required this.quickLinks,
    required this.onSelect,
    required this.onQuickLink,
    required this.onLogout,
  });

  final List<_ShellDestination> destinations;
  final int currentIndex;
  final String currentUserName;
  final String currentUserEmail;
  final List<_QuickLink> quickLinks;
  final ValueChanged<int> onSelect;
  final ValueChanged<String> onQuickLink;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 304,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFEEF5F4),
        border: Border(right: BorderSide(color: Color(0xFFD9E6E4))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.favorite_rounded),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HHL Care',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Chat-first patient workspace',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => onSelect(0),
            icon: const Icon(Icons.add_comment_rounded),
            label: const Text('New chat'),
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Workspace',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (var i = 0; i < destinations.length; i++) ...[
                  _SidebarDestinationTile(
                    destination: destinations[i],
                    selected: i == currentIndex,
                    onTap: () => onSelect(i),
                  ),
                  const SizedBox(height: 6),
                ],
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Quick actions',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                for (final quickLink in quickLinks) ...[
                  _QuickLinkTile(
                    quickLink: quickLink,
                    onTap: () => onQuickLink(quickLink.sectionKey),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUserName,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentUserEmail,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarDestinationTile extends StatelessWidget {
  const _SidebarDestinationTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFDDF2EE) : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                color: selected ? AppColors.primaryDark : AppColors.muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.title,
                      style: TextStyle(
                        color: selected ? AppColors.ink : AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      destination.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickLinkTile extends StatelessWidget {
  const _QuickLinkTile({required this.quickLink, required this.onTap});

  final _QuickLink quickLink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: quickLink.color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(quickLink.icon, color: AppColors.primaryDark),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  quickLink.title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selectedIcon,
    required this.sectionKey,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final IconData selectedIcon;
  final String sectionKey;
}

class _QuickLink {
  const _QuickLink({
    required this.title,
    required this.icon,
    required this.sectionKey,
    required this.color,
  });

  final String title;
  final IconData icon;
  final String sectionKey;
  final Color color;
}
