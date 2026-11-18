import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:roti_bakar_borneo_flutter/core/network/app_config.dart';

class ApiClient {
  ApiClient(this._http);
  final http.Client _http;

  Future<Map<String, dynamic>> get(
    String action, [
    Map<String, String> parameters = const {},
    Duration timeout = const Duration(seconds: 60),
  ]) async {
    final uri = Uri.parse(AppConfig.apiBaseUrl).replace(
      queryParameters: {
        'action': action,
        'api_key': AppConfig.apiKey,
        ...parameters,
        '_': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    final response = await _http.get(uri).timeout(timeout);
    if (response.body.trim().isEmpty) {
      throw const ApiException('Respons server kosong.');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] != true) {
      throw ApiException(
        body['message']?.toString() ?? 'Server tidak dapat memuat data.',
      );
    }
    return body;
  }

  Future<Map<String, dynamic>> post(
    String action,
    Map<String, dynamic> payload, [
    Duration timeout = const Duration(seconds: 60),
  ]) async {
    final jsonPayload = jsonEncode({
      'action': action,
      'api_key': AppConfig.apiKey,
      ...payload,
    });

    http.Response response;

    if (kIsWeb) {
      // Di web, biarkan browser mengikuti redirect secara otomatis.
      // Gunakan POST biasa (followRedirects default = true).
      response = await _http
          .post(
            Uri.parse(AppConfig.apiBaseUrl),
            headers: {'Content-Type': 'text/plain'},
            body: jsonPayload,
          )
          .timeout(timeout);
    } else {
      // Di mobile/desktop, tangani redirect 302 secara manual.
      final request = http.Request('POST', Uri.parse(AppConfig.apiBaseUrl))
        ..followRedirects = false
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonPayload;
      final initial = await _http.send(request).timeout(timeout);
      final location = initial.headers['location'];
      response =
          location != null &&
              initial.statusCode >= 300 &&
              initial.statusCode < 400
          ? await _http.get(Uri.parse(location)).timeout(timeout)
          : await http.Response.fromStream(initial);
    }

    if (response.body.trim().isEmpty) {
      throw const ApiException('Respons server kosong.');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] != true) {
      throw ApiException(
        body['message']?.toString() ?? 'Server tidak dapat menyimpan data.',
      );
    }
    return body;
  }
}

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
