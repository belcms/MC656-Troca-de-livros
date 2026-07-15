import 'package:http/http.dart' as http;

import '../auth/auth_token_provider.dart';

class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:8000';

  static AuthTokenProvider? authTokenProvider;

  static Future<http.Response> get(
    String path,
  ) {
    return _send(
      'GET',
      path,
    );
  }

  static Future<http.Response> post(
    String path, {
    String? body,
  }) {
    return _send(
      'POST',
      path,
      body: body,
    );
  }

  static Future<http.Response> put(
    String path, {
    String? body,
  }) {
    return _send(
      'PUT',
      path,
      body: body,
    );
  }

  static Future<http.Response> _send(
    String method,
    String path, {
    String? body,
    bool retry = true,
  }) async {
    final token = authTokenProvider?.accessToken;

    final headers = {
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final uri = Uri.parse(
      '$baseUrl$path',
    );

    late http.Response response;

    if (method == 'POST') {
      response = await http.post(
        uri,
        headers: headers,
        body: body,
      );
    } else if (method == 'PUT') {
      response = await http.put(
        uri,
        headers: headers,
        body: body,
      );
    } else {
      response = await http.get(
        uri,
        headers: headers,
      );
    }

    final provider = authTokenProvider;

    if (
      response.statusCode == 401 &&
      retry &&
      provider != null &&
      await provider.refresh()
    ) {
      return _send(
        method,
        path,
        body: body,
        retry: false,
      );
    }

    return response;
  }
}