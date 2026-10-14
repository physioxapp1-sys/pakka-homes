import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/auth_scope.dart';
import '../data/product_models.dart' show formatNpr;
import '../data/rent_models.dart';
import '../data/rent_repository.dart';
import '../theme/app_colors.dart';
import 'rent_forms.dart';

/// One house, read the way a landlord walks it: floor by floor, each room
/// vacant or occupied.
class BuildingScreen extends StatefulWidget {
  const BuildingScreen({
    super.key,
    required this.building,
    required this.repository,
  });

  final Building building;
  final RentRepository repository;

  @override
  State<BuildingScreen> createState() => _BuildingScreenState();
}

class _BuildingScreenState extends State<BuildingScreen> {
  late Building _building = widget.building;
  List<RentProperty>? _rooms;
  String? _error;

  /// True if anything changed, so the list behind knows to reload.
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final token = AuthScope.of(context).token!;
    try {
      final rooms = await widget.repository.rooms(token, _building.id);
      final buildings = await widget.repository.buildings(token);
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _building = buildings.firstWhere((b) => b.id == _building.id,
            orElse: () => _building);
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _rooms = const [];
          _error = e.message;
        });
      }
    }
  }

  Future<void> _rename() async {
    final controller = TextEditingController(text: _building.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    try {
      final updated = await widget.repository.renameBuilding(
        _building.id,
        token: AuthScope.of(context).token!,
        name: name,
      );
      if (mounted) setState(() {
        _building = updated;
        _dirty = true;
      });
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _addRooms() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddRoomsScreen(
          building: _building,
          repository: widget.repository,
        ),
      ),
    );
    if (added == true && mounted) {
      _dirty = true;
      await _load();
    }
  }

  Future<void> _addTenant(RentProperty room) async {
    final alsoVacant = [
      for (final r in _rooms ?? const <RentProperty>[])
        if (r.id != room.id && !r.isOccupied) r,
    ];
    final added = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTenantScreen(property: room, alsoVacant: alsoVacant),
      ),
    );
    if (added != null && mounted) {
      _dirty = true;
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_dirty);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          title: Text(_building.name),
          actions: [
            IconButton(
              onPressed: _rename,
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Rename',
            ),
          ],
        ),
        body: _body(),
        floatingActionButton: _building.hasRooms
            ? FloatingActionButton.extended(
                onPressed: _addRooms,
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add rooms'),
              )
            : null,
      ),
    );
  }

  Widget _body() {
    final rooms = _rooms;
    if (rooms == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }
    if (rooms.isEmpty) {
      return _Empty(
        message: _error ??
            (_building.hasRooms
                ? 'No rooms yet. Lay out the floors and this fills in.'
                : 'Nothing in here yet.'),
        actionLabel: _building.hasRooms ? 'Add rooms' : null,
        onAction: _building.hasRooms ? _addRooms : null,
      );
    }

    // Grouped by floor, in the order they are walked.
    final byFloor = <int, List<RentProperty>>{};
    for (final room in rooms) {
      byFloor.putIfAbsent(room.floor ?? 0, () => []).add(room);
    }
    final floors = byFloor.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.green,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          _Header(building: _building),
          const SizedBox(height: 14),
          for (final floor in floors) ...[
            _FloorHeading(floor: floor, rooms: byFloor[floor]!),
            const SizedBox(height: 8),
            for (final room in byFloor[floor]!)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RoomRow(
                  room: room,
                  onAddTenant: room.isOccupied ? null : () => _addTenant(room),
                ),
              ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.building});

  final Building building;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(building.kindDisplay.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11, letterSpacing: 0.8, color: Color(0xFFBBD4EA))),
              ),
              if (building.roomsVacant > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${building.roomsVacant} vacant',
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            building.hasRooms
                ? '${building.roomsLet} of ${building.roomsTotal} rooms let'
                : 'Let whole',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          if (building.address.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              [building.address, building.city]
                  .where((s) => s.isNotEmpty)
                  .join(', '),
              style: const TextStyle(fontSize: 12.5, color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}

class _FloorHeading extends StatelessWidget {
  const _FloorHeading({required this.floor, required this.rooms});

  final int floor;
  final List<RentProperty> rooms;

  @override
  Widget build(BuildContext context) {
    final let = rooms.where((r) => r.isOccupied).length;
    return Row(
      children: [
        Text(floor == 0 ? 'Rooms' : 'Floor $floor',
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navy)),
        const SizedBox(width: 8),
        Text('$let of ${rooms.length} let',
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _RoomRow extends StatelessWidget {
  const _RoomRow({required this.room, required this.onAddTenant});

  final RentProperty room;

  /// Null on a room that already has someone in it.
  final VoidCallback? onAddTenant;

  @override
  Widget build(BuildContext context) {
    final occupied = room.isOccupied;
    final colour = occupied ? AppColors.green : AppColors.blue;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            height: 10,
            width: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: colour),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_shortTitle(room),
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  occupied
                      ? '${room.tenantName ?? "Occupied"} · '
                          '${formatNpr(room.monthlyRent)}'
                      : (room.monthlyRent > 0
                          ? 'Vacant · ${formatNpr(room.monthlyRent)}'
                          : 'Vacant'),
                  style: TextStyle(
                      fontSize: 12.5,
                      color: occupied ? AppColors.textSecondary : colour),
                ),
              ],
            ),
          ),
          if (onAddTenant != null)
            TextButton(
              onPressed: onAddTenant,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.green,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Add tenant'),
            ),
        ],
      ),
    );
  }

  /// "Floor 2, Room 3" reads as "Room 3" under a Floor 2 heading.
  String _shortTitle(RentProperty room) {
    final prefix = 'Floor ${room.floor}, ';
    return room.title.startsWith(prefix)
        ? room.title.substring(prefix.length)
        : room.title;
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.meeting_room_outlined,
                size: 46, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary)),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
