import 'dart:convert';

/// Base exception for Obsidian API errors.
///
/// Typed subclasses for common HTTP error codes:
/// - [AuthException] (401)
/// - [NotFoundException] (404)
/// - [MethodNotAllowedException] (405)
/// - [ConnectionException] (connection refused / timeout)
/// - [TlsException] (self-signed cert not trusted)
class ObsidianApiException implements Exception {
  /// Creates an API exception with [statusCode] and [message].
  const ObsidianApiException(this.statusCode, this.message, {this.detail});

  /// Parse an HTTP error response into a typed exception.
  ///
  /// Attempts to extract a meaningful message from the Obsidian REST API
  /// error response. Falls back to the raw body if parsing fails.
  factory ObsidianApiException.fromResponse(int statusCode, String body) {
    Map<String, dynamic>? json;
    String message;

    try {
      json = jsonDecode(body) as Map<String, dynamic>;
      final errorCode = json['errorCode'] as int?;
      final msg = json['message'] as String?;
      message = msg ?? 'HTTP $statusCode (errorCode: $errorCode)';
    } on FormatException {
      message = body.isNotEmpty ? body : 'HTTP $statusCode';
    }

    return switch (statusCode) {
      401 => AuthException(message, detail: json),
      404 => NotFoundException(message, detail: json),
      405 => MethodNotAllowedException(message, detail: json),
      _ => ObsidianApiException(statusCode, message, detail: json),
    };
  }

  /// HTTP status code.
  final int statusCode;

  /// Human-readable error message.
  final String message;

  /// Raw error response body (if parseable as JSON).
  final Map<String, dynamic>? detail;

  @override
  String toString() => 'ObsidianApiException($statusCode): $message';
}

/// Authentication failure (401 Unauthorized) -- bad or missing API key.
class AuthException extends ObsidianApiException {
  /// Creates an auth exception.
  const AuthException(String message, {Map<String, dynamic>? detail})
      : super(401, message, detail: detail);
}

/// Resource not found (404 Not Found) -- file/directory does not exist.
class NotFoundException extends ObsidianApiException {
  /// Creates a not-found exception.
  const NotFoundException(String message, {Map<String, dynamic>? detail})
      : super(404, message, detail: detail);
}

/// Method not allowed (405) -- e.g., GET on a non-existent periodic note type.
class MethodNotAllowedException extends ObsidianApiException {
  /// Creates a method-not-allowed exception.
  const MethodNotAllowedException(
    String message, {
    Map<String, dynamic>? detail,
  }) : super(405, message, detail: detail);
}

/// Connection refused / timeout -- Obsidian not running or API not enabled.
class ConnectionException extends ObsidianApiException {
  /// Creates a connection exception.
  const ConnectionException(String message, {Map<String, dynamic>? detail})
      : super(0, message, detail: detail);
}

/// TLS error -- self-signed cert not trusted.
class TlsException extends ObsidianApiException {
  /// Creates a TLS exception.
  const TlsException(String message, {Map<String, dynamic>? detail})
      : super(0, message, detail: detail);
}
