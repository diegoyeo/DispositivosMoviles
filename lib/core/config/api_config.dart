class ApiConfig {
  static const String baseUrl = 'http://192.168.0.103:3000/api';
  static const Duration timeout = Duration(seconds: 10);

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String exams = '/exams';
  static const String examStats = '/exams/stats';
  static const String saved = '/saved';
  static const String profile = '/user/profile';
  static const String password = '/user/password';
  static const String carreras = '/carreras';
  static const String salones = '/salones';
}
