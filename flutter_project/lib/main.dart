import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'pages/careplan_view_page.dart';
import 'pages/login_page.dart';
import 'pages/ai_onboarding_page.dart';
import 'services/careplan_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Awesome Notifications
  AwesomeNotifications().initialize(
    null, // default icon
    [
      NotificationChannel(
        channelKey: 'med_reminders',
        channelName: 'Medication Reminders',
        channelDescription: 'Reminder notifications for medication times',
        importance: NotificationImportance.Max,
        defaultColor: Colors.blue,
        ledColor: Colors.white,
        channelShowBadge: true,
        criticalAlerts: true,
      ),
    ],
    debug: true,
  );

  // Initialize custom notification service
  await CarePlanNotificationService.init();

  runApp(const MyApp());
}

// Global navigator key to handle notification taps
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Hackathon CarePlan Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Poppins',
        ),
        initialRoute: '/careplan',
        routes: {
          '/careplan': (context) => const PreloadingCarePlanWrapper(),
          '/login': (context) => const LoginPage(),
          '/ai_onboarding': (context) => const AIOnboardingPage(),
        },
        home: const PreloadingCarePlanWrapper(),
      ),
    );
  }
}

/// Wrapper to start preloading diet & exercise data immediately when the app loads
class PreloadingCarePlanWrapper extends StatefulWidget {
  const PreloadingCarePlanWrapper({super.key});

  @override
  State<PreloadingCarePlanWrapper> createState() => _PreloadingCarePlanWrapperState();
}

class _PreloadingCarePlanWrapperState extends State<PreloadingCarePlanWrapper> {
  @override
  void initState() {
    super.initState();
    // Removed background preload of Exercise/Diet API (endpoints disabled)
  }

  @override
  Widget build(BuildContext context) {
    return const CarePlanViewPage();
  }
}
