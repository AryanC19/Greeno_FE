import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../video_player_page.dart';

class ExerciseDietPage extends StatefulWidget {
  const ExerciseDietPage({super.key});

  @override
  State<ExerciseDietPage> createState() => _ExerciseDietPageState();
}

class _ExerciseDietPageState extends State<ExerciseDietPage> {
  bool _showLottieLoading = true;

  // Hardcoded master diet data (static) - NO IMAGES
  static const List<Map<String, dynamic>> _dietPlanMaster = [
    {
      "analysis": "To support your recovery and improve your health, include these nutrient-rich foods tailored to your needs."
    },
    {
      "nutrient": "Fiber",
      "food": "Oatmeal",
      "reason": "High in soluble fiber which can help stabilize digestion and may alleviate IBS symptoms."
    },
    {
      "nutrient": "Omega-3 Fatty Acids",
      "food": "Grilled Salmon",
      "reason": "Rich in Omega-3s, which have anti-inflammatory properties that may reduce the frequency of migraines."
    },
    {
      "nutrient": "Magnesium",
      "food": "Spinach",
      "reason": "Excellent source of magnesium, which can help prevent migraines and support overall muscle function."
    },
    {
      "nutrient": "Potassium",
      "food": "Banana",
      "reason": "Good source of potassium that helps regulate blood pressure and may improve gut health."
    },
    {
      "nutrient": "Antioxidants",
      "food": "Blueberries",
      "reason": "High in antioxidants that can help reduce inflammation and may aid in migraine management."
    },
    {
      "nutrient": "Healthy Fats",
      "food": "Avocado",
      "reason": "Provides monounsaturated fats beneficial for heart health and cholesterol management."
    }
  ];

  // Pool of possible exercises (YouTube basic training links)
  static final List<Map<String, String>> _exercisePool = [
    {
      "name": "Bodyweight Squats",
      "reason": "Build lower-body strength and enhance joint stability.",
      "video_url": "https://www.youtube.com/watch?v=YaXPRqUwItQ"
    },
    {
      "name": "Push Ups",
      "reason": "Strengthen chest, shoulders, and core with a classic compound move.",
      "video_url": "https://www.youtube.com/watch?v=_l3ySVKYVJ8"
    },
    {
      "name": "Plank Hold",
      "reason": "Improve core stability and posture with isometric engagement.",
      "video_url": "https://www.youtube.com/watch?v=pSHjTRCQxIw"
    },
    {
      "name": "Glute Bridges",
      "reason": "Activate posterior chain and support lower back health.",
      "video_url": "https://www.youtube.com/watch?v=m2Zx-57cSok"
    },
    {
      "name": "Jumping Jacks",
      "reason": "Simple full-body warm-up to elevate heart rate.",
      "video_url": "https://www.youtube.com/watch?v=c4DAnQ6DtF8"
    },
    {
      "name": "Lunges",
      "reason": "Improve balance and unilateral leg strength.",
      "video_url": "https://www.youtube.com/watch?v=QOVaHwm-Q6U"
    },
    {
      "name": "Superman Raises",
      "reason": "Strengthen lower back and posterior chain.",
      "video_url": "https://www.youtube.com/watch?v=z6PJMT2y8GQ"
    },
    {
      "name": "Mountain Climbers",
      "reason": "Cardio core move to build endurance and stability.",
      "video_url": "https://www.youtube.com/watch?v=nmwgirgXLYM"
    }
  ];

  Map<String, dynamic> _dietExercisePlan = {};

  @override
  void initState() {
    super.initState();
    _generateNewPlan();
    _startFakeLoader();
  }

  void _startFakeLoader() async {
    setState(() => _showLottieLoading = true);
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _showLottieLoading = false);
  }

  void _generateNewPlan() {
    final random = Random();
    // Pick 5 distinct random exercises
    final poolCopy = List<Map<String, String>>.from(_exercisePool);
    poolCopy.shuffle(random);
    final chosen = poolCopy.take(5).toList();
    _dietExercisePlan = {
      "diet_plan": _dietPlanMaster,
      "exercise_plan": chosen,
    };
  }

  Future<void> _handleRefresh() async {
    _generateNewPlan();
    _startFakeLoader();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2563EB),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Exercise & Diet Plan",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 24),
              onPressed: _handleRefresh,
            ),
          ),
        ],
      ),
      body: _showLottieLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/lottie_animations/exercise_diet_load.json',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Loading your personalized plan...",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final hasDiet = _hasDietPlan(_dietExercisePlan);
    final hasExercise = _hasExercisePlan(_dietExercisePlan);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasDiet) ...[
            _buildDietSection(_dietExercisePlan),
            const SizedBox(height: 32),
          ],
          if (hasExercise) ...[
            _buildExerciseSection(_dietExercisePlan),
          ],
          if (!hasDiet && !hasExercise)
            Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 48,
                      color: Color(0xFF64748B),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "No diet or exercise plan available",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper method to check if diet plan data exists and is not empty
  bool _hasDietPlan(Map<String, dynamic> dietExercisePlan) {
    final dietPlan = dietExercisePlan["diet_plan"];
    return dietPlan != null && dietPlan is List && dietPlan.isNotEmpty;
  }

  // Helper method to check if exercise plan data exists and is not empty
  bool _hasExercisePlan(Map<String, dynamic> dietExercisePlan) {
    final exercisePlan = dietExercisePlan["exercise_plan"];
    return exercisePlan != null && exercisePlan is List && exercisePlan.isNotEmpty;
  }

  Widget _buildDietSection(Map<String, dynamic> dietData) {
    final dietPlan = dietData["diet_plan"] ?? [];
    if (dietPlan.isEmpty) return const SizedBox();

    final analysis = dietPlan.isNotEmpty && dietPlan[0]["analysis"] != null ? dietPlan[0]["analysis"] : "";
    final foods = dietPlan.length > 1 ? dietPlan.sublist(1) : [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  "Diet Plan",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            if (analysis.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  analysis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                    height: 1.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ...foods.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item["nutrient"] ?? "Nutrient",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item["food"] ?? "",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item["reason"] ?? "",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseSection(Map<String, dynamic> dietExercisePlan) {
    final exercisePlan = dietExercisePlan["exercise_plan"] ?? [];
    if (exercisePlan.isEmpty) return const SizedBox();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    color: Color(0xFF3B82F6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  "Exercise Plan",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...exercisePlan.map((item) {
              final videoUrl = item["video_url"] ?? "";
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.play_circle_outline_rounded,
                              color: Color(0xFF3B82F6),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item["name"] ?? "",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item["reason"] ?? "",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),
                      if (videoUrl.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoPlayerPage(
                                  videoUrl: videoUrl,
                                  videoTitle: item["name"] ?? "Exercise Video",
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Watch "${item["name"] ?? "Exercise"}" Video',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ));
              }).toList(),
          ],
        ),
      ),
    );
  }
}
