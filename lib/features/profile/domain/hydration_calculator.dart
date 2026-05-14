class HydrationCalculator {
  static const double kBaseMlPerKg = 35.0;

  static double calculateTarget({
    required double weightKg,
    required String gender,
    required String activityLevel,
  }) {
    // 1. Base calculation
    double target = weightKg * kBaseMlPerKg;

    // 2. Activity Multiplier
    final double multiplier = _getActivityMultiplier(activityLevel);
    target *= multiplier;

    // 3. Gender Adjustment (Research specific: Male + 200ml)
    if (gender.toLowerCase() == 'male') {
      target += 200;
    }

    return target;
  }

  static double _getActivityMultiplier(String level) {
    switch (level.toLowerCase()) {
      case 'sedentary':
        return 1.0;
      case 'light':
        return 1.1;
      case 'moderate':
        return 1.2;
      case 'active':
        return 1.3;
      case 'very_active':
        return 1.4;
      default:
        return 1.0;
    }
  }
}
