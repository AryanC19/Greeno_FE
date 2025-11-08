import 'package:flutter/material.dart';
import '../../widgets/gradient_app_bar.dart';

class AppointmentsConfirmationPage extends StatefulWidget {
  const AppointmentsConfirmationPage({super.key});

  @override
  State<AppointmentsConfirmationPage> createState() => _AppointmentsConfirmationPageState();
}

class _AppointmentsConfirmationPageState extends State<AppointmentsConfirmationPage> {
  // Mock slots for now (replace with backend data later)
  List<String> slots = ["Tue 10:00 AM", "Wed 03:00 PM", "Fri 01:00 PM", "Mon 09:30 AM", "Thu 05:15 PM"];
  String? booked;
  String? selected;
  bool confirming = false;

  // Unified palette
  final Color primaryBlue = const Color(0xFF1E88E5);
  final Color accentGreen = const Color(0xFF2EAD6D);
  final Color softBg = const Color(0xFFF8FAFE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      appBar: buildGradientAppBar(
        title: 'Confirm Appointment',
        actionIcon: Icons.calendar_today_outlined,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: _header(),
          ),
          Expanded(
            child: slots.isEmpty ? _emptyState() : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
              itemCount: slots.length,
              itemBuilder: (c, i) => _slotCard(slots[i]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _header() => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: LinearGradient(colors: [primaryBlue.withAlpha(30), accentGreen.withAlpha(28)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      border: Border.all(color: primaryBlue.withAlpha(90)),
    ),
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [primaryBlue, accentGreen]),
          ),
          child: const Icon(Icons.event_available, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booked != null ? 'Appointment booked' : 'Pick a slot to confirm',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: .2),
              ),
              const SizedBox(height: 6),
              Text(
                booked != null
                    ? 'You have confirmed $booked. You can leave this page.'
                    : 'Select one of the suggested slots below that fits your schedule.',
                style: TextStyle(fontSize: 13.5, height: 1.33, color: Colors.blueGrey.shade800),
              ),
            ],
          ),
        )
      ],
    ),
  );

  Widget _slotCard(String slot) {
    final bool isSelected = selected == slot;
    final bool isBooked = booked == slot;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isBooked ? 0.75 : 1,
      child: InkWell(
        onTap: booked != null || isBooked ? null : () => setState(() => selected = slot),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            border: Border.all(
              color: isBooked
                  ? accentGreen.withAlpha(200)
                  : isSelected
                      ? primaryBlue.withAlpha(160)
                      : primaryBlue.withAlpha(50),
              width: isSelected || isBooked ? 2 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withAlpha(28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [primaryBlue, accentGreen]),
                ),
                child: Icon(
                  isBooked ? Icons.check_circle : (isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(slot, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, letterSpacing: .2)),
                    const SizedBox(height: 4),
                    Text(
                      isBooked
                          ? 'Confirmed'
                          : isSelected
                              ? 'Selected'
                              : 'Tap to select',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isBooked
                            ? accentGreen.darken(.15)
                            : isSelected
                                ? primaryBlue.darken(.15)
                                : Colors.blueGrey.shade500,
                        letterSpacing: .3,
                      ),
                    ),
                  ],
                ),
              ),
              if (isBooked)
                _statusBadge('BOOKED', accentGreen)
              else if (isSelected)
                _statusBadge('READY', primaryBlue)
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(32),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withAlpha(160)),
        ),
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .6, color: color.darken(.2))),
      );

  Widget _bottomBar() {
    final bool canConfirm = selected != null && booked == null && !confirming;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 18, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _legendSwatch(primaryBlue, 'Selected'),
                const SizedBox(width: 14),
                _legendSwatch(accentGreen, 'Booked'),
                const SizedBox(width: 14),
                _legendSwatch(Colors.blueGrey.shade500, 'Available'),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canConfirm ? _confirm : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  backgroundColor: booked != null ? accentGreen : primaryBlue,
                  elevation: 3,
                ),
                child: confirming
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        booked != null
                            ? 'Done'
                            : selected == null
                                ? 'Select a slot'
                                : 'Confirm Slot',
                        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, letterSpacing: .3, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendSwatch(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color.withAlpha(60),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withAlpha(180)),
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11.5, color: Colors.blueGrey.shade600, fontWeight: FontWeight.w500)),
        ],
      );

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: primaryBlue.withAlpha(160)),
            const SizedBox(height: 14),
            Text('No slots available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade800)),
            const SizedBox(height: 8),
            Text('Your provider has not released new appointment slots yet.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, color: Colors.blueGrey.shade600)),
          ],
        ),
      );

  Future<void> _confirm() async {
    if (selected == null) return; setState(() { confirming = true; });
    await Future.delayed(const Duration(milliseconds: 850)); // mock delay
    setState(() { booked = selected; confirming = false; });
  }
}

extension _ColorShadeX on Color { Color darken([double amount = .15]) { final hsl = HSLColor.fromColor(this); return hsl.withLightness((hsl.lightness - amount).clamp(0,1)).toColor(); } }
