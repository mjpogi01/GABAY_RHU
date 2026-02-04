import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/design_system.dart';
import '../../providers/app_provider.dart';
import '../../models/user_model.dart';

/// Admin Users: search, list, and user detail modal.
/// Uses mock list until admin API (e.g. list all users) is available.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: EdgeInsets.only(left: DesignSystem.s(context, 12)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Users',
              style: TextStyle(fontWeight: FontWeight.bold, color: DesignSystem.textPrimary, fontSize: DesignSystem.appTitleSize(context)),
            ),
          ),
        ),
        backgroundColor: DesignSystem.cardSurface,
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: DesignSystem.s(context, 12)),
            child: IconButton(icon: Icon(Icons.filter_list, color: DesignSystem.textSecondary, size: DesignSystem.s(context, 24)), onPressed: () {}),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(DesignSystem.adminContentPadding(context)),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(fontSize: DesignSystem.captionSize(context)),
              decoration: InputDecoration(
                hintText: 'Search name or user id.',
                hintStyle: TextStyle(fontSize: DesignSystem.captionSize(context), color: DesignSystem.textMuted),
                prefixIcon: const Icon(Icons.search, color: DesignSystem.textMuted),
                filled: true,
                fillColor: DesignSystem.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignSystem.inputBorderRadius),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _UserList(
              query: _query,
              onUserTap: (u) => _showUserModal(context, u),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserModal(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: DesignSystem.cardSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              DesignSystem.adminContentPadding(context) * 1.2,
              DesignSystem.s(context, 12),
              DesignSystem.adminContentPadding(context) * 1.2,
              DesignSystem.adminContentPadding(context) * 1.2,
            ),
            children: [
              Center(
                child: Container(
                  width: DesignSystem.wRatio(context, 40 / 375),
                  height: 4,
                  decoration: BoxDecoration(
                    color: DesignSystem.inputBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: DesignSystem.s(context, 12)),
              CircleAvatar(
                radius: DesignSystem.adminAvatarLarge(context) / 2,
                backgroundColor: DesignSystem.accentYellow,
                child: Icon(Icons.person, size: DesignSystem.adminAvatarLarge(context) * 0.6, color: Colors.grey.shade700),
              ),
              SizedBox(height: DesignSystem.adminGridGap(context)),
              Text(
                user.displayName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: DesignSystem.sectionTitleSize(context),
                  fontWeight: FontWeight.bold,
                  color: DesignSystem.textPrimary,
                ),
              ),
              SizedBox(height: DesignSystem.adminSectionGap(context)),
              _detailRow('Status', user.status ?? '—'),
              _detailRow('Age', '—'),
              _detailRow('Children', user.numberOfChildren?.toString() ?? '0'),
              SizedBox(height: DesignSystem.adminGridGap(context)),
              Text('Progress', style: TextStyle(fontWeight: FontWeight.w600, color: DesignSystem.textPrimary)),
              SizedBox(height: 4),
              LinearProgressIndicator(
                value: 0.6,
                backgroundColor: DesignSystem.inputBackground,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 8),
              Text('60%', style: TextStyle(fontSize: DesignSystem.captionSize(context), color: DesignSystem.textSecondary)),
              SizedBox(height: DesignSystem.adminSectionGap(context)),
              _tasksTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: DesignSystem.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, color: DesignSystem.textPrimary)),
        ],
      ),
    );
  }

  Widget _tasksTable() {
    final rows = [
      ('Pre-Test', 'Done', '70%'),
      ('Module 12', 'Done', '30:00'),
      ('Module 13', 'Done', '30:00'),
      ('Module 14', 'Not Done', '—'),
      ('Post-Test', 'Not Done', '—'),
    ];
    return Table(
      columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1.2), 2: FlexColumnWidth(1)},
      children: [
        TableRow(
          decoration: BoxDecoration(color: DesignSystem.inputBackground),
          children: ['Tasks', 'Status', 'Score/Time'].map((h) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          )).toList(),
        ),
        ...rows.map((r) => TableRow(
          children: [
            Padding(padding: const EdgeInsets.all(8), child: Text(r.$1, style: const TextStyle(fontSize: 12))),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: r.$2 == 'Done' ? Colors.green.shade50 : DesignSystem.inputBackground,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(r.$2, style: TextStyle(fontSize: 12, color: r.$2 == 'Done' ? Colors.green.shade800 : DesignSystem.textSecondary)),
              ),
            ),
            Padding(padding: const EdgeInsets.all(8), child: Text(r.$3, style: const TextStyle(fontSize: 12))),
          ],
        )),
      ],
    );
  }
}

class _UserList extends StatelessWidget {
  final String query;
  final ValueChanged<UserModel> onUserTap;

  const _UserList({required this.query, required this.onUserTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        // Build list: never include the logged-in admin. In production, use an admin API to list all non-admin users.
        final List<UserModel> users = [];
        final currentUser = provider.user;
        if (currentUser != null && !currentUser.isAdmin) {
          users.add(currentUser);
        }
        // Placeholder entries for UI demo when no other users (e.g. when logged in as admin).
        if (users.isEmpty) {
          users.addAll([
            UserModel(
              id: 'demo-1',
              anonymizedId: 'anon-1',
              role: 'parent',
              createdAt: DateTime.now(),
              firstName: 'Maritess',
              lastName: 'Cruz',
              status: 'Expecting Mother',
            ),
            UserModel(
              id: 'demo-2',
              anonymizedId: 'anon-2',
              role: 'parent',
              createdAt: DateTime.now(),
              firstName: 'Jerjer',
              lastName: 'Moneyger',
              status: 'New Mother',
            ),
          ]);
        }
        // Ensure no admin accounts appear in the list (e.g. from a future API).
        final nonAdminUsers = users.where((u) => !u.isAdmin).toList();
        final filtered = query.isEmpty
            ? nonAdminUsers
            : nonAdminUsers.where((u) {
                final name = '${u.firstName ?? ''} ${u.lastName ?? ''} ${u.id}'.toLowerCase();
                return name.contains(query.toLowerCase());
              }).toList();

        if (filtered.isEmpty) {
          return Center(child: Text('No users found', style: TextStyle(color: DesignSystem.textSecondary)));
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: DesignSystem.adminContentPadding(context)),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final u = filtered[i];
            final progress = 0.6; // placeholder
            return Card(
              margin: EdgeInsets.only(bottom: DesignSystem.adminGridGap(context)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.adminCardRadius(context))),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: DesignSystem.adminContentPadding(context), vertical: DesignSystem.adminGridGap(context)),
                leading: CircleAvatar(
                  radius: DesignSystem.wRatio(context, 24 / 375),
                  backgroundColor: DesignSystem.primary.withValues(alpha: 0.2),
                  child: Text((u.firstName?.substring(0, 1) ?? 'U').toUpperCase(), style: const TextStyle(color: DesignSystem.primary)),
                ),
                title: Text('${u.displayName}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.status ?? '—', style: TextStyle(fontSize: 12, color: DesignSystem.textSecondary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Progress: ${(progress * 100).round()}%', style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: DesignSystem.inputBackground,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: const Icon(Icons.more_vert),
                onTap: () => onUserTap(u),
              ),
            );
          },
        );
      },
    );
  }
}
