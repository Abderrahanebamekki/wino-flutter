import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/child.dart';
import '../models/safe_zone.dart';
import '../service/safezone_service.dart';
import 'edit_safezone_screen.dart';

class ManageSafezonesScreen extends StatefulWidget {
  final List<Child> children;

  const ManageSafezonesScreen({super.key, required this.children});

  @override
  State<ManageSafezonesScreen> createState() => _ManageSafezonesScreenState();
}

class _ManageSafezonesScreenState extends State<ManageSafezonesScreen> {
  Child? _selectedChild;
  List<SafeZone> _safeZones = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.children.isNotEmpty) {
      _selectedChild = widget.children.first;
      _loadZones();
    }
  }

  Future<void> _loadZones() async {
    if (_selectedChild == null) return;
    setState(() => _isLoading = true);
    try {
      final zones = await SafezoneService.getSafeZone(_selectedChild!.id);
      if (!mounted) return;
      setState(() {
        _safeZones = zones;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editZone(SafeZone zone) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditSafezoneScreen(safezone: zone),
      ),
    );

    if (result == true && mounted) {
      _loadZones();
    }
  }

  Future<void> _deleteZone(SafeZone zone) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Safezone'),
        content: Text('Delete "${zone.name}"?'),
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
      await SafezoneService.deleteSafezone(zone.id);
      if (!mounted) return;
      setState(() => _safeZones.removeWhere((z) => z.id == zone.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${zone.name}" deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Safe Zones'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: DropdownButtonFormField<int>(
              value: _selectedChild?.id,
              decoration: const InputDecoration(
                labelText: 'Select Child',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: widget.children.map((child) {
                return DropdownMenuItem(
                  value: child.id,
                  child: Text(child.fullName),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedChild = widget.children.firstWhere((c) => c.id == value);
                });
                _loadZones();
              },
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_safeZones.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No safe zones for this child',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _safeZones.length,
                itemBuilder: (context, index) {
                  final zone = _safeZones[index];
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
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.success,
                        child: Icon(Icons.shield, color: Colors.white),
                      ),
                      title: Text(
                        zone.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Radius: ${zone.radius.toStringAsFixed(0)}m',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _editZone(zone),
                            icon: const Icon(Icons.edit, size: 20),
                            color: Colors.blue,
                          ),
                          IconButton(
                            onPressed: () => _deleteZone(zone),
                            icon: const Icon(Icons.delete, size: 20),
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
