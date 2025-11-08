import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ExerciseDietProvider extends ChangeNotifier {
  Map<String, dynamic>? _dietExercisePlan;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isPreloaded = false;

  Map<String, dynamic>? get dietExercisePlan => _dietExercisePlan;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get isPreloaded => _isPreloaded;

  /// Preload the diet & exercise plan in the background
  Future<void> preloadDietExercisePlan() async {
    if (_isPreloaded || _isLoading) return; // Don't reload if already loaded or loading

    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final response = await ApiService.getDietExercisePlan();

      if (response != null && response.containsKey("diet_exercise_plan")) {
        _dietExercisePlan = response["diet_exercise_plan"];
        _isPreloaded = true;
        _hasError = false;
      } else {
        _hasError = true;
      }
    } catch (e) {
      debugPrint("Error preloading diet & exercise plan: $e");
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Force refresh the data (for manual refresh button)
  Future<void> refreshDietExercisePlan() async {
    _isPreloaded = false;
    _dietExercisePlan = null;
    await preloadDietExercisePlan();
  }

  /// Clear the cached data
  void clearCache() {
    _dietExercisePlan = null;
    _isPreloaded = false;
    _isLoading = false;
    _hasError = false;
    notifyListeners();
  }
}
