import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  ApiService._();
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;

  static const _kToken = 'auth_token';

  Future<Map<String, String>> _getHeaders({bool requiresAuth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (requiresAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_kToken);
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    switch (response.statusCode) {
      case 200:
      case 201:
        return body;
      case 401:
        throw Exception('Sesión expirada');
      case 403:
        throw Exception('Sin permisos');
      case 404:
        throw Exception('No encontrado');
      case 409:
        throw Exception(body['message'] ?? 'Conflicto');
      case 500:
        throw Exception('Error del servidor');
      default:
        throw Exception(
          body['message'] ?? 'Error desconocido (${response.statusCode})',
        );
    }
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http
          .get(Uri.parse(ApiConfig.baseUrl + endpoint), headers: headers)
          .timeout(ApiConfig.timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado');
    } on SocketException {
      throw Exception(
        'No se puede conectar al servidor. Verifica tu conexión',
      );
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http
          .post(
            Uri.parse(ApiConfig.baseUrl + endpoint),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado');
    } on SocketException {
      throw Exception(
        'No se puede conectar al servidor. Verifica tu conexión',
      );
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http
          .put(
            Uri.parse(ApiConfig.baseUrl + endpoint),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado');
    } on SocketException {
      throw Exception(
        'No se puede conectar al servidor. Verifica tu conexión',
      );
    }
  }

  Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http
          .patch(
            Uri.parse(ApiConfig.baseUrl + endpoint),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado');
    } on SocketException {
      throw Exception(
        'No se puede conectar al servidor. Verifica tu conexión',
      );
    }
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http
          .delete(
            Uri.parse(ApiConfig.baseUrl + endpoint),
            headers: headers,
          )
          .timeout(ApiConfig.timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado');
    } on SocketException {
      throw Exception(
        'No se puede conectar al servidor. Verifica tu conexión',
      );
    }
  }
}
