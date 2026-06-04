import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '../theme/app_colors.dart';
import '../models/child.dart';
import '../models/child_gps.dart';

class ChildrenPanel extends StatelessWidget {
  final ScrollController scrollController;
  final PanelController panelController;
  final List<Child> children;
  final Map<int, ChildGps> locations;
  final VoidCallback onToggle;
  final void Function(Child) onChildTap;

  const ChildrenPanel({
    super.key,
    required this.scrollController,
    required this.panelController,
    required this.children,
    required this.locations,
    required this.onToggle,
    required this.onChildTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PanelHandle(onToggle: onToggle),
        const SizedBox(height: 8),
        _PanelHeader(childrenCount: _activeChildren.length, onToggle: onToggle),
        Expanded(child: _buildChildrenList()),
      ],
    );
  }

  List<Child> get _activeChildren =>
      children.where((c) => locations.containsKey(c.id)).toList();

  Widget _buildChildrenList() {
    final active = _activeChildren;
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: active.length,
      itemBuilder: (context, index) => _buildChildItem(active[index]),
    );
  }

  Widget _buildChildItem(Child child) {
    final location = locations[child.id];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.info,
          child: Text(
            child.initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          child.fullName,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${child.age} years old',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        trailing: CircleAvatar(
          radius: 25,
          backgroundColor: AppColors.info,
          child: Text(
            location == null
                ? '--'
                : '${location.speed.toStringAsFixed(0)}\nkm/h',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () => onChildTap(child),
      ),
    );
  }
}

class _PanelHandle extends StatelessWidget {
  final VoidCallback onToggle;
  const _PanelHandle({required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: 44,
        height: 5,
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final int childrenCount;
  final VoidCallback onToggle;
  const _PanelHeader({
    required this.childrenCount,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              const Text(
                'Children Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$childrenCount active',
                  style: const TextStyle(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
