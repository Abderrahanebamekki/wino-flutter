import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/child.dart';
import '../service/child_service.dart';

class ManageChildrenScreen extends StatefulWidget {
  final List<Child> children;

  const ManageChildrenScreen({super.key, required this.children});

  @override
  State<ManageChildrenScreen> createState() => _ManageChildrenScreenState();
}

class _ManageChildrenScreenState extends State<ManageChildrenScreen> {
  late List<Child> _children;

  @override
  void initState() {
    super.initState();
    _children = List.from(widget.children);
  }

  Future<void> _deleteChild(Child child) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Child'),
        content: Text('Are you sure you want to delete ${child.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ChildService.deleteChild(child.id);
      if (!mounted) return;
      setState(() => _children.removeWhere((c) => c.id == child.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${child.fullName} deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Children'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _children.isEmpty
          ? const Center(
              child: Text(
                'No children added yet',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _children.length,
              itemBuilder: (context, index) {
                final child = _children[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusMedium),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${child.age} years old'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.edit, size: 20),
                          color: Colors.blue,
                        ),
                        IconButton(
                          onPressed: () => _deleteChild(child),
                          icon: const Icon(Icons.delete, size: 20),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
