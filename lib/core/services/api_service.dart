import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'api_exception.dart';

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
      case 400:
        throw const ApiException(
          message: 'Datos incorrectos. Verifica la información ingresada',
          statusCode: 400,
          type: ApiErrorType.validation,
        );
      case 401:
        throw const ApiException(
          message: 'Sesión expirada. Por favor inicia sesión de nuevo',
          statusCode: 401,
          type: ApiErrorType.unauthorized,
        );
      case 403:
        throw const ApiException(
          message: 'No tienes permisos para realizar esta acción',
          statusCode: 403,
          type: ApiErrorType.forbidden,
        );
      case 404:
        throw const ApiException(
          message: 'El recurso solicitado no fue encontrado',
          statusCode: 404,
          type: ApiErrorType.notFound,
        );
      case 409:
        throw ApiException(
          message: body['message'] as String? ??
              'Ya existe un registro con esos datos',
          statusCode: 409,
          type: ApiErrorType.conflict,
        );
      case 500:
      case 502:
      case 503:
        throw ApiException(
          message: 'Error en el servidor. Intenta de nuevo más tarde',
          statusCode: response.statusCode,
          type: ApiErrorType.serverError,
        );
      default:
        throw ApiException(
          message: body['message'] as String? ??
              'Error inesperado (${response.statusCode})',
          statusCode: response.statusCode,
          type: ApiErrorType.unknown,
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
      throw const ApiException(
        message: 'Tiempo de espera agotado. Verifica tu conexión a internet',
        type: ApiErrorType.timeout,
      );
    } on SocketException {
      throw const ApiException(
        message:
            'Sin conexión al servidor. Verifica que estés en la misma red WiFi',
        type: ApiErrorType.noConnection,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Error inesperado: $e',
        type: ApiErrorType.unknown,
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
      throw const ApiException(
        message: 'Tiempo de espera agotado. Verifica tu conexión a internet',
        type: ApiErrorType.timeout,
      );
    } on SocketException {
      throw const ApiException(
        message:
            'Sin conexión al servidor. Verifica que estés en la misma red WiFi',
        type: ApiErrorType.noConnection,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Error inesperado: $e',
        type: ApiErrorType.unknown,
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
      throw const ApiException(
        message: 'Tiempo de espera agotado. Verifica tu conexión a internet',
        type: ApiErrorType.timeout,
      );
    } on SocketException {
      throw const ApiException(
        message:
            'Sin conexión al servidor. Verifica que estés en la misma red WiFi',
        type: ApiErrorType.noConnection,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Error inesperado: $e',
        type: ApiErrorType.unknown,
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
      throw const ApiException(
        message: 'Tiempo de espera agotado. Verifica tu conexión a internet',
        type: ApiErrorType.timeout,
      );
    } on SocketException {
      throw const ApiException(
        message:
            'Sin conexión al servidor. Verifica que estés en la misma red WiFi',
        type: ApiErrorType.noConnection,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Error inesperado: $e',
        type: ApiErrorType.unknown,
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
      throw const ApiException(
        message: 'Tiempo de espera agotado. Verifica tu conexión a internet',
        type: ApiErrorType.timeout,
      );
    } on SocketException {
      throw const ApiException(
        message:
            'Sin conexión al servidor. Verifica que estés en la misma red WiFi',
        type: ApiErrorType.noConnection,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Error inesperado: $e',
        type: ApiErrorType.unknown,
      );
    }
  }
}
