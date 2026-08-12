import 'package:flutter/material.dart';
import 'package:plateforme_administrateur/ui/producers_dashboard/users/models/user_model.dart';
import 'package:plateforme_administrateur/gen/app_localizations.dart';

class UserFilters extends StatefulWidget {
  final TextEditingController searchController;
  final UserStatus? selectedStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(UserStatus?) onStatusChanged;
  final Function(DateTime?) onStartDateChanged;
  final Function(DateTime?) onEndDateChanged;
  final VoidCallback onReset;

  const UserFilters({
    super.key,
    required this.searchController,
    required this.selectedStatus,
    required this.startDate,
    required this.endDate,
    required this.onStatusChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onReset,
  });

  @override
  State<UserFilters> createState() => _UserFiltersState();
}

class _UserFiltersState extends State<UserFilters> {
  Future<void> _pickDate({
    required DateTime? initialDate,
    required Function(DateTime?) onDatePicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onDatePicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // 🔎 Recherche
            SizedBox(
              width: 220,
              child: TextField(
                controller: widget.searchController,
                decoration: InputDecoration(
                  labelText: l10n.searchUsers,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            // 📌 Statut
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<UserStatus>(
                value: widget.selectedStatus,
                decoration: InputDecoration(
                  labelText: "Statut",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: UserStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.toString().split('.').last),
                  );
                }).toList(),
                onChanged: widget.onStatusChanged,
              ),
            ),

            // 📅 Date début
            SizedBox(
              width: 150,
              child: ElevatedButton.icon(
                onPressed: () => _pickDate(
                  initialDate: widget.startDate,
                  onDatePicked: widget.onStartDateChanged,
                ),
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(
                  widget.startDate == null
                      ? "Date début"
                      : "${widget.startDate!.day}/${widget.startDate!.month}/${widget.startDate!.year}",
                ),
              ),
            ),

            // 📅 Date fin
            SizedBox(
              width: 150,
              child: ElevatedButton.icon(
                onPressed: () => _pickDate(
                  initialDate: widget.endDate,
                  onDatePicked: widget.onEndDateChanged,
                ),
                icon: const Icon(Icons.event, size: 18),
                label: Text(
                  widget.endDate == null
                      ? "Date fin"
                      : "${widget.endDate!.day}/${widget.endDate!.month}/${widget.endDate!.year}",
                ),
              ),
            ),

            // 🔄 Reset
            ElevatedButton.icon(
              onPressed: widget.onReset,
              icon: const Icon(Icons.refresh),
              label: const Text("Réinitialiser"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
