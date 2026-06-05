import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../service/child_service.dart';
import '../service/auth_token_service.dart';
import '../service/invitation_service.dart';
import '../service/parent_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadData();
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
