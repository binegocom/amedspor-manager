import '../../entities/ball.dart';
import '../../models/weather_condition.dart';

class PhysicsEngine {
  final double fieldWidth = 105.0;
  final double fieldHeight = 68.0;

  bool checkOutOfBounds(Ball ball) {
    if (ball.isShot) return false;
    return ball.x < 0.5 ||
        ball.x > 104.5 ||
        ball.y < 0.0 ||
        ball.y > fieldHeight;
  }

  bool isXAxisExit(Ball ball) {
    return ball.x < 0.5 || ball.x > 104.5;
  }

  bool isGoalArea(Ball ball) {
    // Left goal area or right goal area
    return (ball.x <= 4.0 && ball.targetX <= 1.0) ||
        (ball.x >= 101.0 && ball.targetX >= 104.0);
  }

  double getWeatherMultiplier(WeatherCondition weather) {
    switch (weather) {
      case WeatherCondition.clear:
        return 1.0;
      case WeatherCondition.cloudy:
        return 0.95;
      case WeatherCondition.rainy:
        return 0.85;
      case WeatherCondition.stormy:
        return 0.70;
      case WeatherCondition.snowy:
        return 0.60;
    }
  }
}
