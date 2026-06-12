import 'dart:async';

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../service/child_service.dart';
import '../service/auth_token_service.dart';
import '../service/invitation_service.dart';
import '../service/parent_service.dart';
import '../service/notification_preferences_service.dart';
import '../models/child.dart';
import 'entry_screen.dart';
import 'manage_children_screen.dart';
import 'manage_safezones_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<Child> _children = [];
  String _parentName = 'Parent';
  bool _isLoading = true;
  bool _speedEnabled = true;
  DateTime? _snoozeUntil;
  Timer? _snoozeTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadNotificationPreferences();
  }

  @override
  void dispose() {
    _snoozeTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadNotificationPreferences() async {
    final speedEnabled = await NotificationPreferencesService.areSpeedNotificationsEnabled();
    final snoozeUntil = await NotificationPreferencesService.getSnoozeUntil();
    if (!mounted) return;
    setState(() {
      _speedEnabled = speedEnabled;
      _snoozeUntil = snoozeUntil;
    });
    _startSnoozeTimer();
  }

  void _startSnoozeTimer() {
    _snoozeTimer?.cancel();
    if (_snoozeUntil != null) {
      _snoozeTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (!mounted) return;
        final remaining = _snoozeUntil!.difference(DateTime.now());
        if (remaining.isNegative) {
          _snoozeTimer?.cancel();
          setState(() => _snoozeUntil = null);
        } else {
          setState(() {});
        }
      });
    }
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ChildService.getChildren(),
        ParentService.getFullName(),
      ]);
      if (!mounted) return;
      setState(() {
        _children = results[0] as List<Child>;
        _parentName = results[1] as String;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSpeedNotifications(bool enabled) async {
    await NotificationPreferencesService.setSpeedNotificationsEnabled(enabled);
    if (!mounted) return;
    setState(() {
      _speedEnabled = enabled;
      if (enabled) {
        _snoozeUntil = null;
        _snoozeTimer?.cancel();
      }
    });
  }

  void _showSnoozeOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Snooze Speed Alerts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _snoozeOption(ctx, '30 minutes', Duration(minutes: 30)),
              _snoozeOption(ctx, '1 hour', const Duration(hours: 1)),
              _snoozeOption(ctx, '2 hours', const Duration(hours: 2)),
              _snoozeOption(ctx, 'Until I change', null),
            ],
          ),
        ),
      ),
    );
  }

  Widget _snoozeOption(BuildContext ctx, String label, Duration? duration) {
    return ListTile(
      title: Text(label),
      leading: const Icon(Icons.timer_outlined),
      onTap: () async {
        Navigator.pop(ctx);
        final snoozeUntil = duration != null
            ? DateTime.now().add(duration)
            : DateTime(2100, 1, 1);
        await NotificationPreferencesService.setSpeedNotificationsEnabled(false);
        await NotificationPreferencesService.setSnoozeUntil(snoozeUntil);
        if (!mounted) return;
        setState(() {
          _speedEnabled = false;
          _snoozeUntil = snoozeUntil;
        });
        _startSnoozeTimer();
      },
    );
  }

  void _cancelSnooze() async {
    await NotificationPreferencesService.clearSnooze();
    await NotificationPreferencesService.setSpeedNotificationsEnabled(true);
    if (!mounted) return;
    setState(() {
      _speedEnabled = true;
      _snoozeUntil = null;
    });
    _snoozeTimer?.cancel();
  }

  String _buildSpeedSubtitle() {
    if (_snoozeUntil != null) {
      final remaining = _snoozeUntil!.difference(DateTime.now());
      if (remaining.isNegative) return 'Snoozed';
      if (_snoozeUntil!.year == 2100) return 'Snoozed until I change';
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes.remainder(60);
      if (hours > 0) {
        return 'Snoozed for ${hours}h ${minutes}m';
      }
      return 'Snoozed for ${minutes}m';
    }
    return _speedEnabled ? 'On' : 'Off';
  }

  void _showInviteDialog(BuildContext context) {
    final phoneController = TextEditingController();
    Child? selectedChild = _children.isNotEmpty ? _children.first : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Invite Guarantor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedChild?.id,
                decoration: const InputDecoration(
                  labelText: 'Select Child',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: _children.map((child) {
                  return DropdownMenuItem(
                    value: child.id,
                    child: Text(child.fullName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() {
                    selectedChild = _children.firstWhere((c) => c.id == value);
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  hintText: '+213 XXX XX XX XX',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final phone = phoneController.text.trim();
                if (phone.isEmpty || selectedChild == null) return;
                try {
                  await InvitationService.inviteGuarantor(
                    phoneNumber: phone,
                    childId: selectedChild!.id,
                  );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invitation sent successfully')),
                  );
                } catch (e) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Send Invite'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await AuthTokenService.deleteToken();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const EntryScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                if (!_isLoading) ...[
                  _ProfileCard(children: _children, parentName: _parentName),
                  const SizedBox(height: 20),
                ],
                _SectionTitle(title: 'General'),
                const SizedBox(height: 8),
                _SettingsTile(
                  icon: Icons.language,
                  title: 'Language',
                  subtitle: 'English',
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                _SectionTitle(title: 'Notifications'),
                const SizedBox(height: 8),
                _NotificationSettingsTile(
                  icon: Icons.speed,
                  title: 'Speed Alerts',
                  subtitle: _buildSpeedSubtitle(),
                  value: _speedEnabled,
                  onToggle: _toggleSpeedNotifications,
                  onSnooze: _speedEnabled ? _showSnoozeOptions : null,
                  onCancelSnooze: _snoozeUntil != null ? _cancelSnooze : null,
                ),
                const SizedBox(height: 20),
                _SectionTitle(title: 'Management'),
                const SizedBox(height: 8),
                _SettingsTile(
                  icon: Icons.people,
                  title: 'Manage Children',
                  subtitle: '${_children.length} child${_children.length == 1 ? '' : 'ren'}',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManageChildrenScreen(children: _children),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _SettingsTile(
                  icon: Icons.shield,
                  title: 'Manage Safe Zones',
                  subtitle: 'View and edit safe zones',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManageSafezonesScreen(children: _children),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _SectionTitle(title: 'Invitations'),
                const SizedBox(height: 8),
                _SettingsTile(
                  icon: Icons.person_add,
                  title: 'Invite Guarantor',
                  subtitle: 'Send invitation by phone number',
                  onTap: () => _showInviteDialog(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusMedium),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final List<Child> children;
  final String parentName;

  const _ProfileCard({required this.children, required this.parentName});

  @override
  Widget build(BuildContext context) {
    final count = children.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.person, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parentName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count child${count == 1 ? '' : 'ren'} tracked',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusMedium),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

class _NotificationSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onSnooze;
  final VoidCallback? onCancelSnooze;

  const _NotificationSettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onToggle,
    this.onSnooze,
    this.onCancelSnooze,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusMedium),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: AppColors.primary),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: Switch(
              value: value,
              activeThumbColor: AppColors.primary,
              onChanged: (v) {
                if (!v && onSnooze != null) {
                  onSnooze!();
                } else {
                  onToggle(v);
                }
              },
            ),
          ),
          if (onCancelSnooze != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: InkWell(
                onTap: onCancelSnooze,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.alarm_off, size: 16, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Cancel Snooze',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
