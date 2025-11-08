import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../../services/api_service.dart';
import '../../widgets/gradient_app_bar.dart';

class MedicationReminderPage extends StatefulWidget {
  const MedicationReminderPage({super.key});
  @override
  State<MedicationReminderPage> createState() => _MedicationReminderPageState();
}

class _MedicationReminderPageState extends State<MedicationReminderPage> {
  Map<String, dynamic>? reminders;
  bool isLoading = true;
  bool hasError = false;

  final Map<String, bool?> takenStatus = {};
  final List<String> _slots = ["morning", "afternoon", "evening", "night"];
  final Map<String, String?> _slotTimes = {
    "morning": null,
    "afternoon": null,
    "evening": null,
    "night": null,
  };
  final Map<String, bool> _slotEnabled = {
    "morning": false,
    "afternoon": false,
    "evening": false,
    "night": false,
  };
  final Map<String, IconData> _slotIcons = {
    "morning": Icons.wb_sunny_outlined,
    "afternoon": Icons.cloud_outlined,
    "evening": Icons.nightlight_round,
    "night": Icons.bedtime,
  };

  // Color-coded slot themes
  final Map<String, Color> _slotBaseColors = {
    'morning': Colors.amber,
    'afternoon': Colors.deepOrange,
    'evening': Colors.indigo,
    'night': Colors.blueGrey,
  };

  final Color primaryBlue = const Color(0xFF1E88E5);
  final Color accentGreen = const Color(0xFF2EAD6D);
  final Color softBg = const Color(0xFFF8FAFE);

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { isLoading = true; hasError = false; });
    await Future.wait([
      fetchMedications(),
      fetchReminderSlots(),
    ]);
    setState(() { isLoading = false; });
  }

  Future<void> fetchReminderSlots() async {
    try {
      final resp = await ApiService.getReminderSlots();
      if (resp != null && resp.containsKey('reminder_slots')) {
        final data = Map<String, dynamic>.from(resp['reminder_slots']);
        for (final slot in _slots) {
          final slotData = data[slot] as Map<String, dynamic>?;
          final time = slotData?['time'] as String?;
          if (time != null) {
            _slotTimes[slot] = time; _slotEnabled[slot] = true; _scheduleNotificationForSlot(slot, time, _medicationsText(slot), silent: true);
          } else {
            final defaultTime = _defaultTime(slot); _slotTimes[slot] = defaultTime; _slotEnabled[slot] = true; _scheduleNotificationForSlot(slot, defaultTime, _medicationsText(slot), silent: true);
          }
        }
      } else {
        for (final slot in _slots) { final dt = _defaultTime(slot); _slotTimes[slot]=dt; _slotEnabled[slot]=true; _scheduleNotificationForSlot(slot, dt, _medicationsText(slot), silent: true);} }
    } catch (_) {
      for (final slot in _slots) { final dt = _defaultTime(slot); _slotTimes[slot]=dt; _slotEnabled[slot]=true; _scheduleNotificationForSlot(slot, dt, _medicationsText(slot), silent: true);} }
  }

  String _defaultTime(String slot){
    switch(slot){
      case 'morning': return '08:00';
      case 'afternoon': return '13:00';
      case 'evening': return '18:00';
      case 'night': return '21:00';
      default: return '08:00';
    }
  }

  Future<void> fetchMedications() async {
    try {
      final resp = await ApiService.getMedications();
      if (resp != null && resp.containsKey('medications')) {
        final medsMap = Map<String, dynamic>.from(resp['medications']);
        takenStatus.clear();
        for (final slot in _slots) {
          for (final med in medsMap[slot] ?? []) {
            final id = med['id'] ?? ''; final taken = med['taken']; takenStatus['${id}_$slot'] = taken;
          }
        }
        setState(() { reminders = medsMap; hasError = false; });
      } else { setState(() { hasError = true; }); }
    } catch (e) { setState(() { hasError = true; }); }
  }

  String _medicationsText(String slot) {
    if (reminders == null) return ''; final list = List.from(reminders?[slot] ?? []);
    return list.map((e) => e['medication'] ?? '').where((s) => (s as String).isNotEmpty).join(', ');
  }

  Future<void> _pickTime(String slot) async {
    final existing = _slotTimes[slot];
    TimeOfDay initial = const TimeOfDay(hour: 8, minute: 0);
    if (existing != null && existing.contains(':')) {
      final parts = existing.split(':'); initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])); }
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final formatted = '${picked.hour.toString().padLeft(2,'0')}:${picked.minute.toString().padLeft(2,'0')}';
      setState(() { _slotTimes[slot] = formatted; });
      final ok = await ApiService.updateReminderSlotTime(slot, formatted);
      if (!ok) { if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save time to server'))); } }
      else { _scheduleNotificationForSlot(slot, formatted, _medicationsText(slot), fromUserPick: true, silent: false); }
    }
  }

  Future<void> _ensurePermission() async { final allowed = await AwesomeNotifications().isNotificationAllowed(); if (!allowed) { await AwesomeNotifications().requestPermissionToSendNotifications(); } }
  int _idForSlot(String slot) => slot.hashCode & 0x7fffffff;

  Future<void> _scheduleNotificationForSlot(String slot, String time, String medsText, {bool fromUserPick = false, bool silent = false}) async {
    if (time.isEmpty) return; await _ensurePermission(); final parts = time.split(':'); if (parts.length != 2) return; final hour = int.tryParse(parts[0]); final minute = int.tryParse(parts[1]); if (hour == null || minute == null) return;
    if (mounted) { setState(() { _slotEnabled[slot] = true; }); }
    final baseId = _idForSlot(slot); await AwesomeNotifications().cancel(baseId); await AwesomeNotifications().cancel(baseId + 999);
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: baseId,
        channelKey: 'med_reminders',
        title: '${slot[0].toUpperCase()+slot.substring(1)} Reminder',
        body: medsText.isEmpty ? 'Time to check your medications' : 'Take: $medsText',
        category: NotificationCategory.Reminder,
        wakeUpScreen: true,
        criticalAlert: true,
        displayOnForeground: true,
        displayOnBackground: true,
        autoDismissible: false,
        locked: true,
      ),
      schedule: NotificationCalendar(hour: hour, minute: minute, second: 0, millisecond: 0, repeats: true, allowWhileIdle: true, preciseAlarm: true),
    );
    final now = DateTime.now(); final nowPassedTargetMinute = (now.hour == hour && now.minute == minute && now.second > 5) || (now.hour == hour && now.minute > minute) || (now.hour > hour);
    if (fromUserPick && now.hour == hour && now.minute == minute && now.second > 5) {
      final fireSecond = (now.second + 5) % 60;
      await AwesomeNotifications().createNotification(
        content: NotificationContent(id: baseId + 999, channelKey: 'med_reminders', title: '${slot[0].toUpperCase()+slot.substring(1)} Reminder (Now)', body: medsText.isEmpty ? 'Check medications now' : 'Take: $medsText', category: NotificationCategory.Reminder, wakeUpScreen: true, criticalAlert: true, displayOnForeground: true, displayOnBackground: true, autoDismissible: false, locked: true),
        schedule: NotificationCalendar(year: now.year, month: now.month, day: now.day, hour: now.hour, minute: now.minute, second: fireSecond, allowWhileIdle: true, preciseAlarm: true, repeats: false),
      );
    } else if (fromUserPick && nowPassedTargetMinute) {
      final immediate = now.add(const Duration(seconds: 7));
      await AwesomeNotifications().createNotification(
        content: NotificationContent(id: baseId + 999, channelKey: 'med_reminders', title: '${slot[0].toUpperCase()+slot.substring(1)} Reminder (Soon)', body: medsText.isEmpty ? 'Upcoming medication' : 'Take now: $medsText', category: NotificationCategory.Reminder, wakeUpScreen: true, criticalAlert: true, displayOnForeground: true, displayOnBackground: true, autoDismissible: false, locked: true),
        schedule: NotificationCalendar(year: immediate.year, month: immediate.month, day: immediate.day, hour: immediate.hour, minute: immediate.minute, second: immediate.second, allowWhileIdle: true, preciseAlarm: true, repeats: false),
      );
    }
    if (fromUserPick && !silent && mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reminder set for ${hour.toString().padLeft(2,'0')}:${minute.toString().padLeft(2,'0')}'))); }
  }

  Future<void> _cancelSlot(String slot) async { await AwesomeNotifications().cancel(_idForSlot(slot)); await AwesomeNotifications().cancel(_idForSlot(slot)+999); if (mounted) { setState(() { _slotEnabled[slot] = false; }); } }
  void _toggleSlot(String slot, bool value) { final time = _slotTimes[slot]; if (value) { if (time == null) { _pickTime(slot); } else { _scheduleNotificationForSlot(slot, time, _medicationsText(slot), fromUserPick: false, silent: true);} } else { _cancelSlot(slot);} }

  Future<void> _triggerTestNotification() async {
    await _ensurePermission();

    // Create a test notification
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 99999, // Use a unique ID for test notifications
        channelKey: 'med_reminders',
        title: '🩺 Care Plan Update',
        body: '📋 You have received a careplan! 👩‍⚕️ Click to view 📱',
        category: NotificationCategory.Reminder,
        wakeUpScreen: true,
        criticalAlert: true,
        displayOnForeground: true,
        displayOnBackground: true,
        autoDismissible: false,
        locked: true,
        customSound: null,
      ),
    );

    // Show a snackbar to confirm the notification was sent
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📋 Care plan notification sent!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      appBar: buildGradientAppBar(
        title: 'Medication Reminders',
        actionIcon: Icons.medical_services_outlined,
        extraActions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_active,
                color: Colors.white,
                size: 24,
              ),
              tooltip: 'Test Notification',
              onPressed: _triggerTestNotification,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5)))
          : hasError
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 70),
          const SizedBox(height: 16),
          const Text('Error loading reminders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          for (final slot in _slots) _buildSection(_titleFor(slot), reminders?[slot] ?? [], slot),
        ],
      ),
    );
  }

  String _titleFor(String slot) => {
    'morning':'Morning', 'afternoon':'Afternoon', 'evening':'Evening', 'night':'Night'
  }[slot] ?? slot;

  Widget _buildSection(String title, List meds, String slot) {
    final time = _slotTimes[slot];
    final enabled = _slotEnabled[slot] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _slotHeader(slot: slot, title: title, time: time, enabled: enabled),
          const SizedBox(height: 14),
          if (meds.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueGrey.withAlpha(60)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.blueGrey.shade600),
                  const SizedBox(width: 10),
                  Expanded(child: Text('No medications in this slot.', style: TextStyle(fontSize: 13.5, color: Colors.blueGrey.shade700))),
                ],
              ),
            )
          else ...[
            for (final med in meds) _medCard(med, slot),
          ],
        ],
      ),
    );
  }

  Widget _slotHeader({required String slot, required String title, required String? time, required bool enabled}) {
    final base = _slotBaseColors[slot] ?? primaryBlue;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: base.withAlpha(35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: base.withAlpha(120), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: base.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: Icon, Title, Switch
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [base, base.darken(.15)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: base.withAlpha(60),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(_slotIcons[slot], color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: base.darken(.35),
                    letterSpacing: .4,
                  ),
                ),
              ),
              Transform.scale(
                scale: 1.1,
                child: Switch(
                  value: enabled,
                  thumbColor: WidgetStateProperty.all(Colors.white),
                  activeTrackColor: base.darken(.05),
                  inactiveTrackColor: Colors.grey.withAlpha(140),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (v) => _toggleSlot(slot, v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bottom row: Time and Edit button together
          Row(
            children: [
              // Time display - larger and more prominent
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: (time == null ? Colors.redAccent : base).withAlpha(45),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (time == null ? Colors.redAccent : base).withAlpha(180),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 20,
                        color: time == null ? Colors.redAccent.darken(.2) : base.darken(.4),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time ?? 'Not set',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: time == null ? Colors.redAccent.darken(.2) : base.darken(.4),
                          letterSpacing: .5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Edit button - close to time
              Container(
                decoration: BoxDecoration(
                  color: base.withAlpha(50),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: base.withAlpha(150), width: 1.2),
                ),
                child: IconButton(
                  tooltip: 'Edit time',
                  icon: Icon(Icons.edit, color: base.darken(.3), size: 24),
                  onPressed: () => _pickTime(slot),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _medCard(Map<String, dynamic> med, String slot) {
    final id = med['id'] ?? '';
    final key = '${id}_$slot';
    final status = takenStatus[key];
    Color borderColor;
    if (status == true) borderColor = accentGreen.withAlpha(200);
    else if (status == false) borderColor = Colors.redAccent.withAlpha(180);
    else borderColor = Colors.blueGrey.withAlpha(80);

    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Reduced margin
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Smaller radius
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 6, offset: const Offset(0, 2))], // Smaller shadow
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 28, height: 28, // Smaller medication icon
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [primaryBlue, accentGreen]),
                ),
                child: const Icon(Icons.medication, color: Colors.white, size: 16), // Smaller icon
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        med['medication'] ?? '',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: .2), // Smaller text
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if ((med['dose'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _dosePill(med['dose']),
                    ]
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10), // Reduced spacing
          Row(
            children: [
              Expanded(
                child: _takeBtn(
                  label: 'Taken',
                  selected: status == true,
                  color: accentGreen,
                  onTap: status == true ? null : () async {
                    setState(() => takenStatus[key] = true);
                    final ok = await ApiService.markMedicationScheduleTaken(id, slot);
                    if (!ok) setState(() => takenStatus[key] = status);
                  },
                ),
              ),
              const SizedBox(width: 8), // Reduced spacing
              Expanded(
                child: _takeBtn(
                  label: 'Not Taken',
                  selected: status == false,
                  color: Colors.redAccent,
                  onTap: status == false ? null : () async {
                    setState(() => takenStatus[key] = false);
                    final ok = await ApiService.markMedicationScheduleNotTaken(id, slot);
                    if (!ok) setState(() => takenStatus[key] = status);
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _dosePill(String? dose) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // Smaller padding
    decoration: BoxDecoration(
      color: primaryBlue.withAlpha(32),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: primaryBlue.withAlpha(140)),
    ),
    child: Text(dose ?? '', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: primaryBlue.darken(.2))), // Smaller text
  );

  Widget _takeBtn({required String label, required bool selected, required Color color, VoidCallback? onTap}) => AnimatedOpacity(
    duration: const Duration(milliseconds: 250),
    opacity: onTap == null ? 0.75 : 1,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12), // Smaller radius
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // Smaller padding
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12), // Smaller radius
          color: selected ? color.withAlpha(50) : Colors.white,
          border: Border.all(color: selected ? color.withAlpha(200) : color.withAlpha(120), width: 1.2),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color.darken(.2))), // Smaller text
      ),
    ),
  );
}

extension _ColorShadeX on Color {
  Color darken([double amount = .15]) { final hsl = HSLColor.fromColor(this); return hsl.withLightness((hsl.lightness - amount).clamp(0, 1)).toColor(); }
}
