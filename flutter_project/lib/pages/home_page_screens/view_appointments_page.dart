import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/foundation.dart';
import '../../services/api_service.dart';
import '../../widgets/gradient_app_bar.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({Key? key}) : super(key: key);
  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Map<String, dynamic>> confirmedAppointments = [];
  List<Map<String, dynamic>> pendingAppointments = [];
  List<Map<String, dynamic>> declinedAppointments = [];
  bool isLoading = true;
  bool refreshing = false;

  // Unified palette
  final Color primaryBlue = const Color(0xFF1E88E5);
  final Color accentGreen = const Color(0xFF2EAD6D);
  final Color softBg = const Color(0xFFF8FAFE);

  @override
  void initState() { super.initState(); _fetchAppointments(); }

  Future<void> _fetchAppointments() async {
    if (!mounted) return; setState(() { isLoading = true; });
    debugPrint('Fetching pending appointments...');
    try {
      final pending = await ApiService.getPendingAppointments();
      debugPrint('Pending appointments fetched: ${pending.length}');
      List<Map<String, dynamic>> updatedPending = [];
      for (var appt in pending) {
        if (appt['proposed_slot'] == null) {
          final slotResult = await ApiService.assignSlot(appt['id']);
          if (slotResult != null && slotResult['proposed_slot'] != null) {
            appt['proposed_slot'] = slotResult['proposed_slot'];
          }
        }
        updatedPending.add(appt);
      }
      final filteredPending = updatedPending.where((a) => a['proposed_slot'] != null && a['proposed_slot'].toString().isNotEmpty).toList();
      final confirmed = await ApiService.getConfirmedAppointments();
      if (!mounted) return;
      setState(() {
        pendingAppointments = filteredPending;
        confirmedAppointments = confirmed;
        isLoading = false; refreshing = false;
      });
    } catch (e) {
      debugPrint('Error in _fetchAppointments: $e');
      if (mounted) setState(() { isLoading = false; refreshing = false; });
    }
  }

  Future<void> _refresh() async {
    setState(() { refreshing = true; });
    await _fetchAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      appBar: buildGradientAppBar(
        title: 'Appointments',
        actionIcon: Icons.refresh,
        onAction: refreshing ? null : _refresh,
      ),
      body: isLoading ? _loading() : _content(),
    );
  }

  Widget _loading() => const Center(child: CircularProgressIndicator());

  Widget _content() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _calendarCard(),
          const SizedBox(height: 12),
          _sectionHeader('Confirmed Appointments', icon: Icons.check_circle, color: accentGreen),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: _appointmentsList(confirmedAppointments, confirmed: true),
          ),
          const SizedBox(height: 24),
          _sectionHeader('Pending Confirmations', icon: Icons.hourglass_bottom, color: Colors.orange),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: _appointmentsList(pendingAppointments, confirmed: false),
          ),
        ],
      ),
    );
  }

  Widget _calendarCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: primaryBlue.withAlpha(40)),
          boxShadow: [BoxShadow(color: primaryBlue.withAlpha(25), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; });
          },
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: primaryBlue.darken(.1)),
            leftChevronIcon: Icon(Icons.chevron_left, color: primaryBlue.darken(.05)),
            rightChevronIcon: Icon(Icons.chevron_right, color: primaryBlue.darken(.05)),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade600),
            weekendStyle: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade600),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            defaultTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            weekendTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            selectedDecoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryBlue, accentGreen]),
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              border: Border.all(color: primaryBlue, width: 2),
              shape: BoxShape.circle,
            ),
          ),
          availableGestures: AvailableGestures.all,
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              if (isSameDay(day, DateTime.now())) return null; // let today builder handle it
              final statusColor = _dayStatusColor(day);
              if (statusColor != null) {
                return Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(70),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withAlpha(160), width: 1),
                  ),
                  child: Center(child: Text('${day.day}', style: TextStyle(fontWeight: FontWeight.w700, color: statusColor.darken(.5)))),
                );
              }
              return null;
            },
            todayBuilder: (context, day, focusedDay) => Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: primaryBlue, width: 2),
                shape: BoxShape.circle,
              ),
              child: Center(child: Text('${day.day}', style: TextStyle(fontWeight: FontWeight.w700, color: primaryBlue.darken(.1)))),
            ),
          ),
        ),
      ),
    );
  }

  Color? _dayStatusColor(DateTime day) {
    bool declined = declinedAppointments.any((a) => _isSameDayAsSlot(day, a['proposed_slot']));
    bool confirmed = confirmedAppointments.any((a) => _isSameDayAsSlot(day, a['proposed_slot']));
    bool pending = pendingAppointments.any((a) => _isSameDayAsSlot(day, a['proposed_slot']));
    if (declined) return Colors.redAccent;
    if (confirmed) return accentGreen;
    if (pending) return Colors.orange;
    return null;
  }

  Widget _sectionHeader(String title, {required IconData icon, required Color color}) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withAlpha(40), color.withAlpha(15)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(120)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withAlpha(45)),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: color.darken(.2), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: .3, color: color.darken(.3)))),
        ],
      ),
    ),
  );

  Widget _appointmentsList(List<Map<String, dynamic>> data, {required bool confirmed}) {
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryBlue.withAlpha(35)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: primaryBlue.withAlpha(160)),
            const SizedBox(width: 10),
            Expanded(child: Text('No ${confirmed ? 'confirmed' : 'pending'} appointments.', style: TextStyle(fontSize: 13.5, color: Colors.blueGrey.shade700, height: 1.3))),
          ],
        ),
      );
    }
    return Column(
      children: data.map((appt) => _appointmentCard(appt, confirmed: confirmed)).toList(),
    );
  }

  Widget _appointmentCard(Map<String, dynamic> appt, {required bool confirmed}) {
    final slot = appt['proposed_slot'] ?? '';
    final dateStr = slot.isNotEmpty ? slot.split('T')[0] : '';
    final id = appt['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: confirmed ? accentGreen.withAlpha(120) : primaryBlue.withAlpha(55), width: 1.4),
        boxShadow: [
          BoxShadow(color: primaryBlue.withAlpha(25), blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: confirmed ? [accentGreen, primaryBlue] : [primaryBlue, Colors.orange]),
              ),
              child: Icon(confirmed ? Icons.check : Icons.schedule, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appt['type'] ?? 'Appointment', style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, letterSpacing: .2)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _infoChip(icon: Icons.event, label: dateStr.isEmpty ? 'Date TBD' : dateStr),
                      if (!confirmed) _statusChip(label: 'Pending', color: Colors.orange),
                      if (confirmed) _statusChip(label: 'Confirmed', color: accentGreen),
                      if (appt['proposed_slot'] == null || appt['proposed_slot'].toString().isEmpty)
                        _statusChip(label: 'No slot', color: Colors.redAccent),
                    ],
                  )
                ],
              ),
            ),
            if (!confirmed) ...[
              const SizedBox(width: 8),
              Column(
                children: [
                  _iconBtn(
                    icon: Icons.close, color: Colors.redAccent,
                    onTap: () async { final success = await ApiService.declineAppointment(id); if (success) { setState(() { pendingAppointments.remove(appt); declinedAppointments.add(appt); }); } },
                  ),
                  const SizedBox(height: 10),
                  _iconBtn(
                    icon: Icons.check, color: accentGreen,
                    onTap: () async { final success = await ApiService.confirmAppointment(id); if (success) { setState(() { pendingAppointments.remove(appt); }); final conf = await ApiService.getConfirmedAppointments(); setState(() { confirmedAppointments = conf; }); } },
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _iconBtn({required IconData icon, required Color color, required VoidCallback onTap}) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withAlpha(28),
        border: Border.all(color: color.withAlpha(140)),
      ),
      padding: const EdgeInsets.all(8),
      child: Icon(icon, size: 18, color: color.darken(.1)),
    ),
  );

  Widget _infoChip({required IconData icon, required String label}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: primaryBlue.withAlpha(25),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: primaryBlue.withAlpha(120)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: primaryBlue.darken(.15)), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: primaryBlue.darken(.2)))]),
  );

  Widget _statusChip({required String label, required Color color}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withAlpha(35),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: color.withAlpha(160)),
    ),
    child: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: .4, color: color.darken(.25))),
  );

  bool _isSameDayAsSlot(DateTime day, String? slot) {
    if (slot == null || slot.isEmpty) return false;
    try { final slotDate = DateTime.parse(slot); return day.year == slotDate.year && day.month == slotDate.month && day.day == slotDate.day; } catch (_) { return false; }
  }
}

extension _ColorShadeX on Color { Color darken([double amount = .15]) { final hsl = HSLColor.fromColor(this); return hsl.withLightness((hsl.lightness-amount).clamp(0,1)).toColor(); } }
