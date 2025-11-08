import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_page.dart';
import 'home_page_screens/view_appointments_page.dart';
import 'home_page_screens/medication_reminder_page.dart';
import 'home_page_screens/exercise_diet_page.dart';
import 'careplan_view_page.dart';
import 'chat_screen.dart';
import 'feature_loading_page.dart';
import '../services/api_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF1E88E5), const Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 20),
            onPressed: () {
              auth.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ),
        title: const Text(
          'HealthCare Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 20,
              child: Icon(Icons.person, color: const Color(0xFF1E88E5), size: 24),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Enhanced header section with gradient
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1E88E5), const Color(0xFF42A5F5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back!',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Manage your health journey',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Health icon or illustration
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Greeno hanging between sections
            // Transform.translate(
            //   offset: const Offset(0, -20),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       Container(
            //         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            //         decoration: BoxDecoration(
            //           color: Colors.white,
            //           borderRadius: BorderRadius.circular(25),
            //           boxShadow: [
            //             BoxShadow(
            //               color: Colors.black.withOpacity(0.1),
            //               blurRadius: 12,
            //               offset: const Offset(0, 4),
            //             ),
            //           ],
            //         ),
            //         child: Row(
            //           mainAxisSize: MainAxisSize.min,
            //           children: [
            //             Container(
            //               width: 90, // Fixed container size
            //               height: 90, // Fixed container size
            //               alignment: Alignment.center,
            //               child: Image.asset(
            //                 'assets/images/greeno_home.png',
            //                 width: 100, // Image size (independent of container)
            //                 height: 100, // Image size (independent of container)
            //                 fit: BoxFit.contain,
            //                 errorBuilder: (_, __, ___) => Container(
            //                   width: 50,
            //                   height: 50,
            //                   decoration: BoxDecoration(
            //                     color: const Color(0xFF2EAD6D),
            //                     borderRadius: BorderRadius.circular(25),
            //                   ),
            //                   child: const Icon(Icons.android, color: Colors.white, size: 25),
            //                 ),
            //               ),
            //             ),
            //             const SizedBox(width: 12),
            //             Column(
            //               crossAxisAlignment: CrossAxisAlignment.start,
            //               mainAxisSize: MainAxisSize.min,
            //               children: [
            //                 Text(
            //                   "Hi, I'm Greeno!",
            //                   style: TextStyle(
            //                     fontSize: 14,
            //                     fontWeight: FontWeight.bold,
            //                     color: const Color(0xFF2EAD6D),
            //                   ),
            //                 ),
            //                 Text(
            //                   "Ready to help you today",
            //                   style: TextStyle(
            //                     fontSize: 12,
            //                     color: Colors.grey[600],
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            // Main content with improved spacing
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Quick Access',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // View Careplan card
                  _buildFeatureCard(
                    context,
                    title: "View Careplan",
                    subtitle: "See your latest medicines and appointments",
                    icon: Icons.assignment,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CarePlanViewPage(viewOnly: true),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Main feature cards
                  _buildFeatureCard(
                    context,
                    title: "View Appointments",
                    subtitle: "Manage your scheduled appointments",
                    icon: Icons.calendar_today,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FeatureLoadingPage(
                            animationAsset: 'assets/lottie_animations/appointment_load.json',
                            messages: const [
                              'Greeno is looking for available doctors…',
                              'Greeno is finding open slots for you…',
                            ],
                            messageDuration: const Duration(seconds: 2),
                            destination: const AppointmentsPage(),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  _buildFeatureCard(
                    context,
                    title: "Medications",
                    subtitle: "Track your daily medication schedule",
                    icon: Icons.medical_services,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FeatureLoadingPage(
                            animationAsset: 'assets/lottie_animations/medicine_reminder_load.json',
                            messages: const [
                              'Greeno is organizing your morning, afternoon, evening & night meds…',
                              'Greeno is auto‑setting reminders for each time slot…',
                            ],
                            messageDuration: const Duration(seconds: 2),
                            destination: const MedicationReminderPage(),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  _buildFeatureCard(
                    context,
                    title: "Exercise & Diet",
                    subtitle: "Your personalized health plan",
                    icon: Icons.fitness_center,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FeatureLoadingPage(
                            animationAsset: 'assets/lottie_animations/exercise_diet_load.json',
                            messages: const [
                              'Preparing your exercise & diet plan…',
                            ],
                            messageDuration: const Duration(seconds: 3), // Single 3s fake load
                            destination: const ExerciseDietPage(),
                            replace: true,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 80), // Extra space for FAB
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 80, // Increased from 70
        height: 80, // Increased from 70
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40), // Adjusted for new size
          gradient: LinearGradient(
            colors: [const Color(0xFF2EAD6D), const Color(0xFF8EE4EC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2EAD6D).withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(40), // Adjusted for new size
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(2), // Increased padding from 16
              child: Image.asset(
                'assets/images/greeno_icon.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.chat_bubble,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.1),
                  color.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: color,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
