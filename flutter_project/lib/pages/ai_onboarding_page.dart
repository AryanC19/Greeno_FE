import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/diet_provider.dart';
import 'home_page.dart';

class OnboardingStep {
  final IconData icon;
  final String question;
  final Future<void> Function()? onAccept;
  final String imagePath;
  OnboardingStep({required this.icon, required this.question, required this.imagePath, this.onAccept});
}

class AIOnboardingPage extends StatefulWidget {
  const AIOnboardingPage({super.key});
  @override
  State<AIOnboardingPage> createState() => _AIOnboardingPageState();
}

class _AIOnboardingPageState extends State<AIOnboardingPage> {
  int current = 0;
  bool busy = false;
  final List<bool?> decisions = [null, null, null];
  String statusMsg = '';

  // Theme palette
  final Color primaryBlue = const Color(0xFF1E88E5);
  final Color accentGreen = const Color(0xFF2EAD6D);
  final Color softBg = const Color(0xFFF4F8FC);

  late final List<OnboardingStep> steps = [
    OnboardingStep(
      icon: Icons.medication_outlined,
      question: "I can see that medications are prescribed. Would you like me to set up smart reminders for them?",
      imagePath: 'assets/images/greeno1.png',
      onAccept: () async {
        await ApiService.getMedications();
        statusMsg = "Medication data cached.";
      },
    ),
    OnboardingStep(
      icon: Icons.calendar_today_outlined,
      question: "There are pending appointments. Should I look for suitable doctor slots for you automatically?",
      imagePath: 'assets/images/greeno2.png',
      onAccept: () async {
        final pending = await ApiService.getPendingAppointments();
        int assigned = 0;
        for (final appt in pending) {
          final id = appt['id'];
          if (id != null) {
            final r = await ApiService.assignSlot(id);
            if (r != null) assigned++;
          }
        }
        statusMsg = "Updated $assigned appointment slots.";
      },
    ),
    OnboardingStep(
      icon: Icons.fitness_center,
      question: "Would you like me to fetch a personalized diet & exercise plan for you now?",
      imagePath: 'assets/images/greeno3.png',
      onAccept: () async {
        // Diet & exercise API is already running in background from app start
        statusMsg = "Plan is being prepared in background.";
      },
    ),
  ];

  void _handleDecision(bool accepted) async {
    if (busy) return;
    setState(() { busy = true; decisions[current] = accepted; statusMsg = ''; });
    if (accepted && steps[current].onAccept != null) {
      try {
        await steps[current].onAccept!();
      } catch (e) {
        statusMsg = 'Action failed.';
      }
    }
    setState(() { busy = false; });
    if (current < steps.length - 1) {
      setState(() { current++; });
    } else {
      // Finished last decision -> navigate immediately without waiting
      _finish();
    }
  }

  void _finish() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    final progress = (current + 1) / steps.length;

    return Scaffold(
      backgroundColor: softBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(progress),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  switchInCurve: Curves.easeOutQuart,
                  switchOutCurve: Curves.easeInQuart,
                  transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                  child: _buildStepCard(steps[current], current + 1, steps.length, key: ValueKey(current)),
                ),
              ),
            ),
            if (statusMsg.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 24, right: 24),
                child: Text(statusMsg, style: TextStyle(fontSize: 12, color: accentGreen, fontWeight: FontWeight.w500)),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [primaryBlue, accentGreen]),
                ),
                padding: const EdgeInsets.all(3),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/greeno.png',
                      width: 100,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.android, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hi, I'm Greeno",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryBlue, height: 1.1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your AI care assistant. I\'ll help optimize your plan.',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.25),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 22),
          // Gradient progress container wrapper
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(colors: [primaryBlue.withValues(alpha: .15), accentGreen.withValues(alpha: .15)]),
            ),
            padding: const EdgeInsets.all(2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.lerp(primaryBlue, accentGreen, 0.4) ?? primaryBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(OnboardingStep step, int index, int total, {Key? key}) {
    final acceptBusy = busy && decisions[current] == true;
    final declineBusy = busy && decisions[current] == false;

    return Card(
      key: key,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      shadowColor: primaryBlue.withValues(alpha: .18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // Large Greeno image anchored bottom-left
            Positioned(
              left: -30,
              bottom: -20,
              child: IgnorePointer(
                child: AnimatedScale(
                  scale: 1,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  child: Image.asset(
                    step.imagePath,
                    width: 400, // Even bigger Greeno
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            // Content overlay
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 28, 26, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STEP $index OF $total', style: TextStyle(letterSpacing: 1, fontSize: 16, fontWeight: FontWeight.w600, color: primaryBlue.withValues(alpha: .75))),
                  const SizedBox(height: 18),
                  // Question bubble style
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: softBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: primaryBlue.withValues(alpha: .08)),
                    ),
                    child: Text(
                      step.question,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.35),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: _DeclineButton(
                          busy: declineBusy,
                          onPressed: busy ? null : () => _handleDecision(false),
                          color: Colors.red.shade600,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _AcceptButton(
                          busy: acceptBusy,
                          onPressed: busy ? null : () => _handleDecision(true),
                          gradient: LinearGradient(colors: [accentGreen, primaryBlue]),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AcceptButton extends StatelessWidget {
  final bool busy;
  final VoidCallback? onPressed;
  final Gradient gradient;
  const _AcceptButton({required this.busy, required this.onPressed, required this.gradient});
  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: onPressed == null ? 0.6 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: busy
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeclineButton extends StatelessWidget {
  final bool busy;
  final VoidCallback? onPressed;
  final Color color;
  const _DeclineButton({required this.busy, required this.onPressed, required this.color});
  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: onPressed == null ? 0.6 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: .65), width: 1.5),
          color: color.withValues(alpha: .05),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: busy
                    ? SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: color, strokeWidth: 2))
                    : Text('Decline', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
