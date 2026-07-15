import 'package:http/http.dart' as http;

import '../auth/auth_token_provider.dart';

class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:8000';

  static AuthTokenProvider? authTokenProvider;

  static Future<http.Response> get(
    String path, {
    http.Client? client,
  }) {
    return _send(
      'GET',
      path,
      client: client,
    );
  }

  static Future<http.Response> post(
    String path, {
    String? body,
    http.Client? client,
  }) {
    return _send(
      'POST',
      path,
      body: body,
      client: client,
    );
  }

  static Future<http.Response> put(
    String path, {
    String? body,
    http.Client? client,
  }) {
    return _send(
      'PUT',
      path,
      body: body,
      client: client,
    );
  }

  static Future<http.Response> patch(
    String path, {
    String? body,
    http.Client? client,
  }) {
    return _send(
      'PATCH',
      path,
      body: body,
      client: client,
    );
  }

  static Future<http.Response> _send(
    String method,
    String path, {
    String? body,
    http.Client? client,
    bool retry = true,
  }) async {
    final token = authTokenProvider?.accessToken;

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final uri = Uri.parse(
      '$baseUrl$path',
    );

    late http.Response response;

    if (method == 'POST') {
      response = await (client?.post(uri, headers: headers, body: body) ?? http.post(uri, headers: headers, body: body));
    } else if (method == 'PUT') {
      response = await (client?.put(uri, headers: headers, body: body) ?? http.put(uri, headers: headers, body: body));
    } else if (method == 'PATCH') {
      response = await (client?.patch(uri, headers: headers, body: body) ?? http.patch(uri, headers: headers, body: body));
    } else {
      response = await (client?.get(uri, headers: headers) ?? http.get(uri, headers: headers));
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
        client: client,
        retry: false,
      );
    }

    return response;
  }
}