import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class RemindersProvider extends ChangeNotifier {
  Map<String, dynamic>? reminders;
  bool isLoading = false;

  Future<void> fetchReminders(String patientId) async {
    isLoading = true;
    notifyListeners();

    reminders = await ApiService.getReminders();

    isLoading = false;
    notifyListeners();
  }
}
