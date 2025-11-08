import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'ai_onboarding_page.dart';
import 'home_page.dart';
import '../widgets/gradient_app_bar.dart';

class CarePlanViewPage extends StatefulWidget {
  const CarePlanViewPage({super.key, this.viewOnly});
  final bool? viewOnly; // if true, show read-only with Back button
  @override
  State<CarePlanViewPage> createState() => _CarePlanViewPageState();
}

class _CarePlanViewPageState extends State<CarePlanViewPage> {
  Map<String,dynamic>? careplan;
  bool loading = true;
  String? error;
  bool retryLoading = false;
  String infoMessage = '';
  bool forceView = false; // user chose to view placeholder even with no careplan

  bool _isPlanPopulated(Map<String,dynamic> plan) {
    try {
      final meds = plan['medications'];
      final appts = plan['appointments'];
      final hasMeds = meds is List && meds.isNotEmpty;
      final hasAppts = appts is List && appts.isNotEmpty;
      return hasMeds || hasAppts;
    } catch (_) { return false; }
  }

  @override
  void initState() { super.initState(); _load(initial: true); }

  Future<void> _load({bool initial = false, bool aggressive = false}) async {
    if (!mounted) return;
    if (initial) { setState(() { loading = true; error = null; infoMessage=''; forceView = false; }); }
    else if (aggressive) { setState(() { retryLoading = true; infoMessage = 'Waiting for care plan to be generated...'; forceView = false; }); }
    else { setState(() { retryLoading = true; forceView = false; }); }

    final maxAttempts = aggressive ? 8 : 1;
    int attempt = 0; Map<String,dynamic>? cp;
    while (attempt < maxAttempts && cp == null) {
      attempt++;
      try {
        final fetched = await ApiService.getCarePlan();
        if (fetched != null && fetched.isNotEmpty && _isPlanPopulated(fetched)) { cp = fetched; break; }
      } catch (_) {}
      if (cp == null && attempt < maxAttempts) await Future.delayed(const Duration(seconds:1));
    }
    if (!mounted) return;
    setState(() {
      if (cp != null) { careplan = cp; error = null; infoMessage=''; }
      else { error = 'No care plan available yet'; infoMessage = aggressive ? 'Still generating... Please try again shortly.' : infoMessage; careplan = null; }
      loading = false; retryLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewOnly = widget.viewOnly ?? false;
    final hasPlan = careplan != null;
    final showingPlaceholder = forceView && !hasPlan;

    Widget body;
    if (loading) body = const Center(child:CircularProgressIndicator());
    else if (hasPlan) body = _buildContent();
    else if (showingPlaceholder) body = _buildPlaceholderContent();
    else body = _buildError();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFE),
      appBar: buildGradientAppBar(
        title: 'Your Care Plan',
        actionIcon: Icons.medical_services,
      ),
      body: body,
      bottomNavigationBar: _buildBottomBar(hasPlan: hasPlan, viewOnly: viewOnly, showingPlaceholder: showingPlaceholder),
    );
  }

  Widget _buildBottomBar({required bool hasPlan, required bool viewOnly, required bool showingPlaceholder}) {
    if (loading) return const SizedBox.shrink();
    if (hasPlan) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16,8,16,16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical:14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              backgroundColor: viewOnly ? Colors.indigo[500] : Colors.blue[500],
              elevation: 3,
            ),
            onPressed: () {
              if (viewOnly) {
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                else { Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage())); }
              } else {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AIOnboardingPage()));
              }
            },
            child: Text(
              viewOnly ? 'Back to Home' : 'Looks good, continue',
              style: const TextStyle(fontSize:16,fontWeight:FontWeight.w600,color:Colors.white, letterSpacing:.2),
            ),
          ),
        ),
      );
    }
    if (showingPlaceholder) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16,8,16,16),
          child: Row(children:[
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical:14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () { setState(()=>forceView=false); },
                child: const Text('Back to Retry'),
              ),
            ),
            const SizedBox(width:12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical:14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: Colors.teal[400],
                ),
                onPressed: retryLoading ? null : () => _load(aggressive: true),
                child: retryLoading
                    ? const SizedBox(height:18,width:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white))
                    : const Text('Try Again'),
              ),
            )
          ]),
        ),
      );
    }
    // Error state (no plan + not placeholder)
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16,8,16,16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical:14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            backgroundColor: Colors.blueGrey[600],
          ),
          onPressed: () { setState(()=>forceView = true); },
          child: const Text('View Anyways (Empty Preview)', style: TextStyle(fontSize:15,fontWeight:FontWeight.w600,color:Colors.white)),
        ),
      ),
    );
  }

  Widget _buildError() => Padding(
    padding: const EdgeInsets.symmetric(horizontal:24, vertical:32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height:40),
        Icon(Icons.health_and_safety, size:72, color: Colors.blue[400]),
        const SizedBox(height:24),
        Text('Care Plan Pending', style: TextStyle(fontSize:22,fontWeight:FontWeight.w700,color: Colors.blueGrey[800])),
        const SizedBox(height:12),
        Text(
          'We have not received your personalized care plan yet. You can retry now or wait a moment while it is being generated.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize:14,color: Colors.blueGrey[600],height:1.4),
        ),
        const SizedBox(height:28),
        if (infoMessage.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal:14, vertical:10),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber[300]!),
            ),
            child: Row(children:[
              const Icon(Icons.info_outline, size:18, color: Colors.amber),
              const SizedBox(width:10),
              Expanded(child: Text(infoMessage, style: const TextStyle(fontSize:12,height:1.3,color: Colors.black87)))
            ]),
          ),
          const SizedBox(height:20),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: retryLoading ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : const Icon(Icons.refresh, size:18),
              label: Text(retryLoading ? 'Retrying...' : 'Quick Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[400],
                padding: const EdgeInsets.symmetric(horizontal:22,vertical:14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: retryLoading ? null : () => _load(),
            ),
            const SizedBox(width:14),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal:20,vertical:14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: retryLoading ? null : () => _load(aggressive:true),
              child: Text(retryLoading ? 'Please wait' : 'Retry & Wait'),
            ),
          ],
        ),
        const SizedBox(height:20),
        Text('Or tap "View Anyways" below to show an empty preview.', style: TextStyle(fontSize:12,color: Colors.blueGrey[500])),
      ],
    ),
  );

  Widget _buildPlaceholderContent() => ListView(
    padding: const EdgeInsets.fromLTRB(16,24,16,140),
    children: [
      Row(children:[
        CircleAvatar(radius:40, backgroundColor: Colors.blue[100], child: Icon(Icons.android,color:Colors.blue[700],size:40)),
        const SizedBox(width:16),
        const Expanded(
          child: Text('Awaiting generation of your personalized care plan...',
            style: TextStyle(fontSize:18,fontWeight:FontWeight.w600,color:Colors.black87,height:1.25)),
        ),
      ]),
      const SizedBox(height:28),
      _sectionBar(title:'Medications (0)', icon:Icons.local_pharmacy, color: Colors.blue[700]!),
      const SizedBox(height:12),
      _skeletonCard(),
      _skeletonCard(widthFactor: .85),
      const SizedBox(height:32),
      _sectionBar(title:'Appointments (0)', icon:Icons.event_note, color: Colors.teal[400]!),
      const SizedBox(height:12),
      _skeletonCard(height:60,widthFactor:.9),
    ],
  );

  Widget _skeletonCard({double height = 80, double widthFactor = 1}) => Opacity(
    opacity: .55,
    child: Card(
      margin: const EdgeInsets.only(bottom:16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.grey[200],
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: widthFactor,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal:18),
              height: height * .45,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildContent() {
    final meds = List<Map<String,dynamic>>.from(careplan?['medications'] ?? []);
    final appts = List<Map<String,dynamic>>.from(careplan?['appointments'] ?? []);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16,24,16,120),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.teal.withValues(alpha: 0.08), Colors.blue.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.teal.withValues(alpha: 0.25), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(44),
                child: Image.asset(
                  'assets/images/greeno.png',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.blue[100],
                    child: Icon(Icons.android, color: Colors.blue[700], size: 36),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Your personalized care plan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        letterSpacing: .2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Curated for you by Dr. Malhotra. Review the items below and continue when you\'re ready.',
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.35,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height:28),
        _sectionBar(title:'Medications', icon:Icons.local_pharmacy, color: Colors.blue[700]!),
        const SizedBox(height:12),
        if (meds.isEmpty) _emptyHint('No medications were added to this plan.'),
        ...meds.map(_medCard),
        const SizedBox(height:32),
        _sectionBar(title:'Appointments', icon:Icons.event_note, color: Colors.teal[400]!),
        const SizedBox(height:12),
        if (appts.isEmpty) _emptyHint('No appointments have been scheduled here yet.'),
        ...appts.map(_apptCard),
      ],
    );
  }

  Widget _emptyHint(String text) => Container(
    margin: const EdgeInsets.only(bottom:16),
    padding: const EdgeInsets.symmetric(horizontal:14, vertical:12),
    decoration: BoxDecoration(
      color: Colors.blueGrey.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.15)),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, size:18, color: Colors.blueGrey[600]),
        const SizedBox(width:10),
        Expanded(child: Text(text, style: TextStyle(fontSize:13.2, height:1.3, color: Colors.blueGrey[700]))),
      ],
    ),
  );

  Widget _sectionBar({required String title, required IconData icon, required Color color}) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color.withAlpha(30), color.withAlpha(10)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withAlpha(90), width:1),
    ),
    padding: const EdgeInsets.symmetric(horizontal:14, vertical:10),
    child: Row(children: [
      Container(
        width:42, height:42,
        decoration: BoxDecoration(shape:BoxShape.circle, color: color.withAlpha(45)),
        child: Icon(icon, color: color, size:22),
      ),
      const SizedBox(width:14),
      Expanded(child: Text(title, style: TextStyle(fontSize:20,fontWeight:FontWeight.w700,color: _darkenColor(color),letterSpacing:.3))),
    ]),
  );

  Widget _medCard(Map<String,dynamic> m) {
    final schedule = List<Map<String,dynamic>>.from(m['schedule'] ?? []);

    List<Widget> statusWidgets = [];
    for (final s in schedule) {
      final time = (s['time'] ?? '').toString();
      final takenVal = s['taken'];
      if (takenVal == null) continue; // skip unknown
      final bool taken = takenVal == true;
      final Color base = taken ? Colors.green : Colors.red;
      statusWidgets.add(_miniDosePill(time.isEmpty ? '--' : time, taken, base));
    }

    return Card(
      margin: const EdgeInsets.only(bottom:20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal:20, vertical:16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(7),
              child: Icon(Icons.medication, color: Colors.blue[700], size:18),
            ),
            const SizedBox(width:12),
            Expanded(child: Text(m['name'] ?? '', style: const TextStyle(fontSize:19,fontWeight:FontWeight.w700, letterSpacing:0.2))),
            _pill(m['dose'] ?? '', Colors.blue),
          ]),
          if (m['duration'] != null) ...[
            const SizedBox(height:8),
            Text('Duration: ${m['duration']}', style: TextStyle(fontSize:13,color:Colors.grey[700])),
          ],
          if (statusWidgets.isNotEmpty) ...[
            const SizedBox(height:10),
            Wrap(
              spacing:6,
              runSpacing:6,
              children: statusWidgets,
            ),
          ],
        ]),
      ),
    );
  }

  Widget _miniDosePill(String time, bool taken, Color base) {
    final Color fg = (taken ? base.darken(.05) : base.darken(.1));
    return AnimatedContainer(
      duration: const Duration(milliseconds:250),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal:6, vertical:3),
      decoration: BoxDecoration(
        color: base.withValues(alpha: taken ? 0.14 : 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: base.withValues(alpha: 0.40), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(taken ? Icons.check_circle_rounded : Icons.close_rounded, size:13, color: fg),
            const SizedBox(width:3),
          Text(time, style: TextStyle(fontSize:10.5,fontWeight:FontWeight.w600, letterSpacing:.2, color: fg)),
        ],
      ),
    );
  }

  Widget _apptCard(Map<String,dynamic> a) {
    final statusRaw = (a['status'] ?? '').toString();
    final status = statusRaw.toLowerCase();

    final bool isConfirmed = status == 'confirmed';
    final bool isDeclined = status == 'declined';

    late Color color;
    late IconData icon;
    late String statusLabel;

    if (isConfirmed) {
      color = Colors.green;
      icon = Icons.check_circle;
      statusLabel = 'Confirmed';
    } else if (isDeclined) {
      color = Colors.red;
      icon = Icons.cancel;
      statusLabel = 'Declined';
    } else {
      color = Colors.orange;
      icon = Icons.hourglass_bottom;
      statusLabel = 'Not confirmed';
    }

    return Card(
      margin: const EdgeInsets.only(bottom:16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: color, size:28),
        title: Text(a['type'] ?? 'Appointment', style: const TextStyle(fontWeight:FontWeight.w600,fontSize:16)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal:10, vertical:4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: .4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal:10, vertical:4),
    decoration: BoxDecoration(
      color: color.withAlpha(40),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: color.withAlpha(100)),
    ),
    child: Text(text, style: TextStyle(color: (color is MaterialColor)? color[700] : color, fontSize:11,fontWeight:FontWeight.w600)),
  );

  Color _darkenColor(Color color, [double amount = 0.18]) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0, 1)).toColor();
  }
}

// Helpers
extension _ColorShade on Color {
  Color darken([double amount=.18]) { final hsl = HSLColor.fromColor(this); return hsl.withLightness((hsl.lightness-amount).clamp(0,1)).toColor(); }
}
