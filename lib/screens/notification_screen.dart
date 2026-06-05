import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/notification.dart';
import '../models/notification_category.dart';
import '../models/invitation_dto.dart';
import '../service/notification_messages.dart';
import '../service/invitation_service.dart';


class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationCategory _selectedCategory = NotificationCategory.update;
  List<InvitationDto> _invitations = [];
  bool _isLoadingInvitations = false;

  final List<NotificationM> _notifications = [
    NotificationM(
      title: 'Safe Zone',
      message: NotificationMessages.safezoneEnter('hala baset', 'school'),
      category: NotificationCategory.update,
      time: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    NotificationM(
      title: 'Speed Alert',
      message: NotificationMessages.abnormalSpeed('hala baset', 9),
      category: NotificationCategory.alert,
      time: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    NotificationM(
      title: 'Safe Zone',
      message: NotificationMessages.safezoneExit('hala baset', 'school'),
      category: NotificationCategory.update,
      time: DateTime.now().subtract(const Duration(minutes: 40)),
    ),
  ];

  List<NotificationM> get _filteredNotifications =>
      _notifications.where((n) => n.category == _selectedCategory).toList();

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    setState(() => _isLoadingInvitations = true);
    try {
      final invitations = await InvitationService.getInvitations();
      if (!mounted) return;
      setState(() {
        _invitations = invitations;
        _isLoadingInvitations = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingInvitations = false);
    }
  }

  Future<void> _acceptInvitation(InvitationDto inv) async {
    try {
      await InvitationService.acceptInvitation(inv.id);
      if (!mounted) return;
      setState(() => _invitations.removeWhere((i) => i.id == inv.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Accepted invitation from ${inv.parentFullName}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Future<void> _declineInvitation(InvitationDto inv) async {
    try {
      await InvitationService.declineInvitation(inv.id);
      if (!mounted) return;
      setState(() => _invitations.removeWhere((i) => i.id == inv.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Declined invitation from ${inv.parentFullName}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  String _categoryName(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.update:
        return 'Updates';
      case NotificationCategory.alert:
        return 'Alerts';
      case NotificationCategory.invitation:
        return 'Invitations';
    }
  }

  Color _categoryColor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.update:
        return AppColors.info;
      case NotificationCategory.alert:
        return AppColors.error;
      case NotificationCategory.invitation:
        return Colors.deepPurple;
    }
  }

  IconData _categoryIcon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.update:
        return Icons.notifications;
      case NotificationCategory.alert:
        return Icons.warning_rounded;
      case NotificationCategory.invitation:
        return Icons.mail;
    }
  }

  String _timeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    return '${difference.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _filteredNotifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          _buildCategoryTabs(),
          const SizedBox(height: 16),
          Expanded(
            child: _selectedCategory == NotificationCategory.invitation
                ? _buildInvitationsContent()
                : notifications.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) =>
                            _buildNotificationCard(notifications[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: NotificationCategory.values.map((category) {
          final isSelected = _selectedCategory == category;
          final color = _categoryColor(category);

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(
                    _categoryIcon(category),
                    color: isSelected ? Colors.white : color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _categoryName(category),
                    style: TextStyle(
                      color: isSelected ? Colors.white : color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationM notification) {
    final color = _categoryColor(notification.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusXLarge),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(_categoryIcon(notification.category), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      _timeAgo(notification.time),
                      style:
                          TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification.message,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationsContent() {
    if (_isLoadingInvitations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_invitations.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _invitations.length,
      itemBuilder: (context, index) => _buildInvitationCard(_invitations[index]),
    );
  }

  Widget _buildInvitationCard(InvitationDto inv) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusXLarge),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.deepPurple.withValues(alpha: 0.12),
            child: const Icon(Icons.mail, color: Colors.deepPurple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Invitation',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (inv.status.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: inv.status == 'PENDING'
                              ? Colors.orange.withValues(alpha: 0.15)
                              : inv.status == 'ACCEPTED'
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          inv.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: inv.status == 'PENDING'
                                ? Colors.orange
                                : inv.status == 'ACCEPTED'
                                    ? Colors.green
                                    : Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'From: ${inv.parentFullName}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Child: ${inv.childFullName}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                if (inv.status == 'PENDING' || inv.status.isEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _acceptInvitation(inv),
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        tooltip: 'Accept',
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () => _declineInvitation(inv),
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        tooltip: 'Decline',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No notifications yet',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
