import 'package:flutter/material.dart';
import 'package:plateforme_producteurs/widgets/users/linked_profiles_widget.dart';
import 'package:plateforme_producteurs/ui/producers_dashboard/users/models/user_model.dart';
import 'package:plateforme_producteurs/widgets/users/user_form.dart';
import 'package:plateforme_producteurs/widgets/users/user_transactions.dart';
import 'package:plateforme_producteurs/widgets/users/user_status_chip.dart';
import 'package:plateforme_producteurs/widgets/users/user_actions.dart';
import 'package:plateforme_producteurs/widgets/users/user_filters.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<User> _users = [];
  List<User> _filteredUsers = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _countries = ['France', 'Belgique', 'Suisse', 'Canada'];

  UserStatus? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  void _loadUsers() {
    setState(() {
      _users = _getMockUsers();
      _filteredUsers = List.from(_users);
    });
  }

  List<User> _getMockUsers() {
    return [
      User(
        id: 1,
        name: 'Jean Dupont',
        email: 'jean.dupont@example.com',
        password: 'motdepasse123',
        phone: '+33612345678',
        profileImage: null,
        subscription: 'Premium',
        country: 'France',
        joinDate: DateTime(2023, 1, 15),
        subscriptionStart: DateTime(2023, 1, 15),
        subscriptionEnd: DateTime(2024, 1, 15),
        status: UserStatus.active,
        linkedProfiles: [
          LinkedProfile(
            id: '1',
            type: 'Enfant',
            name: 'Lucas Dupont',
            relation: 'Fils',
            accessLevel: 'Limité',
          ),
        ],
        transactions: [
          Transaction(
            id: 'TXN001',
            amount: 49.99,
            date: DateTime(2023, 2, 5),
            method: PaymentMethod.creditCard,
            status: TransactionStatus.completed,
          ),
          Transaction(
            id: 'TXN002',
            amount: 29.99,
            date: DateTime(2023, 3, 10),
            method: PaymentMethod.paypal,
            status: TransactionStatus.pending,
          ),
        ],
      ),
    ];
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredUsers = _users.where((user) {
        final matchSearch = user.name.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query);

        final matchStatus =
            _selectedStatus == null || user.status == _selectedStatus;

        final matchDate = (_startDate == null || user.joinDate.isAfter(_startDate!)) &&
            (_endDate == null || user.joinDate.isBefore(_endDate!));

        return matchSearch && matchStatus && matchDate;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
      _startDate = null;
      _endDate = null;
      _filteredUsers = List.from(_users);
    });
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addUser),
        content: UserForm(
          countries: _countries,
          onSave: _addUser,
        ),
      ),
    );
  }

  void _addUser(User newUser) {
    setState(() {
      _users.add(newUser);
      _filterUsers();
    });
    Navigator.pop(context);
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildHeader(l10n),
            const SizedBox(height: 16),
            UserFilters(
              searchController: _searchController,
              selectedStatus: _selectedStatus,
              startDate: _startDate,
              endDate: _endDate,
              onStatusChanged: (status) {
                setState(() {
                  _selectedStatus = status;
                  _filterUsers();
                });
              },
              onStartDateChanged: (date) {
                setState(() {
                  _startDate = date;
                  _filterUsers();
                });
              },
              onEndDateChanged: (date) {
                setState(() {
                  _endDate = date;
                  _filterUsers();
                });
              },
              onReset: _resetFilters,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildUsersTable(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.usersManagement,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        ElevatedButton.icon(
          onPressed: _showAddUserDialog,
          icon: const Icon(Icons.add),
          label: Text(l10n.addUser),
        ),
      ],
    );
  }

  Widget _buildUsersTable() {
    if (_filteredUsers.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noUsersFound,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: _buildDataColumns(),
          rows: _filteredUsers.map(_buildDataRow).toList(),
        ),
      ),
    );
  }

  List<DataColumn> _buildDataColumns() {
    final l10n = AppLocalizations.of(context)!;
    return [
      const DataColumn(label: Text('Avatar')),
      DataColumn(label: Text(l10n.name)),
      DataColumn(label: Text(l10n.email)),
      DataColumn(label: Text(l10n.phone)),
      DataColumn(label: Text(l10n.country)),
      DataColumn(label: Text(l10n.joinDate)),
      DataColumn(label: Text(l10n.subscriptionStart)),
      DataColumn(label: Text(l10n.subscriptionEnd)),
      DataColumn(label: Text(l10n.status)),
      DataColumn(label: Text(l10n.actions)),
    ];
  }

  DataRow _buildDataRow(User user) {
    return DataRow(
      cells: [
        DataCell(
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[200],
            backgroundImage: user.profileImage != null
                ? NetworkImage(user.profileImage!)
                : null,
            child: user.profileImage == null
                ? const Icon(Icons.person, size: 16)
                : null,
          ),
        ),
        DataCell(Text(user.name)),
        DataCell(Text(user.email)),
        DataCell(Text(user.phone)),
        DataCell(Text(user.country)),
        DataCell(Text(formatDate(user.joinDate))),
        DataCell(Text(formatDate(user.subscriptionStart))),
        DataCell(Text(formatDate(user.subscriptionEnd))),
        DataCell(UserStatusChip(status: user.status)),
        DataCell(UserActions(
          user: user,
          onEdit: () => _editUser(user.id),
          onFinance: () => _showTransactions(user),
          onManageProfiles: () => _manageLinkedProfiles(user),
        )),
      ],
    );
  }

  void _editUser(int userId) {
    final user = _users.firstWhere((u) => u.id == userId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.editUser),
        content: UserForm(
          user: user,
          countries: _countries,
          onSave: (updatedUser) => _updateUser(updatedUser),
        ),
      ),
    );
  }

  void _updateUser(User updatedUser) {
    setState(() {
      final index = _users.indexWhere((u) => u.id == updatedUser.id);
      if (index != -1) {
        _users[index] = updatedUser;
        _filterUsers();
      }
    });
    Navigator.pop(context);
  }

  void _showTransactions(User user) {
    showDialog(
      context: context,
      builder: (context) =>
          UserTransactionsWidget(transactions: user.transactions),
    );
  }

  void _manageLinkedProfiles(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Profils liés - ${user.name}'),
        content: LinkedProfilesWidget(
          profiles: user.linkedProfiles,
          onAddProfile: (profile) => _addLinkedProfile(user, profile),
          onRemoveProfile: (profileId) => _removeLinkedProfile(user, profileId),
        ),
      ),
    );
  }

  void _addLinkedProfile(User user, LinkedProfile profile) {
    setState(() {
      user.linkedProfiles.add(profile);
    });
  }

  void _removeLinkedProfile(User user, String profileId) {
    setState(() {
      user.linkedProfiles.removeWhere((p) => p.id == profileId);
    });
  }
}
