import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'token_store.dart';

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.title,
    required this.detail,
    this.errors = const {},
  });

  final int statusCode;
  final String title;
  final String detail;
  final Map<String, dynamic> errors;

  String get userMessage {
    if (statusCode == 0)
      return 'Không kết nối được máy chủ. Hãy kiểm tra mạng và thử lại.';
    final validation = errors.values
        .expand((value) => value is List ? value : [value])
        .whereType<String>()
        .firstOrNull;
    return validation ?? (detail.isNotEmpty ? detail : title);
  }

  @override
  String toString() => 'ApiException($statusCode, $title, $detail)';
}

class ApiClient {
  ApiClient({
    required String baseUrl,
    required TokenStore tokenStore,
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 15),
  }) : this._(
         Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/'),
         tokenStore,
         httpClient ?? http.Client(),
         timeout,
       );

  ApiClient._(this._baseUri, this._tokenStore, this._httpClient, this.timeout);

  final Uri _baseUri;
  final TokenStore _tokenStore;
  final http.Client _httpClient;
  final Duration timeout;
  Future<void> Function()? onUnauthorized;
  Future<void> Function()? onForbidden;

  Future<dynamic> getJson(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> postJson(String path, [Object? body]) =>
      _send('POST', path, body: body);

  Future<dynamic> putJson(String path, [Object? body]) =>
      _send('PUT', path, body: body);

  Future<dynamic> patchJson(String path, [Object? body]) =>
      _send('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Uri resolveMediaUri(String url) {
    final parsed = Uri.parse(url.trim());
    return parsed.hasScheme ? parsed : _baseUri.resolve(url.trim());
  }

  Future<dynamic> postMultipart(
    String path, {
    required String fileFieldName,
    required String filePath,
  }) async {
    const uploadTimeout = Duration(minutes: 2);
    final request = http.MultipartRequest('POST', _buildUri(path, null))
      ..headers['Accept'] = 'application/json';
    final token = await _tokenStore.read();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    try {
      request.files.add(
        await http.MultipartFile.fromPath(fileFieldName, filePath),
      );
      final streamed = await _httpClient.send(request).timeout(uploadTimeout);
      final response = await http.Response.fromStream(streamed)
          .timeout(uploadTimeout);
      return await _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        statusCode: 0,
        title: 'Hết thời gian chờ',
        detail: '',
      );
    } on SocketException {
      throw const ApiException(
        statusCode: 0,
        title: 'Không thể kết nối',
        detail: '',
      );
    } on http.ClientException {
      throw const ApiException(
        statusCode: 0,
        title: 'Không thể kết nối',
        detail: '',
      );
    }
  }

  Uri _buildUri(String path, Map<String, String>? query) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final uri = _baseUri.resolve(normalizedPath);
    return query == null || query.isEmpty
        ? uri
        : uri.replace(queryParameters: query);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    final token = await _tokenStore.read();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (body != null)
      headers['Content-Type'] = 'application/json; charset=utf-8';

    final request = http.Request(method, _buildUri(path, query))
      ..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    try {
      final streamed = await _httpClient.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamed)
          .timeout(timeout);
      return await _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        statusCode: 0,
        title: 'Hết thời gian chờ',
        detail: '',
      );
    } on SocketException {
      throw const ApiException(
        statusCode: 0,
        title: 'Không thể kết nối',
        detail: '',
      );
    } on http.ClientException {
      throw const ApiException(
        statusCode: 0,
        title: 'Không thể kết nối',
        detail: '',
      );
    }
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    if (response.statusCode == 204 || response.bodyBytes.isEmpty) return null;

    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      decoded = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) {
        await _tokenStore.clear();
        await onUnauthorized?.call();
      } else if (response.statusCode == 403) {
        await _tokenStore.clear();
        await onForbidden?.call();
      }
      final problem = decoded is Map<String, dynamic>
          ? decoded
          : const <String, dynamic>{};
      throw ApiException(
        statusCode: response.statusCode,
        title: problem['title'] as String? ?? 'Yêu cầu không thành công',
        detail: problem['detail'] as String? ?? '',
        errors: problem['errors'] is Map<String, dynamic>
            ? problem['errors'] as Map<String, dynamic>
            : const {},
      );
    }
    return decoded;
  }

  void close() => _httpClient.close();
}
