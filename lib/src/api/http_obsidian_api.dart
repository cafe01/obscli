import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/config_resolver.dart';
import 'obsidian_api.dart';
import 'obsidian_api_exception.dart';

/// Concrete [ObsidianApi] implementation using raw HTTP via `package:http`.
///
/// Takes an [http.Client] as transport (injectable for testing) and a
/// [ConfigResolver] for host/API key resolution.
class HttpObsidianApi implements ObsidianApi {
  /// Creates an API client backed by [client].
  HttpObsidianApi({
    required http.Client client,
    required ConfigResolver config,
  })  : _client = client,
        _config = config;

  final http.Client _client;
  final ConfigResolver _config;

  /// Build a full URI from an endpoint path.
  Uri _uri(String path, {Map<String, String>? queryParams}) {
    final base = _config.host;
    return Uri.parse('$base$path').replace(
      queryParameters:
          queryParams != null && queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// Default headers with Bearer auth.
  Map<String, String> _headers({
    String? accept,
    String? contentType,
  }) {
    final h = <String, String>{};
    final key = _config.apiKey;
    if (key != null && key.isNotEmpty) {
      h['Authorization'] = 'Bearer $key';
    }
    if (accept != null) h['Accept'] = accept;
    if (contentType != null) h['Content-Type'] = contentType;
    return h;
  }

  /// Throw typed exception from response.
  Never _throwFromResponse(http.Response response) {
    throw ObsidianApiException.fromResponse(
      response.statusCode,
      response.body,
    );
  }

  /// Check response status, throw on error.
  void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    _throwFromResponse(response);
  }

  /// Parse JSON response body.
  Map<String, dynamic> _parseJson(http.Response response) {
    final dynamic decoded = jsonDecode(response.body);
    return decoded as Map<String, dynamic>;
  }

  // ---- Server status ----

  @override
  Future<Map<String, dynamic>> getStatus() async {
    final uri = _uri('/');
    final response = await _client.get(uri, headers: _headers());
    _checkResponse(response);
    return _parseJson(response);
  }

  // ---- Vault note operations ----

  @override
  Future<String> readNote(String path) async {
    final uri = _uri('/vault/$path');
    final response = await _client.get(
      uri,
      headers: _headers(accept: 'text/markdown'),
    );
    _checkResponse(response);
    return response.body;
  }

  @override
  Future<Map<String, dynamic>> readNoteStructured(String path) async {
    final uri = _uri('/vault/$path');
    final response = await _client.get(
      uri,
      headers: _headers(accept: 'application/vnd.olrapi.note+json'),
    );
    _checkResponse(response);
    return _parseJson(response);
  }

  @override
  Future<List<Map<String, dynamic>>> listDirectory([String path = '/']) async {
    // Normalize path: remove leading slash to avoid double slashes
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final uri = _uri('/vault/$normalizedPath');
    final response = await _client.get(
      uri,
      headers: _headers(accept: 'application/json'),
    );
    _checkResponse(response);
    final json = _parseJson(response);
    final files = json['files'] as List<dynamic>;

    // API returns strings with trailing '/' for directories
    return files.map((item) {
      final name = item as String;
      final isFolder = name.endsWith('/');
      return <String, dynamic>{
        'name': isFolder ? name.substring(0, name.length - 1) : name,
        'type': isFolder ? 'folder' : 'file',
      };
    }).toList();
  }

  @override
  Future<void> createNote(String path, String content) async {
    final uri = _uri('/vault/$path');
    final response = await _client.put(
      uri,
      headers: _headers(contentType: 'text/markdown'),
      body: content,
    );
    _checkResponse(response);
  }

  @override
  Future<void> appendToNote(String path, String content) async {
    final uri = _uri('/vault/$path');
    final response = await _client.post(
      uri,
      headers: _headers(contentType: 'text/markdown'),
      body: content,
    );
    _checkResponse(response);
  }

  @override
  Future<void> patchNote(
    String path,
    String content, {
    String? heading,
    String? blockId,
    bool frontmatter = false,
    String? insertPosition,
  }) async {
    final uri = _uri('/vault/$path');
    final headers = <String, String>{};

    if (frontmatter) {
      // Frontmatter patches send JSON body
      headers.addAll(_headers(contentType: 'application/vnd.olrapi.note+json'));
      final response = await _client.patch(uri, headers: headers, body: content);
      _checkResponse(response);
    } else {
      // Regular markdown patches
      headers.addAll(_headers(contentType: 'text/markdown'));
      if (heading != null) headers['Heading'] = heading;
      if (blockId != null) headers['Block-Reference'] = blockId;
      if (insertPosition != null) {
        headers['Content-Insertion-Position'] = insertPosition;
      }
      final response = await _client.patch(uri, headers: headers, body: content);
      _checkResponse(response);
    }
  }

  @override
  Future<void> deleteNote(String path) async {
    final uri = _uri('/vault/$path');
    final response = await _client.delete(uri, headers: _headers());
    _checkResponse(response);
  }

  // ---- UI operations ----

  @override
  Future<void> openNote(String path, {bool newLeaf = false}) async {
    final uri = _uri('/open/$path');
    final queryParams = newLeaf ? <String, String>{'newLeaf': 'true'} : null;
    final uriWithParams = queryParams != null
        ? uri.replace(queryParameters: queryParams)
        : uri;
    final response = await _client.post(uriWithParams, headers: _headers());
    _checkResponse(response);
  }

  // ---- Active file operations ----

  @override
  Future<String> readActiveFile() async {
    final uri = _uri('/active/');
    final response = await _client.get(
      uri,
      headers: _headers(accept: 'text/markdown'),
    );
    _checkResponse(response);
    return response.body;
  }

  @override
  Future<Map<String, dynamic>> readActiveFileStructured() async {
    final uri = _uri('/active/');
    final response = await _client.get(
      uri,
      headers: _headers(accept: 'application/vnd.olrapi.note+json'),
    );
    _checkResponse(response);
    return _parseJson(response);
  }

  @override
  Future<void> replaceActiveFile(String content) async {
    final uri = _uri('/active/');
    final response = await _client.put(
      uri,
      headers: _headers(contentType: 'text/markdown'),
      body: content,
    );
    _checkResponse(response);
  }

  @override
  Future<void> appendToActiveFile(String content) async {
    final uri = _uri('/active/');
    final response = await _client.post(
      uri,
      headers: _headers(contentType: 'text/markdown'),
      body: content,
    );
    _checkResponse(response);
  }

  @override
  Future<void> patchActiveFile(
    String content, {
    String? heading,
    String? blockId,
    bool frontmatter = false,
    String? insertPosition,
  }) async {
    final uri = _uri('/active/');
    final headers = <String, String>{};

    if (frontmatter) {
      headers.addAll(_headers(contentType: 'application/vnd.olrapi.note+json'));
      final response = await _client.patch(uri, headers: headers, body: content);
      _checkResponse(response);
    } else {
      headers.addAll(_headers(contentType: 'text/markdown'));
      if (heading != null) headers['Heading'] = heading;
      if (blockId != null) headers['Block-Reference'] = blockId;
      if (insertPosition != null) {
        headers['Content-Insertion-Position'] = insertPosition;
      }
      final response = await _client.patch(uri, headers: headers, body: content);
      _checkResponse(response);
    }
  }

  @override
  Future<void> deleteActiveFile() async {
    final uri = _uri('/active/');
    final response = await _client.delete(uri, headers: _headers());
    _checkResponse(response);
  }

  // ---- Periodic notes ----

  @override
  Future<String> readPeriodicNote(String period, {String? date}) async {
    final path = _periodicPath(period, date);
    final uri = _uri(path);
    final response = await _client.get(
      uri,
      headers: _headers(accept: 'text/markdown'),
    );
    _checkResponse(response);
    return response.body;
  }

  @override
  Future<Map<String, dynamic>> readPeriodicNoteStructured(
    String period, {
    String? date,
  }) async {
    final path = _periodicPath(period, date);
    final uri = _uri(path);
    final response = await _client.get(
      uri,
      headers: _headers(accept: 'application/vnd.olrapi.note+json'),
    );
    _checkResponse(response);
    return _parseJson(response);
  }

  @override
  Future<void> createPeriodicNote(
    String period,
    String content, {
    String? date,
  }) async {
    final path = _periodicPath(period, date);
    final uri = _uri(path);
    final response = await _client.put(
      uri,
      headers: _headers(contentType: 'text/markdown'),
      body: content,
    );
    _checkResponse(response);
  }

  @override
  Future<void> appendToPeriodicNote(
    String period,
    String content, {
    String? date,
  }) async {
    final path = _periodicPath(period, date);
    final uri = _uri(path);
    final response = await _client.post(
      uri,
      headers: _headers(contentType: 'text/markdown'),
      body: content,
    );
    _checkResponse(response);
  }

  @override
  Future<void> patchPeriodicNote(
    String period,
    String content, {
    String? date,
    String? heading,
    String? blockId,
    bool frontmatter = false,
    String? insertPosition,
  }) async {
    final path = _periodicPath(period, date);
    final uri = _uri(path);
    final headers = <String, String>{};

    if (frontmatter) {
      headers.addAll(_headers(contentType: 'application/vnd.olrapi.note+json'));
      final response = await _client.patch(uri, headers: headers, body: content);
      _checkResponse(response);
    } else {
      headers.addAll(_headers(contentType: 'text/markdown'));
      if (heading != null) headers['Heading'] = heading;
      if (blockId != null) headers['Block-Reference'] = blockId;
      if (insertPosition != null) {
        headers['Content-Insertion-Position'] = insertPosition;
      }
      final response = await _client.patch(uri, headers: headers, body: content);
      _checkResponse(response);
    }
  }

  @override
  Future<void> deletePeriodicNote(String period, {String? date}) async {
    final path = _periodicPath(period, date);
    final uri = _uri(path);
    final response = await _client.delete(uri, headers: _headers());
    _checkResponse(response);
  }

  /// Build the path for a periodic note endpoint.
  ///
  /// When [date] is null: `/periodic/{period}/`
  /// When [date] is provided (YYYY-MM-DD): `/periodic/{period}/{year}/{month}/{day}/`
  String _periodicPath(String period, String? date) {
    if (date == null) {
      return '/periodic/$period/';
    }
    // Parse YYYY-MM-DD into path segments
    final parts = date.split('-');
    if (parts.length != 3) {
      throw ArgumentError('Date must be in YYYY-MM-DD format');
    }
    final year = parts[0];
    final month = parts[1];
    final day = parts[2];
    return '/periodic/$period/$year/$month/$day/';
  }

  // ---- Search operations ----

  @override
  Future<List<Map<String, dynamic>>> searchSimple(
    String query, {
    int? contextLength,
  }) async {
    final queryParams = <String, String>{'query': query};
    if (contextLength != null) {
      queryParams['contextLength'] = contextLength.toString();
    }
    final uri = _uri('/search/simple/', queryParams: queryParams);
    final response = await _client.post(
      uri,
      headers: _headers(),
    );
    _checkResponse(response);
    // API returns array directly, not wrapped in object
    final dynamic decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> searchDql(String dqlQuery) async {
    final uri = _uri('/search/');
    final response = await _client.post(
      uri,
      headers: _headers(contentType: 'application/vnd.olrapi.dataview-dql+txt'),
      body: dqlQuery,
    );
    _checkResponse(response);
    return _parseJson(response);
  }

  @override
  Future<Map<String, dynamic>> searchJsonLogic(Map<String, dynamic> query) async {
    final uri = _uri('/search/');
    final response = await _client.post(
      uri,
      headers: _headers(contentType: 'application/vnd.olrapi.jsonlogic+json'),
      body: jsonEncode(query),
    );
    _checkResponse(response);
    return _parseJson(response);
  }

  // ---- Command operations ----

  @override
  Future<List<Map<String, dynamic>>> listCommands() async {
    final uri = _uri('/commands/');
    final response = await _client.get(uri, headers: _headers());
    _checkResponse(response);
    final json = _parseJson(response);
    final commands = json['commands'] as List<dynamic>?;
    return commands?.cast<Map<String, dynamic>>() ?? [];
  }

  @override
  Future<void> executeCommand(String commandId) async {
    final uri = _uri('/commands/$commandId/');
    final response = await _client.post(uri, headers: _headers());
    _checkResponse(response);
  }

  // ---- Raw escape hatch ----

  @override
  Future<dynamic> rawRequest(
    String method,
    String endpoint, {
    String? body,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  }) async {
    final uri = _uri(endpoint, queryParams: queryParams);
    final requestHeaders = <String, String>{};
    requestHeaders.addAll(_headers());
    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    late http.Response response;
    switch (method.toUpperCase()) {
      case 'GET':
        response = await _client.get(uri, headers: requestHeaders);
        break;
      case 'POST':
        response = await _client.post(
          uri,
          headers: requestHeaders,
          body: body,
        );
        break;
      case 'PUT':
        response = await _client.put(
          uri,
          headers: requestHeaders,
          body: body,
        );
        break;
      case 'PATCH':
        response = await _client.patch(
          uri,
          headers: requestHeaders,
          body: body,
        );
        break;
      case 'DELETE':
        response = await _client.delete(uri, headers: requestHeaders);
        break;
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }

    _checkResponse(response);

    // Try to parse as JSON, otherwise return raw body
    try {
      return jsonDecode(response.body);
    } on FormatException {
      return response.body;
    }
  }
}
