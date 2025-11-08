import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000"; // Emulator → FastAPI
  static const String apiBase = "$baseUrl/api";

  // ---------------- CarePlan ----------------
  static Future<Map<String, dynamic>?> uploadCarePlan(Map<String, dynamic> carePlanData) async {
    final url = Uri.parse("$apiBase/careplans/upload-careplan");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(carePlanData),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  static Future<Map<String, dynamic>?> getCarePlan() async {
    final url = Uri.parse("$apiBase/careplans/careplan");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['careplan'] != null ? Map<String, dynamic>.from(data['careplan']) : null;
    }
    return null;
  }

  // ---------------- Medications ----------------
  static Future<Map<String, dynamic>?> getMedications() async {
    final url = Uri.parse("$apiBase/medications/");
    final response = await http.get(url);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  static Future<bool> markMedicationScheduleTaken(String medicationId, String time) async {
    final url = Uri.parse("$apiBase/medications/api/$medicationId/schedule/$time/taken");
    final response = await http.post(url);
    return response.statusCode == 200;
  }

  static Future<bool> markMedicationScheduleNotTaken(String medicationId, String time) async {
    final url = Uri.parse("$apiBase/medications/api/$medicationId/schedule/$time/not-taken");
    final response = await http.post(url);
    return response.statusCode == 200;
  }

  // ---------------- Diet Only (DISABLED: now hardcoded) ----------------
  static Future<Map<String, dynamic>?> getDietPlan() async {
    // Disabled: returning null to avoid hitting /api/exercise/diet
    return null;
  }

  // ---------------- Diet & Exercise (DISABLED) ----------------
  static Future<Map<String, dynamic>?> getDietExercisePlan() async {
    // Disabled: returning null to avoid hitting /api/exercise/
    return null;
  }

  // ---------------- Reminders ----------------
  static Future<Map<String, dynamic>?> getReminders() async {
    final url = Uri.parse("$apiBase/medications/");
    final response = await http.get(url);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  static Future<Map<String, dynamic>?> getReminderSlots() async {
    final url = Uri.parse("$apiBase/reminders/");
    final response = await http.get(url);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  static Future<bool> updateReminderSlotTime(String slot, String time) async {
    final url = Uri.parse("$apiBase/reminders/$slot/update-time?time=$time");
    final response = await http.post(url);
    return response.statusCode == 200;
  }

  // ---------------- Appointments ----------------
  static Future<List<Map<String, dynamic>>> getPendingAppointments() async {
    final url = Uri.parse("$apiBase/appointments/pending-appointments");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data["pending"] ?? []);
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getConfirmedAppointments() async {
    final url = Uri.parse("$apiBase/appointments/confirmed-appointments");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data["confirmed"] ?? []);
    }
    return [];
  }

  static Future<Map<String, dynamic>?> assignSlot(String appointmentId) async {
    final url = Uri.parse("$apiBase/appointments/$appointmentId/assign-slot");
    final response = await http.post(url);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  static Future<bool> confirmAppointment(String appointmentId) async {
    final url = Uri.parse("$apiBase/appointments/$appointmentId/confirm");
    final response = await http.post(url);
    return response.statusCode == 200;
  }

  static Future<bool> declineAppointment(String appointmentId) async {
    final url = Uri.parse("$apiBase/appointments/$appointmentId/decline");
    final response = await http.post(url);
    return response.statusCode == 200;
  }

  // ---------------- Doctors ----------------
  static Future<Map<String, dynamic>?> addDoctorAvailability(String doctorId, Map<String, dynamic> availabilityData) async {
    final url = Uri.parse("$apiBase/doctors/doctor-availability");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(availabilityData),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  static Future<Map<String, dynamic>?> getDoctorAvailability(String doctorId) async {
    final url = Uri.parse("$apiBase/doctors/doctor-availability/$doctorId");
    final response = await http.get(url);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  // Enhanced response formatter with emojis and visual appeal
  static String _enhanceResponseVisually(String originalResponse) {
    String enhanced = originalResponse;

    // Replace markdown bold with emojis and clean text (completely remove ** formatting)
    enhanced = enhanced.replaceAllMapped(
      RegExp(r'\*\*(.*?)\*\*'),
      (match) {
        String content = match.group(1)!.toLowerCase();
        String originalText = match.group(1)!;

        // Medical appointment emojis
        if (content.contains('eye checkup') || content.contains('eye')) {
          return '👁️ $originalText';
        }
        if (content.contains('flu shot') || content.contains('flu') || content.contains('vaccination')) {
          return '💉 $originalText';
        }
        if (content.contains('physiotherapy') || content.contains('physical therapy')) {
          return '🏃‍♂️ $originalText';
        }
        if (content.contains('colonoscopy') || content.contains('screening')) {
          return '🔬 $originalText';
        }
        if (content.contains('dermatologist') || content.contains('skin')) {
          return '🩺 $originalText';
        }
        if (content.contains('dental') || content.contains('dentist')) {
          return '🦷 $originalText';
        }
        if (content.contains('cardiology') || content.contains('heart')) {
          return '❤️ $originalText';
        }
        if (content.contains('blood test') || content.contains('lab')) {
          return '🩸 $originalText';
        }
        if (content.contains('x-ray') || content.contains('scan') || content.contains('mri')) {
          return '📷 $originalText';
        }

        // Default medical emoji for other appointments
        return '🏥 $originalText';
      },
    );

    // Remove any remaining asterisks that might have been missed
    enhanced = enhanced.replaceAll(RegExp(r'\*+'), '');

    // Enhance status indicators
    enhanced = enhanced.replaceAll('Status: Confirmed', '✅ Status: Confirmed');
    enhanced = enhanced.replaceAll('Status: Pending', '⏳ Status: Pending');
    enhanced = enhanced.replaceAll('Status: Declined', '❌ Status: Declined');
    enhanced = enhanced.replaceAll('Status: Cancelled', '🚫 Status: Cancelled');

    // Enhance date and time formatting
    enhanced = enhanced.replaceAllMapped(
      RegExp(r'(\w+day),?\s+(\w+ \d{1,2}, \d{4}),?\s+at\s+(\d{1,2}:\d{2}\s+[AP]M)', caseSensitive: false),
      (match) => '📅 ${match.group(2)} at 🕐 ${match.group(3)}',
    );

    // Add section headers with emojis (remove any bold formatting)
    if (enhanced.contains('upcoming appointments')) {
      enhanced = enhanced.replaceFirst(
        RegExp(r'Here are your upcoming appointments:?', caseSensitive: false),
        '📋 Your Upcoming Appointments'
      );
    }

    // Replace "Proposed Slot:" with cleaner formatting
    enhanced = enhanced.replaceAll('Proposed Slot:', '📍 Time:');

    // Add visual separators and spacing
    enhanced = enhanced.replaceAllMapped(
      RegExp(r'(\d+\.\s+[^\n]+\n(?:\s*-[^\n]+\n)*)', multiLine: true),
      (match) => '\n${match.group(0)?.trim()}\n',
    );

    // Enhance list formatting
    enhanced = enhanced.replaceAll(RegExp(r'^\s*-\s+', multiLine: true), '   • ');

    // Add helpful closing message
    if (enhanced.contains('appointments') && enhanced.contains('Let me know')) {
      enhanced = enhanced.replaceFirst(
        'Let me know if you need any more information!',
        '\n💬 Need to confirm, decline, or reschedule any appointment? Just let me know!'
      );
    }

    return enhanced.trim();
  }

  static Future<String?> sendChatMessage(String question) async {
    try {
      // Enhance the user's question with specific visual appeal instructions
      String enhancedQuestion = "$question (Response rules: Add relevant emojis for appointments and status indicators. Make it visually appealing. Do NOT use markdown bold formatting like **text**. Do NOT wrap appointment names in asterisks. Use clean text formatting only. Replace any bold text with emoji + plain text.)";

      final url = Uri.parse("$apiBase/chat/");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"question": enhancedQuestion}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String originalAnswer = data["answer"] as String? ?? "";

        // Apply visual enhancements to the response
        return _enhanceResponseVisually(originalAnswer);
      } else {
        return null;
      }
    } catch (e) {
      print('Chat API Error: $e');
      return null;
    }
  }
}

